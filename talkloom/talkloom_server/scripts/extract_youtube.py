import sys
import json
import re
import urllib.request
from urllib.parse import parse_qs, urlparse

MAX_OEMBED_BYTES = 64 * 1024
MAX_TRANSCRIPT_BYTES = 2 * 1024 * 1024
DEFAULT_TARGET_LANG = 'de'

# Ensure UTF-8 output on Windows consoles
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

def _base_lang(code):
    return (code or '').lower().replace('_', '-').split('-')[0]


def iter_transcript_candidates(transcripts, target_lang):
    """Yield (transcript, translated) in preference order. Pure: no network.

    Order: target manual, target auto-generated, any manual translatable to
    the target, any manual, any auto-generated.
    """
    items = list(transcripts)
    target = _base_lang(target_lang)
    manual = [t for t in items if not t.is_generated]
    generated = [t for t in items if t.is_generated]
    for t in manual:
        if _base_lang(t.language_code) == target:
            yield t, False
    for t in generated:
        if _base_lang(t.language_code) == target:
            yield t, False
    for t in manual:
        if _base_lang(t.language_code) == target:
            continue
        if getattr(t, 'is_translatable', False):
            try:
                yield t.translate(target), True
            except Exception:
                continue
    for t in manual:
        if _base_lang(t.language_code) != target:
            yield t, False
    for t in generated:
        if _base_lang(t.language_code) != target:
            yield t, False


def fetch_youtube_data(url, target_lang=''):
    video_id = None
    parsed = urlparse(url)
    host = (parsed.hostname or '').lower().removeprefix('www.')
    if parsed.scheme != 'https' or host not in {'youtube.com', 'youtu.be'}:
        return _error_result('invalid_url')
    if host == 'youtu.be':
        video_id = parsed.path.strip('/').split('/')[0]
    elif parsed.path == '/watch':
        video_id = parse_qs(parsed.query).get('v', [None])[0]
    if video_id and not re.fullmatch(r'[A-Za-z0-9_-]{11}', video_id):
        video_id = None

    title = ''
    author = ''
    transcript = ''
    error = ''
    language = ''
    is_generated = False
    translated = False
    description = ''

    if video_id:
        # 1. Fetch title, author, and description
        try:
            oembed_url = f'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v={video_id}&format=json'
            req = urllib.request.Request(oembed_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=5) as res:
                payload = res.read(MAX_OEMBED_BYTES + 1)
                if len(payload) > MAX_OEMBED_BYTES:
                    raise ValueError('oEmbed response exceeded the size limit')
                data = json.loads(payload.decode('utf-8'))
                title = data.get('title', '')
                author = data.get('author_name', '')
        except Exception:
            pass

        try:
            watch_url = f'https://www.youtube.com/watch?v={video_id}'
            watch_req = urllib.request.Request(
                watch_url,
                headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/122.0.0.0'},
            )
            with urllib.request.urlopen(watch_req, timeout=5) as res:
                page_bytes = res.read(256 * 1024)
                page_text = page_bytes.decode('utf-8', errors='ignore')
                desc_match = re.search(r'<meta\s+name=["\']description["\']\s+content=["\']([^"\']+)["\']', page_text, re.IGNORECASE)
                if desc_match:
                    description = desc_match.group(1).strip()
        except Exception:
            pass

        # 2. Fetch transcript via youtube_transcript_api
        try:
            from youtube_transcript_api import YouTubeTranscriptApi
            api = YouTubeTranscriptApi()
            transcript_list = api.list(video_id)
            target = (target_lang or DEFAULT_TARGET_LANG).strip() or DEFAULT_TARGET_LANG
            for candidate, was_translated in iter_transcript_candidates(
                transcript_list, target
            ):
                try:
                    text = _join_bounded_transcript(candidate.fetch())
                except Exception:
                    continue
                if text:
                    transcript = text
                    language = (
                        target if was_translated else candidate.language_code
                    )
                    is_generated = bool(candidate.is_generated)
                    translated = was_translated
                    break
        except ImportError:
            error = 'transcript_dependency_missing'
        except Exception:
            error = 'transcript_unavailable'

    if transcript == '__transcript_too_large__':
        transcript = ''
        error = 'transcript_too_large'

    return {
        'videoId': video_id or '',
        'title': title or (f'YouTube Video ({video_id})' if video_id else 'YouTube Video'),
        'author': author,
        'description': description,
        'transcript': transcript,
        'error': error,
        'language': language,
        'isGenerated': is_generated,
        'translated': translated,
    }


def _join_bounded_transcript(snippets):
    parts = []
    byte_count = 0
    for snippet in snippets:
        text = getattr(snippet, 'text', '')
        if not text:
            continue
        byte_count += len(text.encode('utf-8')) + 1
        if byte_count > MAX_TRANSCRIPT_BYTES:
            return '__transcript_too_large__'
        parts.append(text)
    return ' '.join(parts)


def _error_result(error):
    return {
        'videoId': '',
        'title': 'YouTube Video',
        'author': '',
        'description': '',
        'transcript': '',
        'error': error,
        'language': '',
        'isGenerated': False,
        'translated': False,
    }

if __name__ == '__main__':
    url = sys.argv[1] if len(sys.argv) > 1 else ''
    target_lang = sys.argv[2] if len(sys.argv) > 2 else ''
    try:
        res = fetch_youtube_data(url, target_lang)
        print(json.dumps(res, ensure_ascii=False))
    except Exception:
        print(json.dumps(_error_result('transcript_unavailable')))

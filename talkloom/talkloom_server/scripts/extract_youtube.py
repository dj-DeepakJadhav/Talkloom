import sys
import json
import re
import urllib.request
from urllib.parse import parse_qs, urlparse

MAX_OEMBED_BYTES = 64 * 1024
MAX_TRANSCRIPT_BYTES = 2 * 1024 * 1024

# Ensure UTF-8 output on Windows consoles
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

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

    if video_id:
        # 1. Fetch title and author from oEmbed
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

        # 2. Fetch transcript via youtube_transcript_api
        try:
            from youtube_transcript_api import YouTubeTranscriptApi
            api = YouTubeTranscriptApi()
            transcript_list = api.list(video_id)
            languages_to_try = [target_lang] if target_lang else []
            languages_to_try.extend(['en', 'de', 'es', 'fr', 'it', 'pt'])
            
            try:
                t = transcript_list.find_transcript(languages_to_try)
                snippets = t.fetch()
                transcript = _join_bounded_transcript(snippets)
            except Exception:
                try:
                    for t in transcript_list:
                        snippets = t.fetch()
                        transcript = _join_bounded_transcript(snippets)
                        if transcript:
                            break
                except Exception:
                    pass
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
        'transcript': transcript,
        'error': error,
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
        'transcript': '',
        'error': error,
    }

if __name__ == '__main__':
    url = sys.argv[1] if len(sys.argv) > 1 else ''
    target_lang = sys.argv[2] if len(sys.argv) > 2 else ''
    try:
        res = fetch_youtube_data(url, target_lang)
        print(json.dumps(res, ensure_ascii=False))
    except Exception:
        print(json.dumps(_error_result('transcript_unavailable')))

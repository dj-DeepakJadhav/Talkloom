import sys
import json
import os
import re
import urllib.request

# Ensure UTF-8 output on Windows consoles
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

def fetch_youtube_data(url, target_lang=''):
    video_id = None
    if 'youtu.be/' in url:
        video_id = url.split('youtu.be/')[1].split('?')[0].split('&')[0]
    elif 'v=' in url:
        m = re.search(r'[?&]v=([^&]+)', url)
        if m:
            video_id = m.group(1)

    title = ''
    author = ''
    transcript = ''

    if video_id:
        # 1. Fetch title and author from oEmbed
        try:
            oembed_url = f'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v={video_id}&format=json'
            req = urllib.request.Request(oembed_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=5) as res:
                data = json.loads(res.read().decode('utf-8'))
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
                transcript = ' '.join([s.text for s in snippets if s.text])
            except Exception:
                try:
                    for t in transcript_list:
                        snippets = t.fetch()
                        transcript = ' '.join([s.text for s in snippets if s.text])
                        if transcript:
                            break
                except Exception:
                    pass
        except Exception:
            pass

    return {
        'videoId': video_id or '',
        'title': title or (f'YouTube Video ({video_id})' if video_id else 'YouTube Video'),
        'author': author,
        'transcript': transcript
    }

if __name__ == '__main__':
    url = sys.argv[1] if len(sys.argv) > 1 else ''
    target_lang = sys.argv[2] if len(sys.argv) > 2 else ''
    try:
        res = fetch_youtube_data(url, target_lang)
        print(json.dumps(res, ensure_ascii=False))
    except Exception as e:
        print(json.dumps({'videoId': '', 'title': 'YouTube Video', 'author': '', 'transcript': ''}))

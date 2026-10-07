"""Local GPU Qwen3-TTS worker. Access through authenticated Serverpod only."""
import hashlib
import json
import os
from pathlib import Path
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MODEL = os.environ.get('QWEN_TTS_MODEL', 'Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice')
VOICE = 'Ryan'
STYLE = 'Speak warmly and naturally, with clear standard German pronunciation and a relaxed conversational pace.'
CACHE = Path(os.environ.get('QWEN_TTS_CACHE', '.serverpod/tts-cache'))
LOCK = threading.Lock()
CAPACITY = threading.BoundedSemaphore(4)

def cache_key(text, language):
    return hashlib.sha256(json.dumps([MODEL, VOICE, STYLE, language, text],
        ensure_ascii=False).encode('utf-8')).hexdigest()

def synthesize(model, text, language):
    import soundfile as sf
    with LOCK:
        target = CACHE / (cache_key(text, language) + '.wav')
        if target.is_file():
            return target.read_bytes()
        wavs, sample_rate = model.generate_custom_voice(
            text=text, language={'de':'German', 'en':'English'}[language],
            speaker=VOICE, instruct=STYLE, max_new_tokens=1024)
        temporary = target.with_suffix('.tmp')
        sf.write(str(temporary), wavs[0], sample_rate, format='WAV', subtype='PCM_16')
        temporary.replace(target)
        # A bounded cache avoids accumulating private conversation audio forever.
        files = sorted(CACHE.glob('*.wav'), key=lambda p:p.stat().st_mtime)
        size = sum(p.stat().st_size for p in files)
        for old in files:
            if size <= 512 * 1024 * 1024:
                break
            if old != target:
                size -= old.stat().st_size
                old.unlink()
        return target.read_bytes()

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_args):
        pass  # No user text or request payloads in logs.

    def do_GET(self):
        if self.path != '/health':
            self.send_error(404)
            return
        body = json.dumps({'ready':True, 'model':MODEL, 'voice':VOICE, 'device':'cuda'}).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if self.path != '/synthesize':
            self.send_error(404)
            return
        try:
            length = int(self.headers.get('Content-Length', '0'))
            if not 0 < length <= 8192:
                raise ValueError()
            data = json.loads(self.rfile.read(length))
            text = data['text']
            language = data['language']
            if not isinstance(text, str) or not 0 < len(text.strip()) <= 600 or language not in ('de','en'):
                raise ValueError()
        except (ValueError, KeyError, TypeError):
            self.send_error(400, 'Invalid speech input')
            return
        if not CAPACITY.acquire(blocking=False):
            self.send_error(503, 'Speech queue is full')
            return
        try:
            audio = synthesize(self.server.model, text.strip(), language)
            self.send_response(200)
            self.send_header('Content-Type', 'audio/wav')
            self.send_header('Content-Length', str(len(audio)))
            self.end_headers()
            self.wfile.write(audio)
        except Exception:
            self.send_error(503, 'Speech generation failed')
        finally:
            CAPACITY.release()

def main():
    import torch
    from qwen_tts import Qwen3TTSModel
    if not torch.cuda.is_available():
        raise RuntimeError('Qwen worker needs CUDA PyTorch and an NVIDIA GPU.')
    CACHE.mkdir(parents=True, exist_ok=True)
    print('Loading Qwen3-TTS on CUDA...', flush=True)
    model = Qwen3TTSModel.from_pretrained(MODEL, device_map='cuda:0',
        dtype=torch.bfloat16, attn_implementation='sdpa')
    server = ThreadingHTTPServer(('127.0.0.1', 8130), Handler)
    server.model = model
    print('Qwen3-TTS ready on 127.0.0.1:8130', flush=True)
    server.serve_forever()

if __name__ == '__main__':
    main()

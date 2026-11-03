"""Local open-source TTS worker (Piper). No cloud, no key, CPU-friendly.

Serves German (and later es/fr/it) neural speech for Talkloom. The server
calls this worker; when it is down or a language is unsupported, the app
falls back to on-device voices. Cached WAVs live under .serverpod/tts-cache.
"""
import hashlib
import json
import os
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from tempfile import NamedTemporaryFile

VOICE_DIR = Path(os.environ.get('TALKLOOM_VOICE_DIR', Path.home() / '.talkloom' / 'voices'))
CACHE = Path(os.environ.get('TTS_CACHE_DIR', '.serverpod/tts-cache'))
CAPACITY = threading.BoundedSemaphore(4)

# Voice id -> model file. Two female, two male German voices.
# Quality: thorsten=high, rest=low. Expand per language as needed.
VOICES = {
    'de-thorsten-m': 'de_thorsten.onnx',
    'de-ramona-f': 'de_ramona.onnx',
    'de-kerstin-f': 'de_kerstin.onnx',
    'de-karlsson-m': 'de_karlsson.onnx',
}
DEFAULT_VOICE = 'de-thorsten-m'

_lock = threading.Lock()
_models = {}


def get_model(voice_id):
    model = _models.get(voice_id)
    if model is None:
        from piper import PiperVoice
        model_path = VOICE_DIR / VOICES[voice_id]
        model = PiperVoice.load(str(model_path))
        _models[voice_id] = model
    return model


def cache_key(text, language, voice_id):
    return hashlib.sha256(
        json.dumps([voice_id, language, text], ensure_ascii=False).encode()
    ).hexdigest()


def synthesize(text, language, voice_id):
    if language != 'de':
        raise ValueError(f'unsupported language: {language}')
    if voice_id not in VOICES:
        raise ValueError(f'unknown voice: {voice_id}')
    key = cache_key(text, language, voice_id)
    CACHE.mkdir(parents=True, exist_ok=True)
    target = CACHE / (key + '.wav')
    with _lock:
        if target.is_file():
            return target.read_bytes()
        model = get_model(voice_id)
        import wave as wav_module

        tmp = NamedTemporaryFile(delete=False, suffix='.wav', dir=CACHE)
        tmp.close()
        try:
            with wav_module.open(tmp.name, 'wb') as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)
                wav_file.setframerate(model.config.sample_rate)
                model.synthesize_wav(text, wav_file)
            data = Path(tmp.name).read_bytes()
            if len(data) < 1000 or data[0:4] != b'RIFF':
                raise RuntimeError('invalid wav produced')
            Path(tmp.name).replace(target)
            files = sorted(CACHE.glob('*.wav'), key=lambda p: p.stat().st_mtime)
            size = sum(p.stat().st_size for p in files)
            for old in files:
                if size <= 512 * 1024 * 1024:
                    break
                if old != target:
                    size -= old.stat().st_size
                    old.unlink()
            return data
        finally:
            Path(tmp.name).unlink(missing_ok=True)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_args):
        pass  # No user text in logs.

    def do_GET(self):
        if self.path != '/health':
            self.send_error(404)
            return
        body = json.dumps({'ready': True, 'voice': 'piper-thorsten-de', 'device': 'cpu'}).encode()
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
            length = int(self.headers.get('Content-Length', 0))
            if not 0 < length <= 8192:
                raise ValueError()
            data = json.loads(self.rfile.read(length))
            text = data['text']
            language = data.get('language', 'de')
            voice_id = data.get('voice', DEFAULT_VOICE)
            if not isinstance(text, str) or not 0 < len(text.strip()) <= 600:
                raise ValueError()
            if language not in ('de',) or voice_id not in VOICES:
                raise ValueError()
        except (ValueError, KeyError, TypeError):
            self.send_error(400, 'Invalid speech input')
            return
        if not CAPACITY.acquire(blocking=False):
            self.send_error(503, 'Speech queue is full')
            return
        try:
            audio = synthesize(text.strip(), language, voice_id)
            self.send_response(200)
            self.send_header('Content-Type', 'audio/wav')
            self.send_header('Content-Length', str(len(audio)))
            self.end_headers()
            self.wfile.write(audio)
        except ValueError as e:
            self.send_error(400, str(e))
        except Exception:
            self.send_error(503, 'Speech generation failed')
        finally:
            CAPACITY.release()


if __name__ == '__main__':
    get_model(DEFAULT_VOICE)  # Fail fast if the default voice is missing.
    server = ThreadingHTTPServer(('127.0.0.1', 8131), Handler)
    print(
        'Piper TTS ready on 127.0.0.1:8131 '
        f'(voices: {", ".join(sorted(VOICES))}, CPU)',
        flush=True,
    )
    server.serve_forever()

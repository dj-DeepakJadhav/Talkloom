"""Read a bounded PDF from stdin and emit its actual text as UTF-8."""
import io
import sys
from pypdf import PdfReader

MAX_BYTES = 8 * 1024 * 1024
MAX_TEXT = 2 * 1024 * 1024

def extract(data):
    if len(data) > MAX_BYTES or not data.startswith(b'%PDF-'):
        raise ValueError('Invalid or oversized PDF')
    reader = PdfReader(io.BytesIO(data))
    if reader.is_encrypted or len(reader.pages) > 200:
        raise ValueError('Encrypted or oversized PDF')
    parts = []
    size = 0
    for page in reader.pages:
        text = page.extract_text() or ''
        size += len(text.encode('utf-8'))
        if size > MAX_TEXT:
            raise ValueError('PDF text exceeds limit')
        parts.append(text)
    return '\n'.join(parts).strip()

if __name__ == '__main__':
    try:
        text = extract(sys.stdin.buffer.read(MAX_BYTES + 1))
        if not text:
            sys.exit(2)
        sys.stdout.buffer.write(text.encode('utf-8'))
    except Exception:
        sys.exit(1)

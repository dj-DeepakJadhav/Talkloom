"""Read a bounded DOCX from stdin and emit its text as UTF-8.

DOCX is a zip of XML parts; the body lives in word/document.xml.
Standard library only — no pip dependency. Legacy .doc (OLE binary)
is rejected: callers ask the learner to save as .docx or PDF instead.
"""
import io
import re
import sys
import zipfile

MAX_BYTES = 8 * 1024 * 1024
MAX_TEXT = 2 * 1024 * 1024


def extract(data):
    if len(data) > MAX_BYTES or not data.startswith(b'PK'):
        raise ValueError('Invalid or oversized DOCX')
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        names = zf.namelist()
        if 'word/document.xml' not in names:
            raise ValueError('Not a DOCX document')
        xml = zf.read('word/document.xml').decode('utf-8', errors='replace')
    # Paragraph and break boundaries become newlines before tags go.
    xml = re.sub(r'</w:p>', '\n', xml)
    xml = re.sub(r'<w:br[^>]*/>', '\n', xml)
    xml = re.sub(r'<w:tab[^>]*/>', ' ', xml)
    text = re.sub(r'<[^>]+>', '', xml)
    text = (
        text.replace('&amp;', '&')
        .replace('&lt;', '<')
        .replace('&gt;', '>')
        .replace('&quot;', '"')
        .replace('&#39;', "'")
    )
    text = re.sub(r'[ \t]+', ' ', text)
    text = re.sub(r'\n{3,}', '\n\n', text).strip()
    if len(text.encode('utf-8')) > MAX_TEXT:
        raise ValueError('DOCX text exceeds limit')
    return text


if __name__ == '__main__':
    try:
        text = extract(sys.stdin.buffer.read(MAX_BYTES + 1))
        if not text:
            sys.exit(2)
        sys.stdout.buffer.write(text.encode('utf-8'))
    except Exception:
        sys.exit(1)

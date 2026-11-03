import io
import unittest
from pypdf import PdfWriter
from pypdf.generic import DictionaryObject, NameObject, DecodedStreamObject
from extract_pdf import extract


class PdfExtractionTest(unittest.TestCase):
    def pdf(self, text=None, password=None):
        writer = PdfWriter()
        page = writer.add_blank_page(width=300, height=300)
        if text:
            font = DictionaryObject({NameObject('/Type'): NameObject('/Font'),
                                     NameObject('/Subtype'): NameObject('/Type1'),
                                     NameObject('/BaseFont'): NameObject('/Helvetica')})
            page[NameObject('/Resources')] = DictionaryObject({
                NameObject('/Font'): DictionaryObject({NameObject('/F1'): font})})
            stream = DecodedStreamObject()
            stream.set_data(('BT /F1 12 Tf 20 100 Td (' + text + ') Tj ET').encode())
            page[NameObject('/Contents')] = stream
        if password:
            writer.encrypt(password)
        output = io.BytesIO()
        writer.write(output)
        return output.getvalue()

    def test_reads_actual_page_text(self):
        self.assertEqual(extract(self.pdf('Guten Morgen!')), 'Guten Morgen!')

    def test_blank_page_does_not_manufacture_text(self):
        self.assertEqual(extract(self.pdf()), '')

    def test_rejects_encrypted_pdf(self):
        with self.assertRaises(ValueError):
            extract(self.pdf(password='test'))

    def test_rejects_non_pdf_bytes(self):
        with self.assertRaises(ValueError):
            extract(b'not a PDF')


if __name__ == '__main__':
    unittest.main()

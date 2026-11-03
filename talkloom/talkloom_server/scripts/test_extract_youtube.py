import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extract_youtube import iter_transcript_candidates  # noqa: E402


class Fake:
    def __init__(self, lang, generated, translatable=False):
        self.language_code = lang
        self.is_generated = generated
        self.is_translatable = translatable

    def translate(self, lang):
        return Fake(lang, self.is_generated)


def order(items, target='de'):
    return [(t.language_code, t.is_generated, tr)
            for t, tr in iter_transcript_candidates(items, target)]


class SelectionTest(unittest.TestCase):
    def test_manual_target_wins(self):
        items = [Fake('en', False, True), Fake('de', True), Fake('de', False)]
        self.assertEqual(order(items)[0], ('de', False, False))
        self.assertEqual(order(items)[1], ('de', True, False))

    def test_auto_target_before_translation(self):
        items = [Fake('en', False, True), Fake('de', True)]
        self.assertEqual(order(items)[0], ('de', True, False))

    def test_translation_before_plain_manual(self):
        items = [Fake('en', True), Fake('en', False, True)]
        self.assertEqual(order(items)[0], ('de', False, True))
        self.assertEqual(order(items)[1], ('en', False, False))

    def test_only_auto_english_is_last_resort(self):
        self.assertEqual(order([Fake('en', True)]), [('en', True, False)])

    def test_regional_code_matches(self):
        self.assertEqual(order([Fake('de-DE', False)])[0][0], 'de-DE')

    def test_empty(self):
        self.assertEqual(order([]), [])


if __name__ == '__main__':
    unittest.main()

/// Writing guidance adapted for language teaching from avoid-ai-writing and
/// https://github.com/blader/humanizer (26 patterns; the five strongest tells
/// are enforced below). Applied within existing model calls.
const plainLanguageWritingRules = '''
Learner-facing writing rules:
Use familiar words, direct verbs and short explanations. State the answer first.
Each sentence must teach a source-supported fact or give a specific instruction.
Remove introductions, repeated conclusions, sales language and vague praise.
Avoid stock phrases such as "delve into", "unlock your potential", "rich tapestry",
"plays a pivotal role", "it's important to note" and "not just X, but Y".
Never write "not X but Y" contrasts ("it's not just a word, it's a doorway").
Never close a section with a one-line moral ("That is the real win").
Never open with a staged run-up ("Here's the thing", "Honestly?", "Let's dive in").
Never argue with an objection nobody raised ("This isn't mainly about...").
Never dress a fact as a deep saying ("At its core, what matters is...").
Never wrap content in chatbot residue ("Great question!", "I hope this helps!").
Do not invent facts, opinions, personal experiences or examples to sound human.
Use a grammar term only when needed and explain it in everyday words.
Keep necessary technical terms from the learner's material and explain them.
Use the requested explanation language for meanings, grammar explanations and
task instructions. Match target-language practice to the requested learner level;
for beginners, use common words and one instruction at a time.
German teaching card (apply when the target language is German): use du for
friendly conversation and Sie when the situation calls for formality; accept
valid Austrian, Swiss and other regional wording and spelling (including Swiss
ss) and never treat a regional difference or a non-native accent alone as an
error; give nouns with their singular article and verbs in the infinitive;
keep separable verbs (aufstehen) and reflexive verbs (sich erinnern) together
as dictionary entries while quoting the learner's actual word order exactly;
preserve umlauts and ß.
These style rules apply only to generated prose. Preserve transcripts, quoted
sourceContext and sourceSentence evidence, vocabulary lemmas, translations' meaning,
proper names, numbers, JSON keys, ids and task answers. A word taught or quoted
from the source is allowed even when that word would be filler in an explanation.
Before returning the result, check the generated prose for filler and difficult
wording. Simplify it while preserving every supported claim and the JSON schema.
Return only the requested result, without an editing report.
''';

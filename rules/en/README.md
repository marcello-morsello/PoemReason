# English Module — PoemReason

## Files

- **`g2p.pl`** — Highly simplified English grapheme-to-phoneme mapper.
  Uses common digraph rules and basic vowel mapping.
  WARNING: English spelling is irregular; this provides approximate
  syllable counts, not accurate IPA.
- **`phonetics.pl`** — Accentual-syllabic scansion (iambic pentameter =
  10 syllables). Uses synaloepha and stress cut.

## Poetic tradition

English poetry uses accentual-syllabic meter (stress patterns within
syllable counts). For simplified scansion: syllable counting with
optional stress-based cut.

## Local forms

- **blank_verse** — Unrhymed iambic pentameter, 10 syllables
- **heroic_couplet** — Rhyming couplets, 10 syllables, AA BB...
- **common_metre** — Ballad stanza: 8-6-8-6, ABCB
- **rhyme_royal** — 7 lines, ABABBCC, 10 syllables (Chaucer)
- **spenserian_stanza** — 9 lines, ABABBCBCC, 8×10 + 1×12

## Limitations

- No pronunciation dictionary — irregular words will be wrong
- No stress marking — can't verify iambic/trochaic patterns
- Vowel quality is approximation only
- No /ð/ vs /θ/ distinction for 'th'

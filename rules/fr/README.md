# Module Français — PoemReason

## Fichiers

- **`g2p.pl`** — Conversion graphème-phonème simplifiée pour le français.
  Gère les voyelles nasales, le e-muet, les consonnes finales muettes.
- **`phonetics.pl`** — Scansion syllabique (alexandrin 12 syllabes).
  Pas de coupe à l'accent — toutes les syllabes comptent.

## Tradition poétique

La métrique française est syllabique :
- L'alexandrin (12 syllabes, césure à la 6e)
- Le décasyllabe (10 syllabes)
- L'octosyllabe (8 syllabes)
- Rime consonante et assonante
- Pas de sinalèphe — l'élision est gérée par le e-muet

## Formes locales

- **Sonnet français** — 14 alexandrins, ABBA ABBA CCD EED
- **Ballade** — 3 huitains + envoi de 4 vers, ababbcbC
- **Triolet** — 8 vers, ABaAabAB
- **Rondeau** — 15 vers, aabba aabR aabbaR
- **Pantoum** — Quatrains ABAB avec reprise de vers

## Limitations

- Distinction /e/-/ɛ/ non gérée sans accent
- Nasales appliquées même en attaque (ex: "ami" → "ɑ̃mi")
- /ə/ toujours utilisé pour le e-muet (pas de règles d'élision)
- Ouïgraphe "ou" non géré comme digraphe unique
- Liaison simplifiée

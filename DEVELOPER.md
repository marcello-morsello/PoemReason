# PoemReason — Developer Guide / Guia do Desenvolvedor

Welcome to the developer guide for PoemReason. This document explains the core concepts, data structures, and architectural flow of the multilingual poetry validation engine.

Bem-vindo ao guia do desenvolvedor do PoemReason. Este documento explica os conceitos fundamentais, estruturas de dados e o fluxo arquitetural do motor de validação poética multilíngue.

---

## 1. Architectural Philosophy / Filosofia Arquitetural

PoemReason is built on a hybrid architecture:
* **SWI-Prolog** handles the heavy lifting of linguistic rules, phonetic scansion, rhyme matching, and form constraints. Prolog's declarative paradigm is uniquely suited for this because poetry rules are naturally defined as constraints rather than step-by-step algorithms.
* **Python** handles CLI parsing, input serialization, subprocess orchestration, and output formatting.

O PoemReason é construído sobre uma arquitetura híbrida:
* **SWI-Prolog** lida com a parte pesada das regras linguísticas, escansão fonética, correspondência de rimas e restrições de forma. O paradigma declarativo do Prolog é perfeito para isso, pois as regras de poesia são definidas naturalmente como restrições, e não como algoritmos passo a passo.
* **Python** lida com o CLI, serialização de entrada, orquestração de subprocessos e formatação de saída.

### Architecture Data Flow / Fluxo de Dados da Arquitetura

```mermaid
graph TD
    Text[Raw Poem Text / Texto Cru] -->|--lang pt| Python[poemreason (Python CLI)]
    Python -->|build_loader(lang)| Loader[Temp Prolog Loader]
    Loader -->|loads| G2P[rules/{lang}/g2p.pl]
    Loader -->|loads| Phon[rules/{lang}/phonetics.pl]
    Loader -->|loads| CORE[common/core.pl]
    CORE -->|linha_sils| G2P
    CORE -->|verso_ln| Phon
    G2P -->|sil/5 + IPA| CORE
    Phon -->|contagens + caudas| CORE
    CORE -->|ln/4 records| HTML[common/html_report.pl]
    CORE -->|JSON stream| Python
    Python -->|table/json| Stdout
    HTML -->|Report file| File
```

### Per-language module structure / Estrutura por idioma

```
rules/{lang}/
├── g2p.pl              # Grapheme-to-phoneme mapping
├── phonetics.pl         # Scansion tradition + rhyme + local forms (multifile)
├── pipeline.pl          # Loader (imports {lang}/* + common/*)
└── README.md            # Documentation in the target language
```

Each language module must export:
- `g2p:g2p/3` — Converts a word atom to `sil/5` list + IPA atom
- `phonetics:contagens/3` — Returns valid metric counts for a verse
- `phonetics:cauda_consoante/2` — Consonant rhyme tail
- `phonetics:cauda_toante/2` — Assonant rhyme tail
- `phonetics:tradicao_padrao/1` — Default scansion tradition atom

Local forms are registered via `multifile`:
```prolog
:- multifile structural_validator:forma/4.
structural_validator:forma(mi_forma, N, M, [a,b,a,b]) :- repete(8, N, M).
```

---

## 2. Core Domain Concepts / Conceitos de Domínio

### A. Grapheme-to-Phoneme (G2P)

The G2P layer (`rules/{lang}/g2p.pl`) converts orthographic words into phoneme streams, determines syllable stress, and builds an IPA (International Phonetic Alphabet) string. Each language has its own G2P with specific phoneme inventories and orthographic rules.

A camada G2P (`rules/{lang}/g2p.pl`) converte palavras ortográficas em cadeias de fonemas, determina a sílaba tônica e monta a representação IPA. Cada idioma tem seu próprio G2P com inventário fonológico e regras ortográficas específicas.

### B. Enriched Syllable Representation / Representação Enriquecida (`sil/5`)

The core data structure representing a syllable is the `sil/5` functor:
`sil(Onset, Nucleus, Coda, Weight, Accent)`

A estrutura de dados central que representa uma sílaba é o functor `sil/5`:
`sil(Onset, Nucleus, Coda, Weight, Accent)`

* `Onset` (Ataque): Consonant cluster preceding the vowel (e.g. `[p, ɾ]` in *prato*).
* `Nucleus` (Núcleo): Vowels and glides (e.g. `[a]` in *prato*).
* `Coda`: Consonants following the nucleus (e.g. `[s]` in *passo*).
* `Weight` (Peso/Duração): Mora count (`1` or `2` units). Used by moraic traditions (Japanese).
* `Accent` (Acento/Tonicidade): Stress marking (`tonica` or `atona`). Used by syllabic traditions (Portuguese, Spanish, Italian).

### C. Scansion traditions / Tradições de escansão

| Tradition | Languages | Unit | Stress cut | Synaloepha |
|-----------|-----------|------|------------|------------|
| `portugues_silabico` | PT | syllable | yes (last stress) | yes |
| `espanhol_silabico` | ES | syllable | yes (last stress) | yes |
| `italiano_silabico` | IT | syllable | yes (last stress) | yes |
| `francais_syllabique` | FR | syllable | no | no |
| `haiku_japones` | JA | mora | no | no |
| `ingles_silabico` | EN | syllable | yes (last stress) | yes |
| `deutsch_silabico` | DE | syllable | no | no |

1. **Cut at Last Stressed Syllable (Corte na última tônica)**: Used by Portuguese, Spanish, Italian, English. Metric lines are only counted up to the last stressed syllable. Post-tonic syllables are ignored.
2. **Synaloepha (Sinalefa)**: When a word ending in a vowel is followed by a word starting with a vowel, they can merge into a single syllable. Since synaloepha is optional (poetic license), Prolog uses **backtracking** to generate all possible metric counts (e.g. `[6, 7]` syllables).
3. **No cut / full count**: Used by French and German. All syllables in the line are counted. French also applies e-muet rules handled at the G2P level.

### D. Rhyme Extraction / Extração de Rima

The rhyme engine extracts the phonetic rhyme tail of a verse starting from the nucleus of the last stressed syllable to the end of the line:

O motor de rimas extrai a cauda fonética do verso a partir do núcleo da última sílaba tônica até o final:

* **Consonant Rhyme (Rima Consoante)**: Vowels AND consonants are compared (e.g., *calma* `/ˈkawmɐ/` and *alma* `/ˈawmɐ/` rhyme).
* **Assonant Rhyme (Rima Toante)**: Only the vowels are compared (e.g., *casa* and *cama* have the same vowel sequence `[a, a]`).

#### Selecting the rhyme mode per form / Selecionando o modo por forma

Every verse is annotated by `core:verso_ln/2` with **both** tails: `ln(Text, IPA, Sils, rima(ConsonantTail, AssonantTail))`. The validator picks the right slot based on the form's rhyme scheme:

Cada verso é anotado pelo `core:verso_ln/2` com **as duas** caudas: `ln(Texto, IPA, Sils, rima(CaudaConsoante, CaudaToante))`. O validador escolhe o slot pelo esquema da forma:

* Bare list (`[a,b,a,b]`) → consonant comparison (strict; sonnets, decima, trova).
* `toante([a,b,a,b])` wrapper → assonant comparison (popular tradition; quadra, cordel sextilha).
* `toante([-,a,-,a])` → assonant on even verses only, odd verses free (seguidilla, copla).
* `livre` → no comparison (haiku, dodoitsu).
* `branco` → all consonant tails must be distinct (blank verse).

---

## 3. Adding a New Language / Adicionando um Novo Idioma

Create `rules/{lang}/` with four files:

```
rules/{lang}/
├── g2p.pl              # G2P: exports g2p/3
├── phonetics.pl         # Scansion: exports contagens/3, cauda_*/2, tradicao_padrao/1
├── pipeline.pl          # Loader: imports {lang}/* + common/*
└── README.md            # Documentation in the target language
```

1. **`g2p.pl`**: Implement `g2p(+Word, -Syllables, -IPA)`. Each syllable is `sil(Ons,Nuc,Cod,W,Ac)`. Return IPA as a flat atom.
2. **`phonetics.pl`**: Define `tradicao_padrao/1` with your tradition atom. Add `unidade/2`, `permite_sinalefa/1`, `conta_ate_tonica/1` as needed. Implement `escande/3`, `contagens/3`, `cauda_consoante/2`, `cauda_toante/2`.
3. **`pipeline.pl`**: Minimal loader. See any existing pipeline.pl as template.
4. **Register forms** via `multifile structural_validator:forma/4` and `multifile diagnostics:forma_estr/4`.
5. **Add to CLI**: Add the language code to `scripts/poemreason` `--lang` choices.
6. **Add tests**: Create `tests/{lang}_g2p_tests.pl`. Add to `scripts/test_all.sh`.

---

## 4. Rule Module Directory / Guia dos Módulos de Regras

### `rules/common/`

| Module | File | Exports | Role |
|--------|------|---------|------|
| **core** | `core.pl` | `linha_sils/3`, `verso_ln/2`, `gera_de_texto/4`, `api_version/1` | Language-agnostic orchestration. Calls `g2p:g2p/3` and `phonetics:*` via qualified calls. |
| **structural_validator** | `structural_validator.pl` | `forma/4`, `valida/2`, `identifica/2`, `diagnostico/2`, `exemplo/2` | Form dictionary + structure/rhyme/constraint validation. `forma/4` is `multifile`. |
| **diagnostics** | `diagnostics.pl` | `forma_estr/4`, `diagnostica/3`, `relatorio/2`, `estrofe_de/4` | Per-stanza error collection. Never fails — collects `prob/4` terms. `forma_estr/4` is `multifile`. |
| **html_report** | `html_report.pl` | `gera_html/5` | Interactive HTML with IPA, TTS buttons, diagnostic badges. |

### `rules/{lang}/`

| Module | Exports | Role |
|--------|---------|------|
| **g2p** | `g2p/3` | Language-specific grapheme-to-phoneme rules |
| **phonetics** | `escande/3`, `contagens/3`, `cauda_consoante/2`, `cauda_toante/2`, `tradicao_padrao/1` | Language-specific scansion + rhyme + local forms |
| **pipeline** | `linha_sils/3`, `verso_ln/2`, `gera_de_texto/4` | Loader that re-exports core predicates |

---

## 5. Testing / Testes

Tests use SWI-Prolog's built-in **plunit** library. They are placed in `tests/` and run automatically using:

Os testes usam a biblioteca nativa do SWI-Prolog **plunit**. Eles residem em `tests/` e são executados automaticamente através de:

```bash
./scripts/test_all.sh
```

To run a specific test suite:

```bash
swipl -q -s tests/pt_g2p_tests.pl -g "run_tests, halt" -t "halt(1)"
swipl -q -s tests/it_g2p_tests.pl -g "run_tests, halt" -t "halt(1)"
```

### Test naming convention / Convenção de nomenclatura

| Pattern | Example | Language |
|---------|---------|----------|
| `tests/*_tests.pl` | `tests/g2p_tests.pl` | Portuguese (original) |
| `tests/{lang}_*_tests.pl` | `tests/it_g2p_tests.pl` | Other languages |

---

## 6. Commit Attribution / Atribuição de Commits

AI agents contributing to this project are automatically credited via git hooks.
See [AGENTS.md](AGENTS.md) for the full policy and the `git ai-commit` wrapper script.

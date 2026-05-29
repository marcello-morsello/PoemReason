# PoemReason

A poetry validation engine powered by [SWI-Prolog](https://www.swi-prolog.org/).
Analyzes verse structure, scansion (syllable/mora counting), rhyme schemes,
and poetic forms — from haiku to sonnets.

Um motor de validação de poesia em [SWI-Prolog](https://www.swi-prolog.org/).
Analisa estrutura de versos, escansão (contagem silábica/moraica), esquemas
de rima e formas poéticas — do haiku ao soneto.

## Prerequisites

- [SWI-Prolog](https://www.swi-prolog.org/Download.html) 8.x or later
- [Python](https://www.python.org/downloads/) 3.x
- [GitHub CLI](https://cli.github.com/) (`gh`)

## Setup

```bash
git clone https://github.com/marcello-morsello/PoemReason.git
cd PoemReason
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
./scripts/check_env.sh
```

## Project structure

```
poemreason              CLI entry point (shell wrapper)
scripts/
├── poemreason          Python CLI (called by wrapper)
├── poem_to_yaml.py     Poem serializer (YAML + Prolog facts)
└── check_env.sh        Environment check (git, swipl, gh, python3, venv, pip)
rules/
├── g2p.pl              Grapheme-to-phoneme (Brazilian Portuguese)
├── phonetic_validator.pl  Scansion engine + rhyme (multilingual: PT syllabic, JP moraic)
├── structural_validator.pl  Structural form validation (haiku → sestina)
├── diagnostics.pl      Reporting layer (collects violations by stanza/verse)
├── html_report.pl      Interactive HTML report generator (links to static/)
└── pipeline.pl         End-to-end orchestration: text → G2P → validation → HTML
static/
├── style.css           Editorial stylesheet (cream paper, sepia ink)
└── script.js           Web Speech API vocalizer (TTS)
tests/
├── g2p_tests.pl        G2P unit tests (25 words)
├── phonetic_tests.pl   Scansion, mora, rhyme, form tests
├── structural_tests.pl Structural form tests (haiku, trova, villanelle, sestina)
├── diagnostics_tests.pl  Diagnostic report tests (sonnet, villanelle)
└── pipeline_tests.pl   End-to-end pipeline tests
requirements.txt        Python dependencies (pyyaml)
```

## Architecture / Arquitetura

The engine is organized in four layers:

O motor é organizado em quatro camadas:

| Layer / Camada | Module / Módulo | Role / Papel |
|---|---|---|
| 1 — Phonetics / Fonética | `g2p.pl` | Grapheme-to-phoneme: word → `sil/5` structures + IPA |
| 2a — Phonetic versification / Versificação fonética | `phonetic_validator.pl` | Scansion (escansão), synaloepha (sinalefa), rhyme extraction |
| 2b — Structural versification / Versificação estrutural | `structural_validator.pl` | Form catalog, metric/rhyme/constraint validation |
| 3 — Reporting / Relatório | `diagnostics.pl` + `html_report.pl` | Error collection + interactive HTML output |
| 4 — Pipeline / Orquestração | `pipeline.pl` | Raw text → full analysis → HTML |

### Supported forms / Formas suportadas

Haiku, tanka, trova, quadra, limerick, cordel (sextilha), décima, soneto italiano,
soneto inglês, vilanela, sextina, verso branco.

### Multilingual / Multilíngue

The `sil/5` representation supports both syllabic traditions (Portuguese — counts
syllables, cuts at last stress) and moraic traditions (Japanese — counts moras).
Each tradition uses exactly the trait the other discards: weight (duration) for
haiku; accent (stress) for decasyllable.

A representação `sil/5` suporta tanto tradições silábicas (português — conta
sílabas, corta na última tônica) quanto tradições moraicas (japonês — conta moras).

## CLI usage

The `poemreason` wrapper at the project root auto-detects `.venv` and runs the Python CLI.

### Analyze a poem from plain text

```bash
# Stanzas separated by blank lines
cat <<EOF | ./poemreason -f table
Eu sinto um grande amor
que sopra como o vento
e cura toda a dor
num passo doce e lento
EOF
```

### Analyze from JSON/YAML

```bash
echo '{"title":"Minha Trova","form":"trova","stanzas":[["Eu sinto um grande amor","que sopra como o vento","e cura toda a dor","num passo doce e lento"]]}' | ./poemreason
```

### Generate HTML report

```bash
cat poem.txt | ./poemreason --html report.html
```

### Run tests

```bash
# List available test suites
./poemreason --example

# Run a specific test suite
./poemreason --example g2p
./poemreason --example structural
```

### Direct Prolog queries

```bash
# G2P for a single word
swipl -q -s rules/g2p.pl -g "g2p(casa, _, IPA), format('~w~n', [IPA]), halt"

# Validate a structural form
swipl -q -s rules/structural_validator.pl \
  -g "exemplo(minha_trova, P), valida(trova, P), writeln(ok), halt" \
  -t "halt(1)"
```

## Contributing

All changes to `main` must go through a Pull Request. See [CLAUDE.md](CLAUDE.md) for coding conventions.

## License

This project is licensed under the [MIT License](LICENSE).

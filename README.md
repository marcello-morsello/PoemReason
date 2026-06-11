# PoemReason

A poetry validation engine powered by [SWI-Prolog](https://www.swi-prolog.org/).
Analyzes verse structure, scansion (syllable/mora counting), rhyme schemes,
and poetic forms — from haiku to sonnets, across 8 languages.

Um motor de validação de poesia em [SWI-Prolog](https://www.swi-prolog.org/).
Analisa estrutura de versos, escansão (contagem silábica/moraica), esquemas
de rima e formas poéticas — do haiku ao soneto, em 8 idiomas.

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
poemreason                     CLI entry point (shell wrapper)
scripts/
├── poemreason                 Python CLI (--lang pt|ja|it|fr|en|de|es)
├── prolog_bridge.py           Shared utilities for SWI-Prolog subprocess
├── analyze_poem               Legacy .md poem analyzer
├── check_env.sh               Environment check (git, swipl, gh, python)
├── git-commit-ai              AI commit wrapper (agent attribution)
├── git_hooks/
│   └── commit-msg             Auto-stamps Agent:/Co-Authored-By: trailers
└── test_all.sh                Runs all test suites across languages
rules/
├── common/                     Language-agnostic shared modules
│   ├── core.pl                 Orchestration (linha_sils, verso_ln, gera_de_texto)
│   ├── structural_validator.pl  Form catalog + valida/identifica/diagnostico
│   ├── diagnostics.pl           Per-stanza error collection + reporting
│   └── html_report.pl           Interactive HTML report (TTS, IPA)
├── pt/  (Português)            g2p.pl + phonetics.pl + pipeline.pl
├── ja/  (日本語)                g2p.pl + phonetics.pl + pipeline.pl
├── it/  (Italiano)             g2p.pl + phonetics.pl + pipeline.pl
├── fr/  (Français)             g2p.pl + phonetics.pl + pipeline.pl
├── en/  (English)              g2p.pl + phonetics.pl + pipeline.pl
├── de/  (Deutsch)              g2p.pl + phonetics.pl + pipeline.pl
└── es/  (Español)              g2p.pl + phonetics.pl + pipeline.pl
static/
├── style.css                   Editorial stylesheet (cream paper, sepia ink)
└── script.js                   Web Speech API vocalizer (TTS)
tests/
├── g2p_tests.pl / phonetic_tests.pl / structural_tests.pl / ...
├── it_g2p_tests.pl / fr_g2p_tests.pl / en_g2p_tests.pl / ...
├── de_g2p_tests.pl / es_g2p_tests.pl
└── pipeline_tests.pl
```

## Architecture / Arquitetura

The engine is organized in four layers:

O motor é organizado em quatro camadas:

| Layer / Camada | Modules / Módulos | Role / Papel |
|---|---|---|
| 1 — G2P | `rules/{lang}/g2p.pl` | Grapheme-to-phoneme: word → `sil/5` + IPA |
| 2a — Scansion | `rules/{lang}/phonetics.pl` | Syllable/mora count, synaloepha, rhyme extraction |
| 2b — Forms | `rules/common/structural_validator.pl` | Form catalog + metric/rhyme validation |
| 3 — Reporting | `rules/common/diagnostics.pl` + `html_report.pl` | Error collection + HTML output |
| 4 — Pipeline | `rules/{lang}/pipeline.pl` + `rules/common/core.pl` | Raw text → full analysis → output |

Each language supplies its own `g2p.pl` (phoneme rules), `phonetics.pl` (scansion tradition),
and `pipeline.pl` (loader). The `rules/common/` modules are shared across all languages.

Cada idioma fornece seu próprio `g2p.pl` (regras fonêmicas), `phonetics.pl` (tradição de
escansão) e `pipeline.pl` (carregador). Os módulos em `rules/common/` são compartilhados.

### Per-language dispatch / Despacho por idioma

The CLI flag `--lang` (default: `pt`) selects which language module to load:

```prolog
% Generated loader (rules/{lang}/g2p + phonetics + common/* + core)
:- use_module(rules/pt/g2p).
:- use_module(rules/pt/phonetics).
:- use_module(rules/common/structural_validator).
:- use_module(rules/common/diagnostics).
:- use_module(rules/common/html_report).
:- use_module(rules/common/core).
```

### Supported forms / Formas suportadas

| Language / Idioma | Local forms / Formas locais |
|---|---|
| PT — Português | trova, quadra, cordel_sextilha, décima, sonetos |
| JA — 日本語 | chōka, sedōka, bussokusekika, katauta, dodoitsu |
| IT — Italiano | terza rima, ottava rima, madrigale |
| FR — Français | sonnet_fr, ballade, triolet, rondeau, pantoum |
| EN — English | blank_verse, heroic_couplet, common_metre, rhyme_royal, spenserian_stanza |
| DE — Deutsch | knittelvers, blankvers, volksliedstrophe, alexandriner, distichon |
| ES — Español | seguidilla, redondilla, cuarteta, copla, lira, décima espinela, octava real, cuaderna vía, silva |

Shared forms across all languages: soneto_italiano, soneto_ingles, limerick, vilanela, sextina, verso_branco.

### Multilingual scansion / Escansão multilíngue

The `sil/5` representation supports multiple traditions:
- **Syllabic** (PT, ES, IT, FR): counts syllables, cuts at last stress, optional synaloepha
- **Moraic** (JA): counts moras (weight units), no stress cut, no synaloepha
- **Accentual-syllabic** (EN, DE): counts syllables, no stress cut (all syllables count)

A representação `sil/5` suporta múltiplas tradições:
- **Silábica** (PT, ES, IT, FR): conta sílabas, corta na última tônica, sinalefa opcional
- **Moraica** (JA): conta moras (unidades de peso), sem corte, sem sinalefa
- **Acentual-silábica** (EN, DE): conta sílabas, sem corte (todas as sílabas contam)

## CLI usage

```bash
# Portuguese (default)
echo "Velha lagoa quieta" | ./poemreason -f table

# Japanese
echo "ふるいけや かわずとびこむ みずのおと" | ./poemreason -l ja -f table

# Italian
echo "Nel mezzo del cammin di nostra vita" | ./poemreason -l it -f table

# French
echo "Je suis le ténébreux" | ./poemreason -l fr -f table

# English
echo "Shall I compare thee to a summer's day" | ./poemreason -l en -f table

# German
echo "Der Mond ist aufgegangen" | ./poemreason -l de -f table

# Spanish
echo "En un lugar de la Mancha" | ./poemreason -l es -f table

# Generate HTML report
cat poem.txt | ./poemreason --html report.html

# JSON output (default)
echo "Verso de exemplo" | ./poemreason
```

### Run tests

```bash
./scripts/test_all.sh          # All 116 tests across all languages
./poemreason --example         # List available test suites
./poemreason --example pt_g2p  # Run a specific suite
```

### Direct Prolog queries

```bash
# Portuguese G2P
swipl -q -s rules/pt/pipeline.pl -g "g2p:g2p(casa, _, IPA), writeln(IPA), halt"

# Japanese scansion
swipl -q -s rules/ja/pipeline.pl -g "core:verso_ln('ふるいけや', L), writeln(L), halt"

# Validate a structural form
swipl -q -s rules/common/structural_validator.pl \
  -g "exemplo(minha_trova, P), valida(trova, P), writeln(ok), halt"
```

## Contributing

All changes to `main` must go through a Pull Request.
See [AGENTS.md](AGENTS.md) for coding conventions and commit attribution policies.

## License

This project is licensed under the [MIT License](LICENSE).

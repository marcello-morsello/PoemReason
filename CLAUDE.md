# PoemReason — Poetry Validation Engine (SWI-Prolog)

## Overview
This project uses SWI-Prolog to validate and analyze poetic forms.
The engine performs grapheme-to-phoneme conversion, syllable/mora counting
(escansão), rhyme extraction, and structural form validation.
Rule modules live in `rules/*.pl`. Tests live in `tests/*.pl`.

Este projeto usa SWI-Prolog para validar e analisar formas poéticas.
O motor realiza conversão grafema-fonema, contagem silábica/moraica
(escansão), extração de rima e validação estrutural de formas.

## Environment
- **Storage**: Dropbox-synced directory (`~/Dropbox/Projects/PoemReason`), used across multiple machines.
  - Never commit Dropbox artifacts (`.dropbox`, `*.conflicted copy*`, etc.) — see `.gitignore`.
  - Be aware of potential sync conflicts when working on multiple machines simultaneously.
- **Git identity**: `marcello@morsello.net` (personal project, public GitHub repo).
- **GitHub repo**: `marcello-morsello/PoemReason`

### Branch protection (`main`)
- Direct pushes to `main` are **blocked** — all changes must go through a Pull Request.
- Force pushes and branch deletion are **disabled**.
- Enforce admins is **on** (rules apply to repo owner too).
- Always create a feature branch, open a PR, and merge via GitHub.

## Running a query
Use SWI-Prolog in non-interactive mode:

```bash
swipl -q -s rules/pipeline.pl -g "GOAL, halt" -t "halt(1)"
```

- `-q`: suppress banner
- `-s FILE`: load file
- `-g GOAL`: execute goal and exit
- `-t "halt(1)"`: exit code ≠ 0 on failure

Example — G2P for a single word:
```bash
swipl -q -s rules/g2p.pl -g "g2p(casa, _, IPA), format('~w~n', [IPA]), halt" -t "halt(1)"
```

Example — validate a poetic form:
```bash
swipl -q -s rules/structural_validator.pl \
  -g "exemplo(minha_trova, P), valida(trova, P), writeln(ok), halt" \
  -t "halt(1)"
```

## Language Rules

### Artifacts and directories
- All file names, directory names, module names, predicate names, variable names, and any other code identifiers **must be in English**.
- Commit messages and branch names must be in English.

### Interaction
- Conversation with the user may be in **Brazilian Portuguese** or **English** — follow the user's lead.

### Documentation
- Documentation (README, CLAUDE.md, file-header comments, docstrings) **must be bilingual**: English first (general audience), Brazilian Portuguese second (domain precision).
- Rationale: the MVP focuses on Lusophone poets, and the domain vocabulary (escansão, sinalefa, cauda consonante, ictus, paroxítona, etc.) carries technical meaning that loses precision in translation. Bilingual prose anchors the domain for native readers while keeping the POC readable for the international audience this public repo also serves.
- Inline comments explaining a Brazilian Portuguese phonetic, prosodic, or domain rule may be in Portuguese alone when that improves clarity.
- Identifiers, file/directory names, commit messages, branch names, PR titles, and CLI output remain **English-only** (see "Artifacts and directories" above).

## Conventions

### Modules
- Every `.pl` file **must** start with `:- module(name, [exported_predicates/arity]).`
- Exported predicates are documented with `%! pred(+Arg) is det.` above the first clause.
- Facts go in separate files from rules when possible.

### Determinism
- If a predicate should return a single answer, **use `!` (cut)** at the end of each non-fallback clause.
- The last fallback clause does not need a cut.
- Document determinism in the `%!` comment: `is det` (exactly one), `is semidet` (zero or one), `is nondet` (multiple).

### JSON output
- When output will be consumed by code, use `library(http/json)` and `json_write_dict/2` instead of `format/2`.
- Predicates that write JSON should be named `*_json/N`.

### Testing
- Use **plunit** (`library(plunit)`) — it ships with SWI-Prolog.
- Tests live in `tests/` with `_tests.pl` suffix.
- Use direct assertion style: `test(name) :- predicate(expected_args).`
- Add a determinism test with `forall` + `once/1` for predicates marked `is det`.
- Always run tests before committing:
  ```bash
  swipl -q -s tests/g2p_tests.pl -g "run_tests, halt" -t "halt(1)"
  swipl -q -s tests/phonetic_tests.pl -g "run_tests, halt" -t "halt(1)"
  swipl -q -s tests/structural_tests.pl -g "run_tests, halt" -t "halt(1)"
  swipl -q -s tests/diagnostics_tests.pl -g "run_tests, halt" -t "halt(1)"
  swipl -q -s tests/pipeline_tests.pl -g "run_tests, halt" -t "halt(1)"
  ```

## Environment check
Run `scripts/check_env.sh` to verify all required tools are installed.
It detects the OS (macOS/Linux/Windows) and prints install commands for any missing tool.

## Common tasks
- **Add a poetic form**: add a `forma/4` clause in `rules/structural_validator.pl`, then a test in `tests/structural_tests.pl`.
- **Add G2P rules**: edit `rules/g2p.pl`, run `tests/g2p_tests.pl`.
- **Debug**: use `trace, GOAL` in an interactive session (`swipl rules/pipeline.pl`).
- **Analyze a poem from text**:
  ```bash
  echo "Velha lagoa quieta" | ./poemreason -f table
  ```
- **Generate HTML report**:
  ```bash
  cat poem.txt | ./poemreason --html report.html
  ```

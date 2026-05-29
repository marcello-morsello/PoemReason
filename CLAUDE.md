# PoemReason — Deterministic Rules Engine (SWI-Prolog)

## Overview
This project uses SWI-Prolog for deterministic decision rules.
Rule bases live in `rules/*.pl`. Tests live in `tests/*.pl`.

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
swipl -q -s rules/core.pl -g "GOAL, halt" -t "halt(1)"
```

- `-q`: suppress banner
- `-s FILE`: load file
- `-g GOAL`: execute goal and exit
- `-t "halt(1)"`: exit code ≠ 0 on failure

Example:
```bash
swipl -q -s rules/core.pl -g "aprovar_credito(joao, V), format('~w~n', [V]), halt" -t "halt(1)"
```

## Language Rules

### Artifacts and directories
- All file names, directory names, module names, predicate names, variable names, and any other code identifiers **must be in English**.
- Commit messages and branch names must be in English.

### Interaction
- Conversation with the user may be in **Brazilian Portuguese** or **English** — follow the user's lead.

### Documentation
- Documentation (README, CLAUDE.md, inline comments, docstrings) should preferably be in **English**.
- Bilingual documentation (English + Brazilian Portuguese) is acceptable when clarity for the team requires it.
- Code comments explaining business rules specific to a Brazilian domain context may be in Portuguese if that improves understanding.

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
- Predicates that write JSON should be named `*_json/N` (e.g., `aprovar_credito_json/1`).

### Testing
- Use **plunit** (`library(plunit)`) — it ships with SWI-Prolog.
- Tests live in `tests/` with `_tests.pl` suffix.
- Use direct assertion style: `test(name) :- predicate(expected_args).`
- Add a determinism test with `forall` + `once/1` for predicates marked `is det`.
- Always run tests before committing:
  ```bash
  swipl -q -s tests/credit_tests.pl -g "run_tests, halt" -t "halt(1)"
  ```

## Common tasks
- **Add a rule**: edit `rules/core.pl`, run the corresponding test.
- **Debug**: use `trace, GOAL` in an interactive session (`swipl rules/core.pl`).
- **List predicates**: `swipl -q -s rules/core.pl -g "listing, halt"`.
- **JSON output for all clients**:
  ```bash
  swipl -q -s rules/core.pl -g "forall(core:cliente(C,_,_,_), aprovar_credito_json(C)), halt"
  ```

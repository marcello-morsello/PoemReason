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

## Commit attribution / Atribuição de commits

**Project rule**: every commit credits every contributor. The git
`Author` field credits the human at the keyboard; AI tools that
helped (Claude Code, Antigravity, Codex, etc.) are credited as
`Co-Authored-By` using the project's branded email pattern.

**Regra do projeto**: todo commit credita todos os contribuidores. O
campo `Author` do git credita o humano no teclado; ferramentas de IA
que ajudaram (Claude Code, Antigravity, Codex, etc.) são creditadas
como `Co-Authored-By` no padrão de email da marca do projeto.

### Brand convention / Convenção de marca

These projects use the brand **"Morsello & AI Sons"**.  AI co-authors
use emails under the project's domain in the form:

```
<tool>.ai@morsello.net
```

Currently registered:

| Tool / Ferramenta | `Agent:` trailer | `Co-Authored-By:` |
|---|---|---|
| Claude Code (Anthropic) | `Agent: claude` | `Claude Code <claude.ai@morsello.net>` |
| Antigravity (Google)    | `Agent: antigravity` | `Antigravity <antigravity.ai@morsello.net>` |
| Codex (OpenAI)          | `Agent: codex` | `Codex <codex.ai@morsello.net>` |
| DeepSeek / opencode     | `Agent: deepseek` | `DeepSeek <deepseek.ai@morsello.net>` |

### Per-human forks / Fork por humano

Each human contributor **must work from their own personal fork** of
this repository.  The `Author` field on every commit then carries the
contributor's own git identity (linked to their GitHub account),
which makes attribution unambiguous.  PRs flow from the personal fork
back to `marcello-morsello/PoemReason`.

Cada humano que contribui **deve trabalhar a partir do seu próprio
fork** deste repositório.  Assim o `Author` de cada commit carrega a
identidade git do humano (vinculada à sua conta GitHub), e a
atribuição fica inequívoca.  PRs sobem do fork pessoal para o
`marcello-morsello/PoemReason`.

### Automatic stamping / Carimbo automático

A `commit-msg` hook at `scripts/git_hooks/commit-msg` detects the AI
tool driving the current commit and injects two trailers:

```
Agent: <name>
Co-Authored-By: <Display> <name.ai@morsello.net>
```

Detection is by environment variable:

- Claude Code → `$CLAUDECODE` or `$CLAUDE_CODE_ENTRYPOINT`
- Antigravity → `$TERM_PROGRAM=antigravity-ide` or any `$ANTIGRAVITY_*`
- Codex CLI → `$CODEX_HOME` or any `$CODEX_*`
- opencode (DeepSeek) → `$OPENCODE` or any `$OPENCODE_*`
- Manual override: `AGENT_ID=<name> git commit ...`

The hook is **idempotent** (re-running doesn't duplicate trailers)
and only activates when a tool is detected — solo human commits in a
plain terminal pass through unchanged.

### Setup / Setup

`scripts/check_env.sh` is idempotent and sets
`git config core.hooksPath scripts/git_hooks` on every run.  Run it
once after every fresh clone:

```bash
./scripts/check_env.sh
```

### Convenience wrapper / Atalho: `git ai-commit`

A wrapper script at `scripts/git-commit-ai` (also available as the git alias
`git ai-commit`) sets the right environment variable so the hook stamps
attribution trailers automatically.  It is **agent-agnostic** — pass the agent
name via `-a <name>`.

Um script auxiliar em `scripts/git-commit-ai` (também disponível como alias
`git ai-commit`) define a variável de ambiente correta para que o hook
carimbe os trailers de atribuição automaticamente.  É **agnóstico de agente** —
passe o nome do agente via `-a <nome>`.

```bash
# Auto-detect (works inside an AI sandbox with known env vars):
git ai-commit -m "feat: add new form"

# Explicit agent override:
git ai-commit -a deepseek -m "feat: add new form"
git ai-commit -a claude -m "feat: add new form"
git ai-commit -a codex -m "feat: add new form"
git ai-commit -a antigravity -m "feat: add new form"

# Plain git commit — no trailers (human-only):
git commit -m "feat: add new form"
```

The alias is registered by `scripts/check_env.sh` (idempotent, run once).

O alias é registrado pelo `scripts/check_env.sh` (idempotente, execute uma vez).

### Multi-agent commits / Commits multi-agente

When a commit includes work from an agent that ran in a previous
session (not the one committing now), the committing party adds the
extra trailer manually:

```bash
git commit -m "..." --trailer "Co-Authored-By: Antigravity <antigravity.ai@morsello.net>"
```

Same rule for human pair-programming: a second human collaborator
adds themselves as `Co-Authored-By` with their personal email.

PR reviewers should reject PRs that omit known contributors —
attribution is project policy, not etiquette.

Quando um commit incluir trabalho de um agente que rodou em outra
sessão (não a do commit atual), quem comita adiciona o trailer extra
manualmente.  A mesma regra vale para programação em par humana:
o segundo colaborador se adiciona como `Co-Authored-By`.  Revisores
de PR devem rejeitar PRs que omitam contribuidores conhecidos —
atribuição é política do projeto, não etiqueta.

### Searching / Buscas

```bash
# Tudo que o DeepSeek tocou:
git log --grep "Agent: deepseek"

# Tudo que o Claude tocou:
git log --grep "Agent: claude"

# Tudo que o Codex tocou:
git log --grep "Agent: codex"

# Tudo que o Antigravity tocou:
git log --grep "Agent: antigravity"

# Tudo que envolveu qualquer agente de IA:
git log --grep "\.ai@morsello.net"

# Tabela de responsáveis por commit:
git log --format='%h | %an | %(trailers:key=Agent,valueonly,separator=%x2C )'
```

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
- Poem files in `poems/` follow the naming convention `<author>_<year>_<title>.md` and **must be UTF-8 encoded** (multilingual support: Portuguese, Japanese, etc.).
- Poem `.md` files start with `# Title — Author (Year)` on the first line.

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
- Always run the full test suite before committing:
  ```bash
  ./scripts/test_all.sh
  ```
- To run individual test suites manually:
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
- **Add a poetic form**: add a `forma/4` clause in `rules/structural_validator.pl`, then a test in `tests/structural_tests.pl`. The rhyme scheme is either a bare list `[a,b,a,b]` (consonant matching, default — strict forms) or `toante([a,b,a,b])` (assonant matching — popular tradition, e.g. quadra, cordel sextilha). The same wrapper convention applies to `forma_estr/4` in `rules/diagnostics.pl`.
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

## Where to run git/gh (sandbox vs. native)

**Git and `gh` are not reliable from the Cowork sandbox.** The repo lives
under a Dropbox mount (`~/Library/CloudStorage`); the sandboxed bash cannot
remove git locks (`.git/*.lock → Operation not permitted`), which leaves
commits half-done and wedges the branch.

Division of labor:

- **Cowork**: creates/edits files and runs verification (the test suites
  listed under **Testing** above) — anything that is **not** git. Does
  not execute `git commit` / `git push` / `gh` on this mount; instead,
  leaves changes ready and describes the suggested commit/PR.
- **Native terminal**: run `git ai-commit` (or `AGENT_ID=<name> git commit`)
  from a native terminal to stamp the correct attribution trailers.
- **Claude Code**: can also run locally, following the same branch protection
  rules documented under **Environment > Branch protection (`main`)**.

If a commit wedges with a stuck `.git/*.lock`, clean it from a native
terminal: `rm -f .git/*.lock`.

Confirm `gh auth status` before opening/merging a PR. If `gh` is not
available, open the PR via the URL printed by `git push`
(`https://github.com/.../pull/new/<branch>`).

## Verification before a PR

Before opening a PR, run the full test suite via:
```bash
./scripts/test_all.sh
```
All tests must report `passed`.

When the change touches the CLI or the pipeline, also run a sanity
analysis end-to-end:

```bash
echo "Velha lagoa quieta" | ./poemreason -f table
```

and confirm the output is well-formed.

## Multi-agent coexistence

This project is worked on by **Cowork**, **Claude Code** and possibly
**Codex**. `AGENTS.md` (this file) is the canonical, agent-agnostic spec.
`CLAUDE.md` is a one-line `@AGENTS.md` stub. Do not duplicate project
facts between the two — any new project fact goes here.

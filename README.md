# PoemReason

A deterministic rules engine powered by [SWI-Prolog](https://www.swi-prolog.org/).

## Prerequisites

- [SWI-Prolog](https://www.swi-prolog.org/Download.html) 8.x or later
- [Python](https://www.python.org/downloads/) 3.x
- [GitHub CLI](https://cli.github.com/) (`gh`)

## Setup

```bash
# Clone the repo
git clone https://github.com/marcello-morsello/PoemReason.git
cd PoemReason

# Create virtual environment and install dependencies
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt

# Verify everything is installed
./scripts/check_env.sh
```

## Project structure

```
poemreason              CLI entry point (shell wrapper)
scripts/
├── poemreason          Python CLI (called by wrapper)
└── check_env.sh        Environment check (git, swipl, gh, python3, venv, pip)
rules/
├── clients.pl          Client facts (cliente/4)
└── core.pl             Decision rules and JSON output
tests/
└── credit_tests.pl     plunit tests for credit approval
requirements.txt        Python dependencies (pyyaml)
```

## CLI usage

The `poemreason` wrapper at the project root auto-detects the `.venv` and runs the Python CLI.

### Evaluate clients from JSON

```bash
# Single client via stdin
echo '{"name":"ana","income":4000,"score":850,"debt":5000}' | ./poemreason

# Multiple clients from file
./poemreason --input clients.json
```

```json
{"cliente":"ana","decisao":"aprovado"}
```

### Evaluate clients from YAML

```bash
cat <<EOF | ./poemreason
- name: bruno
  income: 10000
  score: 650
  debt: 3500
- name: clara
  income: 5000
  score: 850
  debt: 9000
EOF
```

### Table output

```bash
echo '[{"name":"joao","income":5000,"score":720,"debt":800}]' | ./poemreason -f table
```

```
Client          Decision
-----------------------------------
joao            aprovado
```

### Interactive mode

```bash
./poemreason --interactive
```

Prompts for name, income, score, and debt for each client.

### Run tests

```bash
# List available test suites
./poemreason --example

# Run a specific test suite
./poemreason --example credit
```

### Direct Prolog queries

```bash
swipl -q -s rules/core.pl \
  -g "aprovar_credito(joao, D), format('~w~n', [D]), halt" \
  -t "halt(1)"
```

## Decision rules

| Condition | Decision |
|-----------|----------|
| Score >= 800 | `aprovado` (regardless of debt) |
| Score >= 700 and debt < 30% of income | `aprovado` |
| Score >= 600 and debt < 40% of income | `analise_manual` |
| Otherwise | `negado` |

## Contributing

All changes to `main` must go through a Pull Request. See [CLAUDE.md](CLAUDE.md) for coding conventions.

## License

This project is licensed under the [MIT License](LICENSE).

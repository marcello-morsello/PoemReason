# PoemReason

A deterministic rules engine powered by [SWI-Prolog](https://www.swi-prolog.org/).

## Prerequisites

- [SWI-Prolog](https://www.swi-prolog.org/Download.html) 8.x or later

## Project structure

```
rules/          Prolog rule modules
tests/          plunit test files
CLAUDE.md       AI assistant conventions and project guidelines
```

## Quick start

Run a credit decision query:

```bash
swipl -q -s rules/core.pl \
  -g "aprovar_credito(joao, Decision), format('~w~n', [Decision]), halt" \
  -t "halt(1)"
```

Get JSON output for all clients:

```bash
swipl -q -s rules/core.pl \
  -g "forall(core:cliente(C,_,_,_), aprovar_credito_json(C)), halt"
```

```json
{"cliente":"joao","decisao":"aprovado"}
{"cliente":"maria","decisao":"analise_manual"}
{"cliente":"pedro","decisao":"negado"}
{"cliente":"ana","decisao":"aprovado"}
```

## Decision rules

| Condition | Decision |
|-----------|----------|
| Score >= 800 | `aprovado` (regardless of debt) |
| Score >= 700 and debt < 30% of income | `aprovado` |
| Score >= 600 and debt < 40% of income | `analise_manual` |
| Otherwise | `negado` |

## Running tests

```bash
swipl -q -s tests/credit_tests.pl -g "run_tests, halt" -t "halt(1)"
```

## Contributing

All changes to `main` must go through a Pull Request. See [CLAUDE.md](CLAUDE.md) for coding conventions.

## License

This project is currently unlicensed. All rights reserved.

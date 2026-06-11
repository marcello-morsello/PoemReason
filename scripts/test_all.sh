#!/usr/bin/env bash
# ============================================================
#  test_all.sh — Run all unit tests for the PoemReason engine
#
#  Executa toda a suíte de testes unitários do motor PoemReason.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Running all PoemReason tests..."
echo "Executando todos os testes do PoemReason..."
echo "----------------------------------------"

# List of test files to run
TEST_FILES=(
    "tests/g2p_tests.pl"
    "tests/phonetic_tests.pl"
    "tests/structural_tests.pl"
    "tests/diagnostics_tests.pl"
    "tests/pipeline_tests.pl"
    "tests/it_g2p_tests.pl"
    "tests/fr_g2p_tests.pl"
    "tests/en_g2p_tests.pl"
    "tests/de_g2p_tests.pl"
    "tests/es_g2p_tests.pl"
    "tests/html_report_tests.pl"
    "tests/validate_pt.pl"
    "tests/validate_ja.pl"
    "tests/validate_it.pl"
    "tests/validate_fr.pl"
    "tests/validate_en.pl"
    "tests/validate_de.pl"
    "tests/validate_es.pl"
)

failed=0

echo "Running / Executando: pytest (Python CLI)..."
cd "$PROJECT_ROOT"
if ! .venv/bin/pytest -q tests/test_cli.py 2>&1; then
    echo "FAIL / FALHA: pytest"
    failed=1
else
    echo "PASS / PASSOU: pytest"
fi
echo "----------------------------------------"

for test_file in "${TEST_FILES[@]}"; do
    full_path="$PROJECT_ROOT/$test_file"
    if [ ! -f "$full_path" ]; then
        echo "Error: test file not found: $test_file"
        failed=1
        continue
    fi
    
    echo "Running / Executando: $test_file..."
    if ! swipl -q -s "$full_path" -g "run_tests, halt" -t "halt(1)"; then
        echo "FAIL / FALHA: $test_file"
        failed=1
    else
        echo "PASS / PASSOU: $test_file"
    fi
    echo "----------------------------------------"
done

if [ "$failed" -ne 0 ]; then
    echo "Some tests failed! / Alguns testes falharam!"
    exit 1
else
    echo "All tests passed successfully! / Todos os testes passaram com sucesso!"
fi

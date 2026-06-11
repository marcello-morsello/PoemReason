#!/usr/bin/env bash
# ============================================================
#  test_lang.sh — Run language-specific tests
#
#  Executa os testes específicos de uma língua + os comuns.
#  Uso:  ./scripts/test_lang.sh pt
#        ./scripts/test_lang.sh ja
#        ./scripts/test_lang.sh it
#        ./scripts/test_lang.sh fr
#        ./scripts/test_lang.sh en
#        ./scripts/test_lang.sh de
#        ./scripts/test_lang.sh es
# ============================================================

set -euo pipefail

LANG="${1:-}"

case "$LANG" in
  pt) LANG_NAME="Português"
      TESTS=(
        "tests/g2p_tests.pl"          # G2P rules
        "tests/phonetic_tests.pl"     # Scansion engine
        "tests/pipeline_tests.pl"     # Full pipeline
        "tests/validate_pt.pl"        # Poem validation
      ) ;;
  ja) LANG_NAME="日本語"
      TESTS=(
        "tests/validate_ja.pl"
      ) ;;
  it) LANG_NAME="Italiano"
      TESTS=(
        "tests/it_g2p_tests.pl"
        "tests/validate_it.pl"
      ) ;;
  fr) LANG_NAME="Français"
      TESTS=(
        "tests/fr_g2p_tests.pl"
        "tests/validate_fr.pl"
      ) ;;
  en) LANG_NAME="English"
      TESTS=(
        "tests/en_g2p_tests.pl"
        "tests/validate_en.pl"
      ) ;;
  de) LANG_NAME="Deutsch"
      TESTS=(
        "tests/de_g2p_tests.pl"
        "tests/validate_de.pl"
      ) ;;
  es) LANG_NAME="Español"
      TESTS=(
        "tests/es_g2p_tests.pl"
        "tests/validate_es.pl"
      ) ;;
  *)
      echo "Usage: $0 {pt|ja|it|fr|en|de|es}"
      echo ""
      echo "Available languages / Línguas disponíveis:"
      echo "  pt  Português"
      echo "  ja  日本語"
      echo "  it  Italiano"
      echo "  fr  Français"
      echo "  en  English"
      echo "  de  Deutsch"
      echo "  es  Español"
      exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Common tests shared by all languages
COMMON_TESTS=(
  "tests/structural_tests.pl"
  "tests/diagnostics_tests.pl"
  "tests/html_report_tests.pl"
)

echo "========================================"
echo "  $LANG_NAME ($LANG)"
echo "========================================"

failed=0

run_tests() {
  local label="$1"
  shift
  for test_file in "$@"; do
    full_path="$PROJECT_ROOT/$test_file"
    if [ ! -f "$full_path" ]; then
      echo "  NOT FOUND: $test_file"
      failed=1
      continue
    fi
    echo "  Testing: $test_file ..."
    if ! swipl -q -s "$full_path" -g "run_tests, halt" -t "halt(1)"; then
      echo "  FAIL: $test_file"
      failed=1
    else
      echo "  PASS: $test_file"
    fi
  done
}

echo ""
echo "--- Language-specific / Específicos ---"
run_tests "$LANG" "${TESTS[@]}"

echo ""
echo "--- Common / Comuns ---"
run_tests "common" "${COMMON_TESTS[@]}"

echo ""
echo "---"
if [ "$failed" -ne 0 ]; then
  echo "Some tests failed! / Alguns testes falharam!"
  exit 1
else
  echo "All tests passed! / Todos os testes passaram!"
fi

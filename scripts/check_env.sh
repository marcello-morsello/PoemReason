#!/usr/bin/env bash
# Check required tools for PoemReason development environment.

set -euo pipefail

# Detect OS
case "$(uname -s)" in
    Darwin*)  OS="macos";;
    Linux*)   OS="linux";;
    MINGW*|MSYS*|CYGWIN*) OS="windows";;
    *)        OS="unknown";;
esac

echo "Detected OS: $OS"
echo "---"

# Install command per OS
install_cmd() {
    local tool="$1"
    case "$OS" in
        macos)   echo "  brew install $tool";;
        linux)   echo "  sudo apt-get install -y $tool";;
        windows) echo "  winget install $tool";;
        *)       echo "  (unknown OS — install $tool manually)";;
    esac
}

# Map tool binary -> package name per OS
pkg_name() {
    local tool="$1"
    case "$tool" in
        swipl)
            case "$OS" in
                macos)   echo "swi-prolog";;
                linux)   echo "swi-prolog";;
                windows) echo "SWI-Prolog.SWI-Prolog";;
            esac;;
        gh)
            case "$OS" in
                macos)   echo "gh";;
                linux)   echo "gh";;
                windows) echo "GitHub.cli";;
            esac;;
        git)
            case "$OS" in
                macos)   echo "git";;
                linux)   echo "git";;
                windows) echo "Git.Git";;
            esac;;
        python3)
            case "$OS" in
                macos)   echo "python3";;
                linux)   echo "python3";;
                windows) echo "Python.Python.3";;
            esac;;
    esac
}

REQUIRED_TOOLS=(git swipl gh python3)
missing=0

for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        version=$("$tool" --version 2>/dev/null | head -1)
        echo "OK  $tool ($version)"
    else
        echo "MISSING  $tool"
        install_cmd "$(pkg_name "$tool")"
        missing=$((missing + 1))
    fi
done

echo "---"

# Check Python venv and pip dependencies
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_ROOT/.venv"
REQUIREMENTS="$PROJECT_ROOT/requirements.txt"

if [ ! -d "$VENV_DIR" ]; then
    echo "MISSING  .venv (Python virtual environment)"
    echo "  python3 -m venv .venv && .venv/bin/pip install -r requirements.txt"
    missing=$((missing + 1))
else
    echo "OK  .venv"
    VENV_PYTHON="$VENV_DIR/bin/python3"
    if [ -f "$REQUIREMENTS" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip empty lines and comments
            line="$(echo "$line" | sed 's/#.*//' | xargs)"
            [ -z "$line" ] && continue
            # Extract package name (strip version specifiers) and map to import name
            pkg="$(echo "$line" | sed 's/[><=!].*//')"
            case "$pkg" in
                pyyaml) import_name="yaml";;
                *)      import_name="$pkg";;
            esac
            if "$VENV_PYTHON" -c "import importlib; importlib.import_module('$import_name')" 2>/dev/null; then
                version=$("$VENV_PYTHON" -c "import $import_name; print(getattr($import_name, '__version__', 'installed'))" 2>/dev/null)
                echo "OK  pip: $pkg ($version)"
            else
                echo "MISSING  pip: $pkg"
                echo "  .venv/bin/pip install -r requirements.txt"
                missing=$((missing + 1))
            fi
        done < "$REQUIREMENTS"
    fi
fi

echo "---"

# ---- git hooks: agent commit attribution -------------------------
# Point git at scripts/git_hooks/ so the commit-msg hook stamps each
# commit with Agent: + Co-Authored-By: trailers automatically.
HOOKS_PATH="scripts/git_hooks"
CURRENT_HOOKS_PATH="$(git -C "$PROJECT_ROOT" config --get core.hooksPath 2>/dev/null || true)"
if [ "$CURRENT_HOOKS_PATH" = "$HOOKS_PATH" ]; then
    echo "OK  git hooks  (core.hooksPath -> $HOOKS_PATH)"
else
    git -C "$PROJECT_ROOT" config core.hooksPath "$HOOKS_PATH"
    echo "OK  git hooks  (set core.hooksPath -> $HOOKS_PATH)"
fi

echo "---"
if [ "$missing" -gt 0 ]; then
    echo "$missing item(s) missing. Install them and re-run this script."
    exit 1
else
    echo "All tools available."
fi

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
    esac
}

REQUIRED_TOOLS=(git swipl gh)
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
if [ "$missing" -gt 0 ]; then
    echo "$missing tool(s) missing. Install them and re-run this script."
    exit 1
else
    echo "All tools available."
fi

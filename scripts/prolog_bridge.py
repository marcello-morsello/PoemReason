#!/usr/bin/env python3
"""prolog_bridge — shared utilities for running SWI-Prolog subprocesses."""

import os
import subprocess
import sys
import tempfile


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
TMP_DIR = os.path.join(PROJECT_ROOT, "tmp")
TESTS_DIR = os.path.join(PROJECT_ROOT, "tests")
RULES_DIR = os.path.join(PROJECT_ROOT, "rules")


def find_swipl():
    """Locate the swipl binary."""
    from shutil import which
    path = which("swipl")
    if not path:
        print("Error: swipl not found. Install SWI-Prolog first.", file=sys.stderr)
        sys.exit(1)
    return path


def run_swipl(args, cwd=None):
    """Run swipl with given args, return (stdout, stderr, returncode)."""
    cmd = [find_swipl()] + args
    result = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd or PROJECT_ROOT)
    return result.stdout, result.stderr, result.returncode


def build_loader(lang):
    """Build a temp Prolog loader file for a given language code.

    The loader imports language-specific and common modules so that
    core:verso_ln/2, core:linha_sils/3, etc. are available.
    """
    lines = [
        ":- encoding(utf8).\n",
        f":- use_module(rules/{lang}/g2p).\n",
        f":- use_module(rules/{lang}/phonetics).\n",
        ":- use_module(rules/common/structural_validator).\n",
        ":- use_module(rules/common/diagnostics).\n",
        ":- use_module(rules/common/html_report).\n",
        ":- use_module(rules/common/core).\n",
        ":- use_module(library(http/json)).\n",
    ]
    return "".join(lines)


def build_loader_file(lang, prefix="analyze_"):
    """Create a temp .pl file with the loader for *lang*.

    Returns the path to the temp file.  The caller **must** unlink it
    when done (e.g. via ``try/finally``).
    """
    os.makedirs(TMP_DIR, exist_ok=True)
    tmp = tempfile.NamedTemporaryFile(
        mode="w", suffix=".pl", dir=TMP_DIR, prefix=prefix, delete=False
    )
    tmp.write(build_loader(lang))
    tmp.close()
    return tmp.name

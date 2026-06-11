"""Tests for the PoemReason CLI and Prolog bridge utilities.

Note: scripts/poemreason has no .py extension, so we load it via exec.
prolog_bridge.py is imported normally since it has the .py extension.
"""

import importlib.util
import json
import os
import sys
import tempfile
from unittest.mock import MagicMock, patch

import pytest

_root = os.path.join(os.path.dirname(__file__), "..")
_scripts = os.path.join(_root, "scripts")
sys.path.insert(0, _scripts)
sys.path.insert(0, _root)

from scripts import prolog_bridge as pb
from scripts.prolog_bridge import (
    PROJECT_ROOT,
    TMP_DIR,
    build_loader,
    build_loader_file,
    run_swipl,
    find_swipl,
)

# Load poemreason via exec (no .py extension)
_pr = {}
with open(os.path.join(_scripts, "poemreason")) as _f:
    exec(compile(_f.read(), "poemreason", "exec"), _pr)

parse_poem_input = _pr["parse_poem_input"]
classify_prose = _pr["classify_prose"]
build_stanzas_prolog = _pr["build_stanzas_prolog"]
print_table = _pr["print_table"]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _temp_input(text):
    f = tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False)
    f.write(text)
    f.close()
    return f.name


# ===========================================================================
#  prolog_bridge tests
# ===========================================================================


class TestBuildLoader:
    def test_pt(self):
        l = build_loader("pt")
        assert "rules/pt/g2p" in l and "rules/common/core" in l

    def test_ja(self):
        l = build_loader("ja")
        assert "rules/ja/g2p" in l

    def test_all_langs(self):
        for lang in ["pt", "ja", "it", "fr", "en", "de", "es"]:
            l = build_loader(lang)
            assert f"rules/{lang}/g2p" in l
            assert "rules/common/structural_validator" in l

    def test_encoding(self):
        assert "utf8" in build_loader("pt")

    def test_temp_file(self):
        path = build_loader_file("pt")
        assert os.path.isfile(path)
        with open(path) as f:
            assert "rules/pt/g2p" in f.read()
        os.unlink(path)


class TestFindSwipl:
    @patch("shutil.which")
    def test_found(self, m):
        m.return_value = "/usr/bin/swipl"
        assert find_swipl() == "/usr/bin/swipl"

    @patch("shutil.which")
    def test_missing(self, m):
        m.return_value = None
        with pytest.raises(SystemExit):
            find_swipl()


class TestRunSwipl:
    @patch("scripts.prolog_bridge.find_swipl")
    @patch("scripts.prolog_bridge.subprocess.run")
    def test_ok(self, mock_run, mock_find):
        mock_find.return_value = "/usr/bin/swipl"
        mock_run.return_value = MagicMock(stdout="ok", stderr="", returncode=0)
        assert run_swipl(["-q"])[0] == "ok"


# ===========================================================================
#  ParsePoemInput tests
# ===========================================================================


class TestParsePoemInput:
    def test_plain_single_stanza(self):
        p = _temp_input("A\nB\n")
        r = parse_poem_input(p)
        assert r["title"] == "Untitled"
        assert len(r["stanzas"]) == 1
        assert r["stanzas"][0] == ["A", "B"]
        os.unlink(p)

    def test_plain_multi_stanza(self):
        p = _temp_input("V1\nV2\n\nV3\nV4\n")
        r = parse_poem_input(p)
        assert len(r["stanzas"]) == 2
        os.unlink(p)

    def test_json(self):
        d = {"title": "J", "form": "t", "stanzas": [["V"]]}
        p = _temp_input(json.dumps(d))
        r = parse_poem_input(p)
        assert r["title"] == "J"
        os.unlink(p)

    def test_markdown_title(self):
        p = _temp_input("# T — A\n\nV\n")
        r = parse_poem_input(p)
        assert r["title"] == "T"
        os.unlink(p)

    def test_empty_exits(self):
        p = _temp_input("")
        with pytest.raises(SystemExit):
            parse_poem_input(p)
        os.unlink(p)

    def test_default_form(self):
        p = _temp_input("V\n")
        assert parse_poem_input(p)["form"] == "cancao"
        os.unlink(p)

    def test_yaml(self):
        p = _temp_input("title: Y\nform: t\nstanzas:\n  - [V]\n")
        assert parse_poem_input(p)["title"] == "Y"
        os.unlink(p)


# ===========================================================================
#  ClassifyProse tests
# ===========================================================================


class TestClassifyProse:
    def test_short_not_prose(self):
        assert classify_prose({"stanzas": [["a"]]}) is None

    def test_long_lines_are_prose(self):
        long = " ".join(["w"] * 30)
        assert classify_prose({"stanzas": [[long]]}) is not None

    def test_microconto(self):
        lines = [" ".join(["w"] * 15)] * 5  # 75 words: fits Microconto (<150)
        r = classify_prose({"stanzas": [lines]})
        assert r is not None and "Micro" in r["genre"]


# ===========================================================================
#  BuildStanzasProlog tests
# ===========================================================================


class TestBuildStanzas:
    def test_single(self):
        r = build_stanzas_prolog([["A", "B"]])
        assert '"A"' in r

    def test_multi(self):
        r = build_stanzas_prolog([["A"], ["B"]])
        assert r.count("[") == 3


# ===========================================================================
#  PrintTable tests
# ===========================================================================


class TestPrintTable:
    def test_basic(self, capsys):
        j = '{"verso":"X","silabas":[5],"rima":"a","ipa":"/a/"}\n'
        print_table(j, "T", "f")
        assert "Syllables" in capsys.readouterr().out

    def test_empty(self, capsys):
        print_table("", "T", "f")
        assert "No results" in capsys.readouterr().out

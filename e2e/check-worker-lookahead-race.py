#!/usr/bin/env python3
"""Executa a regressão de retomada concorrente usada pela suíte do worker."""
from pathlib import Path
import runpy

runpy.run_path(str(Path(__file__).resolve().parents[1] / "tests/check-worker-lookahead-race.py"),
               run_name="__main__")

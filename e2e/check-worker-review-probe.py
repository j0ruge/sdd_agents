#!/usr/bin/env python3
"""Recusa o verde de I11 quando o bloco de revisão não pôde ser carregado."""
from pathlib import Path
import subprocess
import sys


root = Path(sys.argv[1]).resolve()
result = subprocess.run(["bash", "tests/check-worker.sh"], cwd=root, text=True,
                        capture_output=True, timeout=550)
anchor = "  ok    review preserves the eligible delta"
errors = [line for line in result.stderr.splitlines() if "review-procedure:" in line]
if result.returncode or result.stdout.splitlines().count(anchor) != 1 or errors:
    if errors:
        print(f"A sonda de revisão reportou sucesso sem carregar o bloco: {errors[0]}",
              file=sys.stderr)
    else:
        print(result.stdout, result.stderr, file=sys.stderr)
    sys.exit(1)
print("1")

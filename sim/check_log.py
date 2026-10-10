#!/usr/bin/env python3
"""Strict simulator result gate: a sole PASS marker never overrides an error."""
import re
import sys
from pathlib import Path


def classify(text):
    if re.search(r"^#?\s*(?:UVM_(?:ERROR|FATAL)\b(?!\s*:\s*0\b)|\*\* (?:Error|Fatal):)", text, re.M) or "TEST FAILED" in text:
        return "FAIL"
    return "PASS" if text.count("[TEST_STATUS] TEST PASSED") == 1 else "UNKNOWN"


if __name__ == "__main__":
    result = classify(Path(sys.argv[1]).read_text(errors="replace"))
    print(result)
    sys.exit(0 if result == "PASS" else 1)

#!/usr/bin/env python3
"""Writes the spec fixtures the Swift tests read from an OpenUI clone's spec/fixtures/1.0:
spec-library.json (the test library) and spec-interactions.json (the cases with interactions.json).

Usage: python3 -I spec-fixtures.py <openui-clone> <fixtures-dir>
"""
import glob
import json
import os
import shutil
import sys

if len(sys.argv) != 3:
    sys.exit("usage: spec-fixtures.py <openui-clone> <fixtures-dir>")
spec = os.path.join(sys.argv[1], "spec", "fixtures", "1.0")
out = sys.argv[2]
shutil.copyfile(os.path.join(spec, "library.json"), os.path.join(out, "spec-library.json"))
cases = []
for path in sorted(glob.glob(os.path.join(spec, "*", "*", "interactions.json"))):
    folder = os.path.dirname(path)
    with open(os.path.join(folder, "input.oui")) as program, open(path) as interactions:
        data = json.load(interactions)
        cases.append({
            "name": os.path.relpath(folder, spec),
            "program": program.read(),
            "interactions": data["interactions"],
            "expected": data["expected"],
        })
with open(os.path.join(out, "spec-interactions.json"), "w") as file:
    json.dump(cases, file, indent=2, ensure_ascii=False)
print(f"{len(cases)} interaction cases written to {out}")

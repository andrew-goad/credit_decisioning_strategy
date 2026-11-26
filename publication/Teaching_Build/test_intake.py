"""Verify exact return, duplicate handling, and preservation of richer native examples."""
import base64
import copy
import csv
import hashlib
import json
import sys
from pathlib import Path
from bridge_intake import add_returned_cases

root = Path(__file__).parent
source = Path(sys.argv[1] if len(sys.argv) > 1 else "upload/teaching_cases.csv")
before = json.loads((root / "cases.json").read_bytes())
after = add_returned_cases(copy.deepcopy(before), source)
raw = source.read_bytes()
assert base64.b64decode(after["returnedSource"]["href"].split(",", 1)[1]) == raw
assert after["returnedSource"]["sha256"] == hashlib.sha256(raw).hexdigest()
with source.open(encoding="utf-8-sig", newline="") as f:
    rows = list(csv.DictReader(f))
observed = {}
for pair, group in after["groups"].items():
    for c in group["cases"]:
        if "returnedEvidence" not in c:
            continue
        for e in c["returnedEvidence"]:
            line = e["line"]
            assert line not in observed
            observed[line] = c
            row = rows[line - 2]
            assert row["pair_id"] == pair and row["application_id"] == c["id"]
            assert row["base_reason"] == c["base"]["primary"]
            assert row["test_path"] == c["challenge"]["path"]
assert set(observed) == {i for i, r in enumerate(rows, 2) if r["application_id"]}
# Make a richer native record at the same pair/id. It must keep the original source and terms.
case = copy.deepcopy(observed[min(observed)])
case.pop("returnedPartial");case.pop("returnedEvidence")
case["dti"] = 0.435
case["base"].update(source="archive", line=123, secondary="native reason")
g = rows[0]["pair_id"]
before["groups"][g]["cases"].append(case)
saved = add_returned_cases(copy.deepcopy(before), source)
matches = [c for c in saved["groups"][g]["cases"] if c["id"]==case["id"]]
assert len(matches) == 1
rich = dict(matches[0]); assert rich.pop("returnedEvidence"); assert rich == case
case["base"]["approved"] = 123
try:
    add_returned_cases(before, source)
except ValueError as e:
    assert "Conflicting" in str(e) and case["id"] in str(e)
else:
    raise AssertionError("Conflicting duplicate accepted")
print(f"PASS {len(observed)} source lines, byte-identical CSV download, native fields retained on overlap, conflicts rejected.")

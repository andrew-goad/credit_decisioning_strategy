"""Attach the operator's stratified case extract to the offline paired-application index."""
import base64
import csv
import hashlib
import io
import json
import math
import re
from collections import defaultdict
from pathlib import Path

COMMON = {
    "product": "product", "band": "score_band", "score": "credit_score",
    "income": "annual_income", "request": "requested_amount",
    "pti": "requested_payment_to_income_ratio", "pd": "estimated_pd",
    "lgd": "estimated_lgd", "requestEL": "requested_expected_loss_amount",
}
DECISIONS = {"outcome": "outcome", "approved": "amount", "approvedEL": "el",
             "primary": "reason", "path": "path"}
TEXT_KEYS = {"product", "band", "outcome", "primary", "path"}
OUTCOMES = {"APPROVE", "COUNTEROFFER", "MANUAL_REVIEW", "DECLINE"}
PRODUCTS = {"AUTO_LOAN", "MORTGAGE", "REVOLVING_LINE", "HELOC", "UNSECURED_PERSONAL_LOAN"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def value(key, raw):
    if key in TEXT_KEYS:
        require(raw != "", f"Missing {key}")
        return raw
    if raw == "" and key in {"approved", "approvedEL"}:
        return None
    number = int(raw) if key == "score" else float(raw)
    require(math.isfinite(number) and number >= 0, f"Invalid numeric value for {key}")
    return number


def validate_overlap(previous, current):
    # Compare only columns actually supplied by this extract. Archive null is evidence.
    for key in COMMON:
        require(previous[key] == current[key], f"Conflicting {key} for {current['id']}")
    for label in ("base", "challenge"):
        for key in DECISIONS:
            require(previous[label][key] == current[label][key],
                    f"Conflicting {label} {key} for {current['id']}")


def add_returned_cases(data, csv_path):
    csv_path = Path(csv_path)
    original = csv_path.read_bytes()
    receipt = json.loads(csv_path.with_name("campaign_provenance.json").read_bytes())
    reference = json.loads(Path(__file__).with_name("full_campaign_reference.json").read_bytes())["runs"]
    authority = reference["M2-01"]
    time = receipt["selected_time_utc"]
    refresh = receipt["selection"] == "OWNER_APPROVED_MAY28_REFRESH"
    require(receipt["analysis_mode"] == "Cases" and receipt["run"] == "M2-01"
            and receipt["strategy_run_id"] == authority["strategy_run_id"]
            and receipt["published_time_utc"] == authority["exportUTC"]
            and (receipt["other_runs_exact_original"], receipt["verified_runs"], receipt["unique_applications_per_run"])
                == (38, 39, 50000), "Case receipt does not cover the registered campaign")
    if refresh:
        require(re.fullmatch(r"2026-05-28T12:40:03\.698\d{3}\+00:00", time),
                "Unrecognized M2-01 refresh time in case receipt")
    else:
        require(receipt["selection"] == "PUBLISHED_ORIGINAL" and time == authority["exportUTC"],
                "Unrecognized M2-01 original time in case receipt")

    reader = csv.DictReader(io.StringIO(original.decode("utf-8-sig"), newline=""))
    additions = defaultdict(dict)
    per_lesson = {}
    examples = defaultdict(list)
    existing = {pair: {c["id"]: c for c in g["cases"]} for pair, g in data["groups"].items()}
    for row in reader:
        pair = row["pair_id"]
        group = data["groups"][pair]
        lesson = int(row["lesson_id"])
        count = int(row["qualifying_applications"])
        key = pair, lesson
        expected = reference[group["baseRun"]]
        require((row["baseline_run"], row["challenger_run"], row["scenario_set"], row["scenario_name"],
                 row["population_id"], row["pair_status"], row["baseline_rows"], row["challenger_rows"],
                 row["matched_ids"], row["changed_inputs"]) ==
                (group["baseRun"], group["challengeRun"], expected["module1_scenario_set_name"],
                 group["scenario"], group["population"], "READY", "50000", "50000", "50000", "0"),
                f"Unverified scope at CSV row {reader.line_num}")
        require(1 <= lesson <= 7 and 0 <= count <= 50000 and per_lesson.setdefault(key, count) == count,
                f"Invalid count for {key}")
        app = row["application_id"]
        if not app:
            require(not count and not row["example_number"] and not examples[key], f"Invalid empty case at {key}")
            examples[key].append(0)
            continue
        require(re.fullmatch(r"APP-\d{8}", app) and 1 <= int(app[4:]) <= 50000, f"Invalid ID {app}")
        examples[key].append(int(row["example_number"]))
        case = {k: value(k, row[col]) for k, col in COMMON.items()}
        require(case["product"] in PRODUCTS, f"Unknown product for {app}")
        case.update(id=app, dti=None, payment=None, returnedPartial=True)
        for label, prefix in (("base", "base"), ("challenge", "test")):
            side = {k: value(k, row[f"{prefix}_{col}"]) for k, col in DECISIONS.items()}
            require(side["outcome"] in OUTCOMES, f"Unknown decision for {app}")
            require((side["approved"] is None) == (side["approvedEL"] is None)
                    and (side["approved"] is None) == (side["outcome"] == "MANUAL_REVIEW"),
                    f"Missing or unexpected approved terms for {app}")
            side.update(paymentUnavailable=True, source="returnedCases", line=reader.line_num)
            case[label] = side
        evidence = {"line": reader.line_num, "lessonId": lesson, "lesson": row["lesson"]}
        if app in additions[pair]:
            previous = additions[pair][app]
            validate_overlap(previous, case)
            require(all(item["lessonId"] != lesson for item in previous["returnedEvidence"]),
                    f"Repeated application in one lesson at {key}")
            previous["returnedEvidence"].append(evidence)
            continue
        if app in existing[pair]:
            validate_overlap(existing[pair][app], case)
            case = dict(existing[pair][app])
        case["returnedEvidence"] = [evidence]
        additions[pair][app] = case

    require(len(per_lesson) == len(existing) * 7, "Incomplete comparison/question matrix")
    for key, count in per_lesson.items():
        expected = list(range(1, min(count, 4) + 1)) if count else [0]
        require(sorted(examples[key]) == expected, f"Incomplete sample at {key}")
    # Mutate only after the entire return and all overlapping records have reconciled.
    for pair, group in data["groups"].items():
        remaining = dict(additions[pair])
        group["cases"] = [remaining.pop(c["id"], c) for c in group["cases"]] + list(remaining.values())
    data["returnedSource"] = {"filename": csv_path.name, "sha256": hashlib.sha256(original).hexdigest(),
                              "href": "data:text/csv;base64," + base64.b64encode(original).decode("ascii"),
                              "refreshUTC": time if refresh else None}
    return data

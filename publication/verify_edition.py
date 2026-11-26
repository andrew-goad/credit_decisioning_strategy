"""Verify the distributable CDS teaching edition against its original DBeaver evidence.

Run at any location: python publication/verify_edition.py (requires lxml).
Verification reads the checked-out site, rebuilds it in a temporary directory,
and compares the decision projections to the independent archived exports.
"""
import csv
import gzip
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlsplit

from lxml import html

ROOT = Path(__file__).resolve().parents[1]
PUBLICATION = ROOT / "publication"
SITE = ROOT / "site"
TEACHING = PUBLICATION / "Teaching_Build"
M2 = ROOT / "Module_2_Credit_Policy_Strategy_&_Decision_Outcome_Simulation_Engine/v1.0"
PREFIX = "module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_"
BASE = "65e7cc84528008ea40c6f9bb70a02745df592f4c"
MANIFEST_SHA = "f75d8c848d1a285844d796d293eb7ae3b44bcbd8442d0d3282329332d07dc934"
REPO = "andrew-goad/credit_decisioning_strategy"
OUTCOMES = {"APPROVE": ("approvals", "approval_count"),
            "COUNTEROFFER": ("counteroffers", "counteroffer_count"),
            "MANUAL_REVIEW": ("reviews", "manual_review_count"),
            "DECLINE": ("declines", "decline_count")}
OFFER = {"APPROVE", "COUNTEROFFER"}
CENT = Decimal("0.01")
MILLION = Decimal("1000000")

# These fields are the user-facing 21-column projection of the original archive.
SOURCE_COLUMNS = {
    "product": "product_type", "band": "score_band", "score": "credit_score",
    "income": "annual_income", "dti": "debt_to_income_ratio", "request": "requested_amount",
    "payment": "requested_monthly_payment_proxy", "pti": "requested_payment_to_income_ratio",
    "pd": "estimated_pd", "lgd": "estimated_lgd", "requestEL": "requested_expected_loss_amount",
}
OUTCOME_COLUMNS = {
    "outcome": "decision_outcome", "approved": "approved_amount", "approvedEL": "approved_expected_loss_amount",
    "payment": "approved_monthly_payment_proxy", "pti": "approved_payment_to_income_ratio",
    "primary": "primary_reason_code", "secondary": "secondary_reason_code", "tertiary": "tertiary_reason_code",
    "path": "decision_path", "resolution": "decision_resolution_source",
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def export(name):
    with (M2 / "outputs" / (PREFIX + name + ".csv")).open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def find_one(doc, xpath, **args):
    matches = doc.xpath(xpath, **args)
    require(len(matches) == 1, f"Expected one {xpath!r} at {args}, got {len(matches)}")
    return matches[0]


def embedded(doc, identity):
    return json.loads(find_one(doc, '//script[@type="application/json" and @id=$id]', id=identity).text,
                      parse_float=Decimal)


def decode_values(vectors, fields, words, symbols):
    records = []
    for vector in vectors:
        row = dict(zip(fields, vector, strict=True))
        for field in symbols.intersection(row):
            index = row[field]
            if index is not None:
                require(type(index) is int and 0 <= index < len(words), f"Bad vocabulary index for {field}")
                row[field] = words[index]
        records.append(row)
    return records


def pick(records, refs, n):
    require(len(refs) == n and all(type(i) is int and 0 <= i < len(records) for i in refs),
            "Wrong number or range of packed references")
    return [records[index] for index in refs]


def read_sample(symbols):
    by_app = defaultdict(dict)
    for row in export("RANDOM_SAMPLE_strategy_decisions_archive"):
        app, run = row["application_id"], row["module2_run_id"]
        require(run not in by_app[app], f"Duplicate sample record for {app} {run}")
        expected = []
        for columns in (SOURCE_COLUMNS, OUTCOME_COLUMNS):
            record = {}
            for key, column in columns.items():
                raw = row[column]
                # The packer retains ordinary JSON number precision for the browser.
                value = raw if key in symbols else Decimal(str(float(raw))) if raw else None
                record[key] = value if raw else None
            expected.append(record)
        by_app[app][run] = expected
    return by_app


def full_archive(doc, data):
    raw_manifest = (data / "manifest.json").read_bytes()
    require(hashlib.sha256(raw_manifest).hexdigest() == MANIFEST_SHA, "Original full campaign manifest differs")
    manifest = json.loads(raw_manifest)
    require(manifest["authorityCommit"] == BASE and manifest["applications"] == 50_000, "Campaign identity differs")
    source_fields, outcome_fields = manifest["sourceFields"], manifest["outcomeFields"]
    require(source_fields == list(SOURCE_COLUMNS) and outcome_fields == list(OUTCOME_COLUMNS), "Projection fields differ")
    symbols = set(manifest["symbolFields"])
    runs = manifest["runs"]
    indices = {run: i for i, run in enumerate(runs)}
    groups = manifest["groups"]
    registry = {r["module2_run_id"]: r for r in export("strategy_run_campaign_registry")}
    pairs = {r["comparison_group_id"]: r for r in export("strategy_comparison_campaign_registry")}
    require(len(runs) == len(registry) == 39 and set(runs) == set(registry), "Run registry differs")
    require(set(groups) == set(pairs) and len(groups) == 20, "Comparison registry differs")
    require(all(manifest["sources"][s] == registry[r]["module1_run_id"] for r, s in zip(runs, manifest["runSource"], strict=True)),
            "Source scenarios differ from campaign registry")
    for group, (before, after) in groups.items():
        expected = pairs[group]
        require(manifest["runSource"][before] == manifest["runSource"][after] and
                (runs[before], runs[after]) == (expected["baseline_module2_run_id"], expected["challenger_module2_run_id"]),
                f"Registered pair differs for {group}")

    sample = read_sample(symbols)
    examples = defaultdict(list)
    for group, collection in embedded(doc, "archived-case-data")["groups"].items():
        for case in collection["cases"]:
            examples[case["id"]].append((group, case))
    totals = [Counter() for _ in runs]
    transitions = {g: Counter() for g in groups}
    changes = {g: Counter() for g in ("CG18", "CG20")}
    sample_count = case_count = 0
    require(len(manifest["shards"]) == 500, "500 shards required")
    require({p.relative_to(data).as_posix() for p in (data / "shards").iterdir()} ==
            {d["file"] for d in manifest["shards"]}, "Shard inventory differs")
    for number, desc in enumerate(manifest["shards"]):
        first = number * 100 + 1
        packed = (data / desc["file"]).read_bytes()
        require(len(packed) == desc["bytes"] and hashlib.sha256(packed).hexdigest() == desc["sha256"],
                f"{desc['file']} differs from its compressed archive digest")
        plain = gzip.decompress(packed)
        require(len(plain) == desc["uncompressedBytes"] and hashlib.sha256(plain).hexdigest() == desc["uncompressedSha256"],
                f"{desc['file']} differs from its uncompressed archive digest")
        shard = json.loads(plain, parse_float=Decimal)
        require(first == desc["first"] == shard["first"] and desc["last"] == first + 99 and len(shard["rows"]) == 100,
                f"Missing, repeated or out-of-order application range at {first}")
        for offset, (src, src_ref, outcomes, outcome_ref) in enumerate(shard["rows"]):
            app = f"APP-{first + offset:08d}"
            by_source = pick(decode_values(src, source_fields, shard["words"], symbols), src_ref, 19)
            decisions = pick(decode_values(outcomes, outcome_fields, shard["words"], symbols), outcome_ref, 39)
            for source in by_source:
                estimate = Decimal(source["request"]) * source["pd"] * source["lgd"]
                require(estimate.quantize(CENT, rounding=ROUND_HALF_UP) == source["requestEL"], f"{app} requested loss differs")
            for i, row in enumerate(decisions):
                counts = totals[i]
                counts[row["outcome"]] += 1
                counts["amount"] += row["approved"] or 0
                counts["loss"] += row["approvedEL"] or 0
            for run, (source, decision) in sample.get(app, {}).items():
                i = indices[run]
                require(source == by_source[manifest["runSource"][i]] and decision == decisions[i], f"Sample mismatch for {app} {run}")
                sample_count += 1
            for group, case in examples.get(app, []):
                baseline, challenger = groups[group]
                source = by_source[manifest["runSource"][baseline]]
                require(all(case[k] == v for k, v in source.items() if case.get(k) is not None), f"{app} {group} teaching source")
                for side, idx in (("base", baseline), ("challenge", challenger)):
                    keys = outcome_fields
                    if case.get("returnedPartial"):
                        keys = ("outcome", "approved", "approvedEL", "primary", "path")
                    elif case.get("sourceStudy"):
                        keys = [k for k in outcome_fields if k not in ("payment", "resolution")]
                    require(all(decisions[idx][k] == case[side][k] for k in keys), f"{app} {group} {side} teaching decision")
                case_count += 1
            for group, (baseline, challenger) in groups.items():
                old, new = decisions[baseline], decisions[challenger]
                old_offer, new_offer = old["outcome"] in OFFER, new["outcome"] in OFFER
                bucket = (("neither", "gained"), ("lost", "both"))[old_offer][new_offer]
                transitions[group][bucket] += 1
                if group in changes:
                    changes[group][bucket] += (new["approved"] or 0) - (old["approved"] or 0)
    require(sample_count == 13_583 and case_count == 940, f"Incomplete checks: {sample_count} archive rows, {case_count} teaching pairs")
    archived = {r["module2_run_id"]: r for r in export("strategy_run_evidence_summary")}
    for run, counts in zip(runs, totals, strict=True):
        row = archived[run]
        require(sum(counts[o] for o in OUTCOMES) == 50_000 and
                all(counts[o] == int(row[col]) for o, (_, col) in OUTCOMES.items()) and
                counts["amount"] == Decimal(row["total_approved_amount"]) and counts["loss"] == Decimal(row["total_approved_expected_loss_amount"]),
                f"{run} totals differ from archived run summary")
    displayed = {g["id"]: g for g in embedded(doc, "pf-evidence")}
    flow = embedded(doc, "offer-flow-data")["groups"]
    require(set(displayed) == set(flow) == set(groups), "Missing or extraneous portfolio comparison")
    for group, (baseline, challenger) in groups.items():
        b, c = displayed[group]["runs"]
        for shown, i in ((b, baseline), (c, challenger)):
            counts = totals[i]
            require(shown["run"] == runs[i] and all(shown[key] == counts[o] for o, (key, _) in OUTCOMES.items()) and
                    shown["offers"] == counts["APPROVE"] + counts["COUNTEROFFER"] and shown["exposure"] == counts["amount"]
                    and abs(shown["loss"] - counts["loss"]) < Decimal("0.00001"), f"{group} portfolio display")
        pair_counts = transitions[group]
        require(sum(pair_counts.values()) == flow[group]["denominator"] == 50_000 and
                flow[group]["counts"]["1"] == pair_counts["gained"] and flow[group]["counts"]["2"] == pair_counts["lost"],
                f"{group} matched offer movements")
    print("PASS 500 compressed and uncompressed shards; 50,000 IDs; 1,950,000 decisions; 950,000 requested loss estimates.")
    print("PASS 13,583 original sample rows × 21 fields; 940 teaching pairs; 39 run summaries and 20 matched portfolio comparisons.")
    return transitions, changes


def signed_amount(amount):
    rounded = (abs(amount) / MILLION).quantize(CENT, rounding=ROUND_HALF_UP)
    return ("+" if amount > 0 else "−") + f"${rounded:,.2f}M" if amount else "$0"


def validate_findings(doc, movements, changes):
    table = find_one(doc, '//*[@id="findings-exposure"]')
    for group, amounts in changes.items():
        counts = movements[group]
        expected = dict((k, (f"{counts[k]:,}", signed_amount(amounts[k]))) for k in ("gained", "lost", "both", "neither"))
        for key, values in expected.items():
            td = find_one(table, './/tr[@data-offer-group=$key]/td[@data-comparison=$group]', key=key, group=group)
            require(tuple(s.text_content().strip() for s in td.xpath('./span')) == values, f"{group} {key} counts and dollars differ")
        td = find_one(table, './/tfoot//td[@data-comparison=$group]', group=group)
        net = counts["gained"] - counts["lost"]
        require(tuple(s.text_content().strip() for s in td.xpath('./span')) == (f"{net:+,}", signed_amount(sum(amounts.values()))),
                f"{group} net counts or offered exposure differ")
    example = find_one(doc, '//*[@id="growth-offer-example"]').text_content()
    for quantity in ("gained", "lost"):
        require(f'{movements["CG02"][quantity]:,}' in example, f"Opening CG02 {quantity} omitted")
    snaps = {r["module2_run_id"]: r for r in export("strategy_run_parameter_snapshot")}
    policy_text = find_one(doc, '//*[@id="counteroffer-policy-change"]').text_content()
    for scenario in ("M2-01", "M2-37", "M2-28", "M2-39"):
        products = json.loads(snaps[scenario]["product_policy_params_jsonb"], parse_float=Decimal)
        heloc = next(p for p in products if p["product_type"] == "HELOC")
        expected = (f"${heloc['product_max_approved_amount']:,.0f}", f"{100 * heloc['counteroffer_target_pti']:.0f}%",
                    f"${heloc['product_approved_el_cap']:,.0f}")
        require(all(value in policy_text for value in expected), f"{scenario} HELOC policy values differ")
    print("PASS visible CG18/CG20 matched funding table, CG02 offer movements and archived HELOC policy settings.")


def compare_module1_versions():
    fields = ("requested_amount", "monthly_payment_proxy", "payment_to_income_ratio", "amount_to_income_ratio",
              "mult_pti", "estimated_pd", "expected_loss_amount")
    source = next(ROOT.glob("Module_1*/v1.0/outputs/*Output_Synthetic_Applications.csv"))
    revised = next(ROOT.glob("Module_1*/v2.0/outputs/*OUTPUT_synthetic_applications.csv"))
    with source.open(encoding="utf-8-sig", newline="") as f:
        original = {row["application_id"]: tuple(Decimal(row[field]) for field in fields) for row in csv.DictReader(f)}
    require(len(original) == 50_000, "Original Module 1 baseline is incomplete")
    changed = 0
    with revised.open(encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            before = original.pop(row["application_id"])
            changed += before != tuple(Decimal(row[field]) for field in fields)
    require(not original, "Revised Module 1 baseline is incomplete")
    require(changed == 21_326, f"Power BI comparison count differs across the seven published measures: {changed}")
    return changed


def verify_chooser_numbers(doc, movements, exposure):
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    release = (PUBLICATION / "RELEASE.md").read_text(encoding="utf-8")
    groups = embedded(doc, "archived-case-data")["groups"]
    portfolios = {p["id"]: p["runs"] for p in embedded(doc, "pf-evidence")}
    opening = next(c for c in groups["CG02"]["cases"] if c["id"] == "APP-00032476")
    before, after = portfolios["CG02"]
    amounts = (
        f'${opening["request"]:,.2f}', f'{opening["score"]}', f'{opening["pd"] * 100:.4f}%',
        f'${opening["payment"]:,.2f}', f'{opening["pti"] * 100:.2f}%', f'${opening["challenge"]["approvedEL"]:,.2f}',
        f'{movements["CG02"]["gained"]:,}', f'{movements["CG02"]["lost"]:,}', f'{after["offers"] - before["offers"]:,}',
        f'${(after["exposure"] - before["exposure"]) / MILLION:,.2f} million',
        f'${(after["loss"] - before["loss"]) / MILLION:,.2f} million',
    )
    for value in amounts:
        require(value in readme, f"Missing verified opening or portfolio figure in README: {value}")
    for group in ("CG18", "CG20"):
        counts = movements[group]
        net_dollars = sum(exposure[group].values())
        require(f'{counts["gained"] - counts["lost"]:,}' in readme and f'${abs(net_dollars) / MILLION:,.2f} million' in readme,
                f"{group} findings differ in README")
    all_cases = [case for group in groups.values() for case in group["cases"]]
    require(f'{len(all_cases):,}' in release and f'{len({case["id"] for case in all_cases}):,}' in release,
            "Offline chooser's teaching case coverage differs")
    changed = compare_module1_versions()
    require(f"{changed:,}" in readme and f"{changed:,}" in doc.text_content(), "Generator comparison count differs in the publication")
    print(f"PASS README credit math and portfolio figures, release case coverage and {changed:,} changed IDs in the two original Module 1 baselines.")


def verify_routes():
    documents = {}
    for page in SITE.rglob("*.html"):
        document = html.fromstring(page.read_bytes())
        ids = Counter(document.xpath('//*[@id]/@id'))
        require(all(n == 1 for n in ids.values()), f"Duplicate HTML IDs in {page.name}")
        documents[page] = (set(ids), set(document.xpath('//*[@href]/@href | //*[@src]/@src')))

    links = [(page, url) for page, (_, urls) in documents.items() for url in urls if url]
    markdown = [ROOT / "README.md", ROOT / "PROJECT_ARTIFACT_MAP.md", PUBLICATION / "RELEASE.md",
                M2 / "docs/MODULE_2_BUSINESS_REQUIREMENTS.md", M2 / "tests/MODULE_2_VALIDATION_SUMMARY.md"]
    for path in markdown:
        text = path.read_text(encoding="utf-8")
        links.extend((path, url) for url in re.findall(r'\]\(([^\s)]+)\)', text))

    checked = 0
    for origin, url in links:
        parsed = urlsplit(url)
        path = unquote(parsed.path)
        if parsed.netloc == "andrew-goad.github.io" and path.rstrip("/") == "/credit_decisioning_strategy":
            destination = SITE / "index.html"
        elif parsed.netloc in {"github.com", "raw.githubusercontent.com"}:
            # Resolve the repository file portion against the preserved historical source tree.
            parts = path.strip("/").split("/")
            if "/".join(parts[:2]) != REPO or len(parts) < 4 or parts[2] == "releases":
                continue
            if parsed.netloc == "github.com" and parts[2] not in {"tree", "blob", "raw"}:
                continue
            offset = 3 if parsed.netloc == "raw.githubusercontent.com" else 4
            destination = ROOT.joinpath(*parts[offset:])
        elif parsed.scheme or parsed.netloc:
            continue
        else:
            destination = (origin.parent / path).resolve() if path else origin
        require(destination.is_relative_to(ROOT) and destination.exists(), f"Link target missing in {origin.name}: {url}")
        if destination in documents:
            ids = documents[destination][0]
            require(not parsed.fragment or unquote(parsed.fragment) in ids, f"Missing anchor from {origin.name}: {url}")
            params = parse_qs(parsed.query)
            for group in params.get("comparison", []):
                require(group in {f"CG{i:02d}" for i in range(1, 21)}, f"Unknown comparison in {url}")
            for app in params.get("app", []):
                require(re.fullmatch(r"APP-\d{8}", app) and 1 <= int(app[4:]) <= 50_000, f"Unknown applicant in {url}")
        checked += 1
    print(f"PASS {checked} local, cross-surface and repository file targets in {len(documents)} HTML pages and {len(markdown)} Markdown documents.")


def verify_distribution():
    with tempfile.TemporaryDirectory(prefix="cds-rebuild-") as folder:
        scratch = Path(folder)
        returned = PUBLICATION / "Case_Discovery/Returned/teaching_cases.csv"
        june = PUBLICATION / "Case_Discovery/Source_rows"
        originals = ["--repo", str(ROOT), "--returned", str(returned), "--june", str(june)]
        inputs = [
            ("build_worked_decision_math.py", "worked_decision_math.json", []),
            ("build_counteroffer_gates.py", "counteroffer_gate_data.json",
             ["--case-dir", str(TEACHING), "--borrower", str(TEACHING / "borrower_math.json")]),
        ]
        for script, output, extra in inputs:
            dest = scratch / output
            subprocess.run([sys.executable, "-B", str(TEACHING / script), *originals, *extra, "--output", str(dest)],
                           cwd=ROOT, check=True)
            # Path.write_text on Windows may use CRLF for these intermediate JSON files.
            require(dest.read_text(encoding="utf-8") == (TEACHING / output).read_text(encoding="utf-8"), f"Rebuilt {output} differs")
        print("PASS worked decision and counteroffer calculations reproduce the distributed evidence.")
        rebuilt = scratch / "site"
        subprocess.run([sys.executable, "-B", str(TEACHING / "build.py"), "--repo", str(ROOT),
                        "--output", str(rebuilt / "index.html")], cwd=ROOT, check=True)
        generated = {p.relative_to(rebuilt) for p in rebuilt.rglob("*") if p.is_file()}
        released = {p.relative_to(SITE) for p in SITE.rglob("*") if p.is_file() and not p.is_relative_to(SITE / "data/full")}
        require(generated == released, f"Generated site inventory differs: {sorted(generated ^ released)}")
        for path in sorted(generated):
            require((SITE / path).read_bytes() == (rebuilt / path).read_bytes(), f"Rebuilt {path} differs from distribution")
    workbook, = ROOT.glob("Module_1*/v2.0/tests/Module1_V1_V2_Release_Validation.pbix")
    require(hashlib.sha256(workbook.read_bytes()).hexdigest() == "50ea9832034d20444cc073f6aa659b93d8d7109e86db630b730dd0d07b9d8b8c",
            "Module 1 Power BI workbook differs from source")
    for path in (M2 / "docs/MODULE_2_BUSINESS_REQUIREMENTS.pdf", M2 / "tests/MODULE_2_VALIDATION_SUMMARY.pdf"):
        require(path.read_bytes().startswith(b"%PDF-"), f"Missing PDF for {path.name}")
    print(f"PASS reproducible build matches all {len(generated)} distributed files outside the original archive; native workbook identity.")
    verify_routes()


def main():
    doc = html.fromstring((SITE / "index.html").read_bytes())
    movements, changes = full_archive(doc, SITE / "data/full")
    validate_findings(doc, movements, changes)
    verify_chooser_numbers(doc, movements, changes)
    verify_distribution()
    print("PASS verify_edition.py")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, KeyError, ArithmeticError, subprocess.CalledProcessError) as exc:
        sys.exit(f"FAIL: {exc}")

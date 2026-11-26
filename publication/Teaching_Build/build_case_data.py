"""Build matched case examples from the committed Module 2 campaign exports."""
import argparse
import csv
from collections import Counter, defaultdict
from datetime import datetime, timezone
import hashlib
from decimal import Decimal, InvalidOperation
import json
from pathlib import Path
from urllib.parse import quote

REV = "65e7cc84528008ea40c6f9bb70a02745df592f4c"
BASE_URL = f"https://github.com/andrew-goad/credit_decisioning_strategy/blob/{REV}/"
FIELD_MAP = {
    "id": "application_id", "product": "product_type", "band": "score_band",
    "score": "credit_score", "income": "annual_income", "dti": "debt_to_income_ratio",
    "request": "requested_amount", "payment": "requested_monthly_payment_proxy",
    "pti": "requested_payment_to_income_ratio", "pd": "estimated_pd", "lgd": "estimated_lgd",
    "requestEL": "requested_expected_loss_amount",
}
COMMON = ["applicant_id", "application_date", "population_id", "module1_scenario_name",
          "module1_scenario_set_name", *FIELD_MAP.values()]
SIDE_INPUT = {
    "outcome": "decision_outcome", "approved": "approved_amount",
    "approvedEL": "approved_expected_loss_amount", "payment": "approved_monthly_payment_proxy",
    "pti": "approved_payment_to_income_ratio", "primary": "primary_reason_code",
    "secondary": "secondary_reason_code", "tertiary": "tertiary_reason_code",
    "path": "decision_path", "resolution": "decision_resolution_source",
}
TEXT_FIELDS = {"id", "product", "band", "outcome", "primary", "secondary", "tertiary",
               "path", "resolution"}
SNAP_ID = ["strategy_run_id", "strategy_name", "strategy_version", "strategy_set_name",
           "population_id", "module1_scenario_name", "module1_scenario_set_name"]

PANEL_IDS = ("APP-00032476","APP-00049178","APP-00042924","APP-00009879",
             "APP-00038911","APP-00036219","APP-00017017","APP-00044180")
HASHES = {
    "*RANDOM_SAMPLE_strategy_decisions_archive.csv":"b79ec89c90b1c97174a5eb3eb1b56f0786fd267e2b3ae40977dc51b9e1bc1b74",
    "*RANDOM_SAMPLE_strategy_decisions_m2_01.csv":"9b8b3d014c9cabbdb05e6ab48839218e41ca787549cc47978cb24762a4241bf1",
    "*OUTPUT_strategy_comparison_campaign_registry.csv":"db3255d4bc718e6e73c299b5153654b0ff18d522dcac9799ace4b140922ce8dc",
    "*OUTPUT_strategy_run_parameter_snapshot.csv":"7805e3388b5618e3e43a7225de3bdd95068574d3cab4499ec0fa16c4f645dafa",
}
def instant(ts):
    value = datetime.fromisoformat(ts.replace(" -","-").replace(" +","+"))
    if value.tzinfo is None:
        raise ValueError("Panel execution timestamps must include a UTC offset.")
    return value.astimezone(timezone.utc)

def write_query(path, runs, fields):
    # All values interpolated here come exclusively from vetted fixed Git inputs.
    def quote_value(value):
        return "'" + value.replace("'", "''") + "'"
    identities=[]
    for run in sorted(runs):
        _, row = next(iter(runs[run].values()))
        identities.append("    (" + ", ".join(map(quote_value,[run,row["strategy_run_id"],instant(row["strategy_run_ts"]).isoformat()]))+")")
    field_sql=[]
    for k in fields:
        if k=="sample_reason": val="'ORIGINAL_ARCHIVE_CURATED_PANEL' AS sample_reason"
        elif k=="module2_run_id": val="e.module2_run_id"
        elif k=="strategy_run_ts":
            val='to_char(a.strategy_run_ts AT TIME ZONE \'UTC\', \'YYYY-MM-DD"T"HH24:MI:SS.MS\') || \'+00:00\' AS strategy_run_ts'
        elif k=="application_date": val="to_char(a.application_date, 'YYYY-MM-DD') AS application_date"
        elif k.endswith("_flag"): val=f"a.{k}::text AS {k}"
        else: val=f"a.{k}"
        field_sql.append("    "+val)
    lines=["-- DBeaver: use the ORIGINAL historical PostgreSQL database and a read-only connection.",
           "-- Run this single SELECT, then export the result grid as a UTF-8 CSV with column headers.",
           "-- Keep an empty field for SQL NULL, a period for the decimal separator, and no grouping.",
           "-- All 39 original archived runs x 8 application IDs = 312 rows (31 runs enter the 20 pairs).",
           "-- File name: original_application_panel.csv",
           "WITH expected(module2_run_id, strategy_run_id, utc_millisecond) AS (VALUES",
           ",\n".join(identities), "), selected(application_id) AS (VALUES",
           ",\n".join("    ("+quote_value(i)+")" for i in PANEL_IDS),")","SELECT",
           ",\n".join(field_sql),
           "FROM credit_decisioning_sim.strategy_decisions_archive AS a",
           "JOIN expected AS e ON a.strategy_run_id = e.strategy_run_id",
           " AND date_trunc('milliseconds', a.strategy_run_ts) = e.utc_millisecond::timestamptz",
           "JOIN selected AS s ON a.application_id = s.application_id",
           "ORDER BY e.module2_run_id, a.application_id;",""]
    path.write_text("\n".join(lines),encoding="utf-8")

def add_panel(path, runs, snapshots, fields, sources_for_rows):
    if path.name!="original_application_panel.csv":
        raise ValueError("Save the original archive export as original_application_panel.csv.")
    seen=set()
    with path.open(encoding="utf-8-sig",newline="") as handle:
        reader=csv.DictReader(handle)
        if len(reader.fieldnames or [])!=len(fields) or set(reader.fieldnames or [])!=set(fields):
            raise ValueError("Unexpected columns. Export the supplied SELECT with headers.")
        for raw in reader:
            line=reader.line_num
            run,app=raw["module2_run_id"],raw["application_id"]
            if run not in snapshots or app not in PANEL_IDS or (run,app) in seen:
                raise ValueError(f"Unexpected run, application or duplicate on CSV line {line}.")
            seen.add((run,app))
            original=next(iter(runs[run].values()))[1]
            expected=snapshots[run][1]
            if (any(raw[k]!=expected[k] for k in SNAP_ID)
                or instant(raw["strategy_run_ts"])!=instant(original["strategy_run_ts"])):
                raise ValueError(f"Saved strategy/source identity or timestamp mismatch on line {line}.")
            if raw["sample_reason"]!="ORIGINAL_ARCHIVE_CURATED_PANEL":
                raise ValueError(f"Expected original archive panel selection on line {line}.")
            outcome=raw["decision_outcome"]
            outcomes={"APPROVE":"approval","COUNTEROFFER":"counteroffer","MANUAL_REVIEW":"manual_review","DECLINE":"decline"}
            if outcome not in outcomes or any((raw[f+"_flag"]=="true")!=(f==outcomes[outcome]) for f in outcomes.values()):
                raise ValueError(f"Outcome flags disagree on line {line}.")
            if (raw["simulated_offer_exposure_flag"]=="true")!=(outcome in {"APPROVE","COUNTEROFFER"}) or not raw["primary_reason_code"]:
                raise ValueError(f"Invalid offer flag or missing reason on line {line}.")
            approved=raw["approved_amount"]
            if not ((outcome=="APPROVE" and values_match(approved,raw["requested_amount"]))
                    or (outcome=="COUNTEROFFER" and Decimal(0)<Decimal(approved)<Decimal(raw["requested_amount"]) and values_match(approved,raw["counteroffer_amount"]))
                    or (outcome=="MANUAL_REVIEW" and approved=="" and raw["approved_expected_loss_amount"]=="")
                    or (outcome=="DECLINE" and values_match(approved,"0") and values_match(raw["approved_expected_loss_amount"],"0"))):
                raise ValueError(f"Inconsistent outcome economics on line {line}.")
            if app in runs[run]:
                published=runs[run][app][1]
                skip={"strategy_run_ts","sample_reason"}
                if any(not values_match(raw[k],published[k]) for k in fields if k not in skip):
                    raise ValueError(f"Panel line {line} disagrees with the published archive row.")
            else:
                runs[run][app]=line,raw
                sources_for_rows[run,app]="panel"
    if seen != {(r,a) for r in snapshots for a in PANEL_IDS}:
        raise ValueError(f"Expected complete original panel with {len(snapshots)*len(PANEL_IDS)} rows; got {len(seen)}.")
    return {"path":path.name,"sha256":hashlib.sha256(path.read_bytes()).hexdigest(),
            "rows":len(seen),"addedRows":len(sources_for_rows),"applicationIDs":list(PANEL_IDS)}

def project(raw, mapping):
    data = {}
    for name, field in mapping.items():
        value = raw[field]
        if value == "":
            data[name] = None
        elif name in TEXT_FIELDS:
            data[name] = value
        elif name == "score":
            data[name] = int(value)
        else:
            data[name] = float(Decimal(value))
    return data

def read_data(root, pattern):
    matches = list(root.glob("Module_2*/v1.0/**/" + pattern))
    assert len(matches) == 1, (pattern, matches)
    path = matches[0]
    original_bytes=path.read_bytes().replace(b"\r\n",b"\n")
    # Accept Git for Windows CRLF conversion while pinning semantic source bytes.
    expected=HASHES[pattern]
    if not any(hashlib.sha256(candidate).hexdigest()==expected for candidate in
               (original_bytes, original_bytes.replace(b"\n",b"\r\n"))):
        raise ValueError(f"Committed CSV digest differs: {path.name}")
    with path.open(encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        rows = [(reader.line_num, row) for row in reader]
    return rows, BASE_URL + quote(path.relative_to(root).as_posix())

def values_match(a,b):
    if a == b:
        return True
    try:
        return Decimal(a) == Decimal(b)
    except InvalidOperation:
        return False

def build(repo, panel=None, sql_output=None):
    if not __debug__:
        raise RuntimeError("Run Python with assertions enabled.")
    archives, url = read_data(repo, "*RANDOM_SAMPLE_strategy_decisions_archive.csv")
    snapshots, snapshot_url = read_data(repo, "*OUTPUT_strategy_run_parameter_snapshot.csv")
    registry, registry_url = read_data(repo, "*OUTPUT_strategy_comparison_campaign_registry.csv")
    detailed, _ = read_data(repo, "*RANDOM_SAMPLE_strategy_decisions_m2_01.csv")
    runs = defaultdict(dict)
    snapshots = {r["module2_run_id"]: (n,r) for n,r in snapshots}
    for n,row in archives:
        run,app = row["module2_run_id"],row["application_id"]
        assert app not in runs[run], (run,app)
        snap = snapshots[run][1]
        assert all(row[k] == snap[k] for k in SNAP_ID), (run,app,"snapshot identity")
        assert row["strategy_run_ts"].rsplit(" ",1)[0] == snap["strategy_run_ts"], (run,app,"snapshot time")
        runs[run][app] = (n,row)
    assert len(archives)==13583 and len(runs)==39
    detailed_by_id = {r["application_id"]:r for _,r in detailed}
    baseline = runs["M2-01"]
    overlap = baseline.keys() & detailed_by_id
    shared_fields = list(COMMON) + list(SIDE_INPUT.values())
    equal = sum(all(values_match(baseline[i][1][field], detailed_by_id[i][field]) for field in shared_fields)
                for i in overlap)
    full_info = {"sameApplicationIDs":len(overlap),"allDisplayedFieldsAgree":equal,
                 "sampleTime":detailed[0][1]["strategy_run_ts"],
                 "archiveTime":next(iter(baseline.values()))[1]["strategy_run_ts"]}
    assert full_info["sampleTime"] != full_info["archiveTime"]
    sources_for_rows = {}
    source_urls = {"archive":url,"snapshots":snapshot_url,"registry":registry_url}
    archive_fields=list(archives[0][1])
    if sql_output:
        write_query(sql_output,runs,archive_fields)
    panel_info=None
    if panel:
        panel_info=add_panel(panel,runs,snapshots,archive_fields,sources_for_rows)
        source_urls["panel"]=panel.name
    pairs = {}
    distinct = set()
    for _,rec in sorted(registry,key=lambda row:row[1]["comparison_group_id"]):
        group=rec["comparison_group_id"]
        br,cr=rec["baseline_module2_run_id"],rec["challenger_module2_run_id"]
        assert rec["registry_active_flag"]=="true"
        baseline,challenger = runs[br],runs[cr]
        observed = []
        for app in sorted(baseline.keys() & challenger):
            bl,base=baseline[app]
            cl,challenge=challenger[app]
            assert all(values_match(base[k],challenge[k]) for k in COMMON),(group,app,"source")
            for row in [base,challenge]:
                assert all(row[k] == rec[k] for k in ["module1_scenario_set_name","module1_scenario_name","population_id"])
            case = project(base,FIELD_MAP)
            case["base"]=dict(project(base,SIDE_INPUT),source=sources_for_rows.get((br,app),"archive"),line=bl)
            case["challenge"]=dict(project(challenge,SIDE_INPUT),source=sources_for_rows.get((cr,app),"archive"),line=cl)
            observed.append(case)
            distinct.add(app)
        assert observed and len(observed)==len({x['id'] for x in observed})
        def profile(run):
            sl,sr=snapshots[run]
            params=json.loads(sr["strategy_params_jsonb"])
            return {"source":"snapshots","line":sl,"approvePD":params["approve_max_estimated_pd_proxy"],
                    "pdBuffer":params["borderline_threshold_buffer_pct"]}
        def amount_moved(c):
            return c["base"]["approved"] != c["challenge"]["approved"]
        pairs[group]={"baseRun":br,"challengeRun":cr, "scenario":rec["module1_scenario_name"],
                      "population":rec["population_id"],"baseProfile":profile(br),"challengeProfile":profile(cr),
                      "outcomeChanged":sum(c["base"]["outcome"]!=c["challenge"]["outcome"] for c in observed),
                      "amountValueChanged":sum(amount_moved(c) for c in observed),
                      "bothAssignedAmountsDifferent":sum(c["base"]["approved"] is not None and c["challenge"]["approved"] is not None and amount_moved(c) for c in observed),
                      "cases":observed}
    assert len(pairs)==20
    assert any(c["id"]=="APP-00032476" for c in pairs["CG02"]["cases"])
    summary={"casePairs":sum(len(v["cases"]) for v in pairs.values()),"distinctApplicationIDs":len(distinct),
             "changedOutcomes":sum(v["outcomeChanged"] for v in pairs.values()),
             "publicArchiveSampleRows":len(archives),"groups":len(pairs)}
    coverage=Counter(x["id"] for v in pairs.values() for x in v["cases"])
    summary["availableInEveryGroup"]=sorted(k for k,v in coverage.items() if v==len(pairs))
    summary["maxGroupsPerID"]=max(coverage.values())
    summary["mostCovered"]=[{"id":k,"groups":v} for k,v in sorted(coverage.items(),key=lambda item:(-item[1],item[0]))[:8]]
    return {"sources":source_urls,"originalPanel":panel_info,
            "summary":summary,"supplementarySampleExcluded":full_info,"groups":pairs}

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo",type=Path);parser.add_argument("output",type=Path)
    parser.add_argument("--panel",type=Path,help="Optional original_application_panel.csv from the supplied read-only query")
    parser.add_argument("--write-panel-sql",type=Path,help="Generate the read-only DBeaver export query")
    args=parser.parse_args()
    data=build(args.repo,args.panel,args.write_panel_sql)
    args.output.write_text(json.dumps(data,separators=(",",":"),ensure_ascii=False),encoding="utf-8")
    print(json.dumps(data["summary"]),json.dumps(data["supplementarySampleExcluded"]))
    print("ID / pairs / changed outcome / changed approved amount with both values assigned")
    for g,v in data["groups"].items():
        print(g,len(v["cases"]),v["outcomeChanged"],v["bothAssignedAmountsDifferent"])

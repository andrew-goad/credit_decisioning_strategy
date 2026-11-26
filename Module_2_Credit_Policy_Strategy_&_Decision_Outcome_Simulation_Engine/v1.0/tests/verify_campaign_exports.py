"""Reconcile the published Module 2 v1.0 CSV evidence. Reads repository files only."""
import argparse
import csv
import json
from collections import Counter, defaultdict
from decimal import Decimal
from pathlib import Path

MODULE = "Module_2_Credit_Policy_Strategy_&_Decision_Outcome_Simulation_Engine/v1.0"
PREFIX = "module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_"
RUN = "module2_run_id"
PAIR = "comparison_group_id"
GRAINS = ("module1_scenario_set_name", "module1_scenario_name", "population_id", "strategy_name", "strategy_version")
OUTCOMES = ("approval_count", "counteroffer_count", "manual_review_count", "decline_count")
AMOUNTS = ("total_requested_amount", "total_approved_amount", "total_requested_expected_loss_amount",
           "total_approved_expected_loss_amount")
RATES = ("approval_rate", "counteroffer_rate", "manual_review_rate", "decline_rate", "simulated_offer_exposure_rate")
GATES = ("campaign_registry", "comparison_registry", "archive", "comparison", "source_consistency", "evidence",
         "parameter_snapshot", "final_output_conventions", "option_c_evidence", "product_guardrail_policy")
STATUS_COUNTS = {"PASS": 666, "REVIEW": 55, "NOT_APPLICABLE": 137}
GROUPS = {"APPROVE": ("approval", "APPROVAL"), "COUNTEROFFER": ("counteroffer", "COUNTEROFFER"),
          "MANUAL_REVIEW": ("manual_review", "MANUAL_REVIEW"), "DECLINE": ("decline", "POLICY_STOP")}


def require(ok, message):
    if not ok:
        raise ValueError(message)


def read(path):
    with path.open(encoding="utf-8-sig", newline="") as file:
        return list(csv.DictReader(file))


def index(rows, key):
    indexed = {row[key]: row for row in rows}
    require(len(rows) == len(indexed), f"Repeated {key}")
    return indexed


def group(rows, key):
    groups = defaultdict(list)
    for row in rows:
        groups[row[key]].append(row)
    return groups


def verify_runs(registry, evidence, parameters, archive, segments, validations):
    run_ids = set(registry)
    require(len(registry) == 39, "Expected 39 registered runs")
    require(all(set(table) == run_ids for table in (evidence, parameters, archive, segments, validations)),
            "Run IDs differ between evidence sets")
    status_counts = Counter()
    for run_id, registration in registry.items():
        executive = evidence[run_id]
        params = parameters[run_id]
        archived = archive[run_id]
        strata = segments[run_id]
        tests = validations[run_id]
        require(registration["registry_active_flag"] == "true", f"{run_id} inactive")
        for key in GRAINS:
            require(registration[key] == executive[key] == params[key] == archived[key], f"{run_id} {key}")
        require(len(strata) == len({(r["product_type_policy_key"], r["score_band_policy_key"]) for r in strata}) == 25,
                f"{run_id} product and score segments")
        for key in ("applications", *OUTCOMES, "offer_count", *AMOUNTS):
            summed = sum(Decimal(row[key]) for row in strata)
            require(summed == Decimal(executive[key]), f"{run_id} segment reconciliation for {key}")
        require(int(executive["applications"]) == sum(int(executive[k]) for k in OUTCOMES) ==
                int(archived["archived_rows"]) == int(archived["distinct_application_id_count"]) == 50_000,
                f"{run_id} archived population or outcome counts")
        require(int(executive["offer_count"]) == int(executive["approval_count"]) + int(executive["counteroffer_count"]),
                f"{run_id} offer count")
        for rate, count in zip(RATES, (*OUTCOMES, "offer_count")):
            require(Decimal(executive[rate]) == Decimal(executive[count]) / Decimal(executive["applications"]),
                    f"{run_id} denominator for {rate}")
        require(len(tests) == len({(r["validation_area"], r["validation_test_name"]) for r in tests}) == 22,
                f"{run_id} validation key coverage")
        statuses = Counter(r["validation_status"] for r in tests)
        for status in STATUS_COUNTS:
            require(statuses[status] == int(executive[f"validation_{status.lower()}_count"]), f"{run_id} {status}")
        status_counts.update(statuses)
        strategy = json.loads(params["strategy_params_jsonb"])
        policy = json.loads(params["product_policy_params_jsonb"])
        require(strategy[RUN] == run_id and len(policy) == len({x["product_type"] for x in policy}) == 5,
                f"{run_id} parameter snapshot")
    require(status_counts == STATUS_COUNTS, f"Historical validation totals differ: {dict(status_counts)}")
    print("PASS 39 runs, 390 segment-to-run totals, 195 outcome rates, 858 validation records and 39 parameter snapshots.")


def verify_pairs(registry, evidence, readiness, source, deltas):
    require(len(registry) == 20 and set(registry) == set(readiness) == set(source) == set(deltas),
            "Comparison IDs are incomplete")
    for key, pair in registry.items():
        ready, matched, delta = readiness[key], source[key], deltas[key]
        for identity in ("baseline_module2_run_id", "challenger_module2_run_id", "module1_scenario_name", "population_id"):
            require(pair[identity] == ready[identity] == matched[identity] == delta[identity], f"{key} {identity}")
        require(ready["readiness_status"] == "READY_FOR_MATCHED_COMPARISON" and
                int(ready["matched_application_id_count"]) == int(matched["matched_application_count"]) == 50_000 and
                int(ready["baseline_only_application_id_count"]) == int(ready["challenger_only_application_id_count"]) == 0,
                f"{key} unmatched application count")
        require(matched["source_consistency_status"] == "SOURCE_FIELDS_MATCH" and
                all(int(value) == 0 for field, value in matched.items() if field.endswith("mismatch_count")),
                f"{key} source mismatches in archived diagnostics")
        baseline, challenger = evidence[pair["baseline_module2_run_id"]], evidence[pair["challenger_module2_run_id"]]
        for metric in (*RATES, "total_approved_amount", "total_approved_expected_loss_amount"):
            calculated = Decimal(challenger[metric]) - Decimal(baseline[metric])
            require(calculated == Decimal(delta[f"delta_{metric}"]), f"{key} delta for {metric}")
    print("PASS 20 registry pairs, source-consistency diagnostics and 140 exact challenger-minus-baseline deltas.")


def verify_guardrails(rows, parameters):
    identities = {(r[RUN], r["product_type"]) for r in rows}
    require(len(rows) == len(identities) == 10 and len({r[RUN] for r in rows}) == 5, "Guardrail audit coverage")
    require({r["product_type"] for r in rows} == {"UNSECURED_PERSONAL_LOAN", "REVOLVING_LINE"}, "Guardrail products")
    for row in rows:
        policies = json.loads(parameters[row[RUN]]["product_policy_params_jsonb"], parse_float=Decimal)
        policy = next(p for p in policies if p["product_type"] == row["product_type"])
        fields = [k.removeprefix("expected_") for k in row if k.startswith("expected_")]
        require(len(fields) == 12, "Expected 12 audited guardrail fields per product")
        for key in fields:
            require(Decimal(row[f"expected_{key}"]) == Decimal(row[f"actual_{key}"]) == Decimal(policy[key]),
                    f"{row[RUN]} {row['product_type']} {key}")
    print("PASS 120 exact expected/actual policy values cross-checked against saved parameter JSON.")


def verify_sample(rows, run_ids):
    identities = {(r[RUN], r["application_id"]) for r in rows}
    require(len(rows) == len(identities) == 13_583 and {r[RUN] for r in rows} == set(run_ids), "Archive sample coverage")
    for row in rows:
        outcome = row["decision_outcome"]
        label = f"{row[RUN]}/{row['application_id']}"
        flag, family = GROUPS[outcome]
        for candidate, _ in GROUPS.values():
            require(row[f"{candidate}_flag"] == ("true" if candidate == flag else "false"), f"{label} outcome flags")
        require(row["simulated_offer_exposure_flag"] == ("true" if outcome in ("APPROVE", "COUNTEROFFER") else "false"),
                f"{label} offer flag")
        amount = row["approved_amount"]
        request = Decimal(row["requested_amount"])
        if outcome == "MANUAL_REVIEW":
            valid = amount == ""
        elif outcome == "DECLINE":
            valid = Decimal(amount) == 0
        elif outcome == "APPROVE":
            valid = Decimal(amount) == request
        else:
            valid = 0 < Decimal(amount) == Decimal(row["counteroffer_amount"]) < request
        require(valid, f"{label} approved amount")
        require(row["primary_reason_code"] and row["primary_reason_family"] == family, f"{label} primary reason")
    print("PASS decision flags, offer flags, amount conventions and primary reason families for 13,583 public archive rows.")


def run(repo):
    release = repo / MODULE

    def output(short_name):
        return read(release / "outputs" / f"{PREFIX}OUTPUT_{short_name}.csv")

    def campaign(section):
        matches = list((release / "tests" / "review_queries" / "campaign").glob(f"{PREFIX}{section}_QA_*.csv"))
        require(len(matches) == 1, f"Expected one Section {section} campaign export, got {len(matches)}")
        return read(matches[0])

    registry = index(output("strategy_run_campaign_registry"), RUN)
    evidence = index(output("strategy_run_evidence_summary"), RUN)
    parameters = index(output("strategy_run_parameter_snapshot"), RUN)
    verify_runs(registry, evidence, parameters, index(campaign("17.2"), RUN),
                group(output("strategy_run_segment_evidence_summary"), RUN), group(output("strategy_run_validation_evidence"), RUN))
    verify_pairs(index(output("strategy_comparison_campaign_registry"), PAIR), evidence,
                 index(campaign("17.12"), PAIR), index(campaign("17.13"), PAIR), index(campaign("17.15"), PAIR))
    verify_guardrails(campaign("17.19"), parameters)
    verify_sample(output("RANDOM_SAMPLE_strategy_decisions_archive"), registry)
    rollups = campaign("17.20")
    require(len(rollups) == 1 and all(rollups[0][f"{gate}_ready_flag"] == "true" for gate in GATES) and
            rollups[0]["module2_campaign_acceptance_status"] == "MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS",
            "Historical gate rollup differs")
    print("PASS ten named readiness gates in the archived final rollup. This verification reads CSVs only.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", type=Path, help="Root of the credit_decisioning_strategy checkout")
    args = parser.parse_args()
    try:
        run(args.repository)
    except (OSError, ValueError, KeyError, ArithmeticError, StopIteration) as error:
        parser.exit(1, f"FAIL: {error}\n")

# Rebuild the teaching page

The paired policy results come from the 50,000-application, 39-run campaign. The DBeaver teaching return and its provenance receipt are in `Case_Discovery/Returned`. The receipt identifies the owner-approved May 28 M2-01 refresh and the other 38 original execution times. `Case_Discovery/Source_rows` preserves the original June teaching records.

Use the teaching edition of the repository. The historical SQL and campaign evidence are pinned to [the original source](https://github.com/andrew-goad/credit_decisioning_strategy/tree/65e7cc84528008ea40c6f9bb70a02745df592f4c). From PowerShell at the teaching edition’s repository root, run

```powershell
$repo = (Get-Location).Path
$raw = 'publication/Case_Discovery/Returned/teaching_cases.csv'
$june = 'publication/Case_Discovery/Source_rows'
$tools = 'publication/Teaching_Build'
py -3 -m pip install lxml
py -3 "$tools/verify_teaching_return.py" $raw publication/Case_Discovery/Returned/campaign_provenance.json --repo $repo
py -3 "$tools/build.py" --repo $repo --output site/index.html
py -3 publication/verify_edition.py
py -3 publication/package_preview.py --site site --output releases-local
```

The release checksum file records the complete download and standalone HTML. The release ZIP contains the same index as the website. The build reads the included math and count JSON files and embeds them with the interface. To reproduce the derived evidence separately, run these commands from the same folder.

```powershell
py -3 "$tools/build_case_data.py" $repo "$tools/cases.json"
py -3 "$tools/verify_teaching_return.py" $raw publication/Case_Discovery/Returned/campaign_provenance.json --repo $repo --output "$tools/returned_counts.json"
py -3 "$tools/build_worked_decision_math.py" --repo $repo --returned $raw --june $june --output "$tools/worked_decision_math.json"
py -3 "$tools/build_counteroffer_gates.py" --repo $repo --returned $raw --june $june --case-dir $tools --borrower "$tools/borrower_math.json" --output "$tools/counteroffer_gate_data.json"
```

The individual borrower calculations use archived source rows wherever a match exists. The remaining observations use the seeded Module 1 SQL replay. `derive_borrower_math.py` checks the source projection against observed fields before exporting the calculations. To regenerate them, point PostgreSQL’s standard `PGHOST`, `PGPORT`, `PGUSER` and `PGDATABASE` settings at a scratch PostgreSQL 17 instance and put its `psql` executable on PATH.

```powershell
py -3 "$tools/derive_borrower_math.py" --repository $repo --catalog "$tools/module1.json" --case-dir $tools --returned $raw --output "$tools/borrower_math.json"
```

The seven lesson counts include all 50,000 applications in each matched group. The interface carries the smaller case selection that the teaching query returned and the available original examples. The shipped lookup uses the retained [full campaign projection](../full_lookup/FULL_CAMPAIGN_EXPORT.md).

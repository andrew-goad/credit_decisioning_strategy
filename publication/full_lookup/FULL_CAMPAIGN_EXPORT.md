# Export the original 50,000-application campaign

The complete explorer ships with the saved 500-file lookup. Rebuilding it from database rows is optional and requires the original campaign archive in PostgreSQL. The campaign evaluated 50,000 synthetic applications per run across 39 runs.

1. Open DBeaver on the original campaign database. Use your read-only connection if configured. Open `export_original_campaign.sql` in a SQL editor bound to that database. It is a single SELECT.
2. Export the **full query result** to CSV. The grid can preview a limited number of rows; use the query as the export source and make sure the export reads all rows. Leave the SQL as supplied. It orders the records by application ID and run.
3. Save as **original_campaign.csv**. Use UTF-8 encoding, one header row, a comma as the field delimiter, standard CSV quoting, no thousands separators and an empty field for SQL NULL. An unassigned amount on manual review and a zero amount on decline have different meanings.
4. Expect **1,950,000 data rows** plus the header. Keep this intermediate CSV outside the public Git repository. Use it as the input to the archive builder below. Some CSV viewers have a row limit, so use the reconciliation report for the authoritative count.

From the repository root, use an empty output path. The packer checks execution identity, counts, sample overlap and approved economics before it writes the manifest.

```powershell
py -3 publication/full_lookup/pack_full_campaign.py 'D:\CDS\original_campaign.csv' --output 'D:\CDS\rebuild\data\full'
```

**Which executions are read?** The SQL matches the 39 campaign run IDs to the timestamps from their saved parameter snapshots. M2-01 has one project-owner-approved alternative. When its historical execution is absent, the same run ID can use the documented May 28 refresh at 12:40:03.698 UTC. The published refresh export records milliseconds. The SQL requires a single distinct timestamp in that millisecond and exports the database value at full microsecond precision. The packager records the observed time in its manifest. All other runs retain their exact historical execution times. The exported rows contain source scenario, population and application IDs along with underwriting inputs, decision reasons and approved economics. [SQL lineage and archive creation](https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/src/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql#L30038-L30089)

**What the checker should establish.** Require 50,000 distinct IDs from APP-00000001 through APP-00050000, 39 distinct campaign runs for each, equal source inputs within each of the 20 registered policy pairs, exact overlap with the public campaign sample and agreement of the original run-level counts and dollars. An original export enables a reader to follow one application across all matched policy pairs. Compare the portfolio-level denominator and any changes to the application-generating scenario before attributing a change to policy.

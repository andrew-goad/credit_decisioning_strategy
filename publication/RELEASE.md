# How does a change in lending policy affect credit offers?

Start with a $12,839.56 auto loan. Baseline sent the applicant to manual review. Growth made a full offer. Compare the two recorded decisions in the browser, follow the loss calculation and see how those policies affected offers across 50,000 synthetic applicants. [Read the opening case in your browser](https://andrew-goad.github.io/credit_decisioning_strategy/)

## Choose a way to explore

| Choose this | What you get |
| --- | --- |
| [Complete explorer in your browser](https://andrew-goad.github.io/credit_decisioning_strategy/) | All 1,950,000 decisions. Search any of the 50,000 application IDs, compare 20 registered policy pairs, or inspect all 39 decisions for an ID. |
| [Complete offline explorer · ZIP, 17.33 MiB](https://github.com/andrew-goad/credit_decisioning_strategy/releases/download/cds-teaching-2026-11/CDS_Teaching_Explorer.zip) | The same site and all 500 lookup files. With Python 3 installed on Windows, extract the ZIP into a new folder and open `Open_Preview.cmd`. The launcher serves the files locally for the browser. |
| [Standalone guided edition · HTML, 4.15 MiB](https://github.com/andrew-goad/credit_decisioning_strategy/releases/download/cds-teaching-2026-11/Credit_Strategy_Explorer.html) | Open the single file in a browser for the opening lesson, portfolio totals, and 940 saved case comparisons for 665 applicants. Choose the complete edition to look up an arbitrary ID. |
| [Module 1 Power BI workbook · 15.49 MiB](https://raw.githubusercontent.com/andrew-goad/credit_decisioning_strategy/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/Module1_V1_V2_Release_Validation.pbix) | Open in Power BI Desktop on Windows to compare v1.0 and v2.0 of the application generator. The [static image](https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_impact_explorer.png) previews the report. |

## Run the SQL or verify a result

To run a new policy experiment, use PostgreSQL and DBeaver, as in the original campaign. The [DBeaver setup and parameter guide](https://andrew-goad.github.io/credit_decisioning_strategy/#parameter-guides) covers both modules, and [Project artifacts](https://andrew-goad.github.io/credit_decisioning_strategy/#artifacts) connects their design, requirements and validation to the code. The archived results measure simulated policy decisions and modeled losses. Repayment, take-up and profitability require observed performance.

To verify either teaching download on Windows, use `Get-FileHash -Algorithm SHA256 -LiteralPath '.\CDS_Teaching_Explorer.zip'`, substituting the downloaded filename. Compare the value with the matching entry in [SHA256SUMS.txt](https://github.com/andrew-goad/credit_decisioning_strategy/releases/download/cds-teaching-2026-11/SHA256SUMS.txt).

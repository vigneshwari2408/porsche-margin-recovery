# QA and reconciliation

| Layer | Check | Result | Evidence |
|---|---|---|---|
| SQL | 305 data-quality and 118 model-quality checks (`sql/07`, `sql/10`) | 423 PASS, 0 FAIL, 28 INFO | [`../data/sql_outputs/dq_results.csv`](../data/sql_outputs/dq_results.csv) |
| Excel | `Audit_Checks` sheet | ALL 50 CHECKS PASS | [`PCL_05_verification_report.txt`](PCL_05_verification_report.txt) |
| Excel | 553 displayed values recomputed from the SQL data | 553 compared, 0 failures | [`PCL_05_verification_report.txt`](PCL_05_verification_report.txt) |
| Excel | Formula portability lint | 2,997 formulas, 0 issues | [`PCL_05_verification_report.txt`](PCL_05_verification_report.txt) |
| Power BI | In-report QA page vs SQL reference (`RefSQL`) | ALL 388 QA CHECKS PASS | [`../powerbi/screenshots/06_qa_lineage.png`](../powerbi/screenshots/06_qa_lineage.png) |
| Cross-tool | Python reconciliation, R1–R5 | 1,524 comparisons, 0 failures | [`PCL_06_reconciliation_report.txt`](PCL_06_reconciliation_report.txt) |

## Reconciliation groups (`reconcile.py`)

Every DAX measure used on the dashboard is replicated in Python over the same CSV tables Power BI loads, then compared with:

| Group | Compared with | Comparisons | Failures |
|---|---|---:|---:|
| R1 | `RefSQL.csv`, the reference the in-report QA page uses | 388 | 0 |
| R2 | Live SQL views, queried directly | 351 | 0 |
| R3 | The Excel model | 566 | 0 |
| R4 | Identities (bridge closure, volume + ASP, mix totals, NCF, L0 → L1 → L2) | 51 | 0 |
| R5 | Export integrity (every base value vs `mart.v_panel_hy`) | 168 | 0 |
| | **Total** | **1,524** | **0** |

A negative test (adding €1m to H1 2026 reported EBIT) produced 214 failures across all five groups, so a single wrong value is detected.

## Running the checks

From the repository root, with Python 3 and `openpyxl`:

    python3 qa/verify_against_sql.py data/excel_import excel/PCL_05_Porsche_Margin_Model_FINAL.xlsx
    python3 qa/lint_portability.py excel/PCL_05_Porsche_Margin_Model_FINAL.xlsx
    python3 qa/reconcile.py excel/PCL_05_Porsche_Margin_Model_FINAL.xlsx

`reconcile.py` group R2 queries the PostgreSQL database built by [`../sql/`](../sql/). It connects with `PGHOST`, `PGPORT`, `PGUSER` and `PGDATABASE` (defaults: `/tmp`, `5433`, `postgres`, `porsche_lens`). `PCL_05_cell_map.json` maps each checked value to its workbook cell.

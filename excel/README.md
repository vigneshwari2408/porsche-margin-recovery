# Excel workbooks

| Workbook | Role | Sheets |
|---|---|---|
| `PCL_01_Sources.xlsx` | Source register and definitions (input to SQL) | README, Source_Register, Definitions, Availability_Matrix, Source_Reference_Long, Audit_Findings, Coverage |
| `PCL_02_Manual_Inputs.xlsx` | The 155 values captured by hand from Porsche's PDF reports, each with source and page (input to SQL) | README, Inputs, FS_Reference, Checks |
| `PCL_05_Porsche_Margin_Model_FINAL.xlsx` | The audited analysis model, built from the SQL outputs | README, Data_Panel, Data_Long, Data_Mix, SQL_Outputs, KPI_Overview, EBIT_Analysis, RD_DA, Commercial, Cash_Crosscheck, Guidance_Scenarios, Audit_Checks, Audit_Register |

## The analysis model (PCL_05)

- **Imports** (blue): the SQL fact table, delivery mix, guidance inputs and the SQL mart results (used for reconciliation only).
- **Calculations** (black formulas, green cross-sheet links): every analytical number is a formula built from the imports. 2,997 formulas in total, no hard-coded results.
- **`Audit_Checks`**: 50 checks that recompute identities and reconcile each key result to SQL. Status cell: **ALL 50 CHECKS PASS**.
- The workbook is set to recalculate fully when opened.

Start at `KPI_Overview`, then `EBIT_Analysis`, then `Audit_Checks`.

## Checks you can run

    python3 qa/verify_against_sql.py data/excel_import excel/PCL_05_Porsche_Margin_Model_FINAL.xlsx
    python3 qa/lint_portability.py excel/PCL_05_Porsche_Margin_Model_FINAL.xlsx

Results: [`../qa/PCL_05_verification_report.txt`](../qa/PCL_05_verification_report.txt) (553 values, 0 failures; 2,997 formulas, 0 portability issues).

## Rebuilding the model

The workbook is generated from the CSVs in [`../data/excel_import/`](../data/excel_import/):

    python3 tools/build_workbook.py data/excel_import PCL_05_Porsche_Margin_Model.xlsx
    python3 tools/blank_no_prior_year.py PCL_05_Porsche_Margin_Model.xlsx
    python3 tools/finalize_calc_flag.py PCL_05_Porsche_Margin_Model.xlsx

The rebuilt file matches the committed FINAL workbook cell for cell (values and formulas).

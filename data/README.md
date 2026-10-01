# Data

Every file here is a derived, tabular dataset created by this project from Porsche AG's public investor-relations publications. The original Porsche documents (PDF reports, presentations, fact-sheet workbooks) and the earnings-call transcript are **not redistributed**. Each one is listed by title and public URL in [`staging/source_register.csv`](staging/source_register.csv) (S001–S026). The mart adds S027, the transcript, in [`../sql/08_mart_setup.sql`](../sql/08_mart_setup.sql).

| Folder | Contents | Produced by | Used by |
|---|---|---|---|
| `staging/` | Source register (26), variable dictionary (47), manual inputs (151 values), data gaps (4), audit findings (11) | [`../sql/export_to_csv.py`](../sql/export_to_csv.py) from the two input workbooks in [`../excel/`](../excel/) | SQL staging layer |
| `sql_outputs/` | The 11 mart views, plus the assumption register, guidance inputs, annotations, data-quality results and audit findings (17 CSVs) | [`../sql/12_export_mart.sql`](../sql/12_export_mart.sql) | Excel model, reconciliation |
| `powerbi/` | The 17 tables loaded by the Power BI report, including `RefSQL.csv` (388 QA reference values) | [`../sql/13_powerbi_export.sql`](../sql/13_powerbi_export.sql); four small legend tables (`DimLevel`, `DimLevelStep`, `DimBridgeStep`, `DimRevenueStep`) are fixed lists kept in this folder | Power BI, website data, reconciliation |
| `excel_import/` | The SQL extracts imported by the Excel model (fact table, mix, guidance grids, registers) | Exported from the database | [`../tools/build_workbook.py`](../tools/build_workbook.py), [`../qa/verify_against_sql.py`](../qa/verify_against_sql.py) |

Counts in `staging/` are as staged. The final database holds 27 sources and 13 audit findings, because the mart setup adds S027 and AF-12 to AF-13.

## Not included

| File | Why it is excluded | How to recreate it |
|---|---|---|
| Porsche PDFs, presentations and fact-sheet workbooks | Porsche AG's copyrighted documents | Download them from the URLs in the source register |
| Earnings-call transcript (S027) | Third-party copyrighted text; only one CFO statement is used, cited by source | URL in the source register |
| `fact_sheet_long.csv` | A cell-by-cell copy of Porsche's two fact-sheet workbooks (S024, S025) | Download both workbooks, then run [`../sql/pcl_extract_factsheets.py`](../sql/pcl_extract_factsheets.py) on that folder |

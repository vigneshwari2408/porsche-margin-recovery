# Power BI dashboard

Six-page Power BI report on the Porsche H1 2026 margin question. It is built on 17 tables exported from the SQL mart and 194 DAX measures.

| File | What it is |
|---|---|
| `Porsche_Company_Lens_2026_Margin_Recovery.pbix` | The final report (Power BI Desktop) |
| [`screenshots/`](screenshots/) | The six final pages, exported from that file |

The semantic model is also kept as text, so it can be read without Power BI: [`../model/PCL_semantic_model.tmdl`](../model/PCL_semantic_model.tmdl) and [`../model/PCL_measures.dax`](../model/PCL_measures.dax). The full design (pages, visuals, measures, QA logic) is in [`PowerBI_Specification.md`](PowerBI_Specification.md).

## Pages

| # | Page | Question | Screenshot |
|---|---|---|---|
| 1 | Executive Overview | Is the recovery real? | [01_executive_overview.png](screenshots/01_executive_overview.png) |
| 2 | EBIT Recovery | What moved EBIT? | [02_ebit_recovery.png](screenshots/02_ebit_recovery.png) |
| 3 | R&D & D&A | Is accounting flattering the margin? | [03_rd_da.png](screenshots/03_rd_da.png) |
| 4 | Commercial Drivers | Price vs volume | [04_commercial_drivers.png](screenshots/04_commercial_drivers.png) |
| 5 | Cash & Guidance | Does cash confirm it, and what must H2 deliver? | [05_cash_guidance.png](screenshots/05_cash_guidance.png) |
| 6 | QA & Lineage | Can we trust it? | [06_qa_lineage.png](screenshots/06_qa_lineage.png) |

Page 6 recomputes 388 values in DAX and compares each one with the SQL reference table `RefSQL`. Result: **ALL 388 QA CHECKS PASS**.

Scenario visuals on page 5 carry the label **"Arithmetic only — not forecasts — no probabilities"**.

## Opening and refreshing the file

The report opens with its data already loaded. To refresh it from the CSV files in this repository:

1. Copy [`../data/powerbi/`](../data/powerbi/) to a local folder, for example `C:\PCL\data\`.
2. In Power BI Desktop, go to **Transform data > Edit parameters** and set `DataFolder` to that folder. Keep the trailing backslash.
3. Select **Refresh**. Page 6 should still read ALL 388 QA CHECKS PASS.

# Build tools

Scripts that generate the project's outputs from the data in [`../data/`](../data/). Run them from the repository root. They need Python 3 and `openpyxl`.

| Script | Produces | Command |
|---|---|---|
| `build_workbook.py` | The Excel model, from `data/excel_import/` (exported by `sql/14_excel_import_export.sql`) | `python3 tools/build_workbook.py data/excel_import out.xlsx` |
| `blank_no_prior_year.py` | Blanks the 26 year-on-year cells that have no prior-year half (2023 columns) | `python3 tools/blank_no_prior_year.py out.xlsx` |
| LibreOffice (not a script here) | Recalculates every formula and stores the cached values, so the file shows results even where nothing recalculates it | `soffice --headless --convert-to xlsx:"Calc MS Excel 2007 XML" --outdir recalc out.xlsx` |
| `finalize_calc_flag.py` | Restores the "recalculate fully when opened" flag, which LibreOffice drops (run on the recalculated file) | `python3 tools/finalize_calc_flag.py recalc/out.xlsx` |
| `gen_model.py` | `model/PCL_semantic_model.tmdl` and `model/PCL_measures.dax`, from `data/powerbi/` | `python3 tools/gen_model.py` |
| `build_site_data.py` | `docs/assets/js/data.js`, from `model/key_values.json` and `data/powerbi/` | `python3 tools/build_site_data.py` |

`gen_model.py` also writes `model/measure_registry.json`, a machine-readable measure list. It is not committed.

The committed `excel/PCL_05_Porsche_Margin_Model_FINAL.xlsx` is reproduced exactly (formulas and cached values) by the four Excel steps above, run in that order. The input workbooks `PCL_01_Sources.xlsx` and `PCL_02_Manual_Inputs.xlsx` are edited by hand (only to correct a source value) and recalculated the same way with LibreOffice and `finalize_calc_flag.py`.

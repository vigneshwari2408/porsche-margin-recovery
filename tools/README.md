# Build tools

Scripts that generate the project's outputs from the data in [`../data/`](../data/). Run them from the repository root. They need Python 3 and `openpyxl`.

| Script | Produces | Command |
|---|---|---|
| `build_workbook.py` | The Excel model, from `data/excel_import/` | `python3 tools/build_workbook.py data/excel_import out.xlsx` |
| `blank_no_prior_year.py` | Blanks the 26 year-on-year cells that have no prior-year half (2023 columns) | `python3 tools/blank_no_prior_year.py out.xlsx` |
| `finalize_calc_flag.py` | Sets the workbook to recalculate fully when opened | `python3 tools/finalize_calc_flag.py out.xlsx` |
| `gen_model.py` | `model/PCL_semantic_model.tmdl` and `model/PCL_measures.dax`, from `data/powerbi/` | `python3 tools/gen_model.py` |
| `build_site_data.py` | `docs/assets/js/data.js`, from `model/key_values.json` and `data/powerbi/` | `python3 tools/build_site_data.py` |

`gen_model.py` also writes `model/measure_registry.json`, a machine-readable measure list. It is not committed.

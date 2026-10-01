"""
Blanks the year-on-year cells in the 2023-H1 and 2023-H2 columns of the Excel model.
No prior-year half exists for 2023, so these cells must be empty (Power BI returns BLANK there too).
This is the presentation fix applied to the final workbook: 26 cells, no other result changes.
Run after tools/build_workbook.py and before tools/finalize_calc_flag.py.
Usage: python3 tools/blank_no_prior_year.py <workbook.xlsx>
"""
import sys
from openpyxl import load_workbook

CELLS = {
    "EBIT_Analysis": ["D40", "E40", "D46", "E46", "D49", "E49", "D51", "E51", "D52", "E52", "D53", "E53",
                      "D54", "E54", "D55", "E55", "D56", "E56", "D57", "E57", "D64", "E64"],
    "RD_DA": ["D21", "E21"],
    "Commercial": ["D22", "E22"],
}

path = sys.argv[1]
wb = load_workbook(path)
n = 0
for sheet, refs in CELLS.items():
    for ref in refs:
        wb[sheet][ref].value = None
        n += 1
wb.save(path)
print(f"blanked {n} cells in {path}")

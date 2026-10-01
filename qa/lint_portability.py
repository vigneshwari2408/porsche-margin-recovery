"""
Static portability lint for every formula in the workbook.
Flags: SUMPRODUCT, INDEX/MATCH, array coercion (--), wildcard criteria, volatile/dynamic functions,
and any range reference (A1:B2) that is NOT a direct argument of a plain aggregate function.
Usage: python3 lint_portability.py <workbook.xlsx>
"""
import re, sys
import openpyxl

AGG = {"SUM", "COUNT", "COUNTA", "COUNTIF", "COUNTIFS", "SUMIFS", "MIN", "MAX", "AVERAGE"}
BANNED = ["SUMPRODUCT(", "INDEX(", "MATCH(", "OFFSET(", "INDIRECT(", "XLOOKUP(", "FILTER(", "LET(", "LAMBDA(", "--("]
RANGE = re.compile(r"(?:'[^']+'|[A-Za-z_][A-Za-z0-9_]*)?!?\$?[A-Z]{1,3}\$?\d+:\$?[A-Z]{1,3}\$?\d+")

def strip_strings(f):
    return re.sub(r'"[^"]*"', '""', f)

def issues(f):
    out = []
    g = strip_strings(f)
    for b in BANNED:
        if b in g.upper(): out.append(f"uses {b}")
    if re.search(r'"[^"]*[*?][^"]*"', f) and re.search(r"COUNTIFS?\(|SUMIFS\(", f.upper()):
        out.append("wildcard criterion")
    for m in RANGE.finditer(g):
        # innermost enclosing function and whether the range stands alone as an argument
        depth, j, fn = 0, m.start() - 1, None
        while j >= 0:
            ch = g[j]
            if ch == ")": depth += 1
            elif ch == "(":
                if depth == 0:
                    k = j - 1
                    while k >= 0 and (g[k].isalnum() or g[k] in "._"): k -= 1
                    fn = g[k + 1:j].upper(); break
                depth -= 1
            j -= 1
        before = g[:m.start()].rstrip()[-1:] ; after = g[m.end():].lstrip()[:1]
        standalone = before in ("(", ",") and after in (")", ",")
        if fn not in AGG or not standalone:
            out.append(f"range {m.group(0)} used inside {fn or 'expression'} (array-style)")
    return out

wb = openpyxl.load_workbook(sys.argv[1])
total, bad = 0, []
for ws in wb:
    for row in ws.iter_rows():
        for c in row:
            if isinstance(c.value, str) and c.value.startswith("="):
                total += 1
                for i in issues(c.value):
                    bad.append((ws.title, c.coordinate, i))
print(f"formulas scanned: {total}   portability issues: {len(bad)}")
for b in bad[:30]: print("  ", *b)

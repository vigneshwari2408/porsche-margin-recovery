"""
PCL Phase 2 - Extract Porsche AG quarterly fact sheets into one tidy (long) table.

Input : Porsche AG IR fact sheets (XLSX), downloaded unchanged from
        investorrelations.porsche.com  (S024 = FY2025, S025 = H1 2026)
Output: fact_sheet_long.csv  - one row per (source, sheet, block, metric, period)
        fact_sheet_qc.txt    - quality-control log

Rules (auditable):
- Values are copied exactly as stored in the XLSX (EUR, not EUR m; units for volumes).
- Nothing is estimated. '%' helper columns are ignored (they are derivable).
- Known header defect: in S025 sheet '01 - Group EBIT', the YTD header cell F28 reads
  'Q1 2025' but the values are Q1 2026 (they equal the discrete Q1 2026 column F12..F18).
  We relabel it to 'Q1 2026' and flag the rows (flag = HEADER_FIX).
- Periods marked '*' are 2022 figures restated for IFRS 17 (flag = IFRS17_RESTATED).
"""
import csv, re, sys, openpyxl

FILES = [
    ("S024", "FY-2025-fact-sheet-porsche-ag.xlsx"),
    ("S025", "Q2-2026-fact-sheet-porsche-ag.xlsx"),
]

METRIC_MAP = {  # raw label (stripped) -> (Var_ID, unit)
    ("01 - Group EBIT", "Sales revenue"): ("G01", "EUR"),
    ("01 - Group EBIT", "Cost of sales"): ("G02", "EUR"),
    ("01 - Group EBIT", "Gross profit"): ("G03", "EUR"),
    ("01 - Group EBIT", "Distribution expenses"): ("G04", "EUR"),
    ("01 - Group EBIT", "Administrative expenses"): ("G05", "EUR"),
    ("01 - Group EBIT", "Net other operating result"): ("G06", "EUR"),
    ("01 - Group EBIT", "Operating profit"): ("G07", "EUR"),
    ("01 - Group EBIT", "Basic/diluted earnings per ordinary share in €"): ("G09", "EUR/share"),
    ("01 - Group EBIT", "Basic/diluted earnings per preferred share in €"): ("G10", "EUR/share"),
    ("02 - Automotive CF", "Cash flows from operating activities"): ("A13a", "EUR"),
    ("02 - Automotive CF", "Investing activities of current operations"): ("A13b", "EUR"),
    ("02 - Automotive CF", "Automotive net cash flow"): ("A13", "EUR"),
    ("02 - Automotive CF", "Automotive net liquidity"): ("A14", "EUR"),
    ("03 - Sales_deliveries by Region", "Vehicle sales"): ("O04", "units"),
    ("03 - Sales_deliveries by Region", "Deliveries to customers"): ("O01", "units"),
    ("03 - Sales_deliveries by Region", "Germany"): ("O03_DE", "units"),
    ("03 - Sales_deliveries by Region", "North America (excluding Mexico)"): ("O03_NA", "units"),
    ("03 - Sales_deliveries by Region", "China (including Hong Kong)"): ("O03_CN", "units"),
    ("03 - Sales_deliveries by Region", "Europe (excluding Germany)"): ("O03_EU", "units"),
    ("03 - Sales_deliveries by Region", "Overseas and Emerging Markets"): ("O03_OEM", "units"),
    ("04 - Sales_deliveries by Model", "Vehicle sales"): ("O04", "units"),
    ("04 - Sales_deliveries by Model", "Deliveries to customers"): ("O01", "units"),
    ("04 - Sales_deliveries by Model", "911"): ("O02_911", "units"),
    ("04 - Sales_deliveries by Model", "718"): ("O02_718", "units"),
    ("04 - Sales_deliveries by Model", "Cayenne"): ("O02_CAY", "units"),
    ("04 - Sales_deliveries by Model", "Panamera"): ("O02_PAN", "units"),
    ("04 - Sales_deliveries by Model", "Macan"): ("O02_MAC", "units"),
    ("04 - Sales_deliveries by Model", "Macan ICE"): ("O02_MAC_ICE", "units"),
    ("04 - Sales_deliveries by Model", "Macan BEV"): ("O02_MAC_BEV", "units"),
    ("04 - Sales_deliveries by Model", "Taycan"): ("O02_TAY", "units"),
}

def clean_period(raw):
    p = raw.replace("*", "").replace(" - ", "-").strip()
    m = re.match(r"^(Q[1-4]) (\d{4})$", p)
    if m: return f"{m.group(2)}-{m.group(1)}", "QTR"
    m = re.match(r"^Q1-Q2 (\d{4})$", p)
    if m: return f"{m.group(1)}-H1", "YTD"
    m = re.match(r"^Q1-Q3 (\d{4})$", p)
    if m: return f"{m.group(1)}-9M", "YTD"
    m = re.match(r"^FY (\d{4})$", p)
    if m: return f"{m.group(1)}-FY", "YTD"
    return None, None

def extract(sid, path):
    wb = openpyxl.load_workbook(path, data_only=True)
    rows = []
    for ws in wb.worksheets[1:]:
        hdr, block_no = {}, 0
        for row in ws.iter_rows():
            cells = [c for c in row if c.value is not None]
            if not cells: continue
            first = cells[0]
            if first.column == 1 and first.value in ("million €", "Units"):
                block_no += 1
                hdr = {c.column: c.value.strip() for c in cells[1:]
                       if isinstance(c.value, str) and "%" not in c.value}
                block_type = "QTR" if block_no == 1 else "YTD"
                continue
            if first.column != 1 or not isinstance(first.value, str) or not hdr:
                continue
            label = first.value.strip()
            key = (ws.title, label)
            if key not in METRIC_MAP: continue
            var, unit = METRIC_MAP[key]
            for c in cells[1:]:
                if c.column not in hdr or not isinstance(c.value, (int, float)): continue
                raw = hdr[c.column]; flags = []
                if block_type == "YTD" and sid == "S025" and ws.title == "01 - Group EBIT" and raw == "Q1 2025" and c.column == 6:
                    raw_used = "Q1 2026"; flags.append("HEADER_FIX")
                else:
                    raw_used = raw
                if "*" in raw: flags.append("IFRS17_RESTATED")
                period, ptype = clean_period(raw_used)
                rows.append({
                    "source_id": sid, "sheet": ws.title, "block": block_type,
                    "cell": c.coordinate, "raw_label": label, "var_id": var,
                    "raw_period": raw, "period": period, "period_type": ptype,
                    "value": c.value, "unit": unit, "flags": ";".join(flags),
                })
    return rows

def main(folder, out_csv, out_qc):
    allrows = []
    for sid, fn in FILES:
        allrows += extract(sid, f"{folder}/{fn}")
    qc = []
    # QC1: duplicates of the same var/period across sheets must agree (O01/O04 appear in two sheets)
    idx = {}
    for r in allrows:
        idx.setdefault((r["source_id"], r["var_id"], r["period"]), set()).add(round(r["value"], 2))
    bad = {k: v for k, v in idx.items() if len(v) > 1}
    qc.append(f"QC1 same var/period inside one file agrees across sheets/blocks: {'PASS' if not bad else 'FAIL ' + str(list(bad.items())[:5])}")
    # QC2: S024 vs S025 overlapping values identical (restatement check)
    a = {(r["var_id"], r["period"]): r["value"] for r in allrows if r["source_id"] == "S024"}
    b = {(r["var_id"], r["period"]): r["value"] for r in allrows if r["source_id"] == "S025"}
    common = set(a) & set(b)
    diffs = [(k, a[k], b[k]) for k in common if abs(a[k] - b[k]) > 0.5]
    qc.append(f"QC2 S024 vs S025 overlapping points: {len(common)}, differences: {len(diffs)} {diffs[:5]}")
    # QC3: quarters sum to YTD (S025 is the latest file -> primary)
    q = {(r["var_id"], r["period"]): r["value"] for r in allrows if r["source_id"] == "S025" and r["period_type"] == "QTR"}
    y = {(r["var_id"], r["period"]): r["value"] for r in allrows if r["source_id"] == "S025" and r["period_type"] == "YTD"}
    fails = []
    for (v, p), val in y.items():
        yr, kind = p.split("-")
        n = {"H1": 2, "9M": 3, "FY": 4}[kind]
        parts = [q.get((v, f"{yr}-Q{i}")) for i in range(1, n + 1)]
        if v == "A14" or None in parts:  # net liquidity is a stock, not additive
            continue
        if abs(sum(parts) - val) > max(1.0, abs(val) * 1e-6):
            fails.append((v, p, sum(parts), val))
    qc.append(f"QC3 quarters sum to YTD (flows only): {'PASS' if not fails else 'FAIL ' + str(fails[:8])}")
    # QC4: regions and models sum to total deliveries
    for group, prefix in (("regions", "O03_"), ("models", "O02_")):
        f2 = []
        for (v, p), val in q.items():
            if v != "O01": continue
            comps = [q.get((k, p)) for k in {r["var_id"] for r in allrows if r["var_id"].startswith(prefix) and r["var_id"] not in ("O02_MAC_ICE", "O02_MAC_BEV")}]
            if None in comps: continue
            if sum(comps) != val: f2.append((p, sum(comps), val))
        qc.append(f"QC4 {group} sum to total deliveries (quarters): {'PASS' if not f2 else 'FAIL ' + str(f2[:5])}")
    # QC5: Macan ICE + BEV = Macan
    f3 = [p for (v, p), val in q.items() if v == "O02_MAC" and q.get(("O02_MAC_ICE", p)) is not None
          and q.get(("O02_MAC_ICE", p)) + q.get(("O02_MAC_BEV", p)) != val]
    qc.append(f"QC5 Macan ICE + BEV = Macan: {'PASS' if not f3 else 'FAIL ' + str(f3)}")
    # QC6: EBIT = GP + distribution + admin + other (analysis window 2023+; 2022 reported rounded/restated)
    f4, f4_2022 = [], []
    for (v, p), val in q.items():
        if v != "G07": continue
        s = sum(q.get((k, p), 0) for k in ("G03", "G04", "G05", "G06"))
        if abs(s - val) > 2:
            (f4_2022 if p.startswith("2022") else f4).append((p, round(s), round(val)))
    qc.append(f"QC6 EBIT = gross profit + distribution + admin + other, quarters 2023+: {'PASS' if not f4 else 'FAIL ' + str(f4[:5])}")
    qc.append(f"QC6b same test, 2022 quarters (outside analysis window; IFRS 17 restated, some lines rounded to EUR m): {len(f4_2022)} small differences {f4_2022}")
    flagged = sum(1 for r in allrows if r["flags"])
    qc.append(f"Rows written: {len(allrows)}; rows with flags: {flagged}")

    with open(out_csv, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(allrows[0].keys()))
        w.writeheader(); w.writerows(allrows)
    with open(out_qc, "w", encoding="utf-8") as fh:
        fh.write("\n".join(qc) + "\n")
    print("\n".join(qc))

if __name__ == "__main__":
    folder = sys.argv[1] if len(sys.argv) > 1 else "."
    main(folder, "fact_sheet_long.csv", "fact_sheet_qc.txt")

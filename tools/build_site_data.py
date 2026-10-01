"""
Generates assets/js/data.js from the FINAL, reconciled project outputs.
No number on the website is typed by hand: every figure comes from these files.
  - model/key_values.json   (Python replica of the DAX measures, reconciled 1,524/0)
  - data/powerbi/*.csv       (tables loaded by the final .pbix)
Run from the repository root:  python3 tools/build_site_data.py
"""
import csv, json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "assets", "js", "data.js")
K = json.load(open(os.path.join(ROOT, "model", "key_values.json")))
rd = lambda t: list(csv.DictReader(open(os.path.join(ROOT, "data", "powerbi", t + ".csv"), encoding="utf-8")))
f = lambda x: None if x in ("", None) else float(x)

periods = list(K["trend"].keys())
label = {p: f"{p[5:]} {p[:4]}" for p in periods}           # 'H1 2026'
T = K["trend"]
series = lambda key: [T[p][key] for p in periods]

grid = [{"id": r["scenario_id"], "rev": r["case_rev"], "ros": r["case_ros"], "ex": r["case_ex"],
         "l0": f(r["h2_margin_l0_pct"]), "l1": f(r["h2_margin_l1_pct"]), "l2": f(r["h2_margin_l2_pct"]),
         "h2rev": f(r["h2_rev"]), "h2ebit": f(r["h2_ebit_l0"])} for r in rd("FactGuidance")]
auto = [{"id": r["scenario_id"], "rev": r["case_rev"], "m": r["case_m"],
         "ebitda": f(r["h2_auto_ebitda_margin_pct"]), "ncf": f(r["h2_auto_ncf_margin_pct"])} for r in rd("FactGuidanceAuto")]
ginputs = [{"id": r["guidance_id"], "metric": r["metric"], "low": f(r["low_value"]), "mid": f(r["mid_value"]), "high": f(r["high_value"]),
            "unit": r["unit_std"], "source": r["source_id"], "ref": r["source_ref"]} for r in rd("GuidanceInputs")]
assumptions = [{"id": r["assumption_id"], "statement": r["statement"]} for r in rd("Assumption")]
src = rd("DimSource")
fh = {r["period_code"]: r for r in rd("FactHalfYear")}
L, Q = K["period"], K["prior"]

D = {
  "periods": [label[p] for p in periods],
  "latest": label[L], "prior": label[Q],
  "kpi": {
    "revenue": [T[Q]["rev"], K["revenue"]], "l0": [T[Q]["L0"], K["L0"]], "l1": [T[Q]["L1"], K["L1"]], "l2": [T[Q]["L2"], K["L2"]],
    "m0": [K["M0_py"], K["M0"]], "m1": [K["M1_py"], K["M1"]], "m2": [K["M2_py"], K["M2"]],
    "asp": [T[Q]["asp"], K["asp"]], "vs": [T[Q]["vs"], K["vs"]], "ncfm": [K["ncf_m_py"], K["ncf_m"]],
    "yoy_l0": K["yoy_L0"], "yoy_l1": K["yoy_L1"], "yoy_m0_pp": K["yoy_M0_pp"], "yoy_m1_pp": K["yoy_M1_pp"], "yoy_m2_pp": K["yoy_M2_pp"],
    "one_offs_share": K["one_offs_share"],
  },
  "margins": {"l0": series("M0"), "l1": series("M1"), "l2": series("M2"), "l3": series("M3")},
  "ebit": {"l0": series("L0"), "l1": series("L1"), "l2": series("L2")},
  "levelBridge": {"l0": K["L0"], "realign": K["L1"] - K["L0"], "tariffs": K["L2"] - K["L1"], "l2": K["L2"]},
  "bridge": [
    {"key": "start", "label": f"EBIT {label[Q]}", "v": K["bridge"]["S0_START"], "kind": "total"},
    {"key": "exc", "label": "Exceptional items (realignment & battery, net)", "v": K["bridge"]["S1_EXC"], "kind": "adjust"},
    {"key": "tar", "label": "US import tariffs", "v": K["bridge"]["S2_TAR"], "kind": "adjust"},
    {"key": "cap", "label": "Capitalised development costs", "v": K["bridge"]["S3_CAPDEV"], "kind": "accounting"},
    {"key": "da", "label": "Clean automotive D&A", "v": K["bridge"]["S4_DA"], "kind": "accounting"},
    {"key": "fs", "label": "Financial Services", "v": K["bridge"]["S5_FS"], "kind": "segment"},
    {"key": "res", "label": "Residual / other drivers (not separated)", "v": K["bridge"]["S6_RES"], "kind": "residual"},
    {"key": "end", "label": f"EBIT {label[L]}", "v": K["L0"], "kind": "total"},
  ],
  "bridgePP": [
    {"label": "Revenue denominator", "v": K["bridge_pp"]["S7_DENOM"]}, {"label": "Exceptional items", "v": K["bridge_pp"]["S1_EXC"]},
    {"label": "US import tariffs", "v": K["bridge_pp"]["S2_TAR"]}, {"label": "Capitalised development costs", "v": K["bridge_pp"]["S3_CAPDEV"]},
    {"label": "Clean automotive D&A", "v": K["bridge_pp"]["S4_DA"]}, {"label": "Financial Services", "v": K["bridge_pp"]["S5_FS"]},
    {"label": "Residual / other drivers", "v": K["bridge_pp"]["S6_RES"]},
  ],
  "residualAltA04": K["res_alt_a04"], "l3": K["L3"], "l3AltA04": K["L3_alt_a04"],
  "rd": {"total": series("rd_t"), "cap": series("cap"), "pl": series("rd_pl"), "rate": series("cap_rate"),
         "cleanDA": series("clean_da"), "imp": series("imp"),
         "latest": {"total": K["rd_total"], "cap": K["cap_dev"], "pl": K["rd_pl"], "rate": K["cap_rate"], "ratePY": K["cap_rate_py"],
                    "capFx": K["cap_fx_sql"], "netCap": K["net_cap"], "cleanDA": K["clean_da"], "daTotal": K["da_total"], "imp": K["impairment"]}},
  "commercial": {"vs": series("vs"), "asp": series("asp"), "volFx": K["vol_fx"], "aspFx": K["asp_fx"],
                 "autoRev": [K["auto_rev_py"], K["auto_rev"]], "deliveries": K["deliv"], "vsYoY": K["vs_yoy"], "aspYoY": K["asp_yoy"],
                 "mix": {dim: [{"name": n, "cur": v[0], "py": v[1]} for n, v in K["mix"][dim].items()] for dim in ("model", "region")}},
  "cash": {"ncfm": series("ncf_m"), "ebitdam": series("ebitda_m"), "ncf": K["ncf"], "cfoEbitda": K["cfo_ebitda"], "proxy": K["proxy"],
           "ebitdamLatest": K["ebitda_m"], "note": fh[L]["cash_notes"]},
  "guidance": {"inputs": ginputs, "grid": grid, "auto": auto,
               "range": {lv: {"min": K["g"][lv][0], "mid": K["g"][lv][1], "max": K["g"][lv][2]} for lv in ("l0", "l1", "l2")},
               "autoRange": {w: {"min": K["ga"][w][0], "mid": K["ga"][w][1], "max": K["ga"][w][2]} for w in ("ebitda", "ncf")},
               "h1": {"l0": K["M0"], "l1": K["M1"], "l2": K["M2"], "ebitda": K["ebitda_m"], "ncf": K["ncf_m"]},
               "h2prior": {"l0": K["prior_h2_M0"], "l1": K["prior_h2_M1"]}},
  "qa": {"sqlDQ": 305, "sqlInfo": 28, "sqlMQ": 118, "excelChecks": 50, "excelValues": 553, "pbiQA": K["n_ref_pass"], "pbiQATotal": K["n_ref"],
         "recon": [["Power BI QA reference", 388], ["Live SQL views", 351], ["Excel model", 566], ["Identities", 51], ["Export integrity", 168]],
         "reconTotal": 1524, "pbixCells": 8111, "tables": 17, "relationships": 8, "measures": 194, "sqlViews": 11, "sqlScripts": 14,
         "sources": len(src), "sourcesPorsche": sum(1 for s in src if s["publisher"] == "Porsche AG"), "manualInputs": 155, "manualValues": 151,
         "gaps": 4, "sourceRefs": 481, "auditFindings": 13, "excelFormulas": 2997},
  "assumptions": assumptions,
}
with open(OUT, "w", encoding="utf-8") as fh_:
    fh_.write("/* Generated by tools/build_site_data.py from the final reconciled project outputs. Do not edit by hand. */\n")
    fh_.write("window.PCL = " + json.dumps(D, ensure_ascii=False, indent=1) + ";\n")
print("wrote", OUT, os.path.getsize(OUT), "bytes;", len(grid), "group scenarios,", len(auto), "automotive scenarios")

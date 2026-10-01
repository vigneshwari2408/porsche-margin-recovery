"""
PCL Phase 6 - generates the Power BI semantic model from ONE registry:
  model/PCL_semantic_model.tmdl   (TMDL script: paste into Power BI Desktop > TMDL view > Apply)
  model/PCL_measures.dax          (readable listing of every measure, same text)
  model/measure_registry.json     (machine-readable measure list; generated, not committed)
Tables are the CSVs in data/powerbi/ (exported from the SQL mart by sql/13_powerbi_export.sql).
Run from the repository root: python3 tools/gen_model.py
"""
import csv, json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data", "powerbi")
OUT = os.path.join(ROOT, "model")
os.makedirs(OUT, exist_ok=True)
T = "\t"

# ------------------------------------------------------------------ tables
TABLES = {  # name: (description, hidden_cols, sort_by {col: sortcol}, int_cols)
 "DimPeriod": ("Half-year periods 2023-H1..2026-H1 (analysis grain). prior_same_half_code drives all YoY measures.", [], {"period_label": "sort_key"}, ["sort_key", "fiscal_year", "half_no", "n_fact_values", "n_derived_values"]),
 "DimLevel": ("EBIT level legend: L0 reported, L1/L2 adjusted headline, L3 supplementary hybrid sensitivity (never headline).", [], {"level_name": "sort_order"}, ["sort_order"]),
 "DimLevelStep": ("Steps of the L0 -> L1 -> L2 waterfall (disconnected; values come from measures).", [], {"lstep_name": "lstep_order"}, ["lstep_order"]),
 "DimRevenueStep": ("Steps of the automotive revenue waterfall (disconnected; values from measures).", [], {"rstep_name": "rstep_order"}, ["rstep_order"]),
 "DimBridgeStep": ("Components of the SQL year-on-year EBIT bridge (mart.v_ebit_bridge_yoy).", [], {"step_name": "step_order"}, ["step_order"]),
 "FactHalfYear": ("One row per half-year: base values from mart.v_panel_hy plus SQL decompositions (v_ebit_adjusted, v_rd_capitalisation, v_da_clean, v_asp_volume, v_cash_crosscheck). Use measures, not columns.", "ALLNUM", {}, []),
 "FactBridgeYoY": ("mart.v_ebit_bridge_yoy in long form: EUR m and margin-point effects per bridge step.", "ALLNUM", {}, []),
 "FactSensitivity": ("Assumption-driven alternatives (A-04). Sensitivity only - never headline.", "ALLNUM", {}, []),
 "FactDeliveryMix": ("mart.v_delivery_mix: retail deliveries by model line (Macan total) and by region.", "ALLNUM", {"member_name": "member_sort"}, ["deliveries", "member_sort"]),
 "FactGuidance": ("mart.v_guidance_2026: 27 SCENARIO COMBINATIONS of FY2026 guidance range ends. NOT forecasts, NO probabilities.", "ALLNUM", {"case_rev": "sort_rev", "case_ros": "sort_ros", "case_ex": "sort_ex"}, ["sort_rev", "sort_ros", "sort_ex"]),
 "FactGuidanceAuto": ("mart.v_guidance_2026_auto: 9 automotive SCENARIO COMBINATIONS (revenue end x margin end). NOT forecasts.", "ALLNUM", {}, []),
 "GuidanceInputs": ("core.fact_guidance: Porsche FY2026 guidance ranges as published (low / mid / high).", [], {}, ["fiscal_year"]),
 "FactLineage": ("core.fact_financial (analysis window): every value with FACT/DERIVED label, source and page.", [], {}, []),
 "DimSource": ("audit.dim_source: source register S001-S027.", [], {}, ["tier"]),
 "Assumption": ("mart.assumption: A-01..A-09.", [], {}, []),
 "Annotation": ("mart.annotation: dated context notes per period.", [], {}, []),
 "RefSQL": ("QA reference: values exactly as published by the SQL mart views, with tolerance = view rounding. Disconnected; used by the QA page.", [], {}, []),
}
RELS = [  # from (many) -> to (one)
 ("FactHalfYear", "period_code", "DimPeriod", "period_code"),
 ("FactBridgeYoY", "period_code", "DimPeriod", "period_code"),
 ("FactBridgeYoY", "step_id", "DimBridgeStep", "step_id"),
 ("FactSensitivity", "period_code", "DimPeriod", "period_code"),
 ("FactDeliveryMix", "period_code", "DimPeriod", "period_code"),
 ("FactLineage", "period_code", "DimPeriod", "period_code"),
 ("FactLineage", "source_id", "DimSource", "source_id"),
 ("Annotation", "period_code", "DimPeriod", "period_code"),
]

def infer(table, col, vals, int_cols):
    v = [x for x in vals if x != ""]
    if v and all(x in ("true", "false") for x in v): return "boolean"
    if col in int_cols: return "int64"
    if col.endswith("_code") or col.endswith("_id") or col in ("period_label",): return "string"
    try:
        [float(x) for x in v]
        return "double" if v else "string"
    except ValueError:
        return "string"

SCHEMA = {}
for t in TABLES:
    rows = list(csv.reader(open(os.path.join(DATA, t + ".csv"), encoding="utf-8")))
    hdr, body = rows[0], rows[1:]
    SCHEMA[t] = [(c, infer(t, c, [r[i] for r in body], TABLES[t][3])) for i, c in enumerate(hdr)]

# ------------------------------------------------------------------ measures
M = []
def m(table, name, folder, fmt, expr, desc):
    M.append({"table": table, "name": name, "folder": folder, "fmt": fmt, "expr": expr.strip("\n"), "desc": desc})

EUR, PCT, PP, K, UNITS, RATIO, TXT = "#,##0", "0.0%", "+0.00;-0.00;0.00", "#,##0.0", "#,##0", "0.00", None
EUR_S, PCT_S, K_S = "+#,##0;-#,##0;0", "+0.0%;-0.0%;0.0%", "+#,##0.0;-#,##0.0;0.0"
F = "FactHalfYear"
def PY(name, base, fmt, desc):
    m(F, name, "03 Prior year (same half)", fmt, f"""
VAR _p = [Prior Period Code]
RETURN
    IF ( NOT ISBLANK ( _p ), CALCULATE ( {base}, REMOVEFILTERS ( DimPeriod ), DimPeriod[period_code] = _p ) )""", desc)

# 01 EBIT levels
m(F, "Revenue", "01 Revenue & EBIT levels", EUR, "SUM ( FactHalfYear[grp_revenue] )", "Group sales revenue, EUR m (G01, S025).")
m(F, "EBIT L0 Reported", "01 Revenue & EBIT levels", EUR, "SUM ( FactHalfYear[grp_ebit] )", "L0 reported group operating profit, EUR m (G07, S025).")
m(F, "Adj Realignment Battery", "01 Revenue & EBIT levels", EUR, "SUM ( FactHalfYear[adj_realignment_net] )", "Strategic realignment incl. battery activities, net charge added back (X01; A-01 = 0 where not disclosed).")
m(F, "Adj US Tariffs", "01 Revenue & EBIT levels", EUR, "SUM ( FactHalfYear[adj_us_tariffs] )", "US import tariff charge added back (X03; A-02 = 0 before April 2025).")
m(F, "Exceptional Items Added Back", "01 Revenue & EBIT levels", EUR, "[Adj Realignment Battery] + [Adj US Tariffs]", "Total disclosed items added back from L0 to L2.")
m(F, "EBIT L1", "01 Revenue & EBIT levels", EUR, "[EBIT L0 Reported] + [Adj Realignment Battery]", "L1 = L0 + X01. Main underlying (headline adjusted) level.")
m(F, "EBIT L2", "01 Revenue & EBIT levels", EUR, "[EBIT L1] + [Adj US Tariffs]", "L2 = L1 + X03 (also excl. US tariffs). Headline adjusted level.")
m(F, "Margin L0", "01 Revenue & EBIT levels", PCT, "DIVIDE ( [EBIT L0 Reported], [Revenue] )", "Reported return on sales.")
m(F, "Margin L1", "01 Revenue & EBIT levels", PCT, "DIVIDE ( [EBIT L1], [Revenue] )", "Margin excl. realignment & battery (headline adjusted).")
m(F, "Margin L2", "01 Revenue & EBIT levels", PCT, "DIVIDE ( [EBIT L2], [Revenue] )", "Margin also excl. US tariffs (headline adjusted).")
m(F, "Margin L1 minus L0 (pp)", "01 Revenue & EBIT levels", PP, "( [Margin L1] - [Margin L0] ) * 100", "How much the disclosed one-offs depress the reported margin, in margin points.")
m(F, "Adjustment Rounding Band", "01 Revenue & EBIT levels", EUR, "SUM ( FactHalfYear[rounding_band_eur_m] )", "+/- uncertainty of the added-back items: EUR 50m per item rounded to 0.1bn, doubled for derived H2 (A-09).")
m(F, "Level Bridge Value", "01 Revenue & EBIT levels", EUR, """
SWITCH (
    SELECTEDVALUE ( DimLevelStep[lstep_id] ),
    "LB0", [EBIT L0 Reported],
    "LB1", [Adj Realignment Battery],
    "LB2", [Adj US Tariffs]
)""", "Value per step of the L0 -> L1 -> L2 waterfall (use with DimLevelStep[lstep_name]; waterfall total = L2).")

# 02 L3
m(F, "Clean DA", "02 L3 supplementary sensitivity", EUR, "SUM ( FactHalfYear[da_total] ) - SUM ( FactHalfYear[impairment_used] )", "Automotive D&A excluding disclosed impairments (A12 - X05; A-03, A-04).")
m(F, "Capitalised Dev Costs", "02 L3 supplementary sensitivity", EUR, "SUM ( FactHalfYear[rd_capitalised] )", "Automotive capitalised development costs (A06).")
m(F, "EBIT L3 Hybrid Sensitivity", "02 L3 supplementary sensitivity", EUR, "[EBIT L1] + [Clean DA] - [Capitalised Dev Costs]", "SUPPLEMENTARY HYBRID SENSITIVITY: L1 + clean automotive D&A - automotive capitalised development costs. Not underlying profitability; never headline.")
m(F, "Margin L3 Hybrid Sensitivity", "02 L3 supplementary sensitivity", PCT, "DIVIDE ( [EBIT L3 Hybrid Sensitivity], [Revenue] )", "SUPPLEMENTARY HYBRID SENSITIVITY margin. Not a KPI.")
m(F, "EBIT L3 Hybrid Sensitivity alt A-04", "02 L3 supplementary sensitivity", EUR, 'CALCULATE ( SUM ( FactSensitivity[value_eur_m] ), FactSensitivity[sensitivity_id] = "SENS_A04_L3" )', "L3 if the H1 2026 impairments are NOT inside D&A (assumption A-04 false).")
m(F, "L3 Warning", "02 L3 supplementary sensitivity", TXT, '"L3 = SUPPLEMENTARY HYBRID SENSITIVITY: group EBIT mixed with automotive-only D&A and R&D. Not underlying profitability - not a KPI."', "Fixed warning text for every L3 visual.")

# 03 prior year
m(F, "Prior Period Code", "03 Prior year (same half)", TXT, "SELECTEDVALUE ( DimPeriod[prior_same_half_code] )", "Same half of the prior year; blank when outside the analysis window.")
for nm, base, fmt in [("Revenue PY", "[Revenue]", EUR), ("EBIT L0 PY", "[EBIT L0 Reported]", EUR), ("EBIT L1 PY", "[EBIT L1]", EUR),
                      ("EBIT L2 PY", "[EBIT L2]", EUR), ("Margin L0 PY", "[Margin L0]", PCT), ("Margin L1 PY", "[Margin L1]", PCT),
                      ("Margin L2 PY", "[Margin L2]", PCT), ("Adj Realignment PY", "[Adj Realignment Battery]", EUR),
                      ("Adj Tariffs PY", "[Adj US Tariffs]", EUR), ("Capitalised Dev Costs PY", "[Capitalised Dev Costs]", EUR),
                      ("Clean DA PY", "[Clean DA]", EUR), ("FS EBIT PY", "[FS EBIT]", EUR), ("RD PL Charge PY", "[RD PL Charge]", EUR),
                      ("Cap Rate Calc PY", "[Cap Rate Calc]", PCT), ("Auto Revenue PY", "[Auto Revenue]", EUR),
                      ("Vehicle Sales PY", "[Vehicle Sales]", UNITS), ("ASP PY", "[ASP (EUR k)]", K), ("Auto NCF PY", "[Auto NCF]", EUR),
                      ("NCF Margin PY", "[NCF Margin]", PCT)]:
    PY(nm, base, fmt, f"{base} in the same half of the prior year.")
def YOY(name, cur, py, fmt, desc, kind="diff"):
    body = {"diff": f"{cur} - {py}", "pp": f"( {cur} - {py} ) * 100", "pct": f"DIVIDE ( {cur}, {py} ) - 1"}[kind]
    m(F, name, "03 Prior year (same half)", fmt, f"IF ( NOT ISBLANK ( {py} ), {body} )", desc)
YOY("YoY Revenue %", "[Revenue]", "[Revenue PY]", PCT_S, "Group revenue change vs same half prior year.", "pct")
YOY("YoY EBIT L0", "[EBIT L0 Reported]", "[EBIT L0 PY]", EUR_S, "Change in reported EBIT, EUR m.")
YOY("YoY EBIT L1", "[EBIT L1]", "[EBIT L1 PY]", EUR_S, "Change in L1 EBIT, EUR m.")
YOY("YoY EBIT L2", "[EBIT L2]", "[EBIT L2 PY]", EUR_S, "Change in L2 EBIT, EUR m.")
YOY("YoY Margin L0 (pp)", "[Margin L0]", "[Margin L0 PY]", PP, "Change in reported margin, pp.", "pp")
YOY("YoY Margin L1 (pp)", "[Margin L1]", "[Margin L1 PY]", PP, "Change in L1 margin, pp.", "pp")
YOY("YoY Margin L2 (pp)", "[Margin L2]", "[Margin L2 PY]", PP, "Change in L2 margin, pp.", "pp")
YOY("YoY Clean DA", "[Clean DA]", "[Clean DA PY]", EUR_S, "Change in clean automotive D&A, EUR m.")
YOY("YoY RD PL Charge", "[RD PL Charge]", "[RD PL Charge PY]", EUR_S, "Change in R&D P&L charge, EUR m.")
YOY("YoY Cap Rate (pp)", "[Cap Rate Calc]", "[Cap Rate Calc PY]", PP, "Change in the capitalisation rate, pp.", "pp")
YOY("YoY Auto Revenue", "[Auto Revenue]", "[Auto Revenue PY]", EUR_S, "Change in automotive revenue, EUR m.")
YOY("YoY Vehicle Sales %", "[Vehicle Sales]", "[Vehicle Sales PY]", PCT_S, "Change in wholesale vehicle sales.", "pct")
YOY("YoY ASP %", "[ASP (EUR k)]", "[ASP PY]", PCT_S, "Change in ASP (automotive revenue per vehicle sold).", "pct")
YOY("YoY NCF Margin (pp)", "[NCF Margin]", "[NCF Margin PY]", PP, "Change in automotive net cash flow margin, pp.", "pp")

# 04 EBIT bridge (SQL) + DAX recompute
B = "FactBridgeYoY"
m(B, "Bridge EUR m", "04 EBIT bridge (SQL)", EUR, "SUM ( FactBridgeYoY[eur_m] )", "SQL bridge value per step (mart.v_ebit_bridge_yoy). Use with DimBridgeStep[step_name] in a waterfall.")
m(B, "Bridge pp", "04 EBIT bridge (SQL)", PP, "SUM ( FactBridgeYoY[pp] )", "SQL margin-point bridge per step; includes the revenue-denominator step; sums to the change in reported margin.")
for nm, sid in [("Bridge Start EBIT", "S0_START"), ("Bridge Exceptional", "S1_EXC"), ("Bridge Tariffs", "S2_TAR"), ("Bridge Cap Dev", "S3_CAPDEV"),
                ("Bridge Clean DA", "S4_DA"), ("Bridge FS", "S5_FS"), ("Bridge Residual", "S6_RES")]:
    m(B, nm, "04 EBIT bridge (SQL)", EUR, f'CALCULATE ( [Bridge EUR m], DimBridgeStep[step_id] = "{sid}" )', f"SQL bridge step {sid}.")
m(B, "Bridge Residual pp", "04 EBIT bridge (SQL)", PP, 'CALCULATE ( [Bridge pp], DimBridgeStep[step_id] = "S6_RES" )', "Residual / other EBIT drivers in margin points.")
m(B, "Bridge Residual alt A-04", "04 EBIT bridge (SQL)", EUR_S, 'CALCULATE ( SUM ( FactSensitivity[value_eur_m] ), FactSensitivity[sensitivity_id] = "SENS_A04_RES" )', "Residual if the H1 2026 impairments are NOT inside D&A (A-04 false). Sensitivity only.")
m(B, "Bridge Components Total", "04 EBIT bridge (SQL)", EUR, 'CALCULATE ( [Bridge EUR m], REMOVEFILTERS ( DimBridgeStep ), DimBridgeStep[step_id] <> "S0_START" )', "Sum of all bridge effects = change in reported EBIT.")
m(B, "One-offs Share of EBIT Change", "04 EBIT bridge (SQL)", "0%", "DIVIDE ( [Bridge Exceptional] + [Bridge Tariffs], [YoY EBIT L0] )", "Lower disclosed one-offs as a share of the reported EBIT change. >100% = the whole reported gain (and more) comes from lower one-offs.")
m(B, "Bridge Closure Check", "04 EBIT bridge (SQL)", "0.000000", "[Bridge Components Total] - [YoY EBIT L0]", "QA: SQL bridge components - DAX change in reported EBIT. Must be 0.")
m(B, "Bridge pp Closure Check", "04 EBIT bridge (SQL)", "0.0000", "ROUND ( CALCULATE ( [Bridge pp], REMOVEFILTERS ( DimBridgeStep ) ) - [YoY Margin L0 (pp)], 4 )", "QA: SQL pp bridge - DAX change in reported margin. Within 0.005 (3-dp rounding in SQL).")
m(F, "FS EBIT", "04 EBIT bridge (SQL)", EUR, "SUM ( FactHalfYear[fs_ebit] )", "Financial Services operating profit (F02).")
def GUARD(expr): return f"IF ( NOT ISBLANK ( [Prior Period Code] ), {expr} )"
m(F, "Recompute Eff Exceptional", "11 QA recompute", EUR, GUARD("- ( [Adj Realignment Battery] - [Adj Realignment PY] )"), "DAX recomputation of the SQL bridge step (QA).")
m(F, "Recompute Eff Tariffs", "11 QA recompute", EUR, GUARD("- ( [Adj US Tariffs] - [Adj Tariffs PY] )"), "DAX recomputation (QA).")
m(F, "Recompute Eff Cap Dev", "11 QA recompute", EUR, GUARD("[Capitalised Dev Costs] - [Capitalised Dev Costs PY]"), "DAX recomputation (QA).")
m(F, "Recompute Eff Clean DA", "11 QA recompute", EUR, GUARD("- ( [Clean DA] - [Clean DA PY] )"), "DAX recomputation (QA).")
m(F, "Recompute Eff FS", "11 QA recompute", EUR, GUARD("[FS EBIT] - [FS EBIT PY]"), "DAX recomputation (QA).")
m(F, "Recompute Residual", "11 QA recompute", EUR, GUARD("[YoY EBIT L0] - [Recompute Eff Exceptional] - [Recompute Eff Tariffs] - [Recompute Eff Cap Dev] - [Recompute Eff Clean DA] - [Recompute Eff FS]"), "DAX recomputation of residual / other EBIT drivers (QA).")

# 05 R&D and D&A
G5 = "05 R&D & D&A"
m(F, "RD Total Costs", G5, EUR, "SUM ( FactHalfYear[rd_total] )", "Total automotive R&D costs (A05) - Porsche accounting definition, not a cash figure.")
m(F, "RD Expensed", G5, EUR, "SUM ( FactHalfYear[rd_expensed] )", "R&D costs expensed as incurred (A08).")
m(F, "Amortisation Cap RD", G5, EUR, "SUM ( FactHalfYear[amort_capitalised_rd] )", "Amortisation of capitalised development costs (A09).")
m(F, "RD PL Charge", G5, EUR, "[RD Expensed] + [Amortisation Cap RD]", "R&D charge in the P&L = expensed + amortisation.")
m(F, "Cap Rate Calc", G5, PCT, "DIVIDE ( [Capitalised Dev Costs], [RD Total Costs] )", "Capitalisation rate = capitalised / total R&D costs.")
m(F, "Cap Rate Published", G5, PCT, "IF ( HASONEVALUE ( DimPeriod[period_code] ), DIVIDE ( SUM ( FactHalfYear[rd_cap_rate_published] ), 100 ) )", "Capitalisation rate as published (A07); H1 periods only.")
m(F, "Net Capitalisation", G5, EUR, "[Capitalised Dev Costs] - [Amortisation Cap RD]", ">0: the P&L R&D charge is below total R&D costs (capitalisation supports EBIT).")
m(F, "RD Total % Auto Revenue", G5, PCT, "DIVIDE ( [RD Total Costs], [Auto Revenue] )", "R&D cost intensity.")
m(F, "RD PL % Auto Revenue", G5, PCT, "DIVIDE ( [RD PL Charge], [Auto Revenue] )", "R&D P&L charge intensity.")
m(F, "Cap Rate Effect (SQL)", G5, K_S, "SUM ( FactHalfYear[sql_ebit_effect_of_cap_rate_change] )", "SQL: actual R&D P&L charge - charge at prior-year same-half capitalisation rate. >0 = extra charge (EBIT headwind); <0 = EBIT support. Illustrative counterfactual (amortisation held fixed).")
m(F, "Cap Rate Effect (DAX recompute)", "11 QA recompute", K, "IF ( NOT ISBLANK ( [Cap Rate Calc PY] ), [RD PL Charge] - ( [RD Total Costs] * ( 1 - [Cap Rate Calc PY] ) + [Amortisation Cap RD] ) )", "DAX recomputation of the capitalisation-rate effect (QA).")
m(F, "DA Total", G5, EUR, "SUM ( FactHalfYear[da_total] )", "Automotive D&A incl. impairments (A12).")
m(F, "Impairments in DA", G5, EUR, "SUM ( FactHalfYear[impairment_used] )", "Disclosed impairments inside automotive D&A as used (X05; A-03 = 0 where undisclosed; A-04 for H1 2026).")
m(F, "Impairment Status", G5, TXT, "SELECTEDVALUE ( FactHalfYear[impairment_status] )", "FACT / assumption used for impairments in the selected half-year.")
m(F, "Clean DA % Auto Revenue", G5, PCT, "DIVIDE ( [Clean DA], [Auto Revenue] )", "Clean D&A intensity.")

# 06 Commercial
G6 = "06 Commercial"
m(F, "Auto Revenue", G6, EUR, "SUM ( FactHalfYear[auto_revenue] )", "Automotive sales revenue (A01).")
m(F, "Vehicle Sales", G6, UNITS, "SUM ( FactHalfYear[vehicle_sales] )", "Wholesale vehicle sales (O04) - drives revenue.")
m(F, "Retail Deliveries", G6, UNITS, "SUM ( FactHalfYear[deliveries] )", "Retail deliveries (O01).")
m(F, "ASP (EUR k)", G6, K, "DIVIDE ( [Auto Revenue] * 1000, [Vehicle Sales] )", "Porsche ASP definition: automotive revenue per vehicle sold, EUR k.")
m(F, "ASP Published (EUR k)", G6, K, "IF ( HASONEVALUE ( DimPeriod[period_code] ), SUM ( FactHalfYear[asp_published_eur_k] ) )", "ASP as published by Porsche (O06), rounded to EUR 1k.")
m(F, "Volume Effect (SQL)", G6, EUR_S, "SUM ( FactHalfYear[sql_volume_effect] )", "SQL: change in vehicle sales x prior ASP / 1000, EUR m.")
m(F, "ASP Effect (SQL)", G6, EUR_S, "SUM ( FactHalfYear[sql_asp_effect] )", "SQL: change in ASP x current vehicle sales / 1000, EUR m. A residual of price, model/derivative mix, options, FX and non-vehicle revenue - not 'price'.")
m(F, "Volume Effect (DAX recompute)", "11 QA recompute", EUR, "IF ( NOT ISBLANK ( [Vehicle Sales PY] ), ( [Vehicle Sales] - [Vehicle Sales PY] ) * [ASP PY] / 1000 )", "DAX recomputation (QA).")
m(F, "ASP Effect (DAX recompute)", "11 QA recompute", EUR, "IF ( NOT ISBLANK ( [ASP PY] ), ( [ASP (EUR k)] - [ASP PY] ) * [Vehicle Sales] / 1000 )", "DAX recomputation (QA).")
m(F, "Volume ASP Closure Check", "11 QA recompute", "0.0", "IF ( NOT ISBLANK ( [Auto Revenue PY] ), [Volume Effect (SQL)] + [ASP Effect (SQL)] - [YoY Auto Revenue] )", "QA: volume + ASP effect - revenue change; within 0.1 (SQL rounds each effect to 0.1).")
m(F, "Wholesale minus Retail", G6, UNITS, "[Vehicle Sales] - [Retail Deliveries]", "PROXY for channel stock movement (wholesale - retail units).")
m(F, "BEV Share Published", G6, PCT, "IF ( HASONEVALUE ( DimPeriod[period_code] ), DIVIDE ( SUM ( FactHalfYear[bev_share_published] ), 100 ) )", "BEV share of deliveries as published (O07); H1 periods only.")
X = "FactDeliveryMix"
m(X, "Mix Deliveries", G6, UNITS, "SUM ( FactDeliveryMix[deliveries] )", "Retail deliveries by model line / region. Always filter FactDeliveryMix[dimension] to one value.")
m(X, "Mix Share", G6, PCT, "DIVIDE ( [Mix Deliveries], CALCULATE ( [Mix Deliveries], REMOVEFILTERS ( FactDeliveryMix[member_id], FactDeliveryMix[member_name], FactDeliveryMix[member_sort] ) ) )", "Share of deliveries within the selected dimension and period (removes only the member filters; the period filter from DimPeriod is kept).")
m(X, "Mix Share PY", G6, PCT, """
VAR _p = [Prior Period Code]
RETURN
    IF ( NOT ISBLANK ( _p ), CALCULATE ( [Mix Share], REMOVEFILTERS ( DimPeriod ), DimPeriod[period_code] = _p ) )""", "Mix share in the same half of the prior year.")
m(X, "Mix Share Change (pp)", G6, PP, "IF ( NOT ISBLANK ( [Mix Share PY] ), ( [Mix Share] - [Mix Share PY] ) * 100 )", "Change in delivery share, pp.")
m(X, "Mix Total Check", "11 QA recompute", UNITS, 'CALCULATE ( [Mix Deliveries], FactDeliveryMix[dimension] = "model" ) - [Retail Deliveries]', "QA: model-line deliveries - total deliveries. Must be 0.")

# 07 Cash
G7 = "07 Cash"
m(F, "Auto NCF", G7, EUR, "SUM ( FactHalfYear[auto_net_cash_flow] )", "Automotive net cash flow (A13).")
m(F, "Auto CFO", G7, EUR, "SUM ( FactHalfYear[auto_cfo] )", "Automotive cash flow from operating activities (A13a).")
m(F, "Auto CFI", G7, EUR, "SUM ( FactHalfYear[auto_cfi_operating] )", "Automotive investing activities of current operations (A13b).")
m(F, "Auto EBITDA", G7, EUR, "SUM ( FactHalfYear[auto_ebitda] )", "Automotive EBITDA (A03).")
m(F, "Auto EBIT", G7, EUR, "SUM ( FactHalfYear[auto_ebit] )", "Automotive operating profit (A02).")
m(F, "Auto Capex", G7, EUR, "SUM ( FactHalfYear[capex] )", "Automotive capex (A10).")
m(F, "NCF Margin", G7, PCT, "DIVIDE ( [Auto NCF], [Auto Revenue] )", "Automotive net cash flow / automotive revenue.")
m(F, "EBITDA Margin", G7, PCT, "DIVIDE ( [Auto EBITDA], [Auto Revenue] )", "Automotive EBITDA margin (calculated).")
m(F, "EBITDA Margin Published", G7, PCT, "IF ( HASONEVALUE ( DimPeriod[period_code] ), DIVIDE ( SUM ( FactHalfYear[auto_ebitda_margin_published] ), 100 ) )", "Automotive EBITDA margin as published (A04); H1 periods only.")
m(F, "CFO to EBITDA", G7, RATIO, "DIVIDE ( [Auto CFO], [Auto EBITDA] )", "Cash conversion of EBITDA.")
m(F, "NCF to EBIT", G7, RATIO, "IF ( [Auto EBIT] > 0, DIVIDE ( [Auto NCF], [Auto EBIT] ) )", "Net cash flow per euro of automotive EBIT (blank if EBIT <= 0).")
m(F, "Simple Cash Proxy", G7, EUR, "[Auto EBITDA] - [Auto Capex] - [Capitalised Dev Costs]", "EBITDA - capex - capitalised development costs.")
m(F, "NCF minus Proxy", G7, EUR, "[Auto NCF] - [Simple Cash Proxy]", "Working capital, tax, provisions and other items (not decomposed).")
m(F, "Net Liquidity (period end)", G7, EUR, """
VAR _k = MAX ( DimPeriod[sort_key] )
RETURN
    CALCULATE ( SUM ( FactHalfYear[auto_net_liquidity] ), REMOVEFILTERS ( DimPeriod ), DimPeriod[sort_key] = _k )""", "Automotive net liquidity at the end of the latest period in context (stock, not summed).")
m(F, "Cash Notes", G7, TXT, "SELECTEDVALUE ( FactHalfYear[cash_notes] )", "Qualitative cash timing notes from the SQL mart.")
m(F, "NCF Identity Check", "11 QA recompute", "0.00", "ROUND ( [Auto NCF] - ( [Auto CFO] + [Auto CFI] ), 3 )", "QA: NCF - (CFO + CFI); within 0.5 (AF-12 rounding).")

# 08 Latest half-year
G8 = "08 Latest half-year (fixed)"
def LATEST(nm, base, fmt, desc):
    m(F, nm, G8, fmt, f"CALCULATE ( {base}, REMOVEFILTERS ( DimPeriod ), DimPeriod[is_latest] = TRUE () )", desc)
m(F, "Latest Period Label", G8, TXT, "CALCULATE ( SELECTEDVALUE ( DimPeriod[period_label] ), REMOVEFILTERS ( DimPeriod ), DimPeriod[is_latest] = TRUE () )", "Label of the latest published half-year.")
for nm, base, fmt in [("Latest Revenue", "[Revenue]", EUR), ("Latest EBIT L0", "[EBIT L0 Reported]", EUR), ("Latest Adj Realignment", "[Adj Realignment Battery]", EUR),
                      ("Latest Adj Tariffs", "[Adj US Tariffs]", EUR), ("Latest Margin L0", "[Margin L0]", PCT), ("Latest Margin L1", "[Margin L1]", PCT),
                      ("Latest Margin L2", "[Margin L2]", PCT), ("Latest Auto Revenue", "[Auto Revenue]", EUR), ("Latest Auto EBITDA", "[Auto EBITDA]", EUR),
                      ("Latest Auto NCF", "[Auto NCF]", EUR), ("Latest EBITDA Margin", "[EBITDA Margin]", PCT), ("Latest NCF Margin", "[NCF Margin]", PCT)]:
    LATEST(nm, base, fmt, f"{base} in the latest published half-year, independent of the page slicer.")
for nm, base in [("Prior H2 Margin L0", "[Margin L0]"), ("Prior H2 Margin L1", "[Margin L1]")]:
    m(F, nm, G8, PCT, f"""
VAR _fy = CALCULATE ( MAX ( DimPeriod[fiscal_year] ), REMOVEFILTERS ( DimPeriod ), DimPeriod[is_latest] = TRUE () )
RETURN
    CALCULATE ( {base}, REMOVEFILTERS ( DimPeriod ), DimPeriod[fiscal_year] = _fy - 1, DimPeriod[half_no] = 2 )""", f"{base} in H2 of the prior fiscal year (comparator for guidance).")

# 09 Guidance scenarios
G = "FactGuidance"; G9 = "09 Guidance scenarios (NOT forecasts)"
m(G, "Scenario Disclaimer", G9, TXT, '"SCENARIO COMBINATIONS OF PORSCHE FY2026 GUIDANCE RANGE ENDS - ARITHMETIC ONLY - NOT FORECASTS - NO PROBABILITIES"', "Fixed disclaimer for every scenario visual.")
m(G, "Scen Rows Selected", G9, "0", "COUNTROWS ( FactGuidance )", "Number of combinations in context (1 = one combination selected).")
m(G, "Scen Selected Label", G9, TXT, 'IF ( COUNTROWS ( FactGuidance ) = 1, "Selected combination: " & SELECTEDVALUE ( FactGuidance[scenario_id] ) & " (revenue / RoS / extraordinary end)", "Select one end for revenue, RoS and extraordinary expenses" )', "Describes the selected combination.")
for lv, col in [("L0", "h2_margin_l0_pct"), ("L1", "h2_margin_l1_pct"), ("L2", "h2_margin_l2_pct")]:
    m(G, f"Scen H2 Margin {lv}", G9, "0.00%", f"IF ( COUNTROWS ( FactGuidance ) = 1, SUM ( FactGuidance[{col}] ) / 100 )", f"H2 2026 {lv} margin implied by the selected combination (SQL v_guidance_2026). Arithmetic, not a forecast.")
    m(G, f"Scen Min Margin {lv}", G9, "0.00%", f"CALCULATE ( MIN ( FactGuidance[{col}] ), REMOVEFILTERS ( FactGuidance ) ) / 100", f"Lowest H2 2026 {lv} margin across the 27 combinations.")
    m(G, f"Scen Mid Margin {lv}", G9, "0.00%", f'CALCULATE ( SUM ( FactGuidance[{col}] ), REMOVEFILTERS ( FactGuidance ), FactGuidance[scenario_id] = "mid/mid/mid" ) / 100', f"H2 2026 {lv} margin when ALL guidance midpoints are combined (not a most-likely case).")
    m(G, f"Scen Max Margin {lv}", G9, "0.00%", f"CALCULATE ( MAX ( FactGuidance[{col}] ), REMOVEFILTERS ( FactGuidance ) ) / 100", f"Highest H2 2026 {lv} margin across the 27 combinations.")
m(G, "Scen H2 Revenue", G9, EUR, "IF ( COUNTROWS ( FactGuidance ) = 1, SUM ( FactGuidance[h2_rev] ) )", "H2 2026 revenue implied (FY guidance end - H1 2026 actual).")
m(G, "Scen H2 EBIT L0", G9, EUR, "IF ( COUNTROWS ( FactGuidance ) = 1, SUM ( FactGuidance[h2_ebit_l0] ) )", "H2 2026 reported EBIT implied.")
m(G, "Scen H2 EBIT L1", G9, EUR, "IF ( COUNTROWS ( FactGuidance ) = 1, SUM ( FactGuidance[h2_ebit_l1] ) )", "H2 2026 L1 EBIT implied (A-06: extraordinary guidance is net).")
m(G, "Scen H2 L1 vs Latest H1 (pp)", G9, PP, "( [Scen H2 Margin L1] - [Latest Margin L1] ) * 100", "Selected combination's H2 L1 margin minus the latest actual H1 L1 margin, pp. Arithmetic gap, not a forecast.")
m(G, "Scen Mid L1 vs Latest H1 (pp)", G9, PP, "( [Scen Mid Margin L1] - [Latest Margin L1] ) * 100", "All-midpoints H2 L1 margin minus latest H1 L1 margin, pp.")
m(G, "Scen H2 Margin L0 (DAX recompute)", "11 QA recompute", "0.00%", """
VAR _r = SELECTEDVALUE ( FactGuidance[fy_rev] )
VAR _ros = SELECTEDVALUE ( FactGuidance[fy_ros] )
RETURN
    IF ( COUNTROWS ( FactGuidance ) = 1, DIVIDE ( _r * _ros / 100 - [Latest EBIT L0], _r - [Latest Revenue] ) )""", "DAX recomputation of the H2 L0 margin from guidance inputs and H1 actuals (QA).")
m(G, "Scen H2 Margin L1 (DAX recompute)", "11 QA recompute", "0.00%", """
VAR _r = SELECTEDVALUE ( FactGuidance[fy_rev] )
VAR _ros = SELECTEDVALUE ( FactGuidance[fy_ros] )
VAR _exc = SELECTEDVALUE ( FactGuidance[fy_exc] )
RETURN
    IF ( COUNTROWS ( FactGuidance ) = 1, DIVIDE ( _r * _ros / 100 - [Latest EBIT L0] + _exc - [Latest Adj Realignment], _r - [Latest Revenue] ) )""", "DAX recomputation (QA).")
m(G, "Scen H2 Margin L2 (DAX recompute)", "11 QA recompute", "0.00%", """
VAR _r = SELECTEDVALUE ( FactGuidance[fy_rev] )
VAR _ros = SELECTEDVALUE ( FactGuidance[fy_ros] )
VAR _exc = SELECTEDVALUE ( FactGuidance[fy_exc] )
RETURN
    IF ( COUNTROWS ( FactGuidance ) = 1, DIVIDE ( _r * _ros / 100 - [Latest EBIT L0] + _exc - [Latest Adj Realignment] + [Latest Adj Tariffs], _r - [Latest Revenue] ) )""", "DAX recomputation (QA; A-07: H2 tariffs = H1).")
A = "FactGuidanceAuto"
for nm, col in [("Scen Auto H2 EBITDA Margin", "h2_auto_ebitda_margin_pct"), ("Scen Auto H2 NCF Margin", "h2_auto_ncf_margin_pct")]:
    m(A, nm, G9, "0.00%", f"""
VAR _t = CALCULATETABLE ( FactGuidanceAuto, TREATAS ( VALUES ( FactGuidance[case_rev] ), FactGuidanceAuto[case_rev] ) )
RETURN
    IF ( COUNTROWS ( _t ) = 1, SUMX ( _t, FactGuidanceAuto[{col}] ) / 100 )""", f"H2 2026 automotive margin implied by the selected revenue end (group slicer) and margin end (automotive slicer). Uses A-05. Not a forecast.")
    m(A, nm.replace("Scen Auto H2", "Scen Auto Min"), G9, "0.00%", f"CALCULATE ( MIN ( FactGuidanceAuto[{col}] ), REMOVEFILTERS ( FactGuidanceAuto ) ) / 100", "Lowest across the 9 automotive combinations.")
    m(A, nm.replace("Scen Auto H2", "Scen Auto Mid"), G9, "0.00%", f'CALCULATE ( SUM ( FactGuidanceAuto[{col}] ), REMOVEFILTERS ( FactGuidanceAuto ), FactGuidanceAuto[scenario_id] = "mid/mid" ) / 100', "All-midpoints automotive combination.")
    m(A, nm.replace("Scen Auto H2", "Scen Auto Max"), G9, "0.00%", f"CALCULATE ( MAX ( FactGuidanceAuto[{col}] ), REMOVEFILTERS ( FactGuidanceAuto ) ) / 100", "Highest across the 9 automotive combinations.")
for nm, gcol, h1 in [("Scen Auto H2 EBITDA Margin (DAX recompute)", "fy_ebitda_margin", "[Latest Auto EBITDA]"), ("Scen Auto H2 NCF Margin (DAX recompute)", "fy_ncf_margin", "[Latest Auto NCF]")]:
    m(A, nm, "11 QA recompute", "0.00%", f"""
VAR _share = DIVIDE ( [Latest Auto Revenue], [Latest Revenue] )
VAR _fyauto = SELECTEDVALUE ( FactGuidanceAuto[fy_grp_rev] ) * _share
RETURN
    IF ( COUNTROWS ( FactGuidanceAuto ) = 1, DIVIDE ( SELECTEDVALUE ( FactGuidanceAuto[{gcol}] ) / 100 * _fyauto - {h1}, _fyauto - [Latest Auto Revenue] ) )""", "DAX recomputation with A-05 (automotive share of H1 2026) (QA).")

# 10 Recovery signals (sign-based only; no new thresholds)
S = "10 Recovery signals"
m(F, "Signal Underlying Margin", S, TXT, """
VAR _d = [YoY Margin L1 (pp)]
RETURN
    IF ( ISBLANK ( _d ), "No prior-year half in window",
        "L1 margin " & FORMAT ( _d, "+0.0;-0.0" ) & " pp vs same half prior year: " & IF ( _d < 0, "underlying margin DOWN", "underlying margin UP" ) )""", "Direction of the headline adjusted (L1) margin.")
m(F, "Signal Recovery Source", S, TXT, """
VAR _exc = [Bridge Exceptional] + [Bridge Tariffs]
VAR _d = [YoY EBIT L0]
RETURN
    SWITCH ( TRUE (),
        ISBLANK ( _d ), "No prior-year half in window",
        _d > 0 && _exc >= _d, "Lower one-offs (" & FORMAT ( _exc, "+#,##0;-#,##0" ) & " EUR m) exceed the whole reported EBIT gain (" & FORMAT ( _d, "+#,##0;-#,##0" ) & " EUR m)",
        _d > 0, "Lower one-offs explain " & FORMAT ( DIVIDE ( _exc, _d ), "0%" ) & " of the reported EBIT gain",
        "Reported EBIT " & FORMAT ( _d, "+#,##0;-#,##0" ) & " EUR m vs same half prior year" )""", "Is the reported EBIT gain explained by lower disclosed one-offs?")
m(F, "Signal Other Drivers", S, TXT, """
VAR _r = [Bridge Residual]
RETURN
    IF ( ISBLANK ( _r ), "No prior-year half in window",
        "Residual / other EBIT drivers " & FORMAT ( _r, "+#,##0;-#,##0" ) & " EUR m (" & IF ( _r < 0, "negative", "positive" ) & "; not separated - not operating performance)" )""", "Sign of the unexplained part of the EBIT change.")
m(F, "Signal Value over Volume", S, TXT, """
VAR _v = [Volume Effect (SQL)]
VAR _a = [ASP Effect (SQL)]
RETURN
    SWITCH ( TRUE (),
        ISBLANK ( _v ), "No prior-year half in window",
        _v < 0 && _a > 0, "ASP effect " & FORMAT ( _a, "+#,##0" ) & " offsets " & FORMAT ( DIVIDE ( _a, - _v ), "0%" ) & " of the volume effect " & FORMAT ( _v, "#,##0" ) & " EUR m",
        "Volume effect " & FORMAT ( _v, "+#,##0;-#,##0" ) & ", ASP effect " & FORMAT ( _a, "+#,##0;-#,##0" ) & " EUR m" )""", "Does value (ASP) compensate for lower volume?")
m(F, "Signal Capitalisation", S, TXT, """
VAR _c = [Cap Rate Effect (SQL)]
RETURN
    IF ( ISBLANK ( _c ), "No prior-year half in window",
        IF ( _c < 0,
            "Higher capitalisation rate lowered the R&D P&L charge by " & FORMAT ( - _c, "#,##0" ) & " EUR m vs the prior-year rate (non-cash EBIT support)",
            "Lower capitalisation rate added " & FORMAT ( _c, "#,##0" ) & " EUR m to the R&D P&L charge vs the prior-year rate (non-cash EBIT headwind)" ) )""", "Non-cash support or headwind from the capitalisation rate (illustrative counterfactual).")
m(F, "Signal Cash", S, TXT, """
VAR _d = [YoY NCF Margin (pp)]
RETURN
    IF ( ISBLANK ( _d ), "No prior-year half in window",
        "Automotive NCF margin " & FORMAT ( [NCF Margin], "0.0%" ) & " (" & FORMAT ( _d, "+0.0;-0.0" ) & " pp vs same half prior year)" )""", "Does cash move with profit?")
m(G, "Signal Guidance Gap", S, TXT, """
VAR _mid = [Scen Mid Margin L1]
VAR _h1 = [Latest Margin L1]
RETURN
    "All-midpoint guidance combination implies an H2 L1 margin of " & FORMAT ( _mid, "0.0%" ) & " vs " & FORMAT ( _h1, "0.0%" ) & " in " & [Latest Period Label]
        & " (" & FORMAT ( ( _mid - _h1 ) * 100, "+0.0;-0.0" ) & " pp) - arithmetic, not a forecast" """, "What the guidance requires from H2 relative to the latest actual half-year.")
m(F, "Signal Color L1", S, TXT, 'IF ( [YoY Margin L1 (pp)] < 0, "#B3261E", IF ( [YoY Margin L1 (pp)] > 0, "#1B6E3C", "#5F6368" ) )', "Conditional-format colour (red = down, green = up).")
m(F, "Signal Color Residual", S, TXT, 'IF ( [Bridge Residual] < 0, "#B3261E", IF ( [Bridge Residual] > 0, "#1B6E3C", "#5F6368" ) )', "Conditional-format colour.")

# 13 Level-driven wrappers (DimLevel legend; filter DimLevel[is_headline] = TRUE on every headline visual)
GL = "13 Level-driven (legend = DimLevel)"
m(F, "EBIT by Level", GL, EUR, """
SWITCH ( SELECTEDVALUE ( DimLevel[level_id] ),
    "L0", [EBIT L0 Reported],
    "L1", [EBIT L1],
    "L2", [EBIT L2],
    "L3", [EBIT L3 Hybrid Sensitivity] )""", "EBIT for the level on the legend. L3 appears only where DimLevel[is_headline] is not filtered to TRUE (sensitivity visuals).")
m(F, "Margin by Level", GL, PCT, """
SWITCH ( SELECTEDVALUE ( DimLevel[level_id] ),
    "L0", [Margin L0],
    "L1", [Margin L1],
    "L2", [Margin L2],
    "L3", [Margin L3 Hybrid Sensitivity] )""", "Margin for the level on the legend.")
for st in ("Min", "Mid", "Max"):
    m(G, f"Scen {st} by Level", GL, "0.00%", f"""
SWITCH ( SELECTEDVALUE ( DimLevel[level_id] ),
    "L0", [Scen {st} Margin L0],
    "L1", [Scen {st} Margin L1],
    "L2", [Scen {st} Margin L2] )""", f"{st} of the H2 2026 implied margin across the 27 combinations, for the level on the axis (L0-L2 only; no L3 scenario exists).")
m(F, "Latest Margin by Level", GL, PCT, """
SWITCH ( SELECTEDVALUE ( DimLevel[level_id] ),
    "L0", [Latest Margin L0],
    "L1", [Latest Margin L1],
    "L2", [Latest Margin L2] )""", "Latest actual half-year margin for the level on the axis (comparator on the guidance chart).")
m(F, "Revenue Bridge Value", G6, EUR, """
SWITCH ( SELECTEDVALUE ( DimRevenueStep[rstep_id] ),
    "RS0", [Auto Revenue PY],
    "RS1", [Volume Effect (SQL)],
    "RS2", [ASP Effect (SQL)] )""", "Automotive revenue waterfall: prior-year revenue, volume effect, ASP effect (total = current automotive revenue within SQL 0.1 rounding).")

# 11 QA (RefSQL)
Q = "RefSQL"; GQ = "12 QA vs SQL"
QMAP = [  # metric_key -> DAX expression evaluated for the RefSQL row
 ("ebit_l0_reported", "[EBIT L0 Reported]"), ("ebit_l1_ex_realignment", "[EBIT L1]"), ("ebit_l2_ex_realignment_tariffs", "[EBIT L2]"),
 ("ebit_l3_hybrid_sensitivity", "[EBIT L3 Hybrid Sensitivity]"), ("margin_l0_reported_pct", "[Margin L0] * 100"), ("margin_l1_pct", "[Margin L1] * 100"),
 ("margin_l2_pct", "[Margin L2] * 100"), ("margin_l3_hybrid_pct", "[Margin L3 Hybrid Sensitivity] * 100"), ("yoy_ebit_l1", "[YoY EBIT L1]"),
 ("yoy_margin_l1_pp", "[YoY Margin L1 (pp)]"), ("yoy_margin_l0_pp", "[YoY Margin L0 (pp)]"), ("da_clean", "[Clean DA]"), ("yoy_da_clean", "[YoY Clean DA]"),
 ("rd_total_costs", "[RD Total Costs]"), ("rd_pl_charge", "[RD PL Charge]"), ("cap_rate_calc_pct", "[Cap Rate Calc] * 100"),
 ("net_capitalisation", "[Net Capitalisation]"), ("ebit_effect_of_cap_rate_change", "[Cap Rate Effect (DAX recompute)]"), ("yoy_rd_pl_charge", "[YoY RD PL Charge]"),
 ("asp_calc_eur_k", "[ASP (EUR k)]"), ("yoy_vehicle_sales_pct", "[YoY Vehicle Sales %] * 100"), ("yoy_asp_pct", "[YoY ASP %] * 100"),
 ("yoy_auto_revenue", "[YoY Auto Revenue]"), ("volume_effect", "[Volume Effect (DAX recompute)]"), ("asp_effect", "[ASP Effect (DAX recompute)]"),
 ("auto_net_cash_flow", "[Auto NCF]"), ("ncf_margin_pct", "[NCF Margin] * 100"), ("ebitda_margin_calc_pct", "[EBITDA Margin] * 100"),
 ("cfo_to_ebitda", "[CFO to EBITDA]"), ("simple_cash_proxy", "[Simple Cash Proxy]"), ("d_ebit", "[YoY EBIT L0]"),
 ("eff_residual_other_drivers", "[Recompute Residual]"), ("d_margin_pp", "[YoY Margin L0 (pp)]"),
]
QG = [("g_h2_margin_l0_pct", "[Scen H2 Margin L0 (DAX recompute)] * 100"), ("g_h2_margin_l1_pct", "[Scen H2 Margin L1 (DAX recompute)] * 100"),
      ("g_h2_margin_l2_pct", "[Scen H2 Margin L2 (DAX recompute)] * 100")]
QS = [(f"gs_{lv.lower()}_{k}", f"[Scen {K2} Margin {lv}] * 100") for lv in ("L0", "L1", "L2") for k, K2 in (("min", "Min"), ("mid", "Mid"), ("max", "Max"))]
QA_ = [("ga_h2_ebitda_margin_pct", "[Scen Auto H2 EBITDA Margin (DAX recompute)] * 100"), ("ga_h2_ncf_margin_pct", "[Scen Auto H2 NCF Margin (DAX recompute)] * 100")]
def sw(pairs): return ",\n            ".join(f'"{k}", {v}' for k, v in pairs)
m(Q, "QA SQL Value", GQ, "0.000000", "IF ( HASONEVALUE ( RefSQL[metric_key] ), SUM ( RefSQL[sql_value] ) )", "Value published by the SQL mart view for this row.")
m(Q, "QA DAX Value", GQ, "0.000000", f"""
VAR _k = SELECTEDVALUE ( RefSQL[metric_key] )
VAR _p = SELECTEDVALUE ( RefSQL[period_code] )
VAR _s = SELECTEDVALUE ( RefSQL[scenario_id] )
RETURN
    SWITCH ( TRUE (),
        LEFT ( _k, 3 ) = "gs_",
            CALCULATE ( SWITCH ( _k,
            {sw(QS)} ) ),
        LEFT ( _k, 2 ) = "g_",
            CALCULATE ( SWITCH ( _k,
            {sw(QG)} ), TREATAS ( {{ _s }}, FactGuidance[scenario_id] ) ),
        _k = "mix_share_pct",
            CALCULATE ( [Mix Share] * 100, REMOVEFILTERS ( DimPeriod ), TREATAS ( {{ _p }}, DimPeriod[period_code] ),
                TREATAS ( {{ SELECTEDVALUE ( RefSQL[dimension] ) }}, FactDeliveryMix[dimension] ),
                TREATAS ( {{ SELECTEDVALUE ( RefSQL[member_id] ) }}, FactDeliveryMix[member_id] ) ),
        LEFT ( _k, 3 ) = "ga_",
            CALCULATE ( SWITCH ( _k,
            {sw(QA_)} ), TREATAS ( {{ _s }}, FactGuidanceAuto[scenario_id] ) ),
        CALCULATE ( SWITCH ( _k,
            {sw(QMAP)} ), REMOVEFILTERS ( DimPeriod ), TREATAS ( {{ _p }}, DimPeriod[period_code] ) )
    )""", "The same quantity recomputed by the Power BI measures (from base values, not from the SQL result).")
m(Q, "QA Abs Difference", GQ, "0.000000", "ABS ( [QA DAX Value] - [QA SQL Value] )", "|DAX - SQL|.")
m(Q, "QA Status", GQ, TXT, 'IF ( ISBLANK ( [QA DAX Value] ), "MISSING", IF ( [QA Abs Difference] <= SELECTEDVALUE ( RefSQL[tolerance] ), "PASS", "FAIL" ) )', "PASS within the SQL view's rounding tolerance.")
m(Q, "QA Fail Count", GQ, "0", 'SUMX ( RefSQL, IF ( [QA Status] = "PASS", 0, 1 ) )', "Rows not passing.")
m(Q, "QA Summary", GQ, TXT, 'VAR _n = COUNTROWS ( RefSQL ) VAR _f = [QA Fail Count] RETURN IF ( _f = 0, "ALL " & _n & " QA CHECKS PASS (Power BI vs SQL mart)", _f & " OF " & _n & " QA CHECKS FAIL - see QA page" )', "Model status card.")
m(Q, "QA Identity Checks Max", GQ, "0.000000", """
ROUND (
    MAXX (
        VALUES ( DimPeriod[period_code] ),
        MAX ( ABS ( [Bridge Closure Check] ), ABS ( [Mix Total Check] ) )
    ),
    10
)""", "Largest EUR/unit identity breach across periods (bridge closure, mix total). Must be 0.")


# ---- name checks: measure names unique model-wide and never equal (case-insensitive) to any column name
_mn = [x["name"].lower() for x in M]
assert len(_mn) == len(set(_mn)), "duplicate measure names"
_cols = {c.lower() for t in SCHEMA for c, _ in SCHEMA[t]}
_clash = [x["name"] for x in M if x["name"].lower() in _cols]
assert not _clash, f"measure/column name clash: {_clash}"
_known = {x["name"] for x in M}
import re as _re
for x in M:
    for ref in _re.findall(r"(?<![A-Za-z_\]])\[([^\]]+)\]", x["expr"]):
        assert ref in _known, f"{x['name']}: unknown measure [{ref}]"
    for tbl, col in _re.findall(r"([A-Za-z]+)\[([A-Za-z0-9_]+)\]", x["expr"]):
        assert tbl in SCHEMA and col in dict(SCHEMA[tbl]), f"{x['name']}: unknown column {tbl}[{col}]"

# ------------------------------------------------------------------ writers
def q(n): return n if n.replace("_", "").isalnum() else "'" + n.replace("'", "''") + "'"
MTYPE = {"string": "type text", "double": "type number", "int64": "Int64.Type", "boolean": "type logical"}
lines = ["createOrReplace", ""]
lines += [f'{T}expression DataFolder = "C:\\PCL\\pcl_powerbi\\data\\" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]', ""]
for t, (desc, hidden, sortby, _ints) in TABLES.items():
    lines.append(f"{T}/// {desc}")
    lines.append(f"{T}table {t}")
    lines.append("")
    for tm in [x for x in M if x["table"] == t]:
        lines.append(f"{T*2}/// {tm['desc']}")
        ex = tm["expr"].split("\n")
        if len(ex) == 1:
            lines.append(f"{T*2}measure {q(tm['name'])} = {ex[0]}")
        else:
            lines.append(f"{T*2}measure {q(tm['name'])} =")
            lines += [f"{T*4}" + T * ((len(e) - len(e.lstrip(" "))) // 4) + e.lstrip(" ") for e in ex if e.strip() != ""]
        if tm["fmt"]: lines.append(f"{T*3}formatString: {tm['fmt']}")
        lines.append(f"{T*3}displayFolder: {tm['folder']}")
        lines.append("")
    for c, dt in SCHEMA[t]:
        lines.append(f"{T*2}column {q(c)}")
        lines.append(f"{T*3}dataType: {dt}")
        if dt in ("double", "int64"):
            lines.append(f"{T*3}summarizeBy: none")
        if (hidden == "ALLNUM" and dt in ("double", "int64")) or c in ("sort_key",) or c.startswith("sort_"):
            lines.append(f"{T*3}isHidden")
        if dt == "double" and c == "tolerance": lines.append(f"{T*3}formatString: 0.000")
        elif dt == "double" and c.endswith(("_pct", "_published")): lines.append(f"{T*3}formatString: 0.00")
        elif dt == "double": lines.append(f"{T*3}formatString: #,##0.00")
        if c in sortby: lines.append(f"{T*3}sortByColumn: {sortby[c]}")
        lines.append(f"{T*3}sourceColumn: {c}")
        lines.append("")
    types = ", ".join('{"%s", %s}' % (c, MTYPE[dt]) for c, dt in SCHEMA[t])
    lines += [f"{T*2}partition {t} = m", f"{T*3}mode: import", f"{T*3}source =", f"{T*5}let",
              f'{T*6}Source = Csv.Document(File.Contents(DataFolder & "{t}.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),',
              f"{T*6}Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),",
              f'{T*6}Typed = Table.TransformColumnTypes(Promoted, {{{types}}}, "en-US")',
              f"{T*5}in", f"{T*6}Typed", ""]
for a, ac, b, bc in RELS:
    lines += [f"{T}relationship {a}_{ac}_{b}", f"{T*2}fromColumn: {a}.{ac}", f"{T*2}toColumn: {b}.{bc}", ""]
open(os.path.join(OUT, "PCL_semantic_model.tmdl"), "w", encoding="utf-8").write("\n".join(lines))

dax = ["// PCL Porsche 2026 Margin Recovery - Power BI measures (generated from gen_model.py; identical to the TMDL script)", ""]
for tm in M:
    dax += [f"// [{tm['folder']}]  {tm['desc']}", f"{tm['table']}[{tm['name']}] =", tm["expr"], ""]
open(os.path.join(OUT, "PCL_measures.dax"), "w", encoding="utf-8").write("\n".join(dax))
json.dump({"measures": M, "schema": SCHEMA, "rels": RELS, "qa_keys": [k for k, _ in QMAP + QG + QS + QA_] + ["mix_share_pct"]},
          open(os.path.join(OUT, "measure_registry.json"), "w"), indent=1)
print(f"tables {len(TABLES)}  columns {sum(len(v) for v in SCHEMA.values())}  relationships {len(RELS)}  measures {len(M)}")

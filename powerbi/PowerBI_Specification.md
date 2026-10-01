# PCL Porsche Company Lens - Phase 6: Power BI management dashboard

**Core question:** *How sustainable is Porsche's 2026 margin recovery?*
**Grain:** half-year, 2023-H1 ... 2026-H1 (7 periods). **Currency:** EUR m unless stated.
**Source of truth:** SQL mart (`porsche_lens`, Phases 3-4) -> Excel model PCL_05 (Phase 5, approved). Power BI is the monitoring / decision layer: it **imports SQL mart outputs**, aggregates, compares, selects scenarios and flags signals. It introduces **no new data, assumptions or thresholds**.

| Layer | Role | What it must never do |
|---|---|---|
| SQL mart | Calculates every decomposition (levels, bridge, R&D counterfactual, volume/ASP, cash proxy, guidance grid) | - |
| Excel PCL_05 | Business model, formulas, audit of the logic | - |
| **Power BI** | Monitors: KPI cards, trends, bridges, scenario exploration, recovery signals, QA | Re-define logic, estimate missing values, present scenarios as forecasts, make L3 a KPI |

> **Final status.** The final report is `powerbi/Porsche_Company_Lens_2026_Margin_Recovery.pbix` (6 pages; screenshots in `powerbi/screenshots/`). Its in-report QA page reads **ALL 388 QA CHECKS PASS (Power BI vs SQL mart)**. The model was first written as the TMDL script in `model/` and every measure was replicated line for line in Python and reconciled to SQL and Excel (section 7: **1,524 comparisons, 0 failures**). Sections 1 to 6 below are the original build specification, kept because they document how the report was constructed.

---

## 1. How to build it (about 20 minutes)

1. Copy the repository's `data/powerbi/` folder to e.g. `C:\PCL\data\`.
2. Power BI Desktop (2025 or later) -> *Options > Preview features* -> enable **TMDL view** (GA in recent builds) -> restart.
3. Blank report -> **TMDL view** -> paste the full content of `model/PCL_semantic_model.tmdl` -> **Apply**. This creates 17 tables, 174 columns, 8 relationships, 194 measures.
4. *Transform data > Edit parameters*: set **DataFolder** to that folder's full path (trailing backslash) -> **Refresh**.
   Numbers are parsed with culture `en-US` inside every query, so a French/German Windows locale does not break decimals.
5. Build the 6 pages from section 5 (visual by visual). Open page 6 first: the **QA Summary** card must read `ALL 388 QA CHECKS PASS`.
6. Refresh after re-running `sql/13_powerbi_export.sql` (the export) whenever the SQL model changes.

Fallback if TMDL view is unavailable: *Get data > Text/CSV* for each file in `data/` (set locale English (United States)), create the relationships in section 3, then paste measures from `model/PCL_measures.dax` (table and name are given for each).

---

## 2. Data model (star schema, half-year grain)

```
                           DimSource ----< FactLineage >---- DimPeriod ----< FactHalfYear      (1 row / half-year)
                                                                  |     ----< FactBridgeYoY >---- DimBridgeStep
                                                                  |     ----< FactSensitivity
                                                                  |     ----< FactDeliveryMix
                                                                  |     ----< Annotation
 Disconnected (by design):  DimLevel | DimLevelStep | DimRevenueStep | FactGuidance | FactGuidanceAuto | GuidanceInputs | Assumption | RefSQL
```

| Table | Grain / rows | Built from (SQL, no recalculation) | Purpose |
|---|---|---|---|
| **DimPeriod** | half-year / 7 | `core.dim_period` + `mart.v_panel_hy` | Period slicer; `prior_same_half_code` drives all YoY; `is_latest`; count of DERIVED inputs per period |
| **FactHalfYear** | half-year / 7 | `v_panel_hy` + `v_ebit_adjusted` (added-back items with A-01/A-02 applied, rounding band) + `v_rd_capitalisation` (cap-rate effect) + `v_da_clean` (impairment used) + `v_asp_volume` (volume/ASP effects) + `v_cash_crosscheck` (cash notes) | All base values; measures compute levels, margins, YoY, ratios |
| **FactBridgeYoY** | half-year x step / 40 | `v_ebit_bridge_yoy` unpivoted | YoY EBIT bridge (EUR and pp) |
| **DimBridgeStep** | 8 | labels | Step name, order, group, sign convention |
| **FactSensitivity** | 2 | `v_ebit_bridge_yoy`, `v_ebit_adjusted` (A-04 alternatives) | Sensitivity values - never headline |
| **FactDeliveryMix** | half-year x member / 77 | `v_delivery_mix` (+ sort order from `dim_model`/`dim_region`) | Mix by model line (Macan total) and region |
| **FactGuidance** | scenario / 27 | `v_guidance_2026` | Group scenario combinations (NOT forecasts) |
| **FactGuidanceAuto** | scenario / 9 | `v_guidance_2026_auto` | Automotive scenario combinations |
| **GuidanceInputs** | 6 | `core.fact_guidance` (mid = (low+high)/2, as in SQL) | Guidance as published |
| **DimLevel** | 4 | labels | L0/L1/L2 headline, L3 sensitivity (`is_headline` = FALSE) |
| **DimLevelStep / DimRevenueStep** | 3 / 3 | labels | Categories for the L0->L1->L2 and revenue waterfalls |
| **FactLineage** | value / 236 | `core.fact_financial` (analysis window) | Every value with FACT/DERIVED, source, page |
| **DimSource / Assumption / Annotation** | 27 / 9 / 7 | `audit.dim_source`, `mart.assumption`, `mart.annotation` | Lineage and context |
| **RefSQL** | 388 | every checked column of 10 mart views (incl. 77 delivery-mix shares), unpivoted, with tolerance = view rounding | QA page reference |

**Why disconnected tables?** Guidance scenarios have no period (they describe H2 2026 hypothetically) - linking them to DimPeriod would let a period slicer silently filter them. Step/level tables only supply categories; values come from measures, so the same logic serves every period. RefSQL is evaluated row by row with `TREATAS`, so it must not filter the model.

## 3. Relationships

| From (many) | To (one) | Cardinality | Filter direction |
|---|---|---|---|
| FactHalfYear[period_code] | DimPeriod[period_code] | many-to-one (1:1 in data) | single |
| FactBridgeYoY[period_code] | DimPeriod[period_code] | many-to-one | single |
| FactBridgeYoY[step_id] | DimBridgeStep[step_id] | many-to-one | single |
| FactSensitivity[period_code] | DimPeriod[period_code] | many-to-one | single |
| FactDeliveryMix[period_code] | DimPeriod[period_code] | many-to-one | single |
| FactLineage[period_code] | DimPeriod[period_code] | many-to-one | single |
| FactLineage[source_id] | DimSource[source_id] | many-to-one ('SQL derived' rows map to blank) | single |
| Annotation[period_code] | DimPeriod[period_code] | many-to-one | single |

Sort-by columns: `period_label` by `sort_key`; step/level names by their order; guidance `case_rev / case_ros / case_ex` by `sort_rev / sort_ros / sort_ex` (low, mid, high). Numeric fact columns are hidden - use measures.

## 4. Measures (194, 13 display folders)

Full text: `model/PCL_measures.dax` (identical to the TMDL). Summary:

| Folder | Key measures | Logic (same as SQL/Excel) |
|---|---|---|
| 01 Revenue & EBIT levels | `Revenue`, `EBIT L0 Reported`, `EBIT L1`, `EBIT L2`, `Margin L0/L1/L2`, `Exceptional Items Added Back`, `Adjustment Rounding Band`, `Level Bridge Value` | L1 = L0 + X01 (net); L2 = L1 + X03; margin = level / G01 |
| 02 L3 supplementary sensitivity | `EBIT L3 Hybrid Sensitivity`, `Margin L3 Hybrid Sensitivity`, `... alt A-04`, `L3 Warning` | L3 = L1 + (A12 - X05) - A06 |
| 03 Prior year (same half) | 19 `... PY` measures, `YoY ...` (EUR, pp, %) | `CALCULATE(<m>, REMOVEFILTERS(DimPeriod), DimPeriod[period_code] = prior_same_half_code)`; BLANK where no prior half in window |
| 04 EBIT bridge (SQL) | `Bridge EUR m`, `Bridge pp`, one measure per step, `One-offs Share of EBIT Change`, `Bridge Closure Check`, `Bridge Residual alt A-04` | Values from `v_ebit_bridge_yoy`; closure checked against DAX `YoY EBIT L0` |
| 05 R&D & D&A | `RD Total Costs`, `RD PL Charge`, `Cap Rate Calc`, `Net Capitalisation`, `Cap Rate Effect (SQL)`, `Clean DA`, `Impairments in DA`, `Impairment Status` | P&L charge = A08 + A09; cap rate = A06 / A05 |
| 06 Commercial | `Vehicle Sales`, `Retail Deliveries`, `ASP (EUR k)`, `Volume Effect (SQL)`, `ASP Effect (SQL)`, `Revenue Bridge Value`, `Mix Share`, `Mix Share Change (pp)` | ASP = A01 x 1000 / O04 |
| 07 Cash | `Auto NCF`, `NCF Margin`, `EBITDA Margin`, `CFO to EBITDA`, `Simple Cash Proxy`, `NCF minus Proxy`, `Net Liquidity (period end)`, `Cash Notes` | Proxy = A03 - A10 - A06 |
| 08 Latest half-year (fixed) | `Latest Margin L0/L1/L2`, `Latest Auto NCF`, `Prior H2 Margin L0/L1` | Comparators for guidance, independent of the page slicer |
| 09 Guidance scenarios (NOT forecasts) | `Scen H2 Margin L0/L1/L2` (selected), `Scen Min/Mid/Max Margin ...`, `Scen H2 L1 vs Latest H1 (pp)`, `Scen Auto ...`, `Scenario Disclaimer` | Values from `v_guidance_2026(_auto)`; selected only when exactly one combination is in context |
| 10 Recovery signals | 7 text measures + 2 colour measures | Sign-based comparisons only (no new thresholds) |
| 11 QA recompute | DAX re-derivations of bridge steps, cap-rate effect, volume/ASP effects, guidance margins, identity checks | Independent recomputation from base values |
| 12 QA vs SQL | `QA DAX Value`, `QA SQL Value`, `QA Abs Difference`, `QA Status`, `QA Fail Count`, `QA Summary` | Row-wise `TREATAS` into DimPeriod / FactGuidance |
| 13 Level-driven | `Margin by Level`, `EBIT by Level`, `Scen Min/Mid/Max by Level`, `Latest Margin by Level` | `SWITCH` on DimLevel so one legend drives colour and labels |

Example (prior-year pattern and the level switch):

```dax
FactHalfYear[Margin L1 PY] =
VAR _p = [Prior Period Code]
RETURN
    IF ( NOT ISBLANK ( _p ), CALCULATE ( [Margin L1], REMOVEFILTERS ( DimPeriod ), DimPeriod[period_code] = _p ) )

FactHalfYear[Margin by Level] =
SWITCH ( SELECTEDVALUE ( DimLevel[level_id] ),
    "L0", [Margin L0], "L1", [Margin L1], "L2", [Margin L2], "L3", [Margin L3 Hybrid Sensitivity] )
```

---

## 5. Visual conventions (apply on every page)

| Element | Rule |
|---|---|
| **Levels** | L0 reported = blue `#2a78d6`; L1 adjusted headline = orange `#eb6834`; L2 adjusted headline = aqua `#1baf7a` (palette validated for colour-vision deficiency; aqua is below 3:1 contrast, so every line/bar carries a data label). Same colour for the same level on every page. |
| **L3** | Grey `#8a8983`, dashed line, hatched background, title prefix **"SUPPLEMENTARY HYBRID SENSITIVITY"**, `[L3 Warning]` text under the visual. Appears **only** on page 3. Headline visuals carry the visual-level filter `DimLevel[is_headline] = TRUE`. |
| **Scenarios** | Grey hatched bands, never a level colour; banner `[Scenario Disclaimer]` above the section; words "forecast", "expected", "likely", "probability" never used; "mid" is always written as "all midpoints". |
| **Sensitivity / assumption values** | Hatched card, tag "SENSITIVITY", assumption ID in the subtitle (A-04 ...). |
| **Waterfalls** | Increase = blue, decrease = red `#e34948`, totals = dark grey `#52514e`. |
| **Labels** | Each card shows FACT / DERIVED / Reported / Adjusted headline tag. Tooltips on every visual: period, value, `Impairment Status` or `Cash Notes` where relevant, and `DimPeriod[period_basis]` (H2 = FY - H1). |
| **Slicers** | Page 1-5: single-select **Period** (`DimPeriod[period_label]`, default = latest). Scenario slicers only on page 5. No dual axes anywhere - different units get separate visuals. |

---

## 6. Page-by-page specification

Layout grid 1280 x 720. Every page: title (top-left), one-line business question (subtitle), Period slicer (top-right), footer "Source: SQL mart porsche_lens (Phases 3-4), Excel PCL_05 (Phase 5). EUR m. L0 reported / L1, L2 adjusted headline / L3 sensitivity / scenarios not forecasts." Previews: `previews/page1..6*.png` (rendered from the reconciled values; layout mock-ups, not Power BI screenshots).

### Page 1 - Executive Overview
**Business question:** Is the 2026 margin recovery real, i.e. does it survive once the disclosed one-offs are removed?

| # | Visual | Fields / measures | Title | Subtitle | Business interpretation (H1 2026) |
|---|---|---|---|---|---|
| 1.1 | 7 KPI cards (new Card visual, reference label = YoY) | `Revenue` + `YoY Revenue %`; `EBIT L0 Reported` + `YoY EBIT L0`; `Margin L0` + `YoY Margin L0 (pp)`; `Margin L1` + `YoY Margin L1 (pp)`; `Margin L2` + `YoY Margin L2 (pp)`; `ASP (EUR k)` + `YoY ASP %`; `Vehicle Sales` + `YoY Vehicle Sales %` | (card labels) | tag Reported / Adjusted headline / FACT / DERIVED | Revenue 17,229 (-5.1%); L0 EBIT 1,348 (+341); L0 margin 7.8% (+2.28 pp) **but** L1 8.4% (-0.99 pp) and L2 10.7% (-0.88 pp); ASP 125.8k (+5.3%); vehicle sales 120,508 (-10.8%). |
| 1.2 | Line chart | X `DimPeriod[period_label]`, Y `Margin by Level`, Legend `DimLevel[level_name]`; filter `is_headline = TRUE`; data labels on last point | Group margin by half-year: reported vs headline adjusted levels | Reported recovery comes from smaller one-offs; the adjusted lines keep falling | L0 swings with one-offs (5.5% -> -3.3% -> 7.8%); L1 falls 9.4% -> 10.0% -> 8.4%; L2 11.6% -> 11.6% -> 10.7%. The recovery exists only at L0. |
| 1.3 | Multi-row card / table of text measures, icon by colour measure | `Signal Underlying Margin`, `Signal Recovery Source`, `Signal Other Drivers`, `Signal Value over Volume`, `Signal Capitalisation`, `Signal Cash`, `Signal Guidance Gap` | Recovery signals | Sign-based measures for the selected half-year | 5 of 7 signals point against sustainability (L1 down; one-offs 176% of the gain; residual -140; ASP covers only 44% of volume; capitalisation a 21m headwind); cash is positive; guidance requires H2 L1 above H1. |

**What this page cannot tell:** why the residual is negative (price, mix, costs are not separable in published data); anything beyond H1 2026.

### Page 2 - EBIT Recovery
**Business question:** What moved reported EBIT, and what is left after the disclosed one-offs?

| # | Visual | Fields / measures | Title | Subtitle | Interpretation (H1 2026) |
|---|---|---|---|---|---|
| 2.1 | Waterfall | Category `DimLevelStep[lstep_name]`, Y `Level Bridge Value`; total label "L2 EBIT" | {period}: L0 -> L1 -> L2 (EUR m) | Disclosed items added back; L1 = headline KPI | 1,348 + 100 (realignment & battery, net) + 400 (US tariffs) = 1,848. Rounding band +/-100 (`Adjustment Rounding Band`) in tooltip. |
| 2.2 | Waterfall | Category `DimBridgeStep[step_name]`, Y `Bridge EUR m`; filter step_id <> S7_DENOM; S0 bar formatted as total | Reported EBIT bridge, same half prior year -> selected half (EUR m) | Blue helps, red hurts. Residual = not separated - not "operating performance" | 1,007 +600 exceptional +0 tariffs -88 capitalised dev. costs -37 clean D&A +6 FS -140 residual = 1,348. |
| 2.3 | 3 cards | `One-offs Share of EBIT Change`; `YoY EBIT L1` (+ `YoY Margin L1 (pp)`); `Bridge Residual alt A-04` (hatched, SENSITIVITY) | - | - | 176%: the entire reported gain, and more, comes from lower one-offs. L1 EBIT -259. Residual would be -79 if the 61m impairments were not inside D&A (A-04) - still negative. |
| 2.4 | Clustered bar | Axis `DimBridgeStep[step_name]`, value `Bridge pp`; filter step_id <> S0_START | Margin-point bridge: reported margin {`YoY Margin L0 (pp)`} pp | Components sum exactly to the change in L0 margin | +3.48 exceptional, +0.30 revenue denominator (smaller revenue base), -0.51 cap. dev., -0.21 D&A, +0.04 FS, -0.81 residual = +2.28 pp. |
| 2.5 | Clustered column | X period, Y `EBIT by Level`, legend DimLevel; filter `is_headline = TRUE` | EBIT by level and half-year (EUR m) | Gap between L0 and L1/L2 = size of disclosed one-offs | One-offs were 0 until 2024; 700 / 2,400 / 100 in H1 25 / H2 25 / H1 26 (plus tariffs 400 / 300 / 400). |

**Cannot tell:** the split of the residual; whether 2026 one-offs are complete (FY guidance EUR 0.8-0.9bn implies 0.7-0.8bn still to come in H2 - page 5).

### Page 3 - R&D & D&A
**Business question:** Is the margin being flattered by accounting (capitalisation, D&A, impairments)?

| # | Visual | Fields / measures | Title | Subtitle | Interpretation (H1 2026) |
|---|---|---|---|---|---|
| 3.1 | 6 cards | `RD Total Costs`; `Capitalised Dev Costs` + `Cap Rate Calc` + `YoY Cap Rate (pp)`; `RD PL Charge`; `Net Capitalisation`; `Cap Rate Effect (SQL)`; `Clean DA` + `Impairments in DA` + `Impairment Status` | - | - | Total R&D 1,116; capitalised 487 (43.6%, -1.9 pp); P&L charge 1,334; net capitalisation -218; cap-rate effect +20.7 (extra charge); clean D&A 1,498 (61 impairments removed, A-04). |
| 3.2 | Clustered column | X period, Y `RD Total Costs`, `RD PL Charge` | R&D costs vs R&D charged to the P&L (EUR m) | Charge above costs = amortisation of past capitalisation exceeds new capitalisation | Since H2 2024 the P&L charge exceeds total R&D costs: accounting is now a **headwind**, not a support. |
| 3.3 | Line chart + data labels | X period, Y `Cap Rate Calc`; tooltip `Cap Rate Published` | Capitalisation rate (capitalised / total R&D costs) | Falling rate = more R&D hits the P&L immediately | 77.7% (H1 23) -> 45.5% (H1 25) -> 43.6% (H1 26). |
| 3.4 | Stacked column | X period, Y `Clean DA`, `Impairments in DA` | Automotive D&A: clean vs impairments (EUR m) | Impairments already sit inside the exceptional items - removed to avoid double counting | H2 2025 impairments 905 (FY - H1, split undisclosed); H1 2026 61. |
| 3.5 | Line chart, hatched background | X period, Y `Margin by Level`, legend DimLevel filtered to L1 and L3; L3 dashed grey; text box `[L3 Warning]`; card `EBIT L3 Hybrid Sensitivity alt A-04` | SUPPLEMENTARY HYBRID SENSITIVITY: L3 vs L1 margin | L3 = L1 + clean auto D&A - capitalised dev. costs; mixes group and automotive items. Not underlying profitability | L3 14.3% vs L1 8.4%. Shown only to size the non-cash wedge; it is never compared with guidance or used as a KPI. |

**Cannot tell:** the cash R&D spend (Porsche reports an accounting total); the cap-rate counterfactual holds amortisation fixed (illustrative).

### Page 4 - Commercial Drivers
**Business question:** Does a higher price per car compensate for fewer cars?

| # | Visual | Fields / measures | Title | Subtitle | Interpretation (H1 2026) |
|---|---|---|---|---|---|
| 4.1 | 6 cards | `Vehicle Sales` + `YoY Vehicle Sales %`; `Retail Deliveries`; `ASP (EUR k)` + `YoY ASP %`; `Volume Effect (SQL)`; `ASP Effect (SQL)`; `Auto Revenue` + `YoY Auto Revenue` | - | - | 120,508 units (-10.8%); 122,306 deliveries; ASP 125.8k (+5.3%); volume -1,748; ASP +768; automotive revenue 15,158 (-980). |
| 4.2 | Waterfall | Category `DimRevenueStep[rstep_name]`, Y `Revenue Bridge Value` | Automotive revenue bridge (EUR m) | Volume effect + ASP effect = revenue change | 16,138 -1,748 +768 = 15,158: ASP recovers 44% of the volume loss. |
| 4.3 | Column chart | X period, Y `Vehicle Sales` | Vehicle sales (wholesale units) | - | 170.8k (H1 23) -> 120.5k (H1 26). |
| 4.4 | Line chart | X period, Y `ASP (EUR k)`; tooltip `ASP Published (EUR k)` | ASP (EUR k per vehicle sold) | Separate chart - no dual axis | 110.6 -> 125.8: value-over-volume is real but not large enough. ASP effect is a residual of price, model/derivative mix, options, FX and non-vehicle revenue. |
| 4.5 | Clustered bar (2 visuals) | Axis `FactDeliveryMix[member_name]`, values `Mix Share` (current) and `Mix Share PY`; data label `Mix Share Change (pp)`; visual filter `dimension = model` / `region` | Delivery mix by model / by region | Share of retail deliveries | Model: 911 25.0% (+7.5 pp), Cayenne 31.2% (+2.6), Macan 28.9% (-2.0), Panamera 7.6% (-2.6), 718 2.3% (-4.9, production ended), Taycan 5.1% (-0.6). Region: China 11.9% (-2.7 pp); North America 30.8% (+1.1). |

**Cannot tell:** model-level revenue or margin (not published); retail mix is not the wholesale mix that drives revenue.

### Page 5 - Cash & Guidance
**Business question:** Does cash confirm the profit picture - and what must H2 2026 deliver to meet guidance?

| # | Visual | Fields / measures | Title | Subtitle | Interpretation |
|---|---|---|---|---|---|
| 5.1 | 4 cards | `Auto NCF` + `NCF Margin`; `YoY NCF Margin (pp)`; `CFO to EBITDA`; `Simple Cash Proxy` (+ `NCF minus Proxy` tooltip) | - | - | NCF 1,020 (6.7%, +4.3 pp vs 2.4%); CFO/EBITDA 0.88; proxy 1,374; NCF - proxy -354 (working capital, tax, provisions, other). |
| 5.2 | Line chart | X period, Y `EBITDA Margin`, `NCF Margin` (same unit, one axis) | Profit vs cash: EBITDA margin and NCF margin | Tooltip `Cash Notes` | H1 2026 NCF improved despite ~0.4bn cash-outs (Audi licence tranche, realignment) and ~0.3bn pension funding (S016 slide 13). |
| 5.3 | Banner (text box, hatched) | `[Scenario Disclaimer]` | SCENARIO COMBINATIONS - NOT FORECASTS - NO PROBABILITIES | - | Mandatory above 5.4-5.7. |
| 5.4 | Clustered bar with error bars | Axis `DimLevel[level_name]` (filter L0-L2), bar = `Scen Mid by Level` (hatched grey), error bars lower `Scen Min by Level` / upper `Scen Max by Level`, marker `Latest Margin by Level` | H2 2026 margin implied by FY2026 guidance (27 combinations) | Band = min-max across combinations; bar = all midpoints; marker = H1 2026 actual | L0 3.25-7.20% (all midpoints 5.25%) vs 7.82% H1; **L1 7.10-11.69% (9.36%) vs 8.41% H1**; L2 9.23-13.94% (11.54%) vs 10.73%. |
| 5.5 | Slicers (tile, single-select) + card | `FactGuidance[case_rev]`, `[case_ros]`, `[case_ex]`; card `Scen Selected Label`, `Scen H2 Margin L1`, `Scen H2 L1 vs Latest H1 (pp)`, `Scen H2 Revenue`, `Scen H2 EBIT L0` | Explore one combination | Each slicer = one end of a published guidance range | Lets management see what each guidance end requires; defaults all "mid". |
| 5.6 | Matrix | Rows `case_rev`, columns `case_ros`, values `Scen H2 Margin L1`; responds only to the `case_ex` slicer (edit interactions: rev/ros slicers = none) | H2 L1 margin: revenue end x RoS end | Extraordinary end from slicer; arithmetic grid | RoS end dominates: at mid extraordinary, low RoS -> ~7.4%, high RoS -> ~11.3%. |
| 5.7 | Clustered bar with error bars (2 rows) | `Scen Auto Min/Mid/Max EBITDA/NCF Margin`, markers `Latest EBITDA Margin`, `Latest NCF Margin`; slicer `FactGuidanceAuto[case_m]` (revenue end follows 5.5 via TREATAS) | Automotive H2 2026 implied (9 combinations) | Uses A-05 (H1 automotive share 88.0%) | Implied H2 automotive EBITDA margin 11.8-15.8% vs 18.3% in H1; NCF margin -0.6-3.4% vs 6.7% in H1 - the guidance itself implies a much weaker H2 cash margin. |
| 5.8 | Table | `GuidanceInputs[metric]`, `low_value`, `mid_value`, `high_value`, `unit_std`, `source_id`, `source_ref` | Guidance inputs as published | FACT, S016 slide 14 / S027 | - |

**Cannot tell:** which end of each range is more likely; H2 one-offs beyond the net guidance (A-06); H2 tariffs are assumed equal to H1 (A-07).

### Page 6 - QA & Lineage (appendix)
**Business question:** Can management trust these numbers?

| # | Visual | Fields / measures | Purpose |
|---|---|---|---|
| 6.1 | Card (green / red by status) | `QA Summary` | Must read `ALL 388 QA CHECKS PASS (Power BI vs SQL mart)` |
| 6.2 | Table | `RefSQL[metric_key]`, `[period_code]`, `[scenario_id]`, `[sql_view]`, `QA DAX Value`, `QA SQL Value`, `QA Abs Difference`, `RefSQL[tolerance]`, `QA Status`; conditional format on status | Row-level reconciliation of Power BI measures (recomputed from base values) to the SQL views |
| 6.3 | Cards | `QA Identity Checks Max`, `Bridge pp Closure Check`, `NCF Identity Check`, `Volume ASP Closure Check` (period slicer) | Internal identities |
| 6.4 | Table | `FactLineage` (period, var_id, var_name, value, value_label, source_id, source_ref, rounding) with `DimSource[document_title]` | Lineage of every value |
| 6.5 | Tables | `Assumption`, `Annotation` | Assumptions A-01..A-09 and dated context |

---

## 7. QA and reconciliation

### 7.1 Inside Power BI (page 6)
`QA DAX Value` recomputes each RefSQL row with the dashboard's own measures from base values - not by reading the SQL result - e.g. margins from EBIT / revenue, the bridge residual from DAX-derived components, the capitalisation-rate effect and volume/ASP effects from their formulas, and all 27 guidance margins from the guidance inputs and H1 2026 actuals. `QA Status` = PASS if |DAX - SQL| <= the SQL view's rounding tolerance. 388 rows across 10 views, including all 77 delivery-mix shares.

### 7.2 Offline reconciliation (`qa/reconcile.py`, report `qa/PCL_06_reconciliation_report.txt`, final run)

| Check group | What is compared | Compared | Failed | Max diff |
|---|---|---|---|---|
| R1 QA page vs RefSQL | replica of `QA DAX Value` for all 388 RefSQL rows | 388 | 0 | 0.049 (within 0.05 rounding tolerance of 0.1-rounded SQL values) |
| R2 replica vs live SQL | the same measures vs the views queried directly from PostgreSQL (independent of the CSV export), incl. every bridge step, all 81 guidance margins, all 77 mix shares | 351 | 0 | 0.049 |
| R3 replica vs Excel PCL_05 | 64 Excel rows x 7 periods (EBIT_Analysis, RD_DA, Commercial, Cash_Crosscheck), guidance summary and all 27 x 3 grid margins, KPI_Overview | 566 | 0 | 0.00047 (Excel unrounded vs SQL 3-dp pp) |
| R4 identities | bridge closure (EUR, pp), volume + ASP = revenue change, revenue waterfall total, L0->L1->L2 waterfall = L2, mix totals, NCF = CFO + CFI, 27 + 9 scenario rows, disclaimer on all 36 rows | 51 | 0 | 0.11 (SQL rounding of NCF components, AF-12) |
| R5 export integrity | 24 base columns x 7 periods of FactHalfYear vs `mart.v_panel_hy` | 168 | 0 | 0 |
| **Total** | | **1,524** | **0** | **PASS** |

**Negative test:** adding EUR 1m to the 2026-H1 reported EBIT in a copy of FactHalfYear produced 214 failures across all five groups - the reconciliation detects a single-value error.

**Finding (Excel presentation, resolved):** in the Excel model, year-on-year cells in the 2023-H1/H2 columns showed values although no prior-year half exists. Power BI correctly returns BLANK there. In the final workbook these 26 cells (EBIT_Analysis, RD_DA and Commercial) are blank; no result changed, and the workbook still reads ALL 50 CHECKS PASS.

### 7.3 Labelling checks
L3 never appears in a headline visual (DimLevel `is_headline` filter; only visual 3.5 shows it, under the sensitivity title and `[L3 Warning]`). All 36 scenario rows carry "not a forecast, no probability"; the disclaimer banner precedes every scenario visual; no visual or measure uses the words forecast / expected / likely / probability except to negate them.

---

## 8. Dashboard narrative - what management should monitor

**Answer to the core question.** On the published H1 2026 data, the margin recovery is a **reported** recovery, not yet an **underlying** one. The reported margin rose from 5.5% to 7.8% (+2.28 pp), but lower disclosed one-offs (+600m) account for 176% of the +341m EBIT gain. Excluding realignment and battery items, the L1 margin fell from 9.4% to 8.4% (-0.99 pp), and it also fell excluding tariffs (L2: 11.6% -> 10.7%). The remaining EBIT drivers were negative (-140m residual; -79m if assumption A-04 is false). Accounting is not flattering the result: capitalisation fell and amortisation now exceeds new capitalisation (-218m net), a small non-cash headwind. Price and mix helped (+5.3% ASP), but covered only 44% of the volume loss (-10.8% vehicle sales). Cash is the one clearly positive signal (NCF margin 6.7%, +4.3 pp), despite timing outflows.

**What would make it sustainable.** Arithmetically, meeting the FY2026 guidance with all ranges at their midpoints requires an H2 L1 margin of 9.4% - about 1 pp **above** H1 2026 (8.4%), though below H2 2025 (10.0%). The full range of combinations spans 7.1% to 11.7%, so the low end of guidance is compatible with H2 staying near H1 levels. The same guidance implies a much weaker H2 automotive cash margin (-0.6% to 3.4%) than H1's 6.7%.

**Monitor at H2 2026 / FY2026 results (all measures already in the model):**

| # | Watch | Measure(s) | What would confirm a sustainable recovery |
|---|---|---|---|
| 1 | Underlying margin | `Margin L1`, `YoY Margin L1 (pp)` vs `Scen Mid Margin L1` | H2 L1 margin at or above the all-midpoints requirement (9.4%) and an L1 margin that stops falling year on year |
| 2 | Source of reported gains | `One-offs Share of EBIT Change`, `Bridge Exceptional` | Reported EBIT growth no longer explained mainly by smaller one-offs |
| 3 | Other EBIT drivers | `Bridge Residual`, `Signal Other Drivers` | Residual turns non-negative |
| 4 | Value over volume | `ASP Effect (SQL)` vs `Volume Effect (SQL)`, `Mix Share` (911, Cayenne vs 718, Macan, China) | ASP effect covering a larger share of volume losses, or volume stabilising |
| 5 | Accounting quality | `Cap Rate Calc`, `Net Capitalisation`, `Cap Rate Effect (SQL)` | Visibility on how long amortisation of past capitalisation keeps exceeding new capitalisation |
| 6 | Cash conversion | `NCF Margin`, `CFO to EBITDA`, `NCF minus Proxy` vs `Scen Auto Mid NCF Margin` | Whether H2 cash follows the weaker path the guidance implies |
| 7 | One-offs still to come | `Scen H2 EBIT L1` vs `Scen H2 EBIT L0`, GuidanceInputs GD_EXTRA | H2 extraordinary expenses within the net EUR 0.8-0.9bn guidance (A-06) |
| 8 | Data trust | `QA Summary` | ALL 388 QA CHECKS PASS after every refresh |

---

## 9. Limitations
Seven half-year observations; H2 values are FY - H1 (DERIVED). Exceptional items are management-defined and rounded to EUR 0.1bn (+/-50m, +/-100m for derived H2). The residual is not decomposable with published data. Guidance scenarios combine range ends independently (A-08) - the grid is arithmetic, not a distribution. L3 mixes group and automotive items. Retail delivery mix is not the wholesale mix that drives revenue.

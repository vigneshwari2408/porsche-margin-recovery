# Porsche 2026 Margin Recovery — Project Report
**Company Lens series · Vigneshwari Nalla · Analysis window: H1 2023 – H1 2026 (half-years)**

> Based exclusively on Porsche AG's public investor-relations disclosures and one public earnings-call transcript. Independent, educational analysis; not affiliated with Porsche AG; not investment advice. Figures are € million unless stated. H2 values are derived as FY − H1.

---

## 1. Executive summary
Porsche's reported return on sales rose from **5.5% in H1 2025 to 7.8% in H1 2026**. This report asks whether that recovery is underlying, or mainly the result of smaller one-off charges, and what Porsche's FY2026 guidance implies for H2 2026.

**Findings**

1. **The recovery is reported, not yet underlying.**
   - Lower disclosed one-offs contributed **+€600m**, which is **176% of the +€341m increase in reported EBIT**.
   - Excluding realignment and battery items, the **L1 margin fell by 0.99 pp to 8.4%**.
   - Also excluding US tariffs, the **L2 margin fell by 0.88 pp to 10.7%**.
2. **The other EBIT drivers were negative.** The residual in the year-on-year bridge is **−€140m**. It is **−€79m** if the H1 2026 impairments are not inside D&A (assumption A-04), so still negative.
3. **Price only partly offsets volume.**
   - Vehicle sales fell by 10.8%, while ASP rose by 5.3% to €125.8k.
   - The ASP effect (+€768m) covered **44%** of the volume effect (−€1,748m).
4. **Accounting is not flattering the margin.**
   - The capitalisation rate fell from 45.5% to 43.6%, and capitalised development costs fell by €88m.
   - The R&D charge in the P&L (€1,334m) exceeds total R&D costs (€1,116m).
5. **Cash improved.** The automotive net cash-flow margin rose from **2.4% to 6.7%**, despite about €0.4bn of cash-outs and about €0.3bn of pension funding (Porsche disclosure).
6. **What guidance implies (scenarios, not forecasts).**
   - Combining the FY2026 guidance midpoints implies an **H2 L1 margin of 9.36%**, about +0.95 pp above H1 2026.
   - Across all 27 combinations the implied H2 L1 margin ranges from **7.10% to 11.69%**.
   - The implied **H2 automotive NCF margin is −0.62% to 3.41%**, versus 6.73% in H1.

All results are reconciled across SQL, Excel and Power BI: **1,524 comparisons with 0 failures**, and **388/388 QA checks passing** in the dashboard.

## 2. Business context
- **2025 was dominated by exceptional items.** Porsche's 2025 results carried large one-off charges: about €3.9bn of extraordinary expenses in FY2025, covering realignment and product strategy (2.4), battery activities (0.7) and US tariffs (0.7) (€bn; S011 slide 6). Reported H2 2025 EBIT was negative (−3.3% margin).
- **In H1 2026 those charges dropped sharply.** The net realignment burden was about €0.1bn, being about €0.4bn of charges less about €0.3bn of provision releases (S016).
- **The reported margin therefore rebounded.** The question is whether the business underneath improved.

## 3. Problem statement
> *"Porsche's reported margin rose from 5.5% to 7.8% in H1 2026. After removing the exceptional items Porsche itself discloses, and isolating non-cash effects from R&D capitalisation and depreciation, is underlying profitability actually improving, and what does H2 2026 guidance imply?"*

## 4. Data and methodology
### 4.1 Sources
- **Porsche AG documents (26, tier 1):**
  - half-year financial reports (H1 2023–H1 2026);
  - annual and sustainability reports (FY2023–FY2025, incl. online versions);
  - press and analyst call presentations;
  - press releases;
  - official fact-sheet XLSX files (H1 2023–H1 2026).
- **One tier-3 source:** a public H1 2026 earnings-call transcript, used only for the CFO's statement on net extraordinary expenses (assumption A-06).
- **Register:** every source is logged in the source register (S001–S027) with URL, document type and period.

### 4.2 Data capture
- **Fact sheets:** Porsche's fact-sheet Excel files were extracted with a script, with QC against the file layout.
- **Manual inputs:** values available only in PDFs (segment tables, R&D, D&A, one-offs, ASP) were recorded manually. There are 155 input rows: 151 values and 4 documented gaps, which were left blank rather than estimated.
- **Metadata:** each value carries source ID, page, period, unit, rounding and its FACT/DERIVED label, plus a double-check status.
- **Traceability:** 481 source-reference rows document where each variable was found.

### 4.3 Half-year derivation
Porsche publishes H1 and FY figures. **H2 = FY − H1** is derived only for additive (flow) variables, and labelled DERIVED. Ratios are never derived this way.

### 4.4 Assumptions
| ID | Statement | Why | Sensitivity |
|---|---|---|---|
| A-01 | No realignment/battery items for 2023-H1 … 2024-H2 (treated as 0) | FY2023/24 EBIT bridges show no extraordinary bracket | If undisclosed one-offs existed, the 2023/24 baseline would be higher and the recovery weaker |
| A-02 | No additional US tariffs before April 2025 | Section 232 auto tariffs effective 3 April 2025; first reported by Porsche in H1 2025 | Low |
| A-03 | Undisclosed impairments inside automotive D&A = 0 (2023-H2, 2024-H2) | H1 notes show nil; FY amounts not verifiable | Would lower clean D&A for those periods |
| A-04 | H1 2026 impairments of €61m (eBike 43 + Cellforce 18) are inside automotive D&A | Published impairments of automotive subsidiaries; line item not confirmed | Alternative shown: residual −€79m instead of −€140m; L3 +€61m |
| A-05 | FY2026 automotive revenue = group revenue guidance × H1 2026 automotive share (88.0%) | Porsche guides automotive margins, not automotive revenue | ±1 pp share moves the implied H2 automotive margins |
| A-06 | FY2026 extraordinary-expense guidance (€0.8–0.9bn) is net, like H1 (~€0.1bn) | CFO statement (S027), consistent with Porsche press release | If gross, implied H2 charges would be lower |
| A-07 | H2 2026 tariffs = H1 2026 (€0.4bn) | No verified primary FY2026 tariff figure | L2 only; €300m instead of €400m lowers the implied H2 L2 margin by ~0.55 pp |
| A-08 | Guidance range ends are combined as independent low/mid/high values | Porsche does not say which ends go together | The range is deliberately wide |
| A-09 | Derived H2 values inherit input rounding (±€100m on H2 one-offs) | H2 = FY − H1, both rounded to €0.1bn | Shown as a rounding band |

## 5. Model architecture
| Layer | Content |
|---|---|
| **Input workbooks** | `PCL_01_Sources.xlsx` (register, definitions, availability, source references, audit findings); `PCL_02_Manual_Inputs.xlsx` (155 inputs, 10 input checks) |
| **SQL (PostgreSQL 16)** | Schemas `stg` → `core` → `mart`, plus `audit`. Core fact table with 701 values across all period types, 236 of them in the half-year window. 11 mart views: panel, adjusted EBIT, clean D&A, R&D capitalisation, ASP/volume, delivery mix, cash cross-check, YoY bridge, guidance grid / summary / automotive. 13 audit findings, 4 documented data gaps. |
| **Excel (PCL_05 FINAL)** | 13 sheets, 2,997 formulas. Data layer (imported from SQL), analysis sheets (EBIT, R&D & D&A, Commercial, Cash, Guidance), `Audit_Checks` (50 checks), `Audit_Register` |
| **Power BI** | 17 tables (star schema on a half-year DimPeriod), 8 many-to-one relationships, 194 DAX measures in 13 folders. Guidance, level and step tables are disconnected so that period filters cannot alter scenarios. RefSQL (388 rows) drives the in-report QA. |

## 6. KPI definitions
| KPI | Definition | Label |
|---|---|---|
| Group revenue | Group sales revenue (G01) | FACT |
| **L0 Reported EBIT** | Group operating profit (G07) | FACT |
| **L1 EBIT** | L0 + strategic realignment incl. battery activities, net (X01) | DERIVED: headline underlying |
| **L2 EBIT** | L1 + US import tariffs (X03) | DERIVED: headline adjusted |
| **L3 hybrid sensitivity** | L1 + clean automotive D&A − automotive capitalised development costs | DERIVED: **sensitivity only, not a KPI** |
| Margin L0 / L1 / L2 | Level ÷ group revenue | DERIVED |
| Clean automotive D&A | Automotive D&A − disclosed impairments (A-03, A-04) | DERIVED |
| R&D P&L charge | Expensed R&D + amortisation of capitalised R&D | DERIVED |
| Capitalisation rate | Capitalised development costs ÷ total automotive R&D costs | DERIVED |
| Net capitalisation | Capitalised − amortised; <0 means the P&L charge exceeds R&D costs | DERIVED |
| Cap-rate effect | Actual R&D P&L charge − charge at the prior-year same-half capitalisation rate (amortisation held fixed; illustrative) | DERIVED |
| ASP | Automotive revenue × 1,000 ÷ vehicle sales (wholesale), € k (Porsche's definition) | DERIVED |
| Volume effect / ASP effect | Δ units × prior ASP / Δ ASP × current units; the two sum to the revenue change | DERIVED |
| NCF margin | Automotive net cash flow ÷ automotive revenue | DERIVED |
| Simple cash proxy | Automotive EBITDA − capex − capitalised development costs | DERIVED |
| Residual / other EBIT drivers | Change in L0 EBIT minus the separated components: price, mix, volume, cost, FX, other. **Not "operating performance".** | DERIVED |

## 7. Analysis by dashboard page
### Page 1: Executive Overview — *Is the recovery real?*
| | H1 2025 | H1 2026 | Change |
|---|---|---|---|
| Revenue | 18,157 | 17,229 | −5.1% |
| L0 EBIT / margin | 1,007 / 5.5% | 1,348 / 7.8% | +341 / +2.28 pp |
| L1 margin | 9.4% | 8.4% | −0.99 pp |
| L2 margin | 11.6% | 10.7% | −0.88 pp |
| ASP | 119.4 | 125.8 | +5.3% |
| Vehicle sales | 135,142 | 120,508 | −10.8% |

- **Margin trend by level:**

  | Half-year | L0 | L1 | L2 |
  |---|---|---|---|
  | H1 2023 | 18.9% | 18.9% | 18.9% |
  | H1 2024 | 15.7% | 15.7% | 15.7% |
  | H1 2025 | 5.5% | 9.4% | 11.6% |
  | H2 2025 | −3.3% | 10.0% | 11.6% |
  | H1 2026 | 7.8% | 8.4% | 10.7% |

  L0, L1 and L2 are identical until 2025, because no one-offs were disclosed before then (A-01, A-02).
- **Recovery signals:** seven rule-based text measures, covering margin direction, source of the recovery, residual sign, price vs volume, capitalisation, cash, and the guidance gap.

### Page 2: EBIT Recovery — *What moved EBIT?*
- **L0 → L2 (H1 2026):** 1,348 + 100 (realignment & battery, net) + 400 (US tariffs) = 1,848.
- **Year-on-year bridge (€m):**

  | Step | €m | Cumulative |
  |---|---|---|
  | H1 2025 reported EBIT | 1,007 | 1,007 |
  | Exceptional items | +600 | 1,607 |
  | US tariffs | 0 | 1,607 |
  | Capitalised development costs | −88 | 1,519 |
  | Clean automotive D&A | −37 | 1,482 |
  | Financial Services | +6 | 1,488 |
  | Residual / other drivers | −140 | **1,348** |
- **Margin-point bridge:**

  | Component | pp |
  |---|---|
  | Revenue denominator | +0.30 |
  | Exceptional items | +3.48 |
  | US tariffs | 0.00 |
  | Capitalised development costs | −0.51 |
  | Clean automotive D&A | −0.21 |
  | Financial Services | +0.04 |
  | Residual / other drivers | −0.81 |
  | **Change in reported margin** | **+2.28** |
- **One-offs share of the EBIT change: 176%.**

### Page 3: R&D & D&A — *Is accounting flattering the margin?*
- **Totals, H1 2026:**
  - Total R&D costs €1,116m.
  - Capitalised €487m.
  - R&D P&L charge €1,334m.
  - Net capitalisation −€218m.
- **Capitalisation rate:** 77.7% (H1 2023) → 45.5% (H1 2025) → 43.6% (H1 2026). The cap-rate effect is +€20.7m, i.e. an extra charge.
- **The P&L charge has exceeded total R&D costs since H2 2024.** Amortisation of earlier capitalised development now outweighs new capitalisation.
- **Clean automotive D&A:** €1,498m, which is D&A of €1,559m less €61m impairments (A-04).
- **L3 hybrid sensitivity:** 14.3%, versus L1 at 8.4%. It is shown only to size the non-cash wedge, and is never compared with guidance.

### Page 4: Commercial Drivers — *Price vs volume*
- **Revenue bridge (€m):** automotive revenue 16,138 → volume −1,748 → ASP +768 → 15,158.
- **Trends:** ASP rose from 110.6 (H1 2023) to 125.8 (H1 2026); vehicle sales fell from 170,802 to 120,508.
- **Delivery mix, H1 2026 (H1 2025), share of retail deliveries:**
  - By model: Cayenne 31.2% (28.6), Macan 28.9% (30.9), 911 25.0% (17.5), Panamera 7.6% (10.2), Taycan 5.1% (5.7), 718 2.3% (7.2).
  - By region: North America 30.8% (29.8), Europe excl. Germany 24.8% (24.2), Overseas & Emerging Markets 20.3% (20.6), Germany 12.2% (10.9), China 11.9% (14.6).

### Page 5: Cash & Guidance — *Does cash confirm it, and what must H2 deliver?*
- **Cash, H1 2026:**
  - Automotive NCF €1,020m; NCF margin 6.7% (+4.3 pp).
  - CFO/EBITDA 0.88; automotive EBITDA margin 18.3%.
  - Simple cash proxy €1,374m.
- **Guidance and scenarios:** see section 9.

### Page 6: QA & Lineage — *Can we trust it?*
- **QA summary card:** ALL 388 QA CHECKS PASS.
- **Identity checks:** bridge closure, NCF = CFO + CFI, volume + ASP = revenue change, mix totals.
- **Lineage:** every value with its FACT/DERIVED label, source, page and rounding; plus the assumption and annotation tables.

## 8. Findings
1. **The margin recovery is driven by lower one-offs.** The underlying L1 and L2 margins are still below the same half of the prior year.
2. **Other EBIT drivers are negative (−€140m).** Published data cannot split this residual into price, mix and cost.
3. **The mix shift towards the 911 and Cayenne, and a higher ASP, only partially offset lower volume.**
4. **There is no accounting tailwind.** The amortisation overhang from past capitalisation raises the P&L charge.
5. **Cash conversion improved in H1 2026.** But the guidance arithmetic implies a much weaker H2 cash margin.
6. **Guidance at its midpoints requires H2 underlying improvement** (L1 about 9.4% vs 8.4% in H1).

## 9. Scenario methodology
- **Inputs:** Porsche's FY2026 guidance (S016 slide 14):
  - revenue €35–36bn;
  - return on sales 5.5–7.5%;
  - automotive EBITDA margin 15–17%;
  - automotive NCF margin 3–5%;
  - BEV share 24–26%;
  - extraordinary expenses (net) €0.8–0.9bn (S027, A-06).
- **Grid:** each range is taken at its low, mid and high end, and the ends are combined independently (A-08). That gives 27 group combinations (revenue × RoS × extraordinary expenses) and 9 automotive combinations (revenue × margin).
- **Arithmetic:**
  - H2 implied = FY implied − H1 2026 actual, with FY EBIT = revenue × RoS.
  - L1 adds back the implied H2 extraordinary expenses (FY guidance − H1 actual).
  - L2 also adds back H2 tariffs (A-07).
  - The automotive combinations use A-05.

| Implied H2 2026 | Min | All midpoints | Max | H1 2026 | H2 2025 |
|---|---|---|---|---|---|
| L0 margin | 3.25% | 5.25% | 7.20% | 7.82% | −3.28% |
| L1 margin | 7.10% | 9.36% | 11.69% | 8.41% | 9.97% |
| L2 margin | 9.23% | 11.54% | 13.94% | 10.73% | — |
| Automotive EBITDA margin | 11.84% | 13.87% | 15.85% | 18.25% | — |
| Automotive NCF margin | −0.62% | 1.42% | 3.41% | 6.73% | — |

With all midpoints, H2 2026 implies revenue of €18,271m and reported EBIT of €959m.

> **These are arithmetic scenario combinations, not forecasts.** No probabilities are attached, "all midpoints" is not a most-likely case, and the full min–max range is intentionally wide, because extreme corners are included.

## 10. QA and reconciliation
| Control | Scope | Result |
|---|---|---|
| Source verification | Values checked against documents or fact sheets; 4 gaps documented | 151 values verified |
| SQL data-quality checks | Completeness, identities, H2 derivation, source coverage | 305 PASS, 28 INFO, 0 FAIL |
| SQL model-quality checks | View logic, bridge closure, scenario grid | 118 PASS, 0 FAIL |
| Excel `Audit_Checks` | 50 formula checks: imports, Excel vs SQL, identities, Porsche reconciliations, labelling, 8 anchor values | 50/50 PASS |
| Excel value verification | 553 displayed values vs the SQL exports | 0 failures |
| Power BI QA page | 388 checks: each measure recomputed from base values vs the SQL reference, incl. 77 delivery-mix shares | 388/388 PASS |
| Cross-tool reconciliation | 1,524 comparisons: QA reference 388 · live SQL 351 · Excel 566 · identities 51 · export integrity 168 | 0 failures |

**Defects found and fixed during review:**
- **Excel lookup portability:** one lookup formula behaved differently in another spreadsheet engine. It was replaced with two-key SUMIFS lookups and scalar audit formulas.
- **Delivery-mix DAX error:** a filter-context mistake divided each share by all periods instead of one. It was fixed, and 77 mix-share checks were added to the QA page so the same class of error is now caught automatically.
- **Excel year-on-year cells:** 26 cells in the 2023 columns, which have no prior-year period, were blanked so they no longer show misleading values.

## 11. Limitations
- **Few observations:** seven half-year observations; H2 values are derived.
- **Exceptional items** are management-defined and rounded to €0.1bn (±€50m per item, ±€100m for derived H2).
- **The residual** combines price, mix, volume, costs, FX and other effects that are not separable with published data.
- **The cap-rate counterfactual** holds amortisation fixed and is illustrative.
- **L3** mixes group and automotive-only items. It is a sensitivity, not underlying profitability.
- **Delivery mix** uses retail deliveries, while revenue follows wholesale units.
- **Scenarios** assume independent range ends (A-08), a constant automotive share (A-05), net extraordinary guidance (A-06) and H2 tariffs = H1 (A-07).
- **One input comes from a tier-3 source:** the CFO statement in an earnings-call transcript.

## 12. Conclusion
On the published data, Porsche's H1 2026 margin recovery is a **reported** recovery. It is explained by smaller one-off charges, while the **underlying** margin (L1: 9.4% → 8.4%) and the other EBIT drivers (−€140m) are still weakening. Higher prices and a richer mix help, but not enough to offset lower volume. Accounting is a headwind rather than a support.

For the recovery to be sustainable **on Porsche's own guidance**, H2 2026 must deliver an underlying margin of about 9.4% at the midpoints, an improvement on H1. The same guidance implies a clearly weaker H2 cash margin. These are the points to monitor at the FY2026 results.

---
*Appendix: the source register (S001–S026 in `data/staging/source_register.csv`, with S027 added in `sql/08_mart_setup.sql`), the assumption register (A-01–A-09, `data/sql_outputs/assumptions.csv`), audit findings (AF-01–AF-13, `data/sql_outputs/audit_findings.csv`) and the full QA outputs (`qa/`).*

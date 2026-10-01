# Porsche 2026 Margin Recovery — Is It Real?
### A Company Lens case study in business analytics, financial reasoning and data quality

**Author:** Vigneshwari Nalla · MSc Data Analytics for Business, KEDGE Business School
**Tools:** PostgreSQL · Excel · Power BI (DAX) · Python
**Data:** Porsche AG public investor-relations disclosures, H1 2023 – H1 2026 (7 half-years)

> Independent portfolio project based only on published company documents. Not affiliated with or endorsed by Porsche AG. Not investment advice.

---

## Executive summary

In H1 2026 Porsche's reported operating margin rose from **5.5% to 7.8%**. On the surface, that looks like a recovery.

I tested whether that recovery is real once the one-off items Porsche itself discloses are taken out, and what Porsche's own full-year guidance implies for the second half.

**Answer: the recovery is visible in reported profit, but not yet in underlying profit.**

- Lower one-off charges (+€600m) are **larger than the entire increase in reported EBIT (+€341m)**: 176% of the gain.
- Excluding the realignment and battery items, the headline adjusted margin (L1) **fell from 9.4% to 8.4%**. Also excluding US tariffs (L2), it fell from 11.6% to 10.7%.
- A higher price per car (+5.3%) offset only **44% of the revenue lost from lower volume** (−10.8% vehicles sold).
- Accounting is not flattering the result. Less R&D is being capitalised, and the R&D charge in the P&L (€1,334m) now exceeds total R&D costs (€1,116m).
- Cash is the clearly positive signal: the automotive net cash-flow margin rose from 2.4% to 6.7%.
- Porsche's FY2026 guidance, with every range at its midpoint, arithmetically implies an **H2 underlying margin of 9.4%**, about 1 point above H1 2026. The implied H2 automotive cash margin is only −0.6% to 3.4%. These are scenario combinations, **not forecasts**.

The whole chain is reconciled end to end: SQL data model → Excel business model → Power BI management dashboard, with **1,524 automated comparisons and 0 failures**, and **388/388 QA checks passing** inside Power BI.

---

## 1. Project overview

The **Company Lens** series takes one public company and one live business question, and answers it with a fully traceable analytics pipeline. This edition looks at Porsche AG's 2026 margin recovery.

| Layer | What it does | Output |
|---|---|---|
| **Sources** | 27 registered documents: 26 Porsche IR publications plus 1 earnings-call transcript. Every value is recorded with its source, page and definition. | Source register, availability matrix |
| **SQL (PostgreSQL)** | Staging → core → mart model. Half-year derivation, adjusted EBIT levels, bridges, scenario grid, 423 data-quality checks. | 11 analytical views |
| **Excel** | A business model built on formulas, reproducing every SQL result independently, with a 50-check audit sheet | `PCL_05_Porsche_Margin_Model_FINAL.xlsx` |
| **Power BI** | 6-page management dashboard: 17 tables, 8 relationships, 194 DAX measures, and an in-report QA page | `Porsche_Company_Lens_2026_Margin_Recovery.pbix` |

## 2. Business problem

After two difficult half-years, Porsche's H1 2026 reported margin recovered. For management and investors, the question that matters is **how much of that recovery is sustainable**. Three things could flatter the headline:

1. **One-off charges.** Porsche booked large realignment, battery and tariff costs in 2025. If they simply shrink, reported profit rises without the business improving.
2. **Accounting effects.** Capitalising more development cost or lower depreciation can lift EBIT without any operational change.
3. **Mix and price.** Selling fewer, more expensive cars can hold revenue up while volume falls.

## 3. Objectives and key questions

| # | Question | Where it is answered |
|---|---|---|
| Q1 | Does the margin recovery survive after removing Porsche's disclosed exceptional items? | Dashboard page 1, page 2 |
| Q2 | What moved reported EBIT year on year, and what is left unexplained? | Page 2 (EBIT bridge) |
| Q3 | Are R&D capitalisation or depreciation flattering the margin? | Page 3 |
| Q4 | Does a higher price per car compensate for fewer cars sold? | Page 4 |
| Q5 | Does cash confirm the profit picture? | Page 5 |
| Q6 | What must H2 2026 deliver for Porsche to meet its own FY2026 guidance? | Page 5 (scenarios) |
| Q7 | Can every number be trusted and traced back to its source? | Page 6 (QA & Lineage) |

## 4. Data sources and structure

- **Sources:** Porsche half-year reports, annual reports, investor presentations, press releases and the official fact-sheet Excel files, H1 2023 to H1 2026. One CFO statement on H2 extraordinary expenses comes from a public earnings-call transcript, flagged as a lower-tier source.
- **Grain:** half-year. Porsche publishes H1 and full-year (FY) figures, so **H2 = FY − H1** is derived for additive items only (never for ratios) and labelled DERIVED.
- **Value labels:** every number is tagged **FACT** (published), **DERIVED** (calculated from published values), **ASSUMPTION** or **PROXY**.
- **Traceability:**
  - 481 source-reference rows record document, page, period and definition.
  - 155 manually recorded inputs (151 values, plus 4 documented gaps that were left blank rather than estimated).
  - 13 audit findings and 9 named assumptions (A-01 to A-09).

## 5. Analytical methodology

1. **Source validation:** every value was checked against the source document or the official fact sheet before entering the model.
2. **SQL model:**
   - Staging, core (facts and dimensions) and mart (analytical views) layers.
   - 305 data-quality checks and 118 model-quality checks, with 0 failures.
3. **Adjusted EBIT levels:** the disclosed one-offs are removed step by step (section 6).
4. **Year-on-year bridge:** the change in reported EBIT versus the same half of the prior year is split into:
   - lower or higher one-offs;
   - US tariffs;
   - capitalised development costs;
   - automotive depreciation and amortisation (D&A) with impairments removed;
   - Financial Services;
   - a residual of other drivers.

   The bridge closes exactly, both in € and in margin points.
5. **Volume vs price:** the change in automotive revenue is split into a volume effect and an average-selling-price (ASP) effect.
6. **Guidance scenarios:** each end of Porsche's FY2026 guidance ranges (low / mid / high) is combined, and the H2 result each combination implies is calculated (section 9).
7. **Independent rebuild and reconciliation:** Excel and Power BI recompute the logic independently, and every result is reconciled back to SQL.

## 6. KPI / margin framework

| Level | Definition | Role |
|---|---|---|
| **L0 Reported EBIT** | Group operating profit as reported | Reported |
| **L1** | L0 + strategic realignment incl. battery activities (net) | **Headline underlying KPI** |
| **L2** | L1 + US import tariffs | Adjusted headline, also excluding tariffs |
| **L3 hybrid sensitivity** | L1 + clean automotive D&A − capitalised development costs | **Sensitivity only, never a KPI.** It mixes group and automotive-only items. |

Margins are always level ÷ group revenue. Impairments already sit inside the realignment item, so they are **not** removed a second time.

## 7. Power BI dashboard architecture

**Model:**
- **Tables:** 17 in a star schema around a half-year period dimension.
- **Relationships:** 8, all many-to-one with single-direction filtering.
- **Scenario tables:** disconnected by design, so a period filter can never silently change a scenario.
- **Measures:** 194 DAX measures in 13 folders.

| Page | Business question it answers |
|---|---|
| 1 Executive Overview | Is the recovery real? 7 KPI cards, the margin trend by level, 7 rule-based recovery signals |
| 2 EBIT Recovery | What moved EBIT? The L0 → L1 → L2 waterfall, the year-on-year bridge in € and in margin points |
| 3 R&D & D&A | Is accounting flattering the margin? Capitalisation rate, R&D charge vs cost, clean D&A, the L3 sensitivity (clearly labelled) |
| 4 Commercial Drivers | Price vs volume: the revenue bridge, the ASP trend, delivery mix by model and by region |
| 5 Cash & Guidance | Does cash confirm it, and what must H2 deliver? Cash conversion, 27 group plus 9 automotive guidance combinations |
| 6 QA & Lineage | Can we trust it? 388 automated checks, identity checks, full source lineage, assumptions |

## 8. Key business insights (H1 2026 vs H1 2025)

**Actuals** (published by Porsche):

| KPI | H1 2025 | H1 2026 | Change |
|---|---|---|---|
| Group revenue (€m) | 18,157 | 17,229 | −5.1% |
| Reported EBIT, L0 (€m) | 1,007 | 1,348 | +341 |
| Reported margin, L0 | 5.5% | 7.8% | +2.28 pp |
| Vehicle sales, wholesale | 135,142 | 120,508 | −10.8% |
| Automotive net cash flow margin | 2.4% | 6.7% | +4.3 pp |

**Analytical adjustments** (derived from Porsche's disclosed items):

| KPI | H1 2025 | H1 2026 | Change |
|---|---|---|---|
| L1 margin (headline underlying) | 9.4% | 8.4% | −0.99 pp |
| L2 margin (also excl. tariffs) | 11.6% | 10.7% | −0.88 pp |
| ASP, € k per vehicle sold | 119.4 | 125.8 | +5.3% |

**Reported EBIT bridge, H1 2025 → H1 2026 (€m, analytical bridge):**
1,007 → +600 exceptional items → 0 US tariffs → −88 capitalised development costs → −37 clean D&A → +6 Financial Services → **−140 residual / other drivers** → 1,348.

What this means:
- **The whole reported gain, and more, comes from smaller one-offs** (176% of the change).
- **The remaining drivers are negative (−€140m).** The residual stays negative (−€79m) even if one impairment assumption (A-04) is reversed.
- **Value over volume works only partially.** The ASP effect (+€768m) covers 44% of the volume effect (−€1,748m). Automotive revenue fell by €980m.
- **Mix moved towards the 911 and Cayenne.** 911 share rose from 17.5% to 25.0% of deliveries, and Cayenne from 28.6% to 31.2%. The 718 fell from 7.2% to 2.3%, as production ended. China's share fell from 14.6% to 11.9%.
- **There is no accounting tailwind.** The capitalisation rate fell from 45.5% to 43.6%. At the prior year's rate, the R&D P&L charge would have been €20.7m lower.
- **Cash improved despite outflows.** NCF was €1,020m, including about €0.4bn of cash-outs (the first Audi licence tranche and realignment) and about €0.3bn of pension funding, as disclosed by Porsche.

## 9. Scenario / guidance analysis — NOT forecasts

Porsche guides FY2026 as ranges:

| Guidance item | Range |
|---|---|
| Revenue | €35–36bn |
| Return on sales | 5.5–7.5% |
| Automotive EBITDA margin | 15–17% |
| Automotive net cash flow margin | 3–5% |
| Extraordinary expenses (net) | ~€0.8–0.9bn |

I combined the low / mid / high ends of the ranges (27 group combinations and 9 automotive combinations), and for each one calculated what H2 2026 must deliver, given the H1 2026 actuals.

| Implied H2 2026 | Range across combinations | All midpoints | H1 2026 actual |
|---|---|---|---|
| Reported margin (L0) | 3.25% – 7.20% | 5.25% | 7.82% |
| L1 margin | 7.10% – 11.69% | 9.36% | 8.41% |
| L2 margin | 9.23% – 13.94% | 11.54% | 10.73% |
| Automotive EBITDA margin | 11.84% – 15.85% | 13.87% | 18.25% |
| Automotive NCF margin | −0.62% – 3.41% | 1.42% | 6.73% |

> These are **arithmetic scenario combinations** of Porsche's published ranges. They are **not forecasts**, carry **no probabilities**, and "all midpoints" is **not** a most-likely case. The assumptions behind them are:
> - **A-05:** automotive share of revenue = its H1 2026 share (88.0%).
> - **A-06:** extraordinary-expense guidance is net.
> - **A-07:** H2 tariffs = H1 tariffs.
> - **A-08:** range ends are combined independently.

**Reading:** meeting guidance at its midpoints requires the underlying margin to rise in H2, to about 1 point above H1. The same guidance implies a clearly weaker H2 cash margin.

## 10. Data validation and QA framework

| Layer | Checks | Result |
|---|---|---|
| Sources | Every value verified against its document or the official fact sheet; 4 gaps documented, not estimated | 151 values + 4 gaps |
| SQL | 305 data-quality + 118 model-quality checks | 0 FAIL |
| Excel | 50 formula-based audit checks (identities, Porsche reconciliations, labelling, 8 anchor values) | 50/50 PASS |
| Power BI | 388 in-report QA checks: every measure recomputed from base values and compared with SQL | 388/388 PASS |

## 11. SQL → Excel → Power BI reconciliation

An independent script recomputes every dashboard measure and compares it with the other layers:

| Comparison group | Comparisons | Failures |
|---|---|---|
| Power BI QA checks vs SQL reference | 388 | 0 |
| Measures vs live SQL views | 351 | 0 |
| Measures vs the Excel model | 566 | 0 |
| Identities (bridges close, volume + ASP = revenue change, mix totals) | 51 | 0 |
| Export integrity (SQL → Power BI tables) | 168 | 0 |
| **Total** | **1,524** | **0** |

The review process also found and fixed real defects before sign-off:
- an Excel lookup that behaved differently in another spreadsheet engine;
- a DAX filter-context error that distorted delivery-mix shares.

The QA scope was extended so that class of error is now caught automatically.

## 12. Key findings and business implications

1. **Headline vs underlying.** The H1 2026 recovery is a *reported* recovery, driven by smaller one-offs. The underlying margin (L1) is still falling year on year.
2. **What sustainability depends on.** Meeting FY2026 guidance at its midpoints requires the H2 underlying margin to rise to about 9.4%, i.e. to improve from H1 rather than just hold.
3. **What to monitor at the FY2026 results:**
   - the L1 margin vs the guidance-implied requirement;
   - the share of EBIT change coming from one-offs;
   - the sign of the residual drivers;
   - ASP coverage of the volume decline;
   - the capitalisation rate and the amortisation overhang;
   - H2 cash conversion.

## 13. Tools and skills demonstrated

- **Business analysis:** framing a business question, defining KPIs, bridge and variance analysis, scenario thinking, clear communication of uncertainty.
- **Financial and operations analytics:** margin architecture, one-off adjustment, volume/price/mix decomposition, cash conversion, guidance-gap analysis.
- **SQL (PostgreSQL):** layered data model, window functions, data-quality framework.
- **Excel:** formula-driven model, audit checks, portability testing.
- **Power BI:** star schema, DAX (filter context, TREATAS, scenario selection), edit interactions, a QA page.
- **Data governance:** source lineage, value labelling, assumption register, automated reconciliation.

## 14. My role and contribution

I owned the project end to end:
- chose the company and the business question;
- defined the scope, KPI framework and labelling rules;
- validated the source data;
- reviewed and approved each phase (sources → inputs → SQL → Excel → Power BI);
- built the Power BI report;
- ran the QA and audit cycle until every layer reconciled.

<!-- Optional transparency line — keep or remove at your discretion:
Code generation and QA review were AI-assisted (Claude); analytical decisions, validation and sign-off were mine. -->

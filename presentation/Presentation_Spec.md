# Porsche 2026 Margin Recovery: presentation spec (first draft)

12 slides, 16:9. Every figure is read from the final validated project outputs (the same `data.js` the website uses). Visual reference: the project website (`docs/`). The Porsche photographs on slides 1, 3 and 7 are third-party images; see `docs/README.md`, "Image rights". Slide 12 carries a one-line image note under its footer.

## Slide 1: Cover: Porsche Company Lens

**Main message:** A public-data business case, analysed end to end.

**Visual:** Cover artwork: giant PORSCHE lettering behind the rear-view 911 cut-out, tail-light glow, smoke at the base.

**Key numbers:** none

**Exact slide copy:**

- COMPANY LENS
- Vigneshwari Nalla / MSc Data Analytics for Business, KEDGE Business School
- 2026  MARGIN RECOVERY
- Is Porsche's 2026 margin recovery actually improving underneath the reported numbers?
- H1 2023 TO H1 2026  /  SQL  /  EXCEL  /  POWER BI  /  PUBLIC DISCLOSURES ONLY

**Speaker notes:** I picked one live business question and answered it with a pipeline where every number can be traced back to Porsche's own disclosures: a PostgreSQL data model, an audited Excel model and a six-page Power BI dashboard. The question is simple: Porsche's reported margin recovered in H1 2026. Is the business actually improving underneath?

## Slide 2: A reported recovery, not yet an underlying one.

**Main message:** The margin recovery comes from smaller one-offs; underlying profitability is still falling.

**Visual:** 4 KPI cards; dashed scenario strip; framed crop of the Power BI page 1 signal panel.

**Key numbers:** 7.8% · 8.4% · 176% · 6.7% · 9.36% vs 8.41% (scenario)

**Exact slide copy:**

- Executive overview
- A REPORTED RECOVERY, NOT YET AN UNDERLYING ONE.
- Reported margin (L0), H1 2026
- 7.8%
- from 5.5% in H1 2025, +2.28 pp
- Underlying margin (L1), H1 2026
- 8.4%
- from 9.4% in H1 2025, −0.99 pp
- One-offs share of the EBIT gain
- 176%
- lower one-offs +€600m vs total EBIT gain +€341m
- Automotive net cash flow margin
- 6.7%
- from 2.4% in H1 2025
- Scenario, not a forecast.  With every FY2026 guidance range at its midpoint, the implied H2 L1 margin is 9.36% vs 8.41% in H1 2026.
- POWER BI, PAGE 1: THE DASHBOARD'S SIGNAL PANEL
- Source: Porsche AG public disclosures; project analysis. € million unless stated.

**Speaker notes:** If you remember one thing: the headline improved because the one-off charges shrank, not because the business improved. Reported margin rose from 5.5% to 7.8%. Remove the realignment and battery items Porsche itself discloses, and the underlying margin fell from 9.4% to 8.4%. Lower one-offs of +€600m are larger than the whole EBIT gain of +€341m. Cash is the clearly positive signal. And on Porsche's own guidance, H2 has to improve on H1 — that last point is scenario arithmetic, not a forecast.

## Slide 3: Business question

**Main message:** "Is the recovery sustainable?" needs three possible illusions tested.

**Visual:** Half-bleed wet-crest photograph; three numbered test cards, each pointing to the slide that tests it.

**Key numbers:** 5.5% → 7.8%

**Exact slide copy:**

- Business question
- After removing Porsche's disclosed one-offs and isolating non-cash accounting effects, is underlying profitability improving, and what does FY2026 guidance require from H2?
- The headline: reported margin 5.5% → 7.8%, H1 2025 to H1 2026.
- 1
- Smaller one-offs
- Is the gain just lower exceptional charges, rather than a better business?
- Tested in the EBIT bridge, slide 5
- 2
- Accounting effects
- Is more R&D being capitalised, or less depreciation booked?
- Tested in R&D and D&A, slide 6
- 3
- Price and mix
- Is a higher price per car hiding fewer cars sold?
- Tested in commercial drivers, slides 7 and 8

**Speaker notes:** I framed it the way a CFO office would: what would have to be true for this recovery to be real? Three things can make a headline look better than the business: smaller one-off charges, accounting choices on R&D capitalisation and depreciation, and a richer price and mix compensating for fewer cars. Each one is tested on its own slide.

## Slide 4: Only the reported margin recovered.

**Main message:** Four profit levels, three of them KPIs; only L0 is up on the same half a year earlier.

**Visual:** L0 → L1 → L2 build card; native line chart of L0/L1/L2 margins H1 2023–H1 2026; framed Power BI page 1 KPI row.

**Key numbers:** €1,348m · +€100m · €1,448m · +€400m · €1,848m; 7.8% / 8.4% / 10.7%; H2 2025 L0 −3.3% vs L1 10.0%

**Exact slide copy:**

- H1 2026 financial performance
- ONLY THE REPORTED MARGIN RECOVERED.
- L0  Reported EBIT
- €1,348m
- margin 7.8%
- + Realignment and battery items (net)
- +€100m
- disclosed by Porsche
- L1  Underlying EBIT, headline KPI
- €1,448m
- margin 8.4%
- + US import tariffs
- +€400m
- disclosed by Porsche
- L2  EBIT excluding tariffs
- €1,848m
- margin 10.7%
- Group margin by half-year: reported vs headline adjusted levels
- H2 2025: L0 −3.3% vs L1 10.0%. Until 2025 the three lines coincide: no one-offs were disclosed (A-01, A-02). H2 = FY − H1.
- POWER BI, PAGE 1: KPI ROW, H1 2026

**Speaker notes:** Four profit levels, only three of them KPIs. L0 is Porsche's reported EBIT. L1 adds back the strategic realignment and battery items Porsche discloses — that is the headline underlying KPI. L2 also adds back US import tariffs. In H1 2026: €1,348m, €1,448m and €1,848m. I use Porsche's own disclosed items, so there is no judgement about what counts as a one-off. Until 2025 all three lines are identical, because no one-offs were disclosed. From 2025 the reported line falls much further, and in H1 2026 only the reported line is up on the same half a year earlier.

## Slide 5: Without the one-off relief, EBIT would have fallen.

**Main message:** Lower one-offs exceed the whole EBIT gain; the remaining drivers are negative.

**Visual:** Year-on-year EBIT waterfall (shapes, exact labels); three callout cards.

**Key numbers:** 1,007 → +600 · 0 · −88 · −37 · +6 · −140 → 1,348; 176%; −€79m under A-04 alternative; +2.28 pp (+3.48 / −0.81 / +0.30)

**Exact slide copy:**

- EBIT recovery bridge
- WITHOUT THE ONE-OFF RELIEF, EBIT WOULD HAVE FALLEN.
- 1,007
- EBIT / H1 2025
- +600
- Exceptional / items
- 0
- US import / tariffs
- −88
- Capitalised / dev. costs
- −37
- Clean / auto D&A
- +6
- Financial / Services
- −140
- Residual, / not separated
- 1,348
- EBIT / H1 2026
- Reported EBIT
- Disclosed one-offs
- Accounting, non-cash
- Financial Services
- Residual, not separated
- 176%
- of the reported EBIT gain came from lower one-offs: +€600m vs a total gain of +€341m.
- Residual −€140m / Price, mix, volume, cost and FX together: not separated, and not "operating performance". Still −€79m if A-04 is reversed.
- In margin points: +2.28 pp / One-offs +3.48 pp, residual −0.81 pp, revenue denominator +0.30 pp. The bridge closes exactly in € and in pp.
- Source: Porsche AG public disclosures; project analysis. Same half of the prior year → H1 2026, € million.

**Speaker notes:** The year-on-year bridge explains the change in reported EBIT, from 1,007 to 1,348 million euros. Lower one-offs contributed +600; tariffs were the same in both halves, so zero; capitalised development −88; clean D&A −37; Financial Services +6; and the residual −140. The residual isn't operating performance: it bundles price, mix, costs and FX that Porsche doesn't split out. But it is negative in both cases I tested, including −€79m if the H1 2026 impairments are not inside D&A.

## Slide 6: Accounting is a headwind, not a hidden tailwind.

**Main message:** Less R&D is capitalised and amortisation pushes the P&L charge above R&D costs.

**Visual:** Native clustered columns (total R&D vs P&L charge); capitalisation-rate dial; four figure cards.

**Key numbers:** 43.6% (45.5%, 77.7%); €1,116m · €1,334m · −€218m · +€20.7m (illustrative); clean D&A €1,498m; L3 14.3% (sensitivity only)

**Exact slide copy:**

- R&D, D&A and capitalisation
- ACCOUNTING IS A HEADWIND, NOT A HIDDEN TAILWIND.
- Total R&D costs vs R&D charged to the P&L (€ million)
- H2 derived as FY − H1. P&L charge = expensed R&D + amortisation of capitalised R&D.
- 43.6%
- of automotive R&D costs capitalised, H1 2026
- 45.5% in H1 2025, 77.7% in H1 2023
- €1,116m
- total R&D costs
- €1,334m
- charged to the P&L
- −€218m
- net capitalisation
- +€20.7m
- cap-rate effect, illustrative
- Clean automotive D&A €1,498m (€61m impairments removed, A-04). L3 hybrid sensitivity 14.3%: sizes the non-cash wedge only, never a KPI.
- Source: Porsche AG public disclosures; project analysis. € million unless stated.

**Speaker notes:** A common worry is that companies flatter EBIT by capitalising more R&D. Here the opposite is happening. The capitalisation rate fell from 45.5% to 43.6%, and it was 77.7% in H1 2023. Past capitalisation is now being amortised through the P&L, so the R&D charge of €1,334m is above total R&D costs of €1,116m. At the prior year's rate, the P&L charge would have been about 20.7 million lower — illustrative, with amortisation held fixed. L3 is shown only to size the non-cash wedge and is never compared with guidance.

## Slide 7: Value over volume works, but only partly.

**Main message:** A higher price per car recovers less than half of the revenue lost to volume.

**Visual:** Framed black-911 poster image; three headline stats; volume + ASP = revenue equation cards; horizontal revenue bridge.

**Key numbers:** 120,508 (−10.8%) · €125.8k (+5.3%) · 44%; −1,748 + 768 = −980; 16,138 → 15,158

**Exact slide copy:**

- Commercial drivers: volume vs ASP
- VALUE OVER VOLUME WORKS, BUT ONLY PARTLY.
- 120,508
- vehicles sold, −10.8%
- €125.8k
- average selling price, +5.3%
- 44%
- of the volume loss recovered by ASP
- −1,748
- Volume effect, € million
- −10.8% vehicles, at last year's ASP
- +
- +768
- ASP effect, € million
- +5.3% per vehicle, on this year's units
- =
- −980
- Automotive revenue change
- €16,138m → €15,158m
- Automotive revenue bridge, € million
- Revenue H1 2025
- 16,138
- Volume effect
- −1,748
- ASP effect
- +768
- Revenue H1 2026
- 15,158
- ASP = automotive revenue ÷ wholesale vehicles sold. The ASP effect is price plus model mix, options and FX, not pure pricing.
- Source: Porsche AG public disclosures; project analysis. € million unless stated.

**Speaker notes:** Porsche sold 10.8% fewer vehicles, 120,508 in H1 2026, while the average selling price rose 5.3% to 125.8 thousand euros. The volume effect of −1,748 million plus the ASP effect of +768 equals the automotive revenue change of −980. The higher price recovered only 44% of what volume took away. The ASP effect is price plus mix, options and FX, not pure pricing.

## Slide 8: Deliveries shifted towards the 911 and the Cayenne.

**Main message:** Mix moved towards the 911 and Cayenne; 718 and China shares fell.

**Visual:** Two native clustered bar charts (model, region; H1 2026 vs H1 2025); four callout cards.

**Key numbers:** 911 25.0% (+7.5 pp) · Cayenne 31.2% (+2.6 pp) · 718 2.3% (−4.9 pp) · China 11.9% (−2.7 pp); retail deliveries 122,306

**Exact slide copy:**

- Delivery mix
- DELIVERIES SHIFTED TOWARDS THE 911 AND THE CAYENNE.
- By model, share of retail deliveries
- By region, share of retail deliveries
- 911
- 25.0%
- +7.5 pp vs H1 2025
- Cayenne
- 31.2%
- +2.6 pp
- 718 Boxster/Cayman
- 2.3%
- −4.9 pp, as production ended
- China
- 11.9%
- −2.7 pp
- Retail deliveries (122,306 in H1 2026) are not the wholesale units that drive revenue.

**Speaker notes:** Mix moved towards the 911 and the Cayenne. The 911 rose to 25.0% of deliveries, up +7.5 pp; the Cayenne to 31.2%. The 718 fell to 2.3% as production ended, and China's share fell to 11.9%. One caveat: these are shares of retail deliveries, while revenue follows wholesale units. Richer mix helps, but as the previous slide showed, it does not replace lost volume.

## Slide 9: Cash is the clearly positive signal.

**Main message:** Cash conversion improved in H1 2026 despite disclosed cash-outs.

**Visual:** Native line chart (automotive EBITDA margin vs NCF margin); four actuals cards; Porsche commentary card.

**Key numbers:** €1,020m · 6.7% (+4.3 pp vs 2.4%) · 0.88 · €1,374m · EBITDA margin 18.3%

**Exact slide copy:**

- Cash performance
- CASH IS THE CLEARLY POSITIVE SIGNAL.
- Automotive EBITDA margin and net cash flow margin, by half-year
- ACTUALS, PUBLISHED BY PORSCHE
- €1,020m
- Automotive net cash flow, H1 2026
- 6.7%
- NCF margin, +4.3 pp vs 2.4%
- 0.88
- Cash from operations ÷ EBITDA
- €1,374m
- Simple cash proxy: EBITDA − capex − capitalised development
- Porsche's commentary: net cash flow improved despite ~€0.4bn of cash-outs (first Audi licence tranche, realignment) and ~€0.3bn additional pension funding (S016, slide 13).
- Automotive EBITDA margin 18.3% in H1 2026. NCF margin = automotive net cash flow ÷ automotive revenue. H2 = FY − H1.
- Source: Porsche AG public disclosures; project analysis. € million unless stated.

**Speaker notes:** Cash is the clearly positive signal. Automotive net cash flow was €1,020m, a margin of 6.7% against 2.4% a year earlier, despite the cash-outs Porsche disclosed: about 0.4 billion for the first Audi licence tranche and the realignment, and about 0.3 billion of pension funding. Cash conversion, CFO over EBITDA, was 0.88. These are actuals as published. The next slide shows why the guidance arithmetic implies a much weaker H2 cash margin.

## Slide 10: On its own guidance, Porsche needs a stronger H2.

**Main message:** Guidance at its midpoints implies H2 must improve on H1. Scenario, not a forecast.

**Visual:** Scenario banner; range chart (min–max band, all-midpoints diamond, H1 actual line) for L0/L1/L2; automotive NCF scenario strip; guidance inputs; A-05 to A-08.

**Key numbers:** L1 7.10–11.69%, mid 9.36% vs 8.41% (+0.95 pp); L0 3.25–7.20%; L2 9.23–13.94%; auto NCF −0.62–3.41% vs 6.73%; H2 revenue €18,271m, EBIT €959m

**Exact slide copy:**

- H2 guidance and scenario analysis
- ON ITS OWN GUIDANCE, PORSCHE NEEDS A STRONGER H2.
- SCENARIO ANALYSIS: ARITHMETIC ONLY — NOT FORECASTS — NO PROBABILITIES
- Implied H2 2026 margin across all 27 group combinations
- 2%
- 4%
- 6%
- 8%
- 10%
- 12%
- 14%
- L0 reported
- 3.25%
- 7.20%
- mid 5.25%
- H1 7.82%
- L1 underlying
- 7.10%
- 11.69%
- mid 9.36%
- H1 8.41%
- L2 excl. tariffs
- 9.23%
- 13.94%
- mid 11.54%
- H1 10.73%
- min to max of the combinations
- all midpoints (not a most-likely case)
- H1 2026 actual
- Automotive H2 NCF margin, 9 combinations: −0.62% to 3.41% / vs 6.73% in H1 2026. EBITDA margin 11.84% to 15.85% vs 18.25%. Uses A-05. Scenario, not a forecast.
- ALL MIDPOINTS, SCENARIO
- 9.36%
- implied H2 L1 margin vs 8.41% in H1 2026 (+0.95 pp)
- H2 revenue €18,271m, H2 reported EBIT €959m
- FY2026 GUIDANCE AS PUBLISHED
- Group revenue
- €35.0–36.0bn
- Return on sales
- 5.5–7.5%
- Extraordinary expenses (net)
- €0.8–0.9bn
- Automotive EBITDA margin
- 15–17%
- Automotive NCF margin
- 3–5%
- A-05 Automotive revenue = group guidance × H1 2026 automotive share (88.0%). / A-06 Extraordinary-expense guidance is net, like H1 (~€0.1bn). / A-07 H2 2026 tariffs = H1 2026 (€0.4bn). / A-08 Range ends are combined independently.
- Sources: FY2026 guidance (S016, slide 14); CFO statement on extraordinary expenses (S027). H2 = implied FY − H1 actual.

**Speaker notes:** I don't forecast. I translate Porsche's published guidance ranges into what they require from H2. Each range is taken at its low, mid and high end, and the ends are combined: 27 combinations for the group, 9 for the automotive segment. With every range at its midpoint, the implied H2 underlying margin is 9.36%, against 8.41% in H1 — about one point of improvement. Across all combinations it runs from 7.10% to 11.69%, so the low end is compatible with H2 not improving. All midpoints is not a most-likely case, and no probabilities are attached. The implied H2 automotive cash margin is much weaker than H1's 6.73%. Assumptions: A-05 for the automotive share, A-06 that the extraordinary-expense guidance is net, A-07 that H2 tariffs equal H1.

## Slide 11: Not just a dashboard. Every number is tested.

**Main message:** Every number reconciles across all tools: ALL 388 QA CHECKS PASS.

**Visual:** Five-node pipeline (Sources → SQL → Excel → Power BI → QA); gold pass statement; framed Power BI page 6 crop.

**Key numbers:** 27 sources · 155 inputs, 4 gaps · 305 + 118 SQL checks · 2,997 formulas · 50/50 · 553 · 17 tables · 194 measures · 388/388 · 1,524 comparisons, 0 failures

**Exact slide copy:**

- Data architecture and QA
- NOT JUST A DASHBOARD. EVERY NUMBER IS TESTED.
- SOURCES
- 27 registered sources
- 155 input rows, 4 gaps documented, none estimated
- SQL
- PostgreSQL 16, 11 mart views
- 305 data-quality + 118 model-quality checks pass
- EXCEL
- 2,997 formulas
- 50/50 audit checks, 553 values verified
- POWER BI
- 17 tables, 194 DAX measures
- 6 report pages, star schema
- QA
- 388/388 in-report checks
- 1,524 cross-tool comparisons, 0 failures
- ALL 388 QA CHECKS PASS
- Inside the Power BI report, each measure is recomputed from base values and compared with the SQL mart.
- Found and fixed in review / A spreadsheet lookup that behaved differently in another engine / A DAX filter-context error in delivery-mix shares; 77 checks added / 26 Excel cells with no prior-year period, blanked
- POWER BI, PAGE 6: QA AND LINEAGE

**Speaker notes:** This is what makes it more than a dashboard. Every value starts in a registered source, labelled fact, derived, assumption or proxy. SQL runs 305 data-quality and 118 model-quality checks; Excel has 50 audit checks; Power BI recomputes 388 measures against the SQL reference — all 388 pass. Across the tools, 1,524 comparisons, zero failures. The review caught real errors, including one that only showed up in a different calculation engine, and a DAX filter-context error in the mix shares. That is why the checks are automated rather than eyeballed.

## Slide 12: What the data shows, and what I did.

**Main message:** A reported recovery, not yet an underlying one; and what I contributed.

**Visual:** Six findings with lead numbers; My role card with six factual role statements.

**Key numbers:** +€600m · −€140m · 44% · 43.6% · 6.7% · 9.36% (scenario)

**Exact slide copy:**

- Key findings and my role
- WHAT THE DATA SHOWS, AND WHAT I DID.
- +€600m
- The recovery is driven by lower one-offs
- 176% of the EBIT gain; L1 margin 9.4% → 8.4%
- −€140m
- Other EBIT drivers are negative
- Residual, not separated; −€79m if A-04 is reversed
- 44%
- ASP covers less than half the volume loss
- +768 vs −1,748 € million
- 43.6%
- No accounting tailwind
- P&L charge €1,334m above R&D costs €1,116m
- 6.7%
- Cash conversion improved
- NCF margin up from 2.4%; H2 implied cash margin weaker
- 9.36%
- Guidance midpoints require a stronger H2
- vs 8.41% in H1. Scenario, not a forecast
- MY ROLE
- Business analytics, operations thinking, financial analysis and data storytelling, applied to one question.
- Framed the question / chose the company and question; defined L0 to L3 and the labelling rules
- Validated the data / built the 27-source register and checked inputs; 4 gaps documented, not estimated
- Reviewed every phase / approved sources, inputs, SQL, Excel and Power BI models in turn
- Built the dashboard / built and formatted the six-page Power BI report
- Ran the audit / ran the QA cycle until SQL, Excel and Power BI reconciled with zero failures
- Told the story / turned the analysis into findings and an FY2026 monitoring plan
- Delivered: a traceable SQL data model, an audited Excel model and a six-page Power BI dashboard, reconciled across 1,524 comparisons with 0 failures.
- Figures from the final validated project outputs. Not affiliated with or endorsed by Porsche AG. Not investment advice.

**Speaker notes:** To close: H1 2026's margin rebound is explained by smaller one-offs; the underlying margin and the other drivers are still weakening. Price and mix help but do not replace volume, accounting is a headwind rather than a hidden tailwind, and cash is the bright spot. On Porsche's own guidance, sustainability depends on H2 improving on H1 — that is scenario arithmetic, not a forecast. What to monitor at the FY2026 results: the L1 margin against the guidance-implied requirement, the share of the EBIT change coming from one-offs, the sign of the residual, ASP coverage of the volume decline, the capitalisation rate, and H2 cash conversion. My part was to frame the question, validate the data, review each phase, build the dashboard, run the audit and tell the story. Happy to walk through any number back to its source page.

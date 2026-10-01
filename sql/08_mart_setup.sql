-- =====================================================================
-- PCL Porsche Company Lens - 08_mart_setup.sql   (Phase 4)
-- Creates the analytical layer 'mart' and its three control tables:
--   mart.view_catalog   : documentation of every analytical view
--   mart.assumption     : every modelling assumption, referenced by views
--   core.fact_guidance  : Porsche FY2026 guidance ranges (with sources)
--   mart.annotation     : verified qualitative notes for periods (for tooltips)
-- Re-runnable.
-- =====================================================================
DROP SCHEMA IF EXISTS mart CASCADE;
CREATE SCHEMA mart;
COMMENT ON SCHEMA mart IS 'Analytical layer: views answering the margin-recovery question. Reads only from core.';

-- ---------------------------------------------------------------------
-- New source used for guidance (management statement on the H1 2026 call)
-- ---------------------------------------------------------------------
INSERT INTO audit.dim_source (source_id, tier, publisher, document_title, doc_type, reporting_period,
                              publication_date, url, file_name, notes)
VALUES ('S027', 3, 'Investing.com',
        'Earnings call transcript: Porsche AG H1 2026 (CFO Jochen Breckner statements)',
        'Call transcript', 'H1 2026', '2026-07-29',
        'https://www.investing.com/news/transcripts/earnings-call-transcript-porsche-ag-posts-stronger-margins-in-h1-2026-93CH-4818792',
        '2026_H1_CallTranscript.pdf (print to PDF)',
        'Tier 3 transcript of a Tier 1 statement. Used only for FY2026 extraordinary-expense guidance (EUR 800-900m), which is not in S016.')
ON CONFLICT (source_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- Audit findings raised while building the analytical layer (Phase 4)
-- ---------------------------------------------------------------------
INSERT INTO audit.audit_finding VALUES
('AF-12','Does automotive net cash flow equal operating + investing cash flow in the fact sheet?',
 'S025 sheet 02: H1 2024 net cash flow stored as exactly 1,117,000,000 EUR while CFO + investing = 1,116.89m; FY2024 as reported therefore makes derived H2 2024 differ by -0.11m.',
 'Porsche stores the H1 2024 net cash flow as a rounded figure. Difference EUR 0.11m.',
 'Resolved','Reported values kept unchanged; check MQ16 uses a EUR 0.5m tolerance and cites this finding.'),
('AF-13','Is assumption A-05 (automotive share of group revenue) stable?',
 'mart.v_panel_hy: automotive revenue / group revenue fell from 92.5% (2023-H1) to 88.0% (2026-H1).',
 'The share is not stable over time (Financial Services grows), but a +/-1pp change moves the implied H2 2026 automotive EBITDA margin by only ~0.05pp.',
 'Resolved','A-05 keeps the latest (H1 2026) share; an earlier draft wording of A-05 stating a 87.9-89.3% range was wrong and was corrected before release.')
ON CONFLICT (af_id) DO NOTHING;

-- ---------------------------------------------------------------------
-- Guidance inputs (FACT = published range; used only by guidance views)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS core.fact_guidance;
CREATE TABLE core.fact_guidance (
    guidance_id  varchar(12) PRIMARY KEY,
    metric       text        NOT NULL,
    fiscal_year  smallint    NOT NULL,
    low_value    numeric(20,4) NOT NULL,
    high_value   numeric(20,4) NOT NULL,
    unit_std     varchar(12) NOT NULL,
    basis        text        NOT NULL,
    value_label  varchar(8)  NOT NULL CHECK (value_label IN ('FACT','DERIVED')),
    source_id    varchar(10) NOT NULL REFERENCES audit.dim_source(source_id),
    source_ref   varchar(160) NOT NULL,
    CHECK (high_value >= low_value)
);
INSERT INTO core.fact_guidance VALUES
('GD_REV',   'Group sales revenue',            2026, 35000, 36000, 'EUR m', 'Group, full year',                        'FACT', 'S016', 'slide 14 (2026 outlook, confirmed at H1 2026)'),
('GD_ROS',   'Group return on sales',          2026,   5.5,   7.5, '%',     'Group EBIT / group revenue, full year',   'FACT', 'S016', 'slide 14'),
('GD_EBITDA','Automotive EBITDA margin',       2026,  15.0,  17.0, '%',     'Automotive EBITDA / automotive revenue',  'FACT', 'S016', 'slide 14'),
('GD_NCF',   'Automotive net cash flow margin',2026,   3.0,   5.0, '%',     'Automotive net cash flow / automotive revenue', 'FACT', 'S016', 'slide 14'),
('GD_BEV',   'Automotive BEV share',           2026,  24.0,  26.0, '%',     'Share of deliveries',                     'FACT', 'S016', 'slide 14'),
('GD_EXTRA', 'Extraordinary expenses (net)',   2026,   800,   900, 'EUR m', 'Net, same basis as H1 2026 net EUR ~0.1bn (CFO compared the two directly)', 'FACT', 'S027', 'CFO answer on H2 visibility');

-- ---------------------------------------------------------------------
-- Assumption register (every view that relies on one cites its ID)
-- ---------------------------------------------------------------------
CREATE TABLE mart.assumption (
    assumption_id varchar(6) PRIMARY KEY,
    statement     text NOT NULL,
    applies_to    text NOT NULL,
    rationale     text NOT NULL,
    sensitivity   text NOT NULL
);
INSERT INTO mart.assumption VALUES
('A-01','No realignment/battery items were disclosed for 2023-H1..2024-H2; treated as 0 in adjusted EBIT.',
        'v_ebit_adjusted, v_ebit_bridge_yoy',
        'FY2023 and FY2024 EBIT bridges (S003 p.55, S007 p.65) show no extraordinary bracket; H1 2024 deck mentions only a qualitative supply disruption.',
        'If undisclosed one-offs existed in 2023/24, the 2023/24 adjusted baseline would be higher and the recovery weaker than shown.'),
('A-02','No additional US import tariffs before April 2025; treated as 0.',
        'v_ebit_adjusted, v_ebit_bridge_yoy',
        'Section 232 auto tariffs took effect 3 April 2025 (Phase 1 research); Porsche first reports tariff costs in H1 2025.',
        'Low: pre-2025 MFN duties are part of normal cost of sales.'),
('A-03','Impairments inside automotive D&A are 0 where not disclosed (2023-H2, 2024-H2).',
        'v_da_clean, v_ebit_adjusted (level L3), v_ebit_bridge_yoy',
        'H1 2023 and H1 2024 segment notes show automotive impairments of 0/nil; FY2023/FY2024 amounts could not be verified (audit.data_gap).',
        'Any undisclosed H2 2023/24 impairment would lower clean D&A for those periods.'),
('A-04','H1 2026 impairments of EUR 61m (eBike 43 + Cellforce 18) are inside automotive D&A.',
        'v_da_clean, v_ebit_adjusted (L3), v_ebit_bridge_yoy',
        'Both are published impairments of automotive subsidiaries; their line item is not confirmed (Inputs M-row note).',
        'Alternative 0: clean D&A +61m, L3 -61m in H1 2026; shown as a sensitivity column.'),
('A-05','FY2026 automotive revenue = group revenue guidance x H1 2026 automotive share of group revenue (88.0%).',
        'v_guidance_2026_auto',
        'Porsche guides automotive margins but not automotive revenue.',
        'The share fell steadily from 92.5% (2023-H1) to 88.0% (2026-H1) as Financial Services grew. Tested: +/-1pp share moves the implied H2 2026 automotive EBITDA margin by only ~0.05pp (13.83%-13.92% at mid guidance).'),
('A-06','FY2026 extraordinary-expense guidance (EUR 0.8-0.9bn) is on the same net basis as the H1 2026 figure (EUR ~0.1bn).',
        'v_guidance_2026',
        'CFO: net effect ~EUR 100m in H1, EUR 800-900m for the full year (S027). Consistent with Porsche press release S018: realignment costs expected to reach a three-digit-million amount in H2 2026.',
        'If the guidance were gross of provision releases, implied H2 exceptional charges would be lower.'),
('A-07','H2 2026 tariff expense = H1 2026 tariff expense (EUR 0.4bn).',
        'v_guidance_2026 (level L2 only)',
        'No primary full-year 2026 tariff figure was verified. A secondary summary of the Q1 2026 call (Quartr) cites ~EUR 700m for FY2026, which would imply ~EUR 300m in H2.',
        'Level L2 only; L0 and L1 do not depend on it. Using EUR 300m instead of 400m lowers the implied H2 L2 margin by ~0.55pp.'),
('A-08','Guidance ranges are combined as a grid of low / mid / high values, treated as independent.',
        'v_guidance_2026, v_guidance_2026_auto',
        'Porsche gives ranges without saying which ends go together.',
        'Extreme corners (low revenue with high margin) are included, so the range is wide on purpose.'),
('A-09','Derived H2 values inherit rounding of their inputs (one-offs EUR 0.1bn -> +/-EUR 100m on H2 one-offs).',
        'all views using H2 one-off values',
        'H2 = FY - H1; both inputs rounded to EUR 0.1bn.',
        'Shown as rounding_band_eur_m in v_ebit_adjusted.');

-- ---------------------------------------------------------------------
-- Verified qualitative notes by period (for dashboard tooltips)
-- ---------------------------------------------------------------------
CREATE TABLE mart.annotation (
    period_code varchar(8) NOT NULL REFERENCES core.dim_period(period_code),
    topic       varchar(30) NOT NULL,
    note        text NOT NULL,
    source_id   varchar(10) NOT NULL REFERENCES audit.dim_source(source_id),
    source_ref  varchar(60) NOT NULL,
    PRIMARY KEY (period_code, topic)
);
INSERT INTO mart.annotation VALUES
('2026-H1','Cash flow','Net cash flow improved despite cash-outs of ~EUR 0.4bn (first Audi licence tranche, realignment); ~EUR 0.3bn additional outflow for pension funding.','S016','slide 13'),
('2026-H1','Exceptional items','Realignment net burden ~EUR 0.1bn = ~EUR 0.4bn charges less ~EUR 0.3bn provision release after supplier settlements.','S016','slides 6, 11'),
('2026-H1','R&D','Expensed R&D increased: higher amortisation of previously capitalised development costs and lower capitalisation.','S016','slide 6'),
('2025-H1','Exceptional items','~EUR 1.1bn extraordinary expenses: strategic realignment, battery activities (Cellforce write-downs), US tariffs.','S009','slides 24, 28'),
('2025-H1','Cash flow','Net cash flow included ~EUR 0.5bn cash-outs for strategic realignment and US tariffs.','S009','slide 35'),
('2025-FY','Exceptional items','~EUR 3.9bn extraordinary expenses: realignment & product strategy 2.4, battery 0.7, US tariffs 0.7 (EUR bn).','S011','slide 6'),
('2025-FY','D&A','2025 automotive D&A includes ~EUR 1,200m impairment losses from the strategic realignment.','S011','slide 34');

-- ---------------------------------------------------------------------
-- View catalogue (filled by 09 together with each view)
-- ---------------------------------------------------------------------
CREATE TABLE mart.view_catalog (
    view_name        varchar(60) PRIMARY KEY,
    grain            text NOT NULL,
    measures         text NOT NULL,
    formula_logic    text NOT NULL,
    assumptions      text NOT NULL,
    limitations      text NOT NULL,
    source_lineage   text NOT NULL
);

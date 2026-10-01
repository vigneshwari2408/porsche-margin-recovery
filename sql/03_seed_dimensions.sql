-- =====================================================================
-- PCL Porsche Company Lens - 03_seed_dimensions.sql
-- Fixed reference data that does not come from a file.
-- =====================================================================

-- ---------------------------------------------------------------------
-- dim_period: every quarter, half-year, 9-month and full-year period 2022-2026
-- ---------------------------------------------------------------------
INSERT INTO core.dim_period (
    period_code, period_type, fiscal_year, half_no, quarter_no,
    start_date, end_date, months, sort_key, period_label,
    is_half_year, in_analysis_window)
SELECT
    y.yr || '-' || p.suffix                                         AS period_code,
    p.ptype,
    y.yr,
    p.half_no,
    p.quarter_no,
    make_date(y.yr, p.start_month, 1)                               AS start_date,
    (make_date(y.yr, p.start_month, 1)
        + make_interval(months => p.months) - interval '1 day')::date AS end_date,
    p.months,
    y.yr * 100 + p.sort_offset                                      AS sort_key,
    p.suffix || ' ' || y.yr                                         AS period_label,
    p.ptype IN ('H1','H2')                                          AS is_half_year,
    p.ptype IN ('H1','H2')
      AND make_date(y.yr, p.start_month, 1) BETWEEN DATE '2023-01-01' AND DATE '2026-01-01'
                                                                    AS in_analysis_window
FROM generate_series(2022, 2026) AS y(yr)
CROSS JOIN (VALUES
    -- suffix, type,  half, quarter, start month, months, sort offset
    ('Q1', 'QTR', 1,    1,    1,  3, 10),
    ('Q2', 'QTR', 1,    2,    4,  3, 20),
    ('H1', 'H1',  1,    NULL, 1,  6, 25),
    ('Q3', 'QTR', 2,    3,    7,  3, 30),
    ('9M', '9M',  NULL, NULL, 1,  9, 35),
    ('Q4', 'QTR', 2,    4,    10, 3, 40),
    ('H2', 'H2',  2,    NULL, 7,  6, 45),
    ('FY', 'FY',  NULL, NULL, 1, 12, 50)
) AS p(suffix, ptype, half_no, quarter_no, start_month, months, sort_offset);

-- ---------------------------------------------------------------------
-- dim_model: model lines exactly as Porsche reports deliveries
-- ---------------------------------------------------------------------
INSERT INTO core.dim_model (model_id, model_name, model_family, body_type, powertrain, parent_model_id, is_subtotal, sort_order) VALUES
('911',     '911',       '911',      'Sports car', 'ICE (incl. T-Hybrid)',                                   NULL,  FALSE, 1),
('718',     '718 Boxster/Cayman', '718', 'Sports car', 'ICE (production ended Oct 2025)',                   NULL,  FALSE, 2),
('TAY',     'Taycan',    'Taycan',   'Sedan',      'BEV',                                                    NULL,  FALSE, 3),
('PAN',     'Panamera',  'Panamera', 'Sedan',      'ICE / PHEV',                                             NULL,  FALSE, 4),
('MAC',     'Macan (total)', 'Macan', 'SUV',       'Mixed (subtotal of ICE and BEV)',                        NULL,  TRUE,  5),
('MAC_ICE', 'Macan ICE', 'Macan',    'SUV',        'ICE',                                                    'MAC', FALSE, 6),
('MAC_BEV', 'Macan BEV', 'Macan',    'SUV',        'BEV',                                                    'MAC', FALSE, 7),
('CAY',     'Cayenne',   'Cayenne',  'SUV',        'ICE / PHEV (BEV version delivered from late June 2026)', NULL,  FALSE, 8);

-- ---------------------------------------------------------------------
-- dim_region: Porsche sales regions
-- ---------------------------------------------------------------------
INSERT INTO core.dim_region (region_id, region_name, porsche_label, sort_order) VALUES
('NA',  'North America',               'North America (excluding Mexico)', 1),
('EU',  'Europe excl. Germany',        'Europe (excluding Germany)',       2),
('DE',  'Germany',                     'Germany',                          3),
('CN',  'China',                       'China (including Hong Kong)',      4),
('OEM', 'Overseas & Emerging Markets', 'Overseas and Emerging Markets',    5);

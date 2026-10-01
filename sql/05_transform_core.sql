-- =====================================================================
-- PCL Porsche Company Lens - 05_transform_core.sql
-- Moves staging data into the keyed core model.
-- Rules:
--   * Fact sheet: only S025 (latest file; S024 was proven identical, AF-06/QC2).
--   * Fact-sheet money is stored by Porsche in EUR -> converted to EUR m.
--   * Each (period, variable) is stored once; duplicates in the Porsche file
--     (same number in the quarter block and the YTD block) are collapsed.
--   * Manual inputs keep their FACT/DERIVED label, source and page.
-- =====================================================================

-- ---------------- audit reference tables ----------------
INSERT INTO audit.dim_source
SELECT source_id, tier, publisher, document_title, doc_type, reporting_period,
       publication_date, url, file_name, notes
FROM stg.source_register;

INSERT INTO audit.audit_finding
SELECT af_id, question, evidence, finding, status, consequence
FROM stg.audit_findings;

-- ---------------- dim_variable ----------------
INSERT INTO core.dim_variable
SELECT var_id, var_name, var_group, segment, measure_type, aggregation, unit_std,
       lower(is_memo) = 'true', definition, NULLIF(comparability_note, '')
FROM stg.variable_dictionary;

-- ---------------- fact_financial: fact sheet ----------------
INSERT INTO core.fact_financial
    (period_code, var_id, value, unit_std, value_label, origin, source_id, source_ref, rounding, note)
SELECT DISTINCT ON (f.period, f.var_id)
    f.period,
    f.var_id,
    CASE WHEN f.unit = 'EUR' THEN round(f.value / 1000000.0, 6) ELSE f.value END,
    v.unit_std,
    'FACT',
    'FACTSHEET',
    f.source_id,
    f.sheet || ' ' || f.cell,
    CASE WHEN f.unit = 'EUR' THEN 'exact (EUR, converted to EUR m)' ELSE 'exact' END,
    NULLIF(f.flags, '')
FROM stg.fact_sheet_long f
JOIN core.dim_variable v ON v.var_id = f.var_id
WHERE f.source_id = 'S025'
  AND f.var_id NOT LIKE 'O02\_%'
  AND f.var_id NOT LIKE 'O03\_%'
ORDER BY f.period, f.var_id,
         CASE f.block WHEN 'QTR' THEN 0 ELSE 1 END,   -- prefer the discrete-quarter block
         f.sheet;

-- ---------------- fact_financial: manual PDF inputs ----------------
INSERT INTO core.fact_financial
    (period_code, var_id, value, unit_std, value_label, origin, source_id, source_ref, rounding, note)
SELECT m.period_code, m.var_id, m.value_std, m.std_unit, m.value_label, 'MANUAL',
       m.source_id, m.source_page, NULLIF(m.rounding, ''),
       m.rec_id || ' | double-checked: ' || coalesce(m.double_checked, '?') || ' | ' || coalesce(m.verification_basis, '') || ' | ' || coalesce(m.note, '')
FROM stg.manual_inputs m;

-- ---------------- deliveries by model ----------------
INSERT INTO core.fact_deliveries_model
    (period_code, model_id, deliveries, value_label, origin, source_id, source_ref)
SELECT DISTINCT ON (f.period, f.var_id)
    f.period,
    CASE f.var_id
        WHEN 'O02_911'     THEN '911'
        WHEN 'O02_718'     THEN '718'
        WHEN 'O02_CAY'     THEN 'CAY'
        WHEN 'O02_PAN'     THEN 'PAN'
        WHEN 'O02_MAC'     THEN 'MAC'
        WHEN 'O02_MAC_ICE' THEN 'MAC_ICE'
        WHEN 'O02_MAC_BEV' THEN 'MAC_BEV'
        WHEN 'O02_TAY'     THEN 'TAY'
    END,
    f.value::int, 'FACT', 'FACTSHEET', f.source_id, f.sheet || ' ' || f.cell
FROM stg.fact_sheet_long f
WHERE f.source_id = 'S025' AND f.var_id LIKE 'O02\_%'
ORDER BY f.period, f.var_id, CASE f.block WHEN 'QTR' THEN 0 ELSE 1 END;

-- ---------------- deliveries by region ----------------
INSERT INTO core.fact_deliveries_region
    (period_code, region_id, deliveries, value_label, origin, source_id, source_ref)
SELECT DISTINCT ON (f.period, f.var_id)
    f.period,
    substring(f.var_id FROM 5),          -- O03_DE -> DE
    f.value::int, 'FACT', 'FACTSHEET', f.source_id, f.sheet || ' ' || f.cell
FROM stg.fact_sheet_long f
WHERE f.source_id = 'S025' AND f.var_id LIKE 'O03\_%'
ORDER BY f.period, f.var_id, CASE f.block WHEN 'QTR' THEN 0 ELSE 1 END;

-- ---------------- documented data gaps ----------------
INSERT INTO audit.data_gap (var_id, period_code, source_id, source_ref, reason)
SELECT var_id, period_code, source_id, source_page, reason
FROM stg.data_gaps;

-- Row counts after transformation
SELECT 'core.fact_financial' AS table_name, origin, count(*) AS row_count
FROM core.fact_financial GROUP BY origin
UNION ALL SELECT 'core.fact_deliveries_model',  'FACTSHEET', count(*) FROM core.fact_deliveries_model
UNION ALL SELECT 'core.fact_deliveries_region', 'FACTSHEET', count(*) FROM core.fact_deliveries_region
ORDER BY 1, 2;

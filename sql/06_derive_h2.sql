-- =====================================================================
-- PCL Porsche Company Lens - 06_derive_h2.sql
-- Porsche publishes H1 and FY, not H2. The analysis grain is the half-year,
-- so H2 is DERIVED here - transparently and only where it is valid:
--   * flows (aggregation = SUM):  H2 = FY - H1
--   * stocks (aggregation = LAST): H2 period-end value = FY period-end value
--   * ratios / per-share (aggregation = NONE): NOT derived here; they are
--     recalculated from their components in the analysis layer (Phase 4).
-- Every derived row: value_label = 'DERIVED', origin = 'SQL_DERIVED',
-- source_ref states the formula. Rounding of the coarser input is inherited.
-- =====================================================================

-- ---------------- step 0: component identity (before H2) ----------------
-- H1 2023 depreciation on capex (A11) is not published, but its two
-- neighbours are: A11 = A12 (total D&A incl. impairments) - A09 (amortisation).
-- Only filled where A11 is missing and both components exist.
INSERT INTO core.fact_financial
    (period_code, var_id, value, unit_std, value_label, origin, source_id, source_ref, rounding, note)
SELECT a12.period_code, 'A11', a12.value - a09.value, 'EUR m', 'DERIVED', 'SQL_DERIVED', NULL,
       'A12 - A09: ' || a12.source_id || ' ' || a12.source_ref || ' minus ' || a09.source_id || ' ' || a09.source_ref,
       'derived from EUR 1m inputs', 'Identity A12 = A09 + A11 (confirmed in every published period, DQ08)'
FROM core.fact_financial a12
JOIN core.fact_financial a09 ON a09.period_code = a12.period_code AND a09.var_id = 'A09'
WHERE a12.var_id = 'A12'
  AND NOT EXISTS (SELECT 1 FROM core.fact_financial x WHERE x.period_code = a12.period_code AND x.var_id = 'A11');

-- ---------------- financial variables ----------------
INSERT INTO core.fact_financial
    (period_code, var_id, value, unit_std, value_label, origin, source_id, source_ref, rounding, note)
SELECT
    fy.period_code_h2,
    fy.var_id,
    CASE v.aggregation WHEN 'SUM' THEN fy.value - h1.value ELSE fy.value END,
    fy.unit_std,
    'DERIVED',
    'SQL_DERIVED',
    NULL,
    CASE v.aggregation
        WHEN 'SUM'  THEN 'FY - H1: ' || fy.period_code || ' (' || coalesce(fy.source_id, 'SQL derived') || ') minus ' || h1.period_code || ' (' || coalesce(h1.source_id, 'SQL derived') || ')'
        ELSE 'Period-end value = ' || fy.period_code || ' (' || coalesce(fy.source_id, 'SQL derived') || ')'
    END,
    CASE WHEN v.aggregation = 'SUM'
         THEN 'derived; inputs rounded: FY ' || coalesce(fy.rounding, '?') || ' / H1 ' || coalesce(h1.rounding, '?')
         ELSE fy.rounding END,
    CASE WHEN v.is_memo THEN 'MEMO item - do not add to totals' END
FROM (
    SELECT f.*, left(f.period_code, 4) || '-H2' AS period_code_h2
    FROM core.fact_financial f
    WHERE f.period_code LIKE '%-FY'
) fy
JOIN core.dim_variable v ON v.var_id = fy.var_id AND v.aggregation IN ('SUM', 'LAST')
LEFT JOIN core.fact_financial h1
       ON h1.var_id = fy.var_id AND h1.period_code = left(fy.period_code, 4) || '-H1'
WHERE (v.aggregation = 'LAST' OR h1.value IS NOT NULL)
  AND NOT EXISTS (SELECT 1 FROM core.fact_financial x
                  WHERE x.var_id = fy.var_id AND x.period_code = fy.period_code_h2);

-- ---------------- deliveries by model ----------------
INSERT INTO core.fact_deliveries_model
    (period_code, model_id, deliveries, value_label, origin, source_id, source_ref)
SELECT left(fy.period_code, 4) || '-H2', fy.model_id, fy.deliveries - h1.deliveries,
       'DERIVED', 'SQL_DERIVED', NULL, 'FY - H1 (fact sheet S025)'
FROM core.fact_deliveries_model fy
JOIN core.fact_deliveries_model h1
  ON h1.model_id = fy.model_id AND h1.period_code = left(fy.period_code, 4) || '-H1'
WHERE fy.period_code LIKE '%-FY';

-- ---------------- deliveries by region ----------------
INSERT INTO core.fact_deliveries_region
    (period_code, region_id, deliveries, value_label, origin, source_id, source_ref)
SELECT left(fy.period_code, 4) || '-H2', fy.region_id, fy.deliveries - h1.deliveries,
       'DERIVED', 'SQL_DERIVED', NULL, 'FY - H1 (fact sheet S025)'
FROM core.fact_deliveries_region fy
JOIN core.fact_deliveries_region h1
  ON h1.region_id = fy.region_id AND h1.period_code = left(fy.period_code, 4) || '-H1'
WHERE fy.period_code LIKE '%-FY';

-- How many H2 rows were derived, by variable group
SELECT v.var_group, count(*) AS derived_h2_rows
FROM core.fact_financial f JOIN core.dim_variable v USING (var_id)
WHERE f.origin = 'SQL_DERIVED'
GROUP BY v.var_group ORDER BY v.var_group;

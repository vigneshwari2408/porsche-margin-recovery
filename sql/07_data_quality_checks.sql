-- =====================================================================
-- PCL Porsche Company Lens - 07_data_quality_checks.sql
-- Every check writes rows to audit.dq_result (PASS / FAIL / INFO).
-- Run after 06. Expected result: zero FAIL rows (see summary at the end).
-- =====================================================================
TRUNCATE audit.dq_result;

-- helper view: one value per (period, var) for quick look-ups
CREATE OR REPLACE VIEW core.v_value AS
SELECT period_code, var_id, value FROM core.fact_financial;

-- DQ01 Fact sheet: quarters add up to the reported YTD totals (flows, 2023+)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'DQ01', 'Quarters sum to reported YTD (fact sheet)', y.period_code, y.var_id,
       y.value, q.qsum, q.qsum - y.value, 0.01,
       CASE WHEN abs(q.qsum - y.value) <= 0.01 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_financial y
JOIN core.dim_period p ON p.period_code = y.period_code AND p.period_type IN ('H1','9M','FY')
JOIN core.dim_variable v ON v.var_id = y.var_id AND v.aggregation = 'SUM'
JOIN LATERAL (
    SELECT sum(q.value) AS qsum, count(*) AS n
    FROM core.fact_financial q JOIN core.dim_period pq ON pq.period_code = q.period_code
    WHERE q.var_id = y.var_id AND pq.period_type = 'QTR'
      AND pq.fiscal_year = p.fiscal_year AND pq.end_date <= p.end_date
) q ON q.n = p.months / 3
WHERE y.origin = 'FACTSHEET' AND p.fiscal_year >= 2023;

-- DQ02 Derived H2 (FY - H1) equals Q3 + Q4 where quarters exist (fact-sheet variables)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'DQ02', 'Derived H2 = Q3 + Q4', h2.period_code, h2.var_id,
       q.qsum, h2.value, h2.value - q.qsum, 0.01,
       CASE WHEN abs(h2.value - q.qsum) <= 0.01 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_financial h2
JOIN core.dim_period p ON p.period_code = h2.period_code AND p.period_type = 'H2'
JOIN LATERAL (
    SELECT sum(q.value) AS qsum, count(*) AS n
    FROM core.fact_financial q
    WHERE q.var_id = h2.var_id
      AND q.period_code IN (p.fiscal_year || '-Q3', p.fiscal_year || '-Q4')
) q ON q.n = 2
WHERE h2.origin = 'SQL_DERIVED' AND p.fiscal_year >= 2023;

-- DQ03 Model lines add up to total deliveries (Macan subtotal excluded)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'DQ03', 'Deliveries by model = total deliveries (O01)', t.period_code, 'models',
       t.value, m.s, m.s - t.value, 0,
       CASE WHEN m.s = t.value THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_financial t
JOIN (SELECT d.period_code, sum(d.deliveries) AS s
      FROM core.fact_deliveries_model d JOIN core.dim_model m USING (model_id)
      WHERE m.parent_model_id IS NULL  -- top-level lines incl. Macan total (ICE/BEV split only exists from FY2024; checked in DQ05)
      GROUP BY d.period_code) m ON m.period_code = t.period_code
WHERE t.var_id = 'O01';

-- DQ04 Regions add up to total deliveries
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'DQ04', 'Deliveries by region = total deliveries (O01)', t.period_code, 'regions',
       t.value, r.s, r.s - t.value, 0,
       CASE WHEN r.s = t.value THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_financial t
JOIN (SELECT period_code, sum(deliveries) AS s FROM core.fact_deliveries_region GROUP BY period_code) r
  ON r.period_code = t.period_code
WHERE t.var_id = 'O01';

-- DQ05 Macan ICE + Macan BEV = Macan
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'DQ05', 'Macan ICE + BEV = Macan total', mac.period_code, 'MAC',
       mac.deliveries, ice.deliveries + bev.deliveries, ice.deliveries + bev.deliveries - mac.deliveries, 0,
       CASE WHEN ice.deliveries + bev.deliveries = mac.deliveries THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_deliveries_model mac
JOIN core.fact_deliveries_model ice ON ice.period_code = mac.period_code AND ice.model_id = 'MAC_ICE'
JOIN core.fact_deliveries_model bev ON bev.period_code = mac.period_code AND bev.model_id = 'MAC_BEV'
WHERE mac.model_id = 'MAC';

-- DQ06 Group EBIT = gross profit + distribution + administration + other (2023+)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'DQ06', 'G07 = G03 + G04 + G05 + G06', e.period_code, 'G07',
       e.value, s.s, s.s - e.value, 0.01,
       CASE WHEN abs(s.s - e.value) <= 0.01 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_financial e
JOIN (SELECT period_code, sum(value) AS s, count(*) AS n FROM core.fact_financial
      WHERE var_id IN ('G03','G04','G05','G06') GROUP BY period_code) s
  ON s.period_code = e.period_code AND s.n = 4
WHERE e.var_id = 'G07' AND left(e.period_code, 4)::int >= 2023;

-- DQ07 Automotive EBITDA = automotive EBIT + D&A (incl. impairments)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'DQ07', 'A03 = A02 + A12', a03.period_code, 'A03',
       a03.value, a02.value + a12.value, a02.value + a12.value - a03.value, 1,
       CASE WHEN abs(a02.value + a12.value - a03.value) <= 1 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_financial a03
JOIN core.fact_financial a02 ON a02.period_code = a03.period_code AND a02.var_id = 'A02'
JOIN core.fact_financial a12 ON a12.period_code = a03.period_code AND a12.var_id = 'A12'
WHERE a03.var_id = 'A03';

-- DQ08 R&D: total = capitalised + expensed ; D&A: total = amortisation + depreciation on capex
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'DQ08', 'A05 = A06 + A08', a.period_code, 'A05', a.value, b.value + c.value, b.value + c.value - a.value, 2,
       CASE WHEN abs(b.value + c.value - a.value) <= 2 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_financial a
JOIN core.fact_financial b ON b.period_code = a.period_code AND b.var_id = 'A06'
JOIN core.fact_financial c ON c.period_code = a.period_code AND c.var_id = 'A08'
WHERE a.var_id = 'A05'
UNION ALL
SELECT 'DQ08', 'A12 = A09 + A11', a.period_code, 'A12', a.value, b.value + c.value, b.value + c.value - a.value, 2,
       CASE WHEN abs(b.value + c.value - a.value) <= 2 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_financial a
JOIN core.fact_financial b ON b.period_code = a.period_code AND b.var_id = 'A09'
JOIN core.fact_financial c ON c.period_code = a.period_code AND c.var_id = 'A11'
WHERE a.var_id = 'A12';

-- DQ09 Porsche EBIT bridge: same period prior year EBIT + B01..B04 = EBIT
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'DQ09', 'Prior-year EBIT + bridge buckets = EBIT', cur.period_code, 'G07',
       cur.value, prv.value + b.s, prv.value + b.s - cur.value, b.tol,
       CASE WHEN abs(prv.value + b.s - cur.value) <= b.tol THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_financial cur
JOIN core.dim_period p ON p.period_code = cur.period_code
JOIN core.fact_financial prv
  ON prv.var_id = 'G07' AND prv.period_code = (p.fiscal_year - 1) || substring(cur.period_code FROM 5)
JOIN (SELECT period_code, sum(value) AS s, count(*) AS n,
             CASE WHEN bool_or(rounding LIKE '%0.1bn%') THEN 250 ELSE 50 END AS tol
      FROM core.fact_financial WHERE var_id IN ('B01','B02','B03','B04') GROUP BY period_code) b
  ON b.period_code = cur.period_code AND b.n = 4
WHERE cur.var_id = 'G07';

-- DQ10 Units: every fact row uses the unit defined for its variable
INSERT INTO audit.dq_result (check_id, check_name, item, actual, status)
SELECT 'DQ10', 'Unit of fact rows matches dim_variable.unit_std', 'rows with unit mismatch',
       count(*), CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_financial f JOIN core.dim_variable v USING (var_id)
WHERE f.unit_std <> v.unit_std;

-- DQ11 No ratio or per-share variable was derived by subtraction
INSERT INTO audit.dq_result (check_id, check_name, item, actual, status)
SELECT 'DQ11', 'Ratios never derived by FY - H1', 'rows violating rule',
       count(*), CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_financial f JOIN core.dim_variable v USING (var_id)
WHERE f.origin = 'SQL_DERIVED' AND v.aggregation = 'NONE';

-- DQ12 Coverage of the analysis window (INFO): which half-year values are missing, and why
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, status)
SELECT 'DQ12', 'Missing half-year value in analysis window: '
               || coalesce(g.reason, 'not published / not applicable for this period'),
       p.period_code, v.var_id, 'INFO'
FROM core.dim_period p
CROSS JOIN core.dim_variable v
LEFT JOIN core.fact_financial f ON f.period_code = p.period_code AND f.var_id = v.var_id
LEFT JOIN audit.data_gap g ON g.period_code = p.period_code AND g.var_id = v.var_id
WHERE p.in_analysis_window
  AND v.var_id IN ('G01','G07','A01','A02','A03','A05','A06','A08','A09','A10','A11','A12',
                   'A13','A14','F01','F02','B01','B02','B03','B04','X01','X03','X05','O01','O04')
  AND f.var_id IS NULL;

-- DQ13 Segment bridge to group revenue (INFO): Auto + FS - Group = consolidation
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, status)
SELECT 'DQ13', 'Automotive + Financial Services revenue vs group revenue (difference = consolidation)',
       g.period_code, 'G01', g.value, a.value + fs.value, a.value + fs.value - g.value, 'INFO'
FROM core.fact_financial g
JOIN core.fact_financial a  ON a.period_code  = g.period_code AND a.var_id  = 'A01'
JOIN core.fact_financial fs ON fs.period_code = g.period_code AND fs.var_id = 'F01'
WHERE g.var_id = 'G01';

-- ---------------- summary ----------------
SELECT check_id, check_name_short, count(*) FILTER (WHERE status = 'PASS') AS pass,
       count(*) FILTER (WHERE status = 'FAIL') AS fail,
       count(*) FILTER (WHERE status = 'INFO') AS info
FROM (SELECT check_id, split_part(check_name, ':', 1) AS check_name_short, status FROM audit.dq_result) x
GROUP BY check_id, check_name_short
ORDER BY check_id;

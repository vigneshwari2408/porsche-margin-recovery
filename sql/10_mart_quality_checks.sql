-- =====================================================================
-- PCL Porsche Company Lens - 10_mart_quality_checks.sql   (Phase 4)
-- Data-quality checks on every analytical view. Results go to
-- audit.dq_result with check_id 'MQnn'. Expected: 0 FAIL.
-- Re-runnable (deletes previous MQ rows first).
-- =====================================================================
DELETE FROM audit.dq_result WHERE check_id LIKE 'MQ%';

-- Published reference ratios used only for reconciliation (FACT, verbatim from decks)
CREATE TEMP TABLE ref_published (period_code varchar(8), metric varchar(20), value numeric, source_ref text);
INSERT INTO ref_published VALUES
('2024-H1','ros',15.7,'S009 slide 27'),
('2025-H1','ros', 5.5,'S016 slide 5'),
('2026-H1','ros', 7.8,'S016 slide 5'),
('2024-H1','ncf_margin',6.3,'S009 slide 35'),
('2025-H1','ncf_margin',2.4,'S016 slide 13'),
('2026-H1','ncf_margin',6.7,'S016 slide 13');

-- ---------------- v_panel_hy ----------------
-- MQ01 exactly 7 half-year rows, one per period
INSERT INTO audit.dq_result (check_id, check_name, item, expected, actual, status)
SELECT 'MQ01', 'v_panel_hy: 7 unique half-year rows (2023-H1..2026-H1)', 'rows', 7, count(DISTINCT period_code),
       CASE WHEN count(*) = 7 AND count(DISTINCT period_code) = 7 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_panel_hy;

-- MQ02 pivot loses nothing: every core value in the window appears in the panel
INSERT INTO audit.dq_result (check_id, check_name, item, expected, actual, difference, status)
SELECT 'MQ02', 'v_panel_hy: panel holds every core value of the analysis window (pivot completeness)', 'values',
       c.n, p.n, p.n - c.n, CASE WHEN p.n = c.n THEN 'PASS' ELSE 'FAIL' END
FROM (SELECT count(*) AS n FROM core.fact_financial f JOIN core.dim_period d USING (period_code)
      WHERE d.in_analysis_window
        AND f.var_id IN ('G01','G02','G03','G04','G05','G06','G07','A01','A02','A03','A04','A05','A06','A07','A08',
                         'A09','A10','A11','A12','A13a','A13b','A13','A14','F01','F02','X01','X02','X03','X04','X05',
                         'B01','B02','B03','B04','B05','O01','O04','O06','O07')) c,
     (SELECT sum(n_fact_values + n_derived_values) AS n FROM mart.v_panel_hy) p;

-- MQ03 every H2 row is made of DERIVED values only where Porsche publishes no H2 (sanity: H2 rows carry derived values)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, actual, status)
SELECT 'MQ03', 'v_panel_hy: H2 rows are flagged as containing DERIVED values', period_code, 'n_derived_values',
       n_derived_values, CASE WHEN n_derived_values > 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_panel_hy WHERE half_no = 2;

-- ---------------- v_ebit_adjusted ----------------
-- MQ04 L0 equals core group EBIT
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ04', 'v_ebit_adjusted: L0 = core G07', a.period_code, 'ebit_l0', f.value, a.ebit_l0_reported,
       a.ebit_l0_reported - f.value, 0.001,
       CASE WHEN abs(a.ebit_l0_reported - f.value) <= 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_ebit_adjusted a JOIN core.fact_financial f ON f.period_code = a.period_code AND f.var_id = 'G07';

-- MQ05 adjustment ladder: L1-L0 = X01, L2-L1 = X03 (no impairment added on top -> no double count)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ05', 'v_ebit_adjusted: L2 - L0 = realignment (X01) + tariffs (X03) only', period_code, 'L2-L0',
       adj_realignment_net + adj_us_tariffs, ebit_l2_ex_realignment_tariffs - ebit_l0_reported,
       (ebit_l2_ex_realignment_tariffs - ebit_l0_reported) - (adj_realignment_net + adj_us_tariffs), 0.001,
       CASE WHEN abs((ebit_l2_ex_realignment_tariffs - ebit_l0_reported) - (adj_realignment_net + adj_us_tariffs)) <= 0.001
            THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_ebit_adjusted;

-- MQ06 reported margin reconciles to Porsche's published return on sales (rounded to 0.1pp)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ06', 'v_ebit_adjusted: L0 margin = published group RoS (' || r.source_ref || ')', a.period_code, 'margin_l0',
       r.value, a.margin_l0_reported_pct, a.margin_l0_reported_pct - r.value, 0.05,
       CASE WHEN abs(a.margin_l0_reported_pct - r.value) <= 0.05 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_ebit_adjusted a JOIN ref_published r ON r.period_code = a.period_code AND r.metric = 'ros';

-- MQ07 L3 identity: L3 = L1 + clean D&A - capitalised R&D
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ07', 'v_ebit_adjusted: L3 (supplementary hybrid) = L1 + clean D&A - capitalised R&D', a.period_code, 'ebit_l3',
       a.ebit_l1_ex_realignment + d.da_clean - p.rd_capitalised, a.ebit_l3_hybrid_sensitivity,
       a.ebit_l3_hybrid_sensitivity - (a.ebit_l1_ex_realignment + d.da_clean - p.rd_capitalised), 0.001,
       CASE WHEN abs(a.ebit_l3_hybrid_sensitivity - (a.ebit_l1_ex_realignment + d.da_clean - p.rd_capitalised)) <= 0.001
            THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_ebit_adjusted a JOIN mart.v_da_clean d USING (period_code) JOIN mart.v_panel_hy p USING (period_code);

-- MQ08 assumption register is complete: every assumption ID cited by a view exists
INSERT INTO audit.dq_result (check_id, check_name, item, actual, status)
SELECT 'MQ08', 'v_ebit_adjusted / guidance views: every cited assumption exists in mart.assumption', 'missing IDs',
       count(*), CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT trim(split_part(x, ':', 1)) AS aid
    FROM (SELECT unnest(string_to_array(assumptions_used, ';')) AS x FROM mart.v_ebit_adjusted
          UNION ALL SELECT unnest(string_to_array(regexp_replace(assumptions_used, '\s*\(.*?\)', '', 'g'), ';')) FROM mart.v_guidance_2026
          UNION ALL SELECT unnest(string_to_array(assumptions_used, ';')) FROM mart.v_guidance_2026_auto) u
    WHERE trim(x) <> ''
) c
WHERE aid NOT IN (SELECT assumption_id FROM mart.assumption);

-- ---------------- v_da_clean ----------------
-- MQ09 clean D&A = total - impairment, never negative, never above total
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, status)
SELECT 'MQ09', 'v_da_clean: da_clean = da_total - impairment_used and 0 < da_clean <= da_total', period_code, 'da_clean',
       da_total - impairment_used, da_clean, da_clean - (da_total - impairment_used),
       CASE WHEN da_clean = da_total - impairment_used AND da_clean > 0 AND da_clean <= da_total THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_da_clean;

-- MQ10 cleaned components add up to clean D&A where both are available
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ10', 'v_da_clean: clean depreciation + clean amortisation = clean D&A (Porsche rounds components to EUR 1m)', period_code, 'components',
       da_clean, dep_on_capex_clean + amort_capitalised_rd_clean,
       dep_on_capex_clean + amort_capitalised_rd_clean - da_clean, 2,
       CASE WHEN abs(dep_on_capex_clean + amort_capitalised_rd_clean - da_clean) <= 2 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_da_clean WHERE dep_on_capex_clean IS NOT NULL AND amort_capitalised_rd_clean IS NOT NULL;

-- ---------------- v_rd_capitalisation ----------------
-- MQ11 calculated capitalisation rate = published rate (0.1pp rounding)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ11', 'v_rd_capitalisation: calculated cap rate = published cap rate', period_code, 'cap_rate',
       cap_rate_published_pct, cap_rate_calc_pct, cap_rate_calc_pct - cap_rate_published_pct, 0.15,
       CASE WHEN abs(cap_rate_calc_pct - cap_rate_published_pct) <= 0.15 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_rd_capitalisation WHERE cap_rate_published_pct IS NOT NULL;

-- MQ12 P&L charge = total R&D costs - net capitalisation (identity)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ12', 'v_rd_capitalisation: P&L charge = total R&D costs - net capitalisation', period_code, 'rd_pl_charge',
       rd_total_costs - net_capitalisation, rd_pl_charge, rd_pl_charge - (rd_total_costs - net_capitalisation), 2,
       CASE WHEN abs(rd_pl_charge - (rd_total_costs - net_capitalisation)) <= 2 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_rd_capitalisation;

-- ---------------- v_asp_volume ----------------
-- MQ13 calculated ASP = Porsche published ASP (published rounded to EUR 1k)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ13', 'v_asp_volume: calculated ASP = published ASP', period_code, 'asp',
       asp_published_eur_k, asp_calc_eur_k, asp_calc_minus_published, 0.5,
       CASE WHEN abs(asp_calc_minus_published) <= 0.5 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_asp_volume WHERE asp_published_eur_k IS NOT NULL;

-- MQ14 volume effect + ASP effect = change in automotive revenue
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ14', 'v_asp_volume: volume effect + ASP effect = revenue change', period_code, 'revenue bridge',
       yoy_auto_revenue, volume_effect + asp_effect, volume_effect + asp_effect - yoy_auto_revenue, 0.5,
       CASE WHEN abs(volume_effect + asp_effect - yoy_auto_revenue) <= 0.5 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_asp_volume WHERE yoy_auto_revenue IS NOT NULL;

-- ---------------- v_delivery_mix ----------------
-- MQ15 shares add to 100% per period and dimension; units match total deliveries
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ15', 'v_delivery_mix: units by ' || m.dimension || ' = total deliveries; shares = 100%', m.period_code, m.dimension,
       p.deliveries, sum(m.deliveries), sum(m.deliveries) - p.deliveries, 0.05,
       CASE WHEN sum(m.deliveries) = p.deliveries AND abs(sum(m.share_pct) - 100) <= 0.05 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_delivery_mix m JOIN mart.v_panel_hy p USING (period_code)
GROUP BY m.period_code, m.dimension, p.deliveries;

-- ---------------- v_cash_crosscheck ----------------
-- MQ16 net cash flow = operating cash flow + investing cash flow (fact-sheet identity)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ16', 'v_cash_crosscheck: NCF = CFO + investing of current operations (AF-12: H1 2024 NCF stored rounded in S025)', period_code, 'ncf',
       auto_cfo + auto_cfi_operating, auto_net_cash_flow, auto_net_cash_flow - (auto_cfo + auto_cfi_operating), 0.5,
       CASE WHEN abs(auto_net_cash_flow - (auto_cfo + auto_cfi_operating)) <= 0.5 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_cash_crosscheck;

-- MQ17 calculated NCF margin = published NCF margin
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ17', 'v_cash_crosscheck: NCF margin = published (' || r.source_ref || ')', c.period_code, 'ncf_margin',
       r.value, c.ncf_margin_pct, c.ncf_margin_pct - r.value, 0.05,
       CASE WHEN abs(c.ncf_margin_pct - r.value) <= 0.05 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_cash_crosscheck c JOIN ref_published r ON r.period_code = c.period_code AND r.metric = 'ncf_margin';

-- MQ18 calculated EBITDA margin = published automotive EBITDA margin
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ18', 'v_cash_crosscheck: EBITDA margin = published automotive EBITDA margin', c.period_code, 'ebitda_margin',
       p.auto_ebitda_margin_published, c.ebitda_margin_calc_pct, c.ebitda_margin_calc_pct - p.auto_ebitda_margin_published, 0.05,
       CASE WHEN abs(c.ebitda_margin_calc_pct - p.auto_ebitda_margin_published) <= 0.05 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_cash_crosscheck c JOIN mart.v_panel_hy p USING (period_code)
WHERE p.auto_ebitda_margin_published IS NOT NULL;

-- ---------------- v_ebit_bridge_yoy ----------------
-- MQ19 EUR bridge closes: all effects + residual = change in EBIT
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ19', 'v_ebit_bridge_yoy: effects + residual = change in EBIT', period_code, 'EUR bridge',
       d_ebit, eff_exceptional_items + eff_us_tariffs + eff_rd_capitalisation + eff_clean_da + eff_financial_services + eff_residual_other_drivers,
       eff_exceptional_items + eff_us_tariffs + eff_rd_capitalisation + eff_clean_da + eff_financial_services + eff_residual_other_drivers - d_ebit,
       0.001,
       CASE WHEN abs(eff_exceptional_items + eff_us_tariffs + eff_rd_capitalisation + eff_clean_da
                     + eff_financial_services + eff_residual_other_drivers - d_ebit) <= 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_ebit_bridge_yoy;

-- MQ20 margin-point bridge closes (rounding of components to 0.001pp)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ20', 'v_ebit_bridge_yoy: margin-point components = change in margin', period_code, 'pp bridge',
       d_margin_pp,
       pp_revenue_denominator + pp_exceptional_items + pp_us_tariffs + pp_rd_capitalisation + pp_clean_da
         + pp_financial_services + pp_residual_other_drivers,
       pp_revenue_denominator + pp_exceptional_items + pp_us_tariffs + pp_rd_capitalisation + pp_clean_da
         + pp_financial_services + pp_residual_other_drivers - d_margin_pp,
       0.01,
       CASE WHEN abs(pp_revenue_denominator + pp_exceptional_items + pp_us_tariffs + pp_rd_capitalisation + pp_clean_da
                     + pp_financial_services + pp_residual_other_drivers - d_margin_pp) <= 0.01 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_ebit_bridge_yoy;

-- MQ21 our bridge agrees with the adjusted-EBIT view: change in L1 = R&D cap + clean D&A + FS + residual
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ21', 'v_ebit_bridge_yoy: change in L1 EBIT = non-exceptional effects (cross-view)', b.period_code, 'L1 change',
       a.yoy_ebit_l1, b.eff_us_tariffs + b.eff_rd_capitalisation + b.eff_clean_da + b.eff_financial_services + b.eff_residual_other_drivers,
       b.eff_us_tariffs + b.eff_rd_capitalisation + b.eff_clean_da + b.eff_financial_services + b.eff_residual_other_drivers - a.yoy_ebit_l1,
       0.001,
       CASE WHEN abs(b.eff_us_tariffs + b.eff_rd_capitalisation + b.eff_clean_da + b.eff_financial_services
                     + b.eff_residual_other_drivers - a.yoy_ebit_l1) <= 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_ebit_bridge_yoy b JOIN mart.v_ebit_adjusted a USING (period_code);

-- MQ22 our total change equals the sum of Porsche's own bridge buckets (within Porsche's rounding)
INSERT INTO audit.dq_result (check_id, check_name, period_code, item, expected, actual, difference, tolerance, status)
SELECT 'MQ22', 'v_ebit_bridge_yoy: change in EBIT = sum of Porsche bridge buckets B01-B04', b.period_code, 'vs Porsche bridge',
       p.bridge_gross_margin_ex_rd + p.bridge_rd + p.bridge_sga + p.bridge_other, b.d_ebit,
       b.d_ebit - (p.bridge_gross_margin_ex_rd + p.bridge_rd + p.bridge_sga + p.bridge_other),
       CASE WHEN p.half_no = 2 AND p.fiscal_year <= 2024 THEN 250 ELSE 50 END,   -- H2 2024 derived from FY2024 buckets printed to EUR 0.1bn
       CASE WHEN abs(b.d_ebit - (p.bridge_gross_margin_ex_rd + p.bridge_rd + p.bridge_sga + p.bridge_other))
                 <= CASE WHEN p.half_no = 2 AND p.fiscal_year <= 2024 THEN 250 ELSE 50 END THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_ebit_bridge_yoy b JOIN mart.v_panel_hy p USING (period_code)
WHERE p.bridge_rd IS NOT NULL;

-- ---------------- guidance views ----------------
-- MQ23 grid completeness and arithmetic: FY EBIT = H1 actual + implied H2
INSERT INTO audit.dq_result (check_id, check_name, item, expected, actual, status)
SELECT 'MQ23', 'v_guidance_2026: 27 cases; FY EBIT = H1 2026 + H2 implied; H2 revenue > 0', 'grid',
       27, count(*),
       CASE WHEN count(*) = 27
             AND bool_and(abs(fy_ebit - (h1_ebit + h2_ebit_l0)) < 0.001)
             AND bool_and(h2_rev > 0) THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_guidance_2026;

-- MQ24 hand-check of the mid case: FY EBIT = 35,500 x 6.5% = 2,307.5
INSERT INTO audit.dq_result (check_id, check_name, item, expected, actual, difference, tolerance, status)
SELECT 'MQ24', 'v_guidance_2026: mid case FY EBIT = 35,500 x 6.5%', 'fy_ebit mid',
       2307.5, fy_ebit, fy_ebit - 2307.5, 0.001,
       CASE WHEN abs(fy_ebit - 2307.5) <= 0.001 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_guidance_2026 WHERE case_rev = 'mid' AND case_ros = 'mid' AND case_ex = 'mid';

-- MQ25 summary is consistent with the grid (min <= mid <= max)
INSERT INTO audit.dq_result (check_id, check_name, item, status)
SELECT 'MQ25', 'v_guidance_2026_summary: min <= mid <= max for L0, L1, L2', 'ordering',
       CASE WHEN h2_margin_l0_min <= h2_margin_l0_mid AND h2_margin_l0_mid <= h2_margin_l0_max
             AND h2_margin_l1_min <= h2_margin_l1_mid AND h2_margin_l1_mid <= h2_margin_l1_max
             AND h2_margin_l2_min <= h2_margin_l2_mid AND h2_margin_l2_mid <= h2_margin_l2_max
            THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_guidance_2026_summary;

-- MQ26 automotive guidance view: 9 cases, implied H2 automotive revenue positive
INSERT INTO audit.dq_result (check_id, check_name, item, expected, actual, status)
SELECT 'MQ26', 'v_guidance_2026_auto: 9 cases, H2 automotive revenue > 0', 'grid', 9, count(*),
       CASE WHEN count(*) = 9 AND bool_and(h2_auto_rev > 0) THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_guidance_2026_auto;

-- ---------------- documentation ----------------
-- MQ27 every mart view is documented in mart.view_catalog, and every catalogue entry exists
INSERT INTO audit.dq_result (check_id, check_name, item, actual, status)
SELECT 'MQ27', 'mart.view_catalog: every mart view documented and every entry exists', 'undocumented or missing',
       count(*), CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT 'mart.' || table_name AS v FROM information_schema.views WHERE table_schema = 'mart'
    EXCEPT SELECT view_name FROM mart.view_catalog
    UNION ALL
    (SELECT view_name FROM mart.view_catalog
     EXCEPT SELECT 'mart.' || table_name FROM information_schema.views WHERE table_schema = 'mart')
) x;

-- MQ28 labelling guard: no misleading column names remain; L3 and guidance rows carry their labels
INSERT INTO audit.dq_result (check_id, check_name, item, actual, status)
SELECT 'MQ28', 'Labelling: no mart column named *cash_spend* / *operating_residual* / *cash_rd*', 'offending columns',
       count(*), CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM information_schema.columns
WHERE table_schema = 'mart' AND (column_name LIKE '%cash_spend%' OR column_name LIKE '%operating_residual%' OR column_name LIKE '%cash_rd%');

INSERT INTO audit.dq_result (check_id, check_name, item, actual, status)
SELECT 'MQ28', 'Labelling: every L3 row flagged as supplementary hybrid sensitivity', 'rows without label',
       count(*) FILTER (WHERE l3_label NOT LIKE '%supplementary hybrid sensitivity%' OR l3_label IS NULL),
       CASE WHEN count(*) FILTER (WHERE l3_label NOT LIKE '%supplementary hybrid sensitivity%' OR l3_label IS NULL) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.v_ebit_adjusted;

INSERT INTO audit.dq_result (check_id, check_name, item, actual, status)
SELECT 'MQ28', 'Labelling: every guidance row labelled as scenario combination (not forecast)', 'rows without label',
       count(*) FILTER (WHERE scenario_type NOT LIKE 'Scenario combination%not a forecast%'),
       CASE WHEN count(*) FILTER (WHERE scenario_type NOT LIKE 'Scenario combination%not a forecast%') = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (SELECT scenario_type FROM mart.v_guidance_2026 UNION ALL SELECT scenario_type FROM mart.v_guidance_2026_auto) g;

DROP TABLE ref_published;

-- ---------------- summary ----------------
SELECT check_id, left(check_name, 90) AS check_name,
       count(*) FILTER (WHERE status = 'PASS') AS pass,
       count(*) FILTER (WHERE status = 'FAIL') AS fail
FROM audit.dq_result WHERE check_id LIKE 'MQ%'
GROUP BY check_id, left(check_name, 90)
ORDER BY check_id, check_name;

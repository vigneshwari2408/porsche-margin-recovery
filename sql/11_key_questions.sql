-- =====================================================================
-- PCL Porsche Company Lens - 11_key_questions.sql   (Phase 4)
-- The analytical questions, answered from the mart views.
-- Run any block on its own. Nothing here writes to the database.
-- =====================================================================

-- Q1. Did the reported margin really rise from 5.5% to 7.8%? (reconciles to Porsche)
SELECT period_code, round(grp_revenue) AS revenue_eur_m, round(ebit_l0_reported) AS ebit_eur_m,
       margin_l0_reported_pct AS reported_margin_pct, yoy_margin_l0_pp
FROM mart.v_ebit_adjusted
WHERE half_no = 1
ORDER BY sort_key;

-- Q2. HEADLINE: remove the exceptional items Porsche discloses (L1, L2) - is the underlying margin improving?
SELECT period_code,
       margin_l0_reported_pct            AS l0_reported,
       margin_l1_pct                     AS l1_ex_realignment,
       margin_l2_pct                     AS l2_ex_realignment_and_tariffs,
       round(ebit_l1_ex_realignment)     AS l1_ebit_eur_m,
       round(yoy_ebit_l1)                AS l1_ebit_yoy_eur_m,
       yoy_margin_l1_pp,
       rounding_band_eur_m, assumptions_used
FROM mart.v_ebit_adjusted
ORDER BY sort_key;

-- Q3. Where did the H1 2026 vs H1 2025 change in EBIT come from? (own bridge, EUR m and margin points)
SELECT period_code, prior_period_code,
       round(d_ebit) AS change_in_ebit,
       eff_exceptional_items, eff_us_tariffs, eff_rd_capitalisation, eff_clean_da,
       round(eff_financial_services) AS eff_financial_services,
       round(eff_residual_other_drivers) AS eff_residual_other_drivers,       -- NOT operating performance: several unseparated effects
       round(eff_residual_other_drivers_alt_a04) AS residual_other_if_a04_false
FROM mart.v_ebit_bridge_yoy
ORDER BY sort_key;

SELECT period_code, d_margin_pp, pp_exceptional_items, pp_us_tariffs, pp_rd_capitalisation,
       pp_clean_da, pp_financial_services, pp_revenue_denominator, pp_residual_other_drivers
FROM mart.v_ebit_bridge_yoy
ORDER BY sort_key;

-- Q4. Non-cash effects: is lower R&D capitalisation or depreciation flattering / hurting EBIT?
SELECT period_code, rd_total_costs, rd_capitalised, amort_capitalised_rd, rd_pl_charge,
       cap_rate_calc_pct, net_capitalisation, ebit_effect_of_cap_rate_change, caveat
FROM mart.v_rd_capitalisation ORDER BY sort_key;

SELECT period_code, da_total, impairment_used, da_clean, da_clean_pct_auto_revenue,
       yoy_da_total, yoy_da_clean, impairment_status
FROM mart.v_da_clean ORDER BY sort_key;

-- Q5. SUPPLEMENTARY HYBRID SENSITIVITY (L3) - not underlying group profitability, not a headline KPI.
--     L1 + clean automotive D&A - automotive capitalised development costs (R&D costs expensed as incurred).
SELECT period_code, margin_l1_pct AS headline_l1_margin, margin_l3_hybrid_pct, round(ebit_l3_hybrid_sensitivity) AS l3_hybrid_eur_m,
       round(ebit_l3_hybrid_alt_a04) AS l3_hybrid_if_a04_false, l3_label
FROM mart.v_ebit_adjusted ORDER BY sort_key;

-- Q6. Value over volume: how much of the revenue change is volume vs revenue per car?
SELECT period_code, vehicle_sales, yoy_vehicle_sales_pct, asp_calc_eur_k, asp_published_eur_k, yoy_asp_pct,
       yoy_auto_revenue, volume_effect, asp_effect, wholesale_minus_retail_units
FROM mart.v_asp_volume ORDER BY sort_key;

SELECT period_code, member_name, deliveries, share_pct
FROM mart.v_delivery_mix
WHERE dimension = 'model' AND period_code IN ('2025-H1','2026-H1')
ORDER BY member_name, period_code;

-- Q7. Does cash confirm the profit picture?
SELECT period_code, round(auto_net_cash_flow) AS ncf, ncf_margin_pct, cfo_to_ebitda, ncf_to_ebit,
       round(simple_cash_proxy) AS ebitda_minus_capex_caprd, round(ncf_minus_proxy_wc_tax_other) AS remainder,
       cash_notes
FROM mart.v_cash_crosscheck ORDER BY sort_key;

-- Q8. What does the FY2026 guidance imply for H2 2026?
--     Rows are SCENARIO COMBINATIONS of guidance range ends: not forecasts, no probabilities; mid = all midpoints.
SELECT * FROM mart.v_guidance_2026_summary;

SELECT scenario_id, case_rev, case_ros, case_ex, round(h2_rev) AS h2_rev, round(h2_ebit_l0) AS h2_ebit,
       h2_margin_l0_pct, h2_exceptional_implied, h2_margin_l1_pct, h2_margin_l2_pct
FROM mart.v_guidance_2026
WHERE case_ex = 'mid'
ORDER BY case_rev, case_ros;

SELECT scenario_id, case_rev, case_m, h2_auto_ebitda_margin_pct, h1_2026_auto_ebitda_margin_pct,
       h2_auto_ncf_margin_pct, h1_2026_auto_ncf_margin_pct
FROM mart.v_guidance_2026_auto
WHERE case_rev = 'mid'
ORDER BY case_m;

-- Q9. Which assumptions drive these answers?
SELECT assumption_id, statement, applies_to, sensitivity FROM mart.assumption ORDER BY assumption_id;

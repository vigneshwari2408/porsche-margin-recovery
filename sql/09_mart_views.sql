-- =====================================================================
-- PCL Porsche Company Lens - 09_mart_views.sql   (Phase 4)
-- Analytical views. Money in EUR m, margins in % (x100).
-- Every view is documented in mart.view_catalog (bottom of this file)
-- and with COMMENT ON VIEW.
-- =====================================================================

-- =====================================================================
-- 1. mart.v_panel_hy : one row per half-year 2023-H1 .. 2026-H1
-- =====================================================================
CREATE VIEW mart.v_panel_hy AS
WITH f AS (
    SELECT p.period_code, p.period_label, p.sort_key, p.fiscal_year, p.half_no,
           f.var_id, f.value, f.value_label
    FROM core.dim_period p
    LEFT JOIN core.fact_financial f
           ON f.period_code = p.period_code
          AND f.var_id IN ('G01','G02','G03','G04','G05','G06','G07','A01','A02','A03','A04','A05','A06','A07','A08',
                           'A09','A10','A11','A12','A13a','A13b','A13','A14','F01','F02','X01','X02','X03','X04','X05',
                           'B01','B02','B03','B04','B05','O01','O04','O06','O07')   -- only the variables pivoted below
    WHERE p.in_analysis_window
)
SELECT
    period_code, period_label, sort_key, fiscal_year, half_no,
    -- group P&L (fact sheet S025)
    max(value) FILTER (WHERE var_id = 'G01') AS grp_revenue,
    max(value) FILTER (WHERE var_id = 'G02') AS grp_cost_of_sales,
    max(value) FILTER (WHERE var_id = 'G03') AS grp_gross_profit,
    max(value) FILTER (WHERE var_id = 'G04') AS grp_distribution,
    max(value) FILTER (WHERE var_id = 'G05') AS grp_admin,
    max(value) FILTER (WHERE var_id = 'G06') AS grp_other_operating,
    max(value) FILTER (WHERE var_id = 'G07') AS grp_ebit,
    -- automotive segment
    max(value) FILTER (WHERE var_id = 'A01') AS auto_revenue,
    max(value) FILTER (WHERE var_id = 'A02') AS auto_ebit,
    max(value) FILTER (WHERE var_id = 'A03') AS auto_ebitda,
    max(value) FILTER (WHERE var_id = 'A04') AS auto_ebitda_margin_published,
    -- R&D, capex, D&A (automotive)
    max(value) FILTER (WHERE var_id = 'A05') AS rd_total,
    max(value) FILTER (WHERE var_id = 'A06') AS rd_capitalised,
    max(value) FILTER (WHERE var_id = 'A07') AS rd_cap_rate_published,
    max(value) FILTER (WHERE var_id = 'A08') AS rd_expensed,
    max(value) FILTER (WHERE var_id = 'A09') AS amort_capitalised_rd,
    max(value) FILTER (WHERE var_id = 'A10') AS capex,
    max(value) FILTER (WHERE var_id = 'A11') AS dep_on_capex,
    max(value) FILTER (WHERE var_id = 'A12') AS da_total,
    -- automotive cash (fact sheet S025)
    max(value) FILTER (WHERE var_id = 'A13a') AS auto_cfo,
    max(value) FILTER (WHERE var_id = 'A13b') AS auto_cfi_operating,
    max(value) FILTER (WHERE var_id = 'A13') AS auto_net_cash_flow,
    max(value) FILTER (WHERE var_id = 'A14') AS auto_net_liquidity,
    -- financial services
    max(value) FILTER (WHERE var_id = 'F01') AS fs_revenue,
    max(value) FILTER (WHERE var_id = 'F02') AS fs_ebit,
    -- exceptional items as disclosed (EUR m, positive = expense)
    max(value) FILTER (WHERE var_id = 'X01') AS exc_realignment_net,
    max(value) FILTER (WHERE var_id = 'X02') AS exc_battery_memo,
    max(value) FILTER (WHERE var_id = 'X03') AS exc_us_tariffs,
    max(value) FILTER (WHERE var_id = 'X04') AS exc_provision_release,
    max(value) FILTER (WHERE var_id = 'X05') AS impairment_in_da,
    -- Porsche EBIT bridge (EUR m, change vs same period prior year)
    max(value) FILTER (WHERE var_id = 'B01') AS bridge_gross_margin_ex_rd,
    max(value) FILTER (WHERE var_id = 'B02') AS bridge_rd,
    max(value) FILTER (WHERE var_id = 'B03') AS bridge_sga,
    max(value) FILTER (WHERE var_id = 'B04') AS bridge_other,
    max(value) FILTER (WHERE var_id = 'B05') AS bridge_extraordinary_memo,
    -- volumes and unit economics
    max(value) FILTER (WHERE var_id = 'O01') AS deliveries,
    max(value) FILTER (WHERE var_id = 'O04') AS vehicle_sales,
    max(value) FILTER (WHERE var_id = 'O06') AS asp_published_eur_k,
    max(value) FILTER (WHERE var_id = 'O07') AS bev_share_published,
    -- lineage summary
    count(*) FILTER (WHERE value_label = 'FACT')    AS n_fact_values,
    count(*) FILTER (WHERE value_label = 'DERIVED') AS n_derived_values,
    string_agg(var_id, ',' ORDER BY var_id) FILTER (WHERE value_label = 'DERIVED') AS derived_var_ids
FROM f
GROUP BY period_code, period_label, sort_key, fiscal_year, half_no;

COMMENT ON VIEW mart.v_panel_hy IS 'Half-year analytical panel 2023-H1..2026-H1 (one row per half-year, EUR m). H2 values are FY - H1 (DERIVED).';

-- =====================================================================
-- 2. mart.v_ebit_adjusted : reported and adjusted EBIT levels
-- =====================================================================
CREATE VIEW mart.v_ebit_adjusted AS
WITH b AS (
    SELECT p.*,
           coalesce(p.exc_realignment_net, 0) AS x01_used,
           coalesce(p.exc_us_tariffs, 0)      AS x03_used,
           coalesce(p.impairment_in_da, 0)    AS x05_used
    FROM mart.v_panel_hy p
), lvl AS (
    SELECT b.*,
           grp_ebit                                  AS ebit_l0_reported,
           grp_ebit + x01_used                       AS ebit_l1_ex_realignment,
           grp_ebit + x01_used + x03_used            AS ebit_l2_ex_realignment_tariffs,
           -- L3 (SUPPLEMENTARY HYBRID SENSITIVITY - not underlying group profitability, not a headline KPI):
           -- L1 + clean automotive D&A - automotive capitalised development costs
           -- = an EBITDA-type figure in which total automotive R&D costs are expensed as incurred.
           grp_ebit + x01_used + (da_total - x05_used) - rd_capitalised AS ebit_l3_hybrid_sensitivity
    FROM b
)
SELECT
    period_code, period_label, sort_key, fiscal_year, half_no,
    grp_revenue,
    ebit_l0_reported,
    round(100 * ebit_l0_reported / grp_revenue, 2)               AS margin_l0_reported_pct,
    x01_used                                                     AS adj_realignment_net,
    ebit_l1_ex_realignment,
    round(100 * ebit_l1_ex_realignment / grp_revenue, 2)         AS margin_l1_pct,
    x03_used                                                     AS adj_us_tariffs,
    ebit_l2_ex_realignment_tariffs,
    round(100 * ebit_l2_ex_realignment_tariffs / grp_revenue, 2) AS margin_l2_pct,
    ebit_l3_hybrid_sensitivity,
    round(100 * ebit_l3_hybrid_sensitivity / grp_revenue, 2)     AS margin_l3_hybrid_pct,
    'L3 = supplementary hybrid sensitivity (group EBIT mixed with automotive-only D&A and R&D); not underlying group profitability; not a headline KPI'
                                                                 AS l3_label,
    -- sensitivity for assumption A-04 (H1 2026 impairments not inside D&A)
    CASE WHEN period_code = '2026-H1' THEN ebit_l3_hybrid_sensitivity + x05_used END AS ebit_l3_hybrid_alt_a04,
    -- year-on-year (same half of prior year)
    ebit_l1_ex_realignment - lag(ebit_l1_ex_realignment) OVER w  AS yoy_ebit_l1,
    round(100 * ebit_l1_ex_realignment / grp_revenue, 2)
      - lag(round(100 * ebit_l1_ex_realignment / grp_revenue, 2)) OVER w AS yoy_margin_l1_pp,
    round(100 * ebit_l0_reported / grp_revenue, 2)
      - lag(round(100 * ebit_l0_reported / grp_revenue, 2)) OVER w       AS yoy_margin_l0_pp,
    -- rounding uncertainty of the adjustments (EUR m): +/-50 per item rounded to 0.1bn, doubled when H2 is derived
    (CASE WHEN exc_realignment_net IS NOT NULL THEN 50 ELSE 0 END
     + CASE WHEN exc_us_tariffs IS NOT NULL THEN 50 ELSE 0 END)
     * CASE WHEN half_no = 2 THEN 2 ELSE 1 END                   AS rounding_band_eur_m,
    concat_ws('; ',
        CASE WHEN exc_realignment_net IS NULL THEN 'A-01' END,
        CASE WHEN exc_us_tariffs IS NULL THEN 'A-02' END,
        CASE WHEN impairment_in_da IS NULL THEN 'A-03' END,
        CASE WHEN period_code = '2026-H1' THEN 'A-04' END,
        CASE WHEN half_no = 2 AND exc_realignment_net IS NOT NULL THEN 'A-09' END) AS assumptions_used
FROM lvl
WINDOW w AS (PARTITION BY half_no ORDER BY fiscal_year);

COMMENT ON VIEW mart.v_ebit_adjusted IS 'Group EBIT at L0 reported, L1 excl. disclosed realignment/battery (net) and L2 also excl. US tariffs (headline levels). L3 = L1 + clean automotive D&A - automotive capitalised development costs is a SUPPLEMENTARY HYBRID SENSITIVITY only, not underlying group profitability and not a headline KPI.';

-- =====================================================================
-- 3. mart.v_da_clean : D&A with impairments removed
-- =====================================================================
CREATE VIEW mart.v_da_clean AS
SELECT
    period_code, period_label, sort_key, fiscal_year, half_no,
    auto_revenue,
    da_total,
    amort_capitalised_rd,
    dep_on_capex,
    impairment_in_da,
    coalesce(impairment_in_da, 0)                                  AS impairment_used,
    da_total - coalesce(impairment_in_da, 0)                       AS da_clean,
    round(100 * (da_total - coalesce(impairment_in_da, 0)) / auto_revenue, 2) AS da_clean_pct_auto_revenue,
    round(100 * da_total / auto_revenue, 2)                        AS da_total_pct_auto_revenue,
    -- component split cleaned only where the impairment's line item is known
    CASE WHEN coalesce(impairment_in_da, 0) = 0 THEN dep_on_capex
         WHEN period_code = '2025-H1' THEN dep_on_capex - impairment_in_da   -- Cellforce: PP&E depreciation (S010 p.32)
    END                                                            AS dep_on_capex_clean,
    CASE WHEN coalesce(impairment_in_da, 0) = 0 OR period_code = '2025-H1' THEN amort_capitalised_rd
    END                                                            AS amort_capitalised_rd_clean,
    (da_total - coalesce(impairment_in_da, 0))
      - lag(da_total - coalesce(impairment_in_da, 0)) OVER w       AS yoy_da_clean,
    da_total - lag(da_total) OVER w                                AS yoy_da_total,
    CASE WHEN impairment_in_da IS NULL THEN 'A-03: impairment not disclosed, 0 used'
         WHEN period_code = '2026-H1'  THEN 'A-04: EUR 61m assumed inside D&A (upper bound)'
         WHEN half_no = 2 AND impairment_in_da > 0 THEN 'H2 impairment = FY - H1; split between amortisation and depreciation not disclosed'
         ELSE 'FACT' END                                           AS impairment_status
FROM mart.v_panel_hy
WINDOW w AS (PARTITION BY half_no ORDER BY fiscal_year);

COMMENT ON VIEW mart.v_da_clean IS 'Automotive D&A including and excluding disclosed impairments. Clean D&A avoids double counting impairments that are already inside the exceptional items.';

-- =====================================================================
-- 4. mart.v_rd_capitalisation : R&D spend vs R&D in the P&L
-- =====================================================================
CREATE VIEW mart.v_rd_capitalisation AS
WITH r AS (
    SELECT period_code, period_label, sort_key, fiscal_year, half_no, auto_revenue,
           rd_total, rd_capitalised, rd_expensed, amort_capitalised_rd, rd_cap_rate_published,
           rd_expensed + amort_capitalised_rd AS rd_pl_charge,
           rd_capitalised::numeric / nullif(rd_total, 0) AS cap_rate
    FROM mart.v_panel_hy
)
SELECT
    period_code, period_label, sort_key, fiscal_year, half_no,
    rd_total                                          AS rd_total_costs,        -- Porsche 'automotive research and development costs'; an accounting cost total, not a cash-flow figure
    rd_capitalised,
    rd_expensed,
    amort_capitalised_rd,
    rd_pl_charge,
    round(100 * cap_rate, 1)                          AS cap_rate_calc_pct,
    rd_cap_rate_published                             AS cap_rate_published_pct,
    rd_capitalised - amort_capitalised_rd             AS net_capitalisation,     -- >0: P&L charge below total R&D costs
    round(100 * rd_total / auto_revenue, 2)           AS rd_total_costs_pct_auto_revenue,
    round(100 * rd_pl_charge / auto_revenue, 2)       AS rd_pl_pct_auto_revenue,
    -- counterfactual: same total R&D costs, prior-year same-half capitalisation rate, same amortisation
    round(rd_total * (1 - lag(cap_rate) OVER w) + amort_capitalised_rd, 1)          AS rd_pl_at_prior_cap_rate,
    round(rd_pl_charge - (rd_total * (1 - lag(cap_rate) OVER w) + amort_capitalised_rd), 1) AS ebit_effect_of_cap_rate_change,  -- >0 = extra charge vs prior-year rate
    rd_pl_charge - lag(rd_pl_charge) OVER w           AS yoy_rd_pl_charge,
    rd_total - lag(rd_total) OVER w                   AS yoy_rd_total_costs,
    amort_capitalised_rd - lag(amort_capitalised_rd) OVER w AS yoy_amortisation,
    (rd_capitalised - amort_capitalised_rd)
      - lag(rd_capitalised - amort_capitalised_rd) OVER w  AS yoy_net_capitalisation,
    CASE WHEN half_no = 2 AND fiscal_year = 2025
         THEN 'H2 2025 amortisation likely includes impairments of capitalised development costs (split not disclosed)'
    END                                               AS caveat
FROM r
WINDOW w AS (PARTITION BY half_no ORDER BY fiscal_year);

COMMENT ON VIEW mart.v_rd_capitalisation IS 'Total automotive R&D costs (Porsche definition; not a cash-flow figure) versus R&D charged to the P&L; capitalisation rate; net capitalisation (capitalised - amortised); effect of capitalisation-rate change.';

-- =====================================================================
-- 5. mart.v_asp_volume : Porsche ASP definition, volume vs ASP effects
-- =====================================================================
CREATE VIEW mart.v_asp_volume AS
WITH a AS (
    SELECT period_code, period_label, sort_key, fiscal_year, half_no,
           auto_revenue, vehicle_sales, deliveries, asp_published_eur_k,
           auto_revenue * 1000.0 / nullif(vehicle_sales, 0) AS asp_calc_eur_k   -- EUR m * 1000 / units = EUR k
    FROM mart.v_panel_hy
)
SELECT
    period_code, period_label, sort_key, fiscal_year, half_no,
    auto_revenue,
    vehicle_sales,
    deliveries,
    vehicle_sales - deliveries                                    AS wholesale_minus_retail_units,
    round(asp_calc_eur_k, 2)                                      AS asp_calc_eur_k,
    asp_published_eur_k,
    round(asp_calc_eur_k - asp_published_eur_k, 2)                AS asp_calc_minus_published,
    round(auto_revenue * 1000.0 / nullif(deliveries, 0), 2)       AS revenue_per_delivery_eur_k,
    vehicle_sales - lag(vehicle_sales) OVER w                     AS yoy_vehicle_sales,
    round(100.0 * (vehicle_sales - lag(vehicle_sales) OVER w) / lag(vehicle_sales) OVER w, 1) AS yoy_vehicle_sales_pct,
    round(100.0 * (asp_calc_eur_k - lag(asp_calc_eur_k) OVER w) / lag(asp_calc_eur_k) OVER w, 1) AS yoy_asp_pct,
    auto_revenue - lag(auto_revenue) OVER w                       AS yoy_auto_revenue,
    -- revenue change = volume effect (at prior ASP) + ASP effect (at current volume); exact identity
    round((vehicle_sales - lag(vehicle_sales) OVER w) * lag(asp_calc_eur_k) OVER w / 1000.0, 1) AS volume_effect,
    round((asp_calc_eur_k - lag(asp_calc_eur_k) OVER w) * vehicle_sales / 1000.0, 1)            AS asp_effect
FROM a
WINDOW w AS (PARTITION BY half_no ORDER BY fiscal_year);

COMMENT ON VIEW mart.v_asp_volume IS 'Automotive revenue per vehicle sold (Porsche ASP definition), wholesale vs retail units, revenue change split into volume and ASP effects.';

-- =====================================================================
-- 6. mart.v_delivery_mix : model and region mix of deliveries
-- =====================================================================
CREATE VIEW mart.v_delivery_mix AS
SELECT p.period_code, p.period_label, p.sort_key,
       'model' AS dimension, m.model_id AS member_id, m.model_name AS member_name,
       d.deliveries,
       round(100.0 * d.deliveries / sum(d.deliveries) OVER (PARTITION BY p.period_code), 2) AS share_pct,
       d.value_label
FROM core.fact_deliveries_model d
JOIN core.dim_model m USING (model_id)
JOIN core.dim_period p USING (period_code)
WHERE p.in_analysis_window AND m.parent_model_id IS NULL        -- top-level lines (Macan total)
UNION ALL
SELECT p.period_code, p.period_label, p.sort_key,
       'region', r.region_id, r.region_name, d.deliveries,
       round(100.0 * d.deliveries / sum(d.deliveries) OVER (PARTITION BY p.period_code), 2),
       d.value_label
FROM core.fact_deliveries_region d
JOIN core.dim_region r USING (region_id)
JOIN core.dim_period p USING (period_code)
WHERE p.in_analysis_window;

COMMENT ON VIEW mart.v_delivery_mix IS 'Deliveries and share by model line and by region per half-year (retail deliveries, not wholesale).';

-- =====================================================================
-- 7. mart.v_cash_crosscheck : cash versus profit
-- =====================================================================
CREATE VIEW mart.v_cash_crosscheck AS
SELECT
    period_code, period_label, sort_key, fiscal_year, half_no,
    auto_revenue, auto_ebit, auto_ebitda,
    auto_cfo, auto_cfi_operating, auto_net_cash_flow, auto_net_liquidity,
    round(100 * auto_net_cash_flow / auto_revenue, 2)               AS ncf_margin_pct,
    round(100 * auto_ebitda / auto_revenue, 2)                      AS ebitda_margin_calc_pct,
    round(auto_cfo / nullif(auto_ebitda, 0), 2)                     AS cfo_to_ebitda,
    CASE WHEN auto_ebit > 0 THEN round(auto_net_cash_flow / auto_ebit, 2) END AS ncf_to_ebit,
    capex + rd_capitalised                                          AS investment_capex_plus_cap_rd,
    -auto_cfi_operating - (capex + rd_capitalised)                  AS other_investing_outflow,
    auto_ebitda - capex - rd_capitalised                            AS simple_cash_proxy,
    auto_net_cash_flow - (auto_ebitda - capex - rd_capitalised)     AS ncf_minus_proxy_wc_tax_other,
    (SELECT string_agg(a.topic || ': ' || a.note || ' [' || a.source_id || ' ' || a.source_ref || ']', ' | ')
       FROM mart.annotation a WHERE a.period_code = v.period_code AND a.topic = 'Cash flow') AS cash_notes
FROM mart.v_panel_hy v;

COMMENT ON VIEW mart.v_cash_crosscheck IS 'Automotive cash flow vs EBIT/EBITDA; net cash flow margin (Porsche definition); simple cash proxy EBITDA - capex - capitalised R&D and the unexplained remainder (working capital, tax, other).';

-- =====================================================================
-- 8. mart.v_ebit_bridge_yoy : our own decomposition of the EBIT change
-- =====================================================================
CREATE VIEW mart.v_ebit_bridge_yoy AS
WITH e AS (
    SELECT a.period_code, a.period_label, a.sort_key, a.fiscal_year, a.half_no,
           a.grp_revenue, a.ebit_l0_reported, a.adj_realignment_net, a.adj_us_tariffs,
           p.rd_capitalised, d.da_clean, d.impairment_used, p.fs_ebit
    FROM mart.v_ebit_adjusted a
    JOIN mart.v_panel_hy p USING (period_code)
    JOIN mart.v_da_clean d USING (period_code)
), pair AS (
    SELECT c.period_code, c.period_label, c.sort_key, pr.period_code AS prior_period_code,
           c.grp_revenue AS rev_cur, pr.grp_revenue AS rev_prior,
           c.ebit_l0_reported AS ebit_cur, pr.ebit_l0_reported AS ebit_prior,
           c.ebit_l0_reported - pr.ebit_l0_reported                     AS d_ebit,
           -(c.adj_realignment_net - pr.adj_realignment_net)            AS eff_exceptional_items,
           -(c.adj_us_tariffs - pr.adj_us_tariffs)                      AS eff_us_tariffs,
           c.rd_capitalised - pr.rd_capitalised                         AS eff_rd_capitalisation,
           -(c.da_clean - pr.da_clean)                                  AS eff_clean_da,
           c.fs_ebit - pr.fs_ebit                                       AS eff_financial_services,
           c.impairment_used AS impairment_cur
    FROM e c
    JOIN e pr ON pr.half_no = c.half_no AND pr.fiscal_year = c.fiscal_year - 1
)
SELECT
    period_code, period_label, sort_key, prior_period_code,
    ebit_prior, ebit_cur, d_ebit,
    eff_exceptional_items, eff_us_tariffs, eff_rd_capitalisation, eff_clean_da, eff_financial_services,
    d_ebit - eff_exceptional_items - eff_us_tariffs - eff_rd_capitalisation - eff_clean_da - eff_financial_services
        AS eff_residual_other_drivers,
    -- A-04 sensitivity: if H1 2026 impairments were NOT inside D&A, clean D&A is 61 higher
    CASE WHEN period_code = '2026-H1'
         THEN d_ebit - eff_exceptional_items - eff_us_tariffs - eff_rd_capitalisation
              - (eff_clean_da - impairment_cur) - eff_financial_services END AS eff_residual_other_drivers_alt_a04,
    -- margin view (pp): each EUR effect / current revenue, plus the revenue-denominator effect; sums exactly
    round(100 * ebit_cur / rev_cur - 100 * ebit_prior / rev_prior, 3)      AS d_margin_pp,
    round(100 * ebit_prior * (1 / rev_cur - 1 / rev_prior), 3)              AS pp_revenue_denominator,
    round(100 * eff_exceptional_items / rev_cur, 3)                         AS pp_exceptional_items,
    round(100 * eff_us_tariffs / rev_cur, 3)                                AS pp_us_tariffs,
    round(100 * eff_rd_capitalisation / rev_cur, 3)                         AS pp_rd_capitalisation,
    round(100 * eff_clean_da / rev_cur, 3)                                  AS pp_clean_da,
    round(100 * eff_financial_services / rev_cur, 3)                        AS pp_financial_services,
    round(100 * (d_ebit - eff_exceptional_items - eff_us_tariffs - eff_rd_capitalisation
                 - eff_clean_da - eff_financial_services) / rev_cur, 3)     AS pp_residual_other_drivers
FROM pair;

COMMENT ON VIEW mart.v_ebit_bridge_yoy IS 'Own decomposition of the year-on-year change in group EBIT (same half): exceptional items, tariffs, capitalised development costs, clean automotive D&A, Financial Services, and a residual of other EBIT drivers that are NOT separated (price, mix, volume, total R&D cost changes, material/supplier costs, SG&A, other operating result, FX, consolidation, rounding of one-offs).';

-- =====================================================================
-- 9. mart.v_guidance_2026 : what the FY2026 guidance implies for H2 2026
-- =====================================================================
CREATE VIEW mart.v_guidance_2026 AS
WITH g AS (
    SELECT
        max(low_value)  FILTER (WHERE guidance_id = 'GD_REV')   AS rev_lo,
        max(high_value) FILTER (WHERE guidance_id = 'GD_REV')   AS rev_hi,
        max(low_value)  FILTER (WHERE guidance_id = 'GD_ROS')   AS ros_lo,
        max(high_value) FILTER (WHERE guidance_id = 'GD_ROS')   AS ros_hi,
        max(low_value)  FILTER (WHERE guidance_id = 'GD_EXTRA') AS ex_lo,
        max(high_value) FILTER (WHERE guidance_id = 'GD_EXTRA') AS ex_hi
    FROM core.fact_guidance
), h1 AS (
    SELECT grp_revenue AS h1_rev, ebit_l0_reported AS h1_ebit, adj_realignment_net AS h1_exc,
           adj_us_tariffs AS h1_tariffs, ebit_l1_ex_realignment AS h1_ebit_l1, margin_l1_pct AS h1_margin_l1,
           margin_l0_reported_pct AS h1_margin_l0
    FROM mart.v_ebit_adjusted WHERE period_code = '2026-H1'
), h2_25 AS (
    SELECT margin_l0_reported_pct AS h2_25_margin_l0, margin_l1_pct AS h2_25_margin_l1
    FROM mart.v_ebit_adjusted WHERE period_code = '2025-H2'
), grid AS (
    SELECT r.case_rev, s.case_ros, x.case_ex,
           CASE r.case_rev WHEN 'low' THEN g.rev_lo WHEN 'mid' THEN (g.rev_lo + g.rev_hi) / 2 ELSE g.rev_hi END AS fy_rev,
           CASE s.case_ros WHEN 'low' THEN g.ros_lo WHEN 'mid' THEN (g.ros_lo + g.ros_hi) / 2 ELSE g.ros_hi END AS fy_ros,
           CASE x.case_ex  WHEN 'low' THEN g.ex_lo  WHEN 'mid' THEN (g.ex_lo  + g.ex_hi)  / 2 ELSE g.ex_hi  END AS fy_exc
    FROM g
    CROSS JOIN (VALUES ('low'),('mid'),('high')) r(case_rev)
    CROSS JOIN (VALUES ('low'),('mid'),('high')) s(case_ros)
    CROSS JOIN (VALUES ('low'),('mid'),('high')) x(case_ex)
)
SELECT
    grid.case_rev || '/' || grid.case_ros || '/' || grid.case_ex         AS scenario_id,
    'Scenario combination of guidance range ends - not a forecast, no probability attached' AS scenario_type,
    grid.case_rev, grid.case_ros, grid.case_ex,
    grid.fy_rev, grid.fy_ros, grid.fy_exc,
    grid.fy_rev * grid.fy_ros / 100                                   AS fy_ebit,
    h1.h1_rev, h1.h1_ebit,
    grid.fy_rev - h1.h1_rev                                           AS h2_rev,
    grid.fy_rev * grid.fy_ros / 100 - h1.h1_ebit                      AS h2_ebit_l0,
    round(100 * (grid.fy_rev * grid.fy_ros / 100 - h1.h1_ebit) / (grid.fy_rev - h1.h1_rev), 2) AS h2_margin_l0_pct,
    grid.fy_exc - h1.h1_exc                                           AS h2_exceptional_implied,
    grid.fy_rev * grid.fy_ros / 100 - h1.h1_ebit + (grid.fy_exc - h1.h1_exc) AS h2_ebit_l1,
    round(100 * (grid.fy_rev * grid.fy_ros / 100 - h1.h1_ebit + (grid.fy_exc - h1.h1_exc))
              / (grid.fy_rev - h1.h1_rev), 2)                          AS h2_margin_l1_pct,
    h1.h1_tariffs                                                     AS h2_tariffs_assumed,
    round(100 * (grid.fy_rev * grid.fy_ros / 100 - h1.h1_ebit + (grid.fy_exc - h1.h1_exc) + h1.h1_tariffs)
              / (grid.fy_rev - h1.h1_rev), 2)                          AS h2_margin_l2_pct,
    h1.h1_margin_l0, h1.h1_margin_l1, h2_25.h2_25_margin_l0, h2_25.h2_25_margin_l1,
    'A-06; A-07 (L2 only); A-08'                                      AS assumptions_used
FROM grid CROSS JOIN h1 CROSS JOIN h2_25;

COMMENT ON VIEW mart.v_guidance_2026 IS '27 SCENARIO COMBINATIONS of the low/mid/high ends of the FY2026 guidance ranges and the H2 2026 revenue, EBIT and margins each combination arithmetically implies. Not forecasts; no probabilities; mid = all range midpoints, not a most-likely case.';

CREATE VIEW mart.v_guidance_2026_summary AS
SELECT
    'H2 2026 implied by guidance scenario combinations' AS scope,
    'Range across 27 scenario combinations; mid = all guidance midpoints. Not a forecast; no probabilities.' AS scenario_type,
    min(h2_rev) AS h2_rev_min, max(h2_rev) AS h2_rev_max,
    min(h2_ebit_l0) AS h2_ebit_l0_min, max(h2_ebit_l0) AS h2_ebit_l0_max,
    min(h2_margin_l0_pct) AS h2_margin_l0_min, max(h2_margin_l0_pct) AS h2_margin_l0_max,
    max(h2_margin_l0_pct) FILTER (WHERE case_rev = 'mid' AND case_ros = 'mid' AND case_ex = 'mid') AS h2_margin_l0_mid,
    min(h2_margin_l1_pct) AS h2_margin_l1_min, max(h2_margin_l1_pct) AS h2_margin_l1_max,
    max(h2_margin_l1_pct) FILTER (WHERE case_rev = 'mid' AND case_ros = 'mid' AND case_ex = 'mid') AS h2_margin_l1_mid,
    min(h2_margin_l2_pct) AS h2_margin_l2_min, max(h2_margin_l2_pct) AS h2_margin_l2_max,
    max(h2_margin_l2_pct) FILTER (WHERE case_rev = 'mid' AND case_ros = 'mid' AND case_ex = 'mid') AS h2_margin_l2_mid,
    max(h1_margin_l0) AS h1_2026_margin_l0, max(h1_margin_l1) AS h1_2026_margin_l1,
    max(h2_25_margin_l0) AS h2_2025_margin_l0, max(h2_25_margin_l1) AS h2_2025_margin_l1
FROM mart.v_guidance_2026;

COMMENT ON VIEW mart.v_guidance_2026_summary IS 'Min / mid / max of the H2 2026 margins implied across the 27 guidance scenario combinations (not forecasts, no probabilities), next to H1 2026 and H2 2025 actuals.';

CREATE VIEW mart.v_guidance_2026_auto AS
WITH g AS (
    SELECT guidance_id, low_value, high_value FROM core.fact_guidance
), h1 AS (
    SELECT grp_revenue, auto_revenue, auto_ebitda, auto_net_cash_flow,
           auto_revenue / grp_revenue AS auto_share
    FROM mart.v_panel_hy WHERE period_code = '2026-H1'
), c AS (
    SELECT r.case_rev, m.case_m,
           CASE r.case_rev WHEN 'low' THEN gr.low_value WHEN 'mid' THEN (gr.low_value + gr.high_value) / 2 ELSE gr.high_value END AS fy_grp_rev,
           CASE m.case_m   WHEN 'low' THEN ge.low_value WHEN 'mid' THEN (ge.low_value + ge.high_value) / 2 ELSE ge.high_value END AS fy_ebitda_margin,
           CASE m.case_m   WHEN 'low' THEN gn.low_value WHEN 'mid' THEN (gn.low_value + gn.high_value) / 2 ELSE gn.high_value END AS fy_ncf_margin
    FROM g gr, g ge, g gn
    CROSS JOIN (VALUES ('low'),('mid'),('high')) r(case_rev)
    CROSS JOIN (VALUES ('low'),('mid'),('high')) m(case_m)
    WHERE gr.guidance_id = 'GD_REV' AND ge.guidance_id = 'GD_EBITDA' AND gn.guidance_id = 'GD_NCF'
)
SELECT c.case_rev || '/' || c.case_m AS scenario_id,
       'Scenario combination of guidance range ends - not a forecast, no probability attached' AS scenario_type,
       c.case_rev, c.case_m,
       c.fy_grp_rev, round(h1.auto_share * 100, 2) AS auto_share_pct_assumed,
       round(c.fy_grp_rev * h1.auto_share, 1)                    AS fy_auto_rev,
       round(c.fy_grp_rev * h1.auto_share - h1.auto_revenue, 1)  AS h2_auto_rev,
       c.fy_ebitda_margin,
       round(100 * (c.fy_ebitda_margin / 100 * c.fy_grp_rev * h1.auto_share - h1.auto_ebitda)
             / (c.fy_grp_rev * h1.auto_share - h1.auto_revenue), 2) AS h2_auto_ebitda_margin_pct,
       c.fy_ncf_margin,
       round(100 * (c.fy_ncf_margin / 100 * c.fy_grp_rev * h1.auto_share - h1.auto_net_cash_flow)
             / (c.fy_grp_rev * h1.auto_share - h1.auto_revenue), 2) AS h2_auto_ncf_margin_pct,
       round(100 * h1.auto_ebitda / h1.auto_revenue, 2)          AS h1_2026_auto_ebitda_margin_pct,
       round(100 * h1.auto_net_cash_flow / h1.auto_revenue, 2)   AS h1_2026_auto_ncf_margin_pct,
       'A-05; A-08' AS assumptions_used
FROM c CROSS JOIN h1;

COMMENT ON VIEW mart.v_guidance_2026_auto IS '9 SCENARIO COMBINATIONS (revenue end x margin end): H2 2026 automotive EBITDA margin and net cash flow margin implied by FY2026 guidance (automotive revenue estimated with assumption A-05). Not forecasts; no probabilities.';

-- =====================================================================
-- View catalogue (documentation, queried by the auditor and by Power BI)
-- =====================================================================
INSERT INTO mart.view_catalog VALUES
('mart.v_panel_hy', '1 row per half-year, 2023-H1..2026-H1 (7 rows)',
 'All core variables side by side: group P&L, automotive segment, R&D/capex/D&A, automotive cash, FS, exceptional items, Porsche bridge, volumes, ASP, BEV share; counts of FACT vs DERIVED inputs.',
 'Pivot of core.fact_financial filtered on dim_period.in_analysis_window (H1 and H2 only).',
 'None (pure pivot). H2 columns are FY - H1 from 06_derive_h2.sql.',
 'Only 7 observations. Values missing in core stay NULL here (e.g. one-offs 2023-2024).',
 'core.fact_financial <- S025 fact sheet (group P&L, cash, volumes) and PDF inputs S002/S006/S010/S011/S013/S016/S017/S026 (segment, R&D, D&A, one-offs, ASP).'),
('mart.v_ebit_adjusted', '1 row per half-year',
 'Headline levels: L0 reported, L1 excl. realignment/battery (net), L2 also excl. US tariffs; YoY changes; rounding band. Supplementary: L3 hybrid sensitivity (see limitations).',
 'L0 = G07. L1 = G07 + X01 (net). L2 = L1 + X03. L3 = L1 + (A12 - X05) - A06, i.e. an EBITDA-type figure with total automotive R&D costs expensed as incurred. Margins = level / G01 x 100. YoY = same half of prior year.',
 'A-01 (no one-offs 2023-24 -> 0), A-02 (no tariffs before 2025), A-03 (undisclosed impairments -> 0), A-04 (H1 2026 impairments inside D&A), A-09 (H2 rounding).',
 'Exceptional items are management-defined and rounded to EUR 0.1bn (+/-50m, +/-100m for derived H2). L3 is a SUPPLEMENTARY HYBRID SENSITIVITY only: it mixes group EBIT with automotive-only D&A and capitalised development costs (FS depreciation stays in), so it is NOT underlying group profitability and must not be used as a headline KPI. X01 is added NET of provision releases, i.e. the H1 2026 EUR 0.3bn release benefit is also removed. X05 is NOT added separately in L1/L2 (already inside X01): no double count.',
 'G07,G01: S025. X01: S016 p.6 / S011 p.6 (FY2025 = 2.4 + 0.7 DERIVED). X03: S010 p.5, S011 p.6, S016 p.6. A12: S011 p.34 / S016 p.25 / S002 p.9. X05: S010 p.32, S011 p.34, S017 p.29. A06: S011 p.34 / S016 p.25 / S002 p.29.'),
('mart.v_da_clean', '1 row per half-year',
 'Automotive D&A total, disclosed impairments inside it, clean D&A (total - impairments), as % of automotive revenue, YoY.',
 'da_clean = A12 - coalesce(X05, 0). Component split cleaned only where the impairment line item is known (H1 2025 Cellforce = PP&E depreciation).',
 'A-03, A-04.',
 'FY2025 impairments (~EUR 1,200m, "around") are rounded to EUR 100m; H2 2025 impairment (905) is FY - H1 and its split between amortisation and depreciation is unknown, so component clean values are NULL there.',
 'A12/A09/A11: S011 p.34, S016 p.25, S002 p.9/p.29. X05: S002 p.38, S006 p.38, S010 p.32, S011 p.34 fn, S017 p.29.'),
('mart.v_rd_capitalisation', '1 row per half-year',
 'Total automotive R&D costs, capitalised, expensed, amortisation, P&L charge, capitalisation rate (calc vs published), net capitalisation, R&D cost intensity, effect of capitalisation-rate change vs prior year.',
 'P&L charge = A08 + A09. Net capitalisation = A06 - A09. Counterfactual P&L charge = A05 x (1 - prior-year same-half cap rate) + A09; effect = actual - counterfactual.',
 'Counterfactual holds amortisation fixed (a modelling simplification, labelled as such).',
 'Total R&D costs are Porsche''s accounting definition (research costs, non-capitalisable development costs and capitalisable development costs), not a cash-flow figure. Amortisation responds to past capitalisation and may include impairments (H2 2025). Counterfactual is illustrative, not what Porsche would have reported.',
 'A05-A09: S011 p.34 (FY), S016 p.25 (H1 2024-26), S002 p.29 + S005 p.28 (H1 2023). H1 2025 total R&D restated (AF-09).'),
('mart.v_asp_volume', '1 row per half-year',
 'Automotive revenue per vehicle sold (Porsche ASP definition) calculated and published, wholesale vs retail units, revenue per delivery, volume vs ASP effect on automotive revenue.',
 'ASP = A01 x 1000 / O04 (EUR k). Volume effect = dO04 x ASP_prior / 1000. ASP effect = dASP x O04_cur / 1000. Volume + ASP effect = dA01 exactly.',
 'None. The ASP effect is a residual of price, model mix, derivative mix, options, FX and non-vehicle revenue - not "price".',
 'Porsche ASP uses automotive revenue (incl. parts/services) over wholesale units; wholesale-retail difference is a proxy for channel stock movement (PROXY).',
 'A01: segment tables (S002/S006/S010/S017/S013/S026). O04/O01: S025. O06: S005 p.20, S009 p.32, S011 p.10, S016 p.10.'),
('mart.v_delivery_mix', '1 row per half-year x model line / region',
 'Retail deliveries and share by top-level model line (Macan as total) and by region.',
 'Share = deliveries / sum over the period.',
 'None.',
 'Deliveries are retail units, not the wholesale units that drive revenue. Macan ICE/BEV split exists only from FY2024 (use core table for it).',
 'core.fact_deliveries_model / _region <- S025 sheets 03 and 04; H2 = FY - H1.'),
('mart.v_cash_crosscheck', '1 row per half-year',
 'Automotive CFO, investing, net cash flow, net liquidity; NCF margin; CFO/EBITDA; NCF/EBIT; simple cash proxy (EBITDA - capex - capitalised R&D) and remainder.',
 'NCF margin = A13 / A01. Proxy = A03 - A10 - A06. Remainder = A13 - proxy (working capital, tax, provisions, other).',
 'None.',
 'Cash timing items (Audi licence, pension funding) are only in annotations, not quantified in the data; remainder is not decomposed further.',
 'A13/A13a/A13b/A14: S025 sheet 02. A03/A10/A06: segment and R&D tables. Notes: mart.annotation (S009 p.35, S016 p.13).'),
('mart.v_ebit_bridge_yoy', '1 row per half-year pair (same half, consecutive years): 5 rows',
 'Year-on-year change in group EBIT split into: exceptional items, US tariffs, capitalised development costs, clean automotive D&A, Financial Services, and residual / other EBIT drivers; same in margin points.',
 'eff_exceptional = -(X01 cur - X01 prior); eff_tariffs = -(X03 diff); eff_rd_cap = A06 cur - A06 prior; eff_clean_da = -(da_clean diff); eff_fs = F02 diff; residual / other EBIT drivers = dEBIT - all effects. pp: effect / revenue_cur plus revenue-denominator term; sums to d_margin exactly.',
 'A-01, A-02, A-03, A-04 (alt residual column), A-09.',
 'The residual / other EBIT drivers term is NOT operating performance and NOT separated: it contains price, model/derivative mix and volume effects, changes in total R&D costs, material and supplier costs (incl. BEV compensation payments), SG&A, other operating income/expense, FX, consolidation effects and the rounding of disclosed one-offs (+/-EUR 100-200m). Impairments are removed from D&A because they are already inside the exceptional-items effect (no double count).',
 'mart.v_ebit_adjusted, mart.v_da_clean, mart.v_panel_hy.'),
('mart.v_guidance_2026', '27 rows = SCENARIO COMBINATIONS of low/mid/high revenue x RoS x extraordinary expenses (not forecasts, no probabilities)',
 'FY2026 EBIT implied by guidance and the H2 2026 revenue, EBIT and margin at L0, L1, L2.',
 'FY EBIT = revenue x RoS. H2 = FY - H1 2026 actual. H2 exceptional = FY guided - H1 net (100). L1 = H2 EBIT + H2 exceptional. L2 = L1 + tariffs (A-07).',
 'A-06, A-07, A-08.',
 'Each row is an arithmetic scenario combination of guidance range ends, not a forecast; no probability is attached and mid is not a most-likely case. Guidance is management expectation. Extraordinary-expense guidance comes from a call transcript (Tier 3 record of a Tier 1 statement).',
 'core.fact_guidance <- S016 slide 14 (revenue, RoS, EBITDA margin, NCF margin, BEV) and S027 (extraordinary expenses). H1 2026 actuals from mart.v_ebit_adjusted.'),
('mart.v_guidance_2026_summary', '1 row',
 'Min / mid / max across the 27 scenario combinations of implied H2 2026 margins at L0, L1, L2, next to H1 2026 and H2 2025 actuals. Not forecasts; no probabilities.',
 'Aggregation of mart.v_guidance_2026.',
 'As v_guidance_2026.',
 'Range is deliberately wide (independent corners, A-08).',
 'mart.v_guidance_2026, mart.v_ebit_adjusted.'),
('mart.v_guidance_2026_auto', '9 rows = SCENARIO COMBINATIONS: revenue end x margin end (not forecasts, no probabilities)',
 'H2 2026 automotive EBITDA margin and automotive NCF margin implied by guidance.',
 'FY auto revenue = FY group revenue x H1 2026 auto share (A-05). H2 margin = (FY margin x FY auto revenue - H1 2026 actual) / (FY auto revenue - H1 2026 auto revenue).',
 'A-05, A-08.',
 'Automotive revenue is not guided; the share assumption drives the result.',
 'core.fact_guidance (S016 slide 14); H1 2026 automotive actuals (S017 p.12, S025).');

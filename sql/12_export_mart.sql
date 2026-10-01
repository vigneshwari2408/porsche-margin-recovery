-- =====================================================================
-- PCL Porsche Company Lens - 12_export_mart.sql   (Phase 4)
-- Writes every analytical view and control table to CSV in ./output
-- (input for the Excel model in Phase 5 and Power BI in Phase 7).
-- Run with psql from the 03_SQL folder; create the 'output' folder first.
-- =====================================================================
\copy (SELECT * FROM mart.v_panel_hy                ORDER BY sort_key)                   TO 'output/v_panel_hy.csv'                WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.v_ebit_adjusted           ORDER BY sort_key)                   TO 'output/v_ebit_adjusted.csv'           WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.v_da_clean                ORDER BY sort_key)                   TO 'output/v_da_clean.csv'                WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.v_rd_capitalisation       ORDER BY sort_key)                   TO 'output/v_rd_capitalisation.csv'       WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.v_asp_volume              ORDER BY sort_key)                   TO 'output/v_asp_volume.csv'              WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.v_delivery_mix            ORDER BY sort_key, dimension, member_id) TO 'output/v_delivery_mix.csv'        WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.v_cash_crosscheck         ORDER BY sort_key)                   TO 'output/v_cash_crosscheck.csv'         WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.v_ebit_bridge_yoy         ORDER BY sort_key)                   TO 'output/v_ebit_bridge_yoy.csv'         WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.v_guidance_2026           ORDER BY case_rev, case_ros, case_ex) TO 'output/v_guidance_2026.csv'          WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.v_guidance_2026_summary)                                       TO 'output/v_guidance_2026_summary.csv'   WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.v_guidance_2026_auto      ORDER BY case_rev, case_m)           TO 'output/v_guidance_2026_auto.csv'      WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.view_catalog              ORDER BY view_name)                  TO 'output/view_catalog.csv'              WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.assumption                ORDER BY assumption_id)              TO 'output/assumptions.csv'               WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM core.fact_guidance             ORDER BY guidance_id)                TO 'output/guidance_inputs.csv'           WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM mart.annotation                ORDER BY period_code, topic)         TO 'output/annotations.csv'               WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM audit.dq_result                ORDER BY check_id, period_code)      TO 'output/dq_results.csv'                WITH (FORMAT csv, HEADER true)
\copy (SELECT * FROM audit.audit_finding            ORDER BY af_id)                      TO 'output/audit_findings.csv'            WITH (FORMAT csv, HEADER true)

-- =====================================================================
-- PCL Porsche Company Lens - 00_run_all.sql
-- Builds the whole database (core + analytical layer) in one go.
-- Afterwards: 11_key_questions.sql (answers) and 12_export_mart.sql (CSV export). Run from the 03_SQL folder:
--   psql -U postgres -d porsche_lens -f 00_run_all.sql
-- (or in the "SQL Shell (psql)": \cd to the folder, then \i 00_run_all.sql)
-- The script stops at the first error.
-- =====================================================================
\set ON_ERROR_STOP on
\echo '1/10 schemas'
\i 01_create_schemas.sql
\echo '2/10 tables'
\i 02_create_tables.sql
\echo '3/10 dimensions'
\i 03_seed_dimensions.sql
\echo '4/10 load CSV files into staging'
\i 04_load_staging.sql
\echo '5/10 transform staging into core'
\i 05_transform_core.sql
\echo '6/10 derive H2 values'
\i 06_derive_h2.sql
\echo '7/10 data-quality checks'
\i 07_data_quality_checks.sql
\echo '8/10 analytical layer setup (Phase 4)'
\i 08_mart_setup.sql
\echo '9/10 analytical views'
\i 09_mart_views.sql
\echo '10/10 checks on the analytical views'
\i 10_mart_quality_checks.sql
\echo 'Done. Any FAIL rows (core DQ and mart MQ checks)?'
SELECT count(*) AS fail_rows FROM audit.dq_result WHERE status = 'FAIL';

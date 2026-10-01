-- =====================================================================
-- PCL Porsche Company Lens - 01_create_schemas.sql
-- Three schemas = three layers:
--   stg   : raw landing tables, one per CSV, loaded unchanged
--   core  : clean, typed, keyed model (dimensions + facts) used by analysis
--   audit : sources, audit findings, data gaps and data-quality results
-- Re-runnable: drops and recreates everything.
-- =====================================================================
DROP SCHEMA IF EXISTS stg   CASCADE;
DROP SCHEMA IF EXISTS core  CASCADE;
DROP SCHEMA IF EXISTS audit CASCADE;

CREATE SCHEMA stg;
CREATE SCHEMA core;
CREATE SCHEMA audit;

COMMENT ON SCHEMA stg   IS 'Raw landing layer: CSV files loaded as-is, no business logic';
COMMENT ON SCHEMA core  IS 'Clean analytical model: dimensions and facts with keys and constraints';
COMMENT ON SCHEMA audit IS 'Traceability: sources, audit findings, data gaps, data-quality check results';

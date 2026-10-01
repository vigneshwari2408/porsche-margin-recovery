-- =====================================================================
-- PCL Porsche Company Lens - 04_load_staging.sql
-- Loads the CSV files into the stg schema. Run with psql from the folder
-- that contains the 'data' subfolder (\copy reads files from your PC).
-- pgAdmin alternative: right-click each stg table > Import/Export Data,
--   Format csv, Header ON, Encoding UTF8, same file as below.
-- =====================================================================
TRUNCATE stg.fact_sheet_long, stg.manual_inputs, stg.source_register,
         stg.variable_dictionary, stg.audit_findings, stg.data_gaps;

\copy stg.fact_sheet_long     FROM 'data/fact_sheet_long.csv'     WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg.manual_inputs       FROM 'data/manual_inputs.csv'       WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg.source_register     FROM 'data/source_register.csv'     WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg.variable_dictionary FROM 'data/variable_dictionary.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg.audit_findings      FROM 'data/audit_findings.csv'      WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg.data_gaps           FROM 'data/data_gaps.csv'           WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Expected row counts: 1902 / 151 / 26 / 47 / 11 / 4
SELECT 'stg.fact_sheet_long' AS table_name, count(*) AS row_count FROM stg.fact_sheet_long
UNION ALL SELECT 'stg.manual_inputs',       count(*) FROM stg.manual_inputs
UNION ALL SELECT 'stg.source_register',     count(*) FROM stg.source_register
UNION ALL SELECT 'stg.variable_dictionary', count(*) FROM stg.variable_dictionary
UNION ALL SELECT 'stg.audit_findings',      count(*) FROM stg.audit_findings
UNION ALL SELECT 'stg.data_gaps',           count(*) FROM stg.data_gaps;

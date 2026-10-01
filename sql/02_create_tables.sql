-- =====================================================================
-- PCL Porsche Company Lens - 02_create_tables.sql
-- All tables with columns, data types, primary keys, foreign keys, checks.
-- Monetary values in core are stored in EUR million (unit_std = 'EUR m').
-- =====================================================================

-- ---------------------------------------------------------------------
-- STAGING (mirrors the CSV files column for column; text-friendly types)
-- ---------------------------------------------------------------------
CREATE TABLE stg.fact_sheet_long (
    source_id    varchar(10),
    sheet        varchar(60),
    block        varchar(10),      -- QTR = discrete-quarter block, YTD = year-to-date block
    cell         varchar(10),      -- cell address in the Porsche XLSX (traceability)
    raw_label    varchar(120),
    var_id       varchar(20),
    raw_period   varchar(20),
    period       varchar(10),      -- already converted to period code, e.g. 2026-H1
    period_type  varchar(5),
    value        numeric(24,6),    -- EUR (not EUR m) or units, as stored by Porsche
    unit         varchar(15),
    flags        varchar(60)
);

CREATE TABLE stg.manual_inputs (
    rec_id          varchar(10),
    var_id          varchar(10),
    period_code     varchar(10),
    source_id       varchar(10),
    source_page     varchar(120),
    unit_as_shown   varchar(10),
    value_as_shown  numeric(20,6),
    value_std       numeric(20,6),
    std_unit        varchar(10),
    value_label     varchar(10),
    rounding        varchar(60),
    double_checked  varchar(4),        -- Y / N / N/A (rule in PCL_02 README)
    note            text,
    verification_basis text
);

CREATE TABLE stg.source_register (
    source_id        varchar(10),
    tier             int,
    publisher        varchar(60),
    document_title   text,
    doc_type         varchar(40),
    reporting_period varchar(20),
    publication_date varchar(20),
    url              text,
    file_name        text,
    notes            text
);

CREATE TABLE stg.variable_dictionary (
    var_id             varchar(10),
    var_name           text,
    var_group          varchar(40),
    segment            varchar(10),
    measure_type       varchar(12),
    aggregation        varchar(6),
    unit_std           varchar(12),
    is_memo            varchar(6),
    definition         text,
    comparability_note text
);

CREATE TABLE stg.audit_findings (
    af_id       varchar(10),
    question    text,
    evidence    text,
    finding     text,
    status      varchar(40),
    consequence text
);

CREATE TABLE stg.data_gaps (
    var_id      varchar(10),
    period_code varchar(10),
    source_id   varchar(10),
    source_page varchar(120),
    reason      text
);

-- ---------------------------------------------------------------------
-- AUDIT
-- ---------------------------------------------------------------------
CREATE TABLE audit.dim_source (
    source_id        varchar(10)  PRIMARY KEY,
    tier             smallint     NOT NULL CHECK (tier IN (1,2,3)),
    publisher        varchar(60)  NOT NULL,
    document_title   text         NOT NULL,
    doc_type         varchar(40)  NOT NULL,
    reporting_period varchar(20),
    publication_date varchar(20),
    url              text,
    file_name        text,
    notes            text
);

CREATE TABLE audit.audit_finding (
    af_id       varchar(10) PRIMARY KEY,
    question    text NOT NULL,
    evidence    text,
    finding     text,
    status      varchar(40),
    consequence text
);

-- ---------------------------------------------------------------------
-- CORE DIMENSIONS
-- ---------------------------------------------------------------------
CREATE TABLE core.dim_period (
    period_code   varchar(8)  PRIMARY KEY,           -- e.g. 2025-Q3, 2025-H1, 2025-H2, 2025-9M, 2025-FY
    period_type   varchar(3)  NOT NULL CHECK (period_type IN ('QTR','H1','H2','9M','FY')),
    fiscal_year   smallint    NOT NULL,
    half_no       smallint    CHECK (half_no IN (1,2)),
    quarter_no    smallint    CHECK (quarter_no BETWEEN 1 AND 4),
    start_date    date        NOT NULL,
    end_date      date        NOT NULL,
    months        smallint    NOT NULL,
    sort_key      int         NOT NULL UNIQUE,
    period_label  varchar(12) NOT NULL,              -- display label, e.g. 'H1 2026'
    is_half_year  boolean     NOT NULL,              -- TRUE for H1 and H2 (the analysis grain)
    in_analysis_window boolean NOT NULL,             -- TRUE for 2023-H1 .. 2026-H1
    CHECK (end_date > start_date)
);

CREATE TABLE core.dim_variable (
    var_id             varchar(10) PRIMARY KEY,
    var_name           text        NOT NULL,
    var_group          varchar(40) NOT NULL,
    segment            varchar(10) NOT NULL CHECK (segment IN ('Group','Auto','FS')),
    measure_type       varchar(12) NOT NULL CHECK (measure_type IN ('flow','stock','ratio','per_share')),
    aggregation        varchar(6)  NOT NULL CHECK (aggregation IN ('SUM','LAST','NONE')),
    unit_std           varchar(12) NOT NULL,
    is_memo            boolean     NOT NULL,         -- TRUE = 'of which' item; never add to a total
    definition         text,
    comparability_note text
);

CREATE TABLE core.dim_model (
    model_id        varchar(10) PRIMARY KEY,
    model_name      varchar(30) NOT NULL,
    model_family    varchar(20) NOT NULL,
    body_type       varchar(20) NOT NULL,
    powertrain      varchar(80) NOT NULL,
    parent_model_id varchar(10) REFERENCES core.dim_model(model_id),
    is_subtotal     boolean     NOT NULL,            -- Macan = Macan ICE + Macan BEV
    sort_order      smallint    NOT NULL
);

CREATE TABLE core.dim_region (
    region_id     varchar(6)  PRIMARY KEY,
    region_name   varchar(40) NOT NULL,
    porsche_label varchar(60) NOT NULL,
    sort_order    smallint    NOT NULL
);

-- ---------------------------------------------------------------------
-- CORE FACTS
-- ---------------------------------------------------------------------
-- One published (or derived) number per period and variable.
CREATE TABLE core.fact_financial (
    period_code  varchar(8)   NOT NULL REFERENCES core.dim_period(period_code),
    var_id       varchar(10)  NOT NULL REFERENCES core.dim_variable(var_id),
    value        numeric(20,6) NOT NULL,
    unit_std     varchar(12)  NOT NULL,
    value_label  varchar(8)   NOT NULL CHECK (value_label IN ('FACT','DERIVED')),
    origin       varchar(12)  NOT NULL CHECK (origin IN ('FACTSHEET','MANUAL','SQL_DERIVED')),
    source_id    varchar(10)  REFERENCES audit.dim_source(source_id),   -- NULL only for SQL_DERIVED rows
    source_ref   varchar(160),                    -- page / sheet+cell / derivation formula
    rounding     varchar(160),
    note         text,
    PRIMARY KEY (period_code, var_id),
    CHECK (origin = 'SQL_DERIVED' OR source_id IS NOT NULL),
    CHECK (origin <> 'SQL_DERIVED' OR value_label = 'DERIVED')
);

CREATE TABLE core.fact_deliveries_model (
    period_code  varchar(8)  NOT NULL REFERENCES core.dim_period(period_code),
    model_id     varchar(10) NOT NULL REFERENCES core.dim_model(model_id),
    deliveries   int         NOT NULL CHECK (deliveries >= 0),
    value_label  varchar(8)  NOT NULL CHECK (value_label IN ('FACT','DERIVED')),
    origin       varchar(12) NOT NULL CHECK (origin IN ('FACTSHEET','SQL_DERIVED')),
    source_id    varchar(10) REFERENCES audit.dim_source(source_id),
    source_ref   varchar(160),
    PRIMARY KEY (period_code, model_id)
);

CREATE TABLE core.fact_deliveries_region (
    period_code  varchar(8)  NOT NULL REFERENCES core.dim_period(period_code),
    region_id    varchar(6)  NOT NULL REFERENCES core.dim_region(region_id),
    deliveries   int         NOT NULL CHECK (deliveries >= 0),
    value_label  varchar(8)  NOT NULL CHECK (value_label IN ('FACT','DERIVED')),
    origin       varchar(12) NOT NULL CHECK (origin IN ('FACTSHEET','SQL_DERIVED')),
    source_id    varchar(10) REFERENCES audit.dim_source(source_id),
    source_ref   varchar(160),
    PRIMARY KEY (period_code, region_id)
);

-- Values that were looked for but could not be verified (kept visible, never estimated)
CREATE TABLE audit.data_gap (
    var_id      varchar(10) NOT NULL REFERENCES core.dim_variable(var_id),
    period_code varchar(8)  NOT NULL REFERENCES core.dim_period(period_code),
    source_id   varchar(10) REFERENCES audit.dim_source(source_id),
    source_ref  varchar(160),
    reason      text        NOT NULL,
    PRIMARY KEY (var_id, period_code)
);

-- Results of every data-quality check (written by 07_data_quality_checks.sql)
CREATE TABLE audit.dq_result (
    check_id    varchar(10)  NOT NULL,
    check_name  text         NOT NULL,
    period_code varchar(8),
    item        varchar(40),
    expected    numeric(20,4),
    actual      numeric(20,4),
    difference  numeric(20,4),
    tolerance   numeric(20,4),
    status      varchar(6)   NOT NULL CHECK (status IN ('PASS','FAIL','INFO')),
    run_at      timestamp    NOT NULL DEFAULT now()
);

CREATE INDEX ix_fact_financial_var ON core.fact_financial (var_id);
CREATE INDEX ix_fact_financial_origin ON core.fact_financial (origin);

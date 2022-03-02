-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION log_analyse" to load this file. \quit

CREATE SCHEMA LOG_ANALYSE;

CREATE TABLE LOG_ANALYSE.LOG_ANALYSE (
    ID serial primary key,
    NAME text,
    CREATE_TIME timestamp without time zone DEFAULT now(),
    REPORT bytea
);

CREATE INTERNAL FUNCTION LOG_ANALYSE.CSV_CHECK()
RETURNS bool
AS 'MODULE_PATHNAME', 'csv_check'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION LOG_ANALYSE.LOG_SNAPSHOT(IN log_name text)
RETURNS bool
AS 'MODULE_PATHNAME', 'log_snapshot'
LANGUAGE C STRICT;

CREATE OR REPLACE internal FUNCTION LOG_ANALYSE.GET_REPORT(id integer)
RETURNS text
AS $$ SELECT convert_from(report, 'UTF8') FROM LOG_ANALYSE.LOG_ANALYSE where id = $1;
$$ LANGUAGE SQL;

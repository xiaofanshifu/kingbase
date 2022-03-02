/* src/pl/plsql/src/plsql--1.0.sql */

/*
 * Currently, all the interesting stuff is done by CREATE LANGUAGE.
 * Later we will probably "dumb down" that command and put more of the
 * knowledge into this script.
 */

CREATE PROCEDURAL LANGUAGE plsql;

COMMENT ON PROCEDURAL LANGUAGE plsql IS 'PL/SQL procedural language';

/*
 * exception stack and backtrace
 */
CREATE FUNCTION format_error_stack()
RETURNS TEXT
AS 'MODULE_PATHNAME', 'format_error_stack'
LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE FUNCTION format_error_backtrace()
RETURNS TEXT
AS 'MODULE_PATHNAME', 'format_error_backtrace'
LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

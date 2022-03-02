/* contrib/kingbase_fdw/kingbase_fdw--1.0.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION KINGBASE_FDW" to load this file. \quit

CREATE INTERNAL FUNCTION KINGBASE_FDW_HANDLER()
RETURNS fdw_handler
AS 'MODULE_PATHNAME', 'kingbase_fdw_handler'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION KINGBASE_FDW_VALIDATOR(TEXT[], OID)
RETURNS void
AS 'MODULE_PATHNAME', 'kingbase_fdw_validator'
LANGUAGE C STRICT;

CREATE FOREIGN DATA WRAPPER KINGBASE_FDW
  HANDLER kingbase_fdw_handler
  VALIDATOR kingbase_fdw_validator;

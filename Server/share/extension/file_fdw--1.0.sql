/* contrib/file_fdw/file_fdw--1.0.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION FILE_FDW" to load this file. \quit
set search_path to sys_catalog;

CREATE INTERNAL FUNCTION FILE_FDW_HANdLER()
RETURNS fdw_handler
AS 'MODULE_PATHNAME', 'file_fdw_handler'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION FILE_FDW_VALIDATOR(text[], oid)
RETURNS void
AS 'MODULE_PATHNAME', 'file_fdw_validator'
LANGUAGE C STRICT;

CREATE FOREIGN DATA WRAPPER FILE_FDW
  HANDLER file_fdw_handler
  VALIDATOR file_fdw_validator;

CREATE SERVER FILEFDW FOREIGN DATA WRAPPER file_fdw;
reset search_path;

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION xlog_record_read" to load this file. \quit

CREATE SCHEMA XLOG_RECORD_READ;

CREATE INTERNAL FUNCTION XLOG_RECORD_READ.READ_RECORD(IN xlogPtr text)
RETURNS INT
AS 'MODULE_PATHNAME', 'read_record'
LANGUAGE C STRICT;

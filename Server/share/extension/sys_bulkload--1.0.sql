/* sys_bulkload/sys_bulkload--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION SYS_BULKLOAD" to load this file. \quit

-- Adjust this setting to control where the objects get created.
CREATE INTERNAL FUNCTION SYS_BULKLOAD(
	IN OPTIONS TEXT[],
	OUT SKIP BIGINT,
	OUT COUNT BIGINT,
	OUT PARSE_ERRORS BIGINT,
	OUT DUPLICATE_NEW BIGINT,
	OUT DUPLICATE_OLD BIGINT,
	OUT SYSTEM_TIME FLOAT8,
	OUT USER_TIME FLOAT8,
	OUT DURATION FLOAT8,
	OUT ERROR_PATH TEXT
)
AS '$libdir/sys_bulkload', 'sys_bulkload' LANGUAGE C VOLATILE STRICT;

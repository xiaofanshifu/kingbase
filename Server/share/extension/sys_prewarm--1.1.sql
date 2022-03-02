/* contrib/sys_prewarm/sys_prewarm--1.1.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION sys_prewarm" to load this file. \quit

-- Register the function.
CREATE INTERNAL FUNCTION SYS_PREWARM(regclass,
						   mode text default 'buffer',
						   fork text default 'main',
						   first_block int8 default null,
						   last_block int8 default null)
RETURNS int8
AS 'MODULE_PATHNAME', 'sys_prewarm'
LANGUAGE C PARALLEL SAFE;

CREATE INTERNAL FUNCTION SYS_EXTEND(regclass, blocks int8)
RETURNS bool
AS 'MODULE_PATHNAME', 'sys_extend'
LANGUAGE C PARALLEL SAFE;

/* contrib/sys_stat_statements/sys_stat_statements--1.2--1.3.sql */

-- complain if script is sourced in ksql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION sys_stat_statements UPDATE TO '1.3'" to load this file. \quit

/* First we have to remove them from the extension */
ALTER EXTENSION sys_stat_statements DROP VIEW sys_stat_statements;
ALTER EXTENSION sys_stat_statements DROP FUNCTION sys_stat_statements(boolean);

/* Then we can drop them */
DROP VIEW sys_stat_statements;
DROP FUNCTION sys_stat_statements(boolean);

/* Now redefine */
CREATE INTERNAL FUNCTION sys_stat_statements(IN showtext boolean,
    OUT userid oid,
    OUT dbid oid,
    OUT queryid bigint,
    OUT query text,
    OUT calls int8,
    OUT total_time float8,
    OUT min_time float8,
    OUT max_time float8,
    OUT mean_time float8,
    OUT stddev_time float8,
    OUT rows int8,
    OUT shared_blks_hit int8,
    OUT shared_blks_read int8,
    OUT shared_blks_dirtied int8,
    OUT shared_blks_written int8,
    OUT local_blks_hit int8,
    OUT local_blks_read int8,
    OUT local_blks_dirtied int8,
    OUT local_blks_written int8,
    OUT temp_blks_read int8,
    OUT temp_blks_written int8,
    OUT blk_read_time float8,
    OUT blk_write_time float8
)
RETURNS SETOF record
AS 'MODULE_PATHNAME', 'sys_stat_statements_1_3'
LANGUAGE C STRICT VOLATILE;

CREATE VIEW sys_stat_statements AS
  SELECT * FROM sys_stat_statements(true);

GRANT SELECT ON sys_stat_statements TO PUBLIC;

/* contrib/sys_stat_statements/sys_stat_statements--1.3--1.4.sql */

-- complain if script is sourced in ksql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION sys_stat_statements UPDATE TO '1.4'" to load this file. \quit

ALTER FUNCTION sys_stat_statements_reset() PARALLEL SAFE;
ALTER FUNCTION sys_stat_statements(boolean) PARALLEL SAFE;

/* contrib/sys_stat_statements/sys_stat_statements--unpackaged--1.0.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION sys_stat_statements FROM unpackaged" to load this file. \quit

ALTER EXTENSION sys_stat_statements ADD function sys_stat_statements_reset();
ALTER EXTENSION sys_stat_statements ADD function sys_stat_statements();
ALTER EXTENSION sys_stat_statements ADD view sys_stat_statements;

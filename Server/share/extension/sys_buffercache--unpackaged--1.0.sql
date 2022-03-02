/* contrib/sys_buffercache/sys_buffercache--unpackaged--1.0.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION sys_buffercache FROM unpackaged" to load this file. \quit

ALTER EXTENSION SYS_BUFFERCACHE ADD FUNCTION SYS_BUFFERCACHE_PAGES();
ALTER EXTENSION SYS_BUFFERCACHE ADD VIEW SYS_BUFFERCACHE;

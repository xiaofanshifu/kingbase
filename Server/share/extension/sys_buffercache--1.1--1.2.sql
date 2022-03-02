/* contrib/sys_buffercache/sys_buffercache--1.1--1.2.sql */

-- complain if script is sourced in ksql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION SYS_BUFFERCACHE UPDATE TO '1.2'" to load this file. \quit

ALTER FUNCTION SYS_BUFFERCACHE_PAGES() PARALLEL SAFE;

/* contrib/sys_prewarm/sys_prewarm--1.0--1.1.sql */

-- complain if script is sourced in ksql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION sys_prewarm UPDATE TO '1.1'" to load this file. \quit

ALTER FUNCTION sys_prewarm(regclass, text, text, int8, int8) PARALLEL SAFE;

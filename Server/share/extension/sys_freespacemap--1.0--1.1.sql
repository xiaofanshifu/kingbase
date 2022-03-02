/* contrib/sys_freespacemap/sys_freespacemap--1.0--1.1.sql */

-- complain if script is sourced in ksql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION sys_freespacemap UPDATE TO '1.1'" to load this file. \quit

ALTER FUNCTION sys_freespace(regclass, bigint) PARALLEL SAFE;
ALTER FUNCTION sys_freespace(regclass) PARALLEL SAFE;

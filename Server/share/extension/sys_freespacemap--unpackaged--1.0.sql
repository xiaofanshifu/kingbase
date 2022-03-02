/* contrib/sys_freespacemap/sys_freespacemap--unpackaged--1.0.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION sys_freespacemap FROM unpackaged" to load this file. \quit

ALTER EXTENSION sys_freespacemap ADD function sys_freespace(regclass,bigint);
ALTER EXTENSION sys_freespacemap ADD function sys_freespace(regclass);

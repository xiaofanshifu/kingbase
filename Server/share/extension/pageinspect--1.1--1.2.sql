/* contrib/pageinspect/pageinspect--1.1--1.2.sql */

-- complain if script is sourced in ksql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION pageinspect UPDATE TO '1.2'" to load this file. \quit

DROP FUNCTION page_header(bytea);
CREATE INTERNAL FUNCTION page_header(IN page bytea,
    OUT lsn sys_lsn,
    OUT checksum smallint,
    OUT flags smallint,
    OUT lower integer,
    OUT upper integer,
    OUT special integer,
    OUT pagesize integer,
    OUT version smallint,
    OUT prune_xid xid)
AS 'MODULE_PATHNAME', 'page_header'
LANGUAGE C STRICT;

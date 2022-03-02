/* contrib/sys_buffercache/sys_buffercache--1.2.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION sys_buffercache" to load this file. \quit
set search_path to sys_catalog;

-- Register the function.
CREATE INTERNAL FUNCTION SYS_BUFFERCACHE_PAGES()
RETURNS SETOF RECORD
AS 'MODULE_PATHNAME', 'sys_buffercache_pages'
LANGUAGE C PARALLEL SAFE;

-- Create a view for convenient access.
CREATE VIEW SYS_BUFFERCACHE AS
	SELECT P.* FROM SYS_BUFFERCACHE_PAGES() AS P
	(BUFFERID INTEGER, RELFILENODE OID, RELTABLESPACE OID, RELDATABASE OID,
	 RELFORKNUMBER INT2, RELBLOCKNUMBER INT8, ISDIRTY BOOL, USAGECOUNT INT2,
	 PINNING_BACKENDS INT4);

CREATE VIEW SYS_BUFFERS AS
  SELECT * FROM  SYS_BUFFERCACHE;


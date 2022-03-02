/* contrib/sys_freespacemap/sys_freespacemap--1.1.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION sys_freespacemap" to load this file. \quit
set search_path to sys_catalog;

-- Register the C function.
CREATE INTERNAL FUNCTION SYS_FREESPACE(regclass, bigint)
RETURNS int2
AS 'MODULE_PATHNAME', 'sys_freespace'
LANGUAGE C STRICT PARALLEL SAFE;

-- sys_freespace shows the recorded space avail at each block in a relation
CREATE INTERNAL FUNCTION
  SYS_FREESPACE(rel regclass, blkno OUT bigint, avail OUT int2)
RETURNS SETOF RECORD
AS $$
  SELECT blkno, sys_freespace($1, blkno) AS avail
  FROM generate_series(0, sys_relation_size($1) / current_setting('block_size')::bigint - 1) AS blkno;
$$
LANGUAGE SQL PARALLEL SAFE;

CREATE OR REPLACE INTERNAL FUNCTION SYS_FREESPACE_ALL_TABLE()
RETURNS SETOF RECORD
AS $$
DECLARE
  rec record;
	 c cursor for SELECT nspname, relname, blkno, sys_freespace(sys_class.oid::REGCLASS, blkno) as avail
  FROM sys_class, sys_namespace, generate_series(0, sys_relation_size(sys_class.oid::regclass) / current_setting('block_size')::bigint - 1) AS blkno
  WHERE relnamespace = sys_namespace.oid AND nspname not in ('PG_CATALOG', 'INFORMATION_SCHEMA') AND relkind ='r' AND relpersistence = 'p'
     AND relpages > 0;
BEGIN
  open c;
  loop
      fetch c into rec;
      if not found then
          exit;
      end if;
	    RETURN NEXT rec;
  end loop;
  close c;
END;
$$
LANGUAGE plsql;

CREATE VIEW SYS_FREESPACES AS
   SELECT * FROM sys_freespace_all_table() AS (nspname name,relname name, blockno bigint,avail smallint);


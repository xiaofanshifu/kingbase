/* contrib/kdb_cast/kdb_cast--1.0.sql */
\echo Use "CREATE EXTENSION kdb_lob" to load this file. \quit

/* fixed bug#27694 */
/* CREATE domain sys_catalog.CLOB as text; */
/* CREATE domain sys_catalog.BLOB as bytea; */

CREATE INTERNAL FUNCTION sys_catalog.EMPTY_BLOB()
RETURNS bytea
AS 'MODULE_PATHNAME', 'empty_blob'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION sys_catalog.BLOB_IMPORT(text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'blob_import'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION sys_catalog.BLOB_EXPORT(bytea, text)
RETURNS int4
AS 'MODULE_PATHNAME', 'blob_export'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION sys_catalog.CLOB_IMPORT(text, text)
RETURNS text
AS 'MODULE_PATHNAME', 'clob_import'
LANGUAGE C ;

CREATE INTERNAL FUNCTION sys_catalog.CLOB_EXPORT(text, text, text)
RETURNS int4
AS 'MODULE_PATHNAME', 'clob_export'
LANGUAGE C ;

CREATE INTERNAL FUNCTION sys_catalog.EMPTY_CLOB()
RETURNS text
AS 'MODULE_PATHNAME', 'empty_blob'
LANGUAGE C STRICT;

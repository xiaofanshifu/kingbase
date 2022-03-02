/* contrib/bloom/bloom--1.0.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION bloom" to load this file. \quit

CREATE INTERNAL FUNCTION BLHANDLER(internal)
RETURNS index_am_handler
AS 'MODULE_PATHNAME' , 'blhandler'
LANGUAGE C;

-- Access method
CREATE ACCESS METHOD BLOOM TYPE INDEX HANDLER blhandler;
COMMENT ON ACCESS METHOD bloom IS 'bloom index access method';

-- Opclasses

CREATE OPERATOR CLASS INT4_OPS
DEFAULT FOR TYPE int4 USING bloom AS
	OPERATOR	1	=(int4, int4),
	FUNCTION	1	hashint4(int4);

CREATE OPERATOR CLASS TEXT_OPS
DEFAULT FOR TYPE text USING bloom AS
	OPERATOR	1	=(text, text),
	FUNCTION	1	hashtext(text);

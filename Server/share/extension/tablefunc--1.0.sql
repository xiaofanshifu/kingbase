/* contrib/tablefunc/tablefunc--1.0.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION tablefunc" to load this file. \quit

CREATE INTERNAL FUNCTION NORMAL_RAND(int4, float8, float8)
RETURNS setof float8
AS 'MODULE_PATHNAME','normal_rand'
LANGUAGE C VOLATILE STRICT;

-- the generic crosstab function:
CREATE INTERNAL FUNCTION CROSSTAB(text)
RETURNS setof record
AS 'MODULE_PATHNAME','crosstab'
LANGUAGE C STABLE STRICT;

-- examples of building custom type-specific crosstab functions:
CREATE TYPE TABLEFUNC_CROSSTAB_2 AS
(
	row_name TEXT,
	category_1 TEXT,
	category_2 TEXT
);

CREATE TYPE TABLEFUNC_CROSSTAB_3 AS
(
	row_name TEXT,
	category_1 TEXT,
	category_2 TEXT,
	category_3 TEXT
);

CREATE TYPE TABLEFUNC_CROSSTAB_4 AS
(
	row_name TEXT,
	category_1 TEXT,
	category_2 TEXT,
	category_3 TEXT,
	category_4 TEXT
);

CREATE INTERNAL FUNCTION CROSSTAB2(text)
RETURNS setof TABLEFUNC_CROSSTAB_2
AS 'MODULE_PATHNAME','crosstab'
LANGUAGE C STABLE STRICT;

CREATE INTERNAL FUNCTION CROSSTAB3(text)
RETURNS setof TABLEFUNC_CROSSTAB_3
AS 'MODULE_PATHNAME','crosstab'
LANGUAGE C STABLE STRICT;

CREATE INTERNAL FUNCTION CROSSTAB4(text)
RETURNS setof TABLEFUNC_CROSSTAB_4
AS 'MODULE_PATHNAME','crosstab'
LANGUAGE C STABLE STRICT;

-- obsolete:
CREATE INTERNAL FUNCTION CROSSTAB(text,int)
RETURNS setof record
AS 'MODULE_PATHNAME','crosstab'
LANGUAGE C STABLE STRICT;

CREATE INTERNAL FUNCTION CROSSTAB(text,text)
RETURNS setof record
AS 'MODULE_PATHNAME','crosstab_hash'
LANGUAGE C STABLE STRICT;

CREATE INTERNAL FUNCTION CONNECTBY(text,text,text,text,int,text)
RETURNS setof record
AS 'MODULE_PATHNAME','connectby_text'
LANGUAGE C STABLE STRICT;

CREATE INTERNAL FUNCTION CONNECTBY(text,text,text,text,int)
RETURNS setof record
AS 'MODULE_PATHNAME','connectby_text'
LANGUAGE C STABLE STRICT;

-- These 2 take the name of a field to ORDER BY as 4th arg (for sorting siblings)

CREATE INTERNAL FUNCTION CONNECTBY(text,text,text,text,text,int,text)
RETURNS setof record
AS 'MODULE_PATHNAME','connectby_text_serial'
LANGUAGE C STABLE STRICT;

CREATE INTERNAL FUNCTION CONNECTBY(text,text,text,text,text,int)
RETURNS setof record
AS 'MODULE_PATHNAME','connectby_text_serial'
LANGUAGE C STABLE STRICT;


/* contrib/operator/operators--1.0.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION kdb_operators" to load this file. \quit

set search_path to SYS_CATALOG, PUBLIC;

------------------------------------------------------------------------
------------------timestamp <-> float8 operator (+, -)--------------------
------------------------------------------------------------------------
-- operator dependent functions
CREATE OR REPLACE INTERNAL FUNCTION TIMESTAMPTZ_PL_FLOAT8(TIMESTAMPTZ, FLOAT8)
RETURNS timestamptz
AS $$
	SELECT $1 + interval '1' day * $2;
$$ LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

CREATE OR REPLACE INTERNAL FUNCTION TIMESTAMP_PL_FLOAT8(TIMESTAMP, FLOAT8)
RETURNS timestamp
AS $$
	SELECT $1 + interval '1' day * $2;
$$ LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

CREATE OR REPLACE INTERNAL FUNCTION FLOAT8_PL_TIMESTAMPTZ(FLOAT8, TIMESTAMPTZ)
RETURNS timestamptz
AS $$
	SELECT $2 + interval '1' day * $1;
$$ LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

CREATE OR REPLACE INTERNAL FUNCTION FLOAT8_PL_TIMESTAMP(FLOAT8, TIMESTAMP)
RETURNS timestamp
AS $$
	SELECT $2 + interval '1' day * $1;
$$ LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

CREATE OR REPLACE INTERNAL FUNCTION TIMESTAMPTZ_MI_FLOAT8(TIMESTAMPTZ, FLOAT8)
RETURNS timestamptz
AS $$
	SELECT $1 - interval '1' day * $2;
$$ LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

CREATE OR REPLACE INTERNAL FUNCTION TIMESTAMP_MI_FLOAT8(TIMESTAMP, FLOAT8)
RETURNS timestamp
AS $$
	SELECT $1 - interval '1' day * $2;
$$ LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

-- create operators
CREATE OPERATOR +(
	LEFTARG = timestamptz,
	RIGHTARG = float8,
	PROCEDURE = timestamptz_pl_float8,
	COMMUTATOR = +
);

CREATE OPERATOR +(
	LEFTARG = timestamp,
	RIGHTARG = float8,
	PROCEDURE = timestamp_pl_float8,
	COMMUTATOR = +
);

CREATE OPERATOR +(
	LEFTARG = float8,
	RIGHTARG = timestamptz,
	PROCEDURE = float8_pl_timestamptz,
	COMMUTATOR = +
);

CREATE OPERATOR +(
	LEFTARG = float8,
	RIGHTARG = timestamp,
	PROCEDURE = float8_pl_timestamp,
	COMMUTATOR = +
);

CREATE OPERATOR -(
	LEFTARG = timestamptz,
	RIGHTARG = float8,
	PROCEDURE = timestamptz_mi_float8
);

CREATE OPERATOR -(
	LEFTARG = timestamp,
	RIGHTARG = float8,
	PROCEDURE = timestamp_mi_float8
);

------------------------------------------------------------------------
----------------------(int4 and int2)mod operator (%)-------------------
------------------------------------------------------------------------
-- operator dependent functions
CREATE INTERNAL FUNCTION INT24MOD(INT2, INT4)
RETURNS int4
AS 'MODULE_PATHNAME', 'int24mod'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

CREATE INTERNAL FUNCTION INT42MOD(INT4, INT2)
returns INT4
AS 'MODULE_PATHNAME', 'int42mod'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

-- create operators
CREATE OPERATOR %(
	LEFTARG = int2,
	RIGHTARG = int4,
	PROCEDURE = int24mod
);

CREATE OPERATOR %(
	LEFTARG = int4,
	RIGHTARG = int2,
	PROCEDURE = int42mod
);

------------------------------------------------------------------------
------------------numeric operators (&, |, #)---------------------------
------------------------------------------------------------------------
-- operator dependent functions
CREATE INTERNAL FUNCTION NUMERICAND(NUMERIC, NUMERIC)
RETURNS numeric
AS 'MODULE_PATHNAME','numeric_and'
LANGUAGE C
IMMUTABLE
STRICT
PARALLEL SAFE;

CREATE INTERNAL FUNCTION NUMERICOR(NUMERIC, NUMERIC)
RETURNS numeric
AS 'MODULE_PATHNAME','numeric_or'
LANGUAGE C
IMMUTABLE
STRICT
PARALLEL SAFE;

CREATE INTERNAL FUNCTION NUMERICXOR(NUMERIC, NUMERIC)
RETURNS numeric
AS 'MODULE_PATHNAME','numeric_xor'
LANGUAGE C
IMMUTABLE
STRICT
PARALLEL SAFE;

-- create operators
CREATE OPERATOR &(
	LEFTARG = numeric,
	RIGHTARG = numeric,
	PROCEDURE = numericand,
	COMMUTATOR = &
);

CREATE OPERATOR |(
	LEFTARG = numeric,
	RIGHTARG = numeric,
	PROCEDURE = numericor,
	COMMUTATOR = |
);

CREATE OPERATOR #(
	LEFTARG = numeric,
	RIGHTARG = numeric,
	PROCEDURE = numericxor,
	COMMUTATOR = #
);

------------------------------------------------------------------------
---------bpchar <-> varchar operator (<. <=, =, <>, >, >=)--------------
------------------------------------------------------------------------
-- operator dependent functions
CREATE INTERNAL FUNCTION BPCHARVARCHAREQ(BPCHAR, VARCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','bpcharvarchareq'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION BPCHARVARCHARNE(BPCHAR, VARCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','bpcharvarcharne'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION BPCHARVARCHARLT(BPCHAR, VARCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','bpcharvarcharlt'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION BPCHARVARCHARGT(BPCHAR, VARCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','bpcharvarchargt'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION BPCHARVARCHARLE(BPCHAR, VARCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','bpcharvarcharle'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION BPCHARVARCHARGE(BPCHAR, VARCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','bpcharvarcharge'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION VARCHARBPCHAREQ(VARCHAR, BPCHAR)
RETURNS bool
LANGUAGE C
AS 'MODULE_PATHNAME','varcharbpchareq'
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION VARCHARBPCHARNE(VARCHAR, BPCHAR)
RETURNS bool
LANGUAGE C
AS 'MODULE_PATHNAME','varcharbpcharne'
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION VARCHARBPCHARLT(VARCHAR, BPCHAR)
RETURNS bool
LANGUAGE C
AS 'MODULE_PATHNAME','varcharbpcharlt'
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION VARCHARBPCHARGT(VARCHAR, BPCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','varcharbpchargt'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION VARCHARBPCHARLE(VARCHAR, BPCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','varcharbpcharle'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION VARCHARBPCHARGE(VARCHAR, BPCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','varcharbpcharge'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

-- create operators
CREATE OPERATOR =(
	LEFTARG = bpchar,
	RIGHTARG = varchar,
	PROCEDURE = bpcharvarchareq,
	COMMUTATOR = =,
	NEGATOR = <>,
	RESTRICT = eqsel,
	JOIN = eqjoinsel,
	HASHES, MERGES
);

CREATE OPERATOR <>(
	LEFTARG = bpchar,
	RIGHTARG = varchar,
	PROCEDURE = bpcharvarcharne,
	COMMUTATOR = <>,
	NEGATOR = =,
	RESTRICT = neqsel,
	JOIN = neqjoinsel
);

CREATE OPERATOR <(
	LEFTARG = bpchar,
	RIGHTARG = varchar,
	PROCEDURE = bpcharvarcharlt,
	COMMUTATOR = >,
	NEGATOR = >=,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OPERATOR >(
	LEFTARG = bpchar,
	RIGHTARG = varchar,
	PROCEDURE = bpcharvarchargt,
	COMMUTATOR = <,
	NEGATOR = <=,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OPERATOR <=(
	LEFTARG = bpchar,
	RIGHTARG = varchar,
	PROCEDURE = bpcharvarcharle,
	COMMUTATOR = >=,
	NEGATOR = >,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OPERATOR >=(
	LEFTARG = bpchar,
	RIGHTARG = varchar,
	PROCEDURE = bpcharvarcharge,
	COMMUTATOR = <=,
	NEGATOR = <,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OPERATOR =(
	LEFTARG = varchar,
	RIGHTARG = bpchar,
	PROCEDURE = varcharbpchareq,
	COMMUTATOR = =,
	NEGATOR = <>,
	RESTRICT = eqsel,
	JOIN = eqjoinsel,
	HASHES, MERGES
);

CREATE OPERATOR <>(
	LEFTARG = varchar,
	RIGHTARG = bpchar,
	PROCEDURE = varcharbpcharne,
	COMMUTATOR = <>,
	NEGATOR = =,
	RESTRICT = neqsel,
	JOIN = neqjoinsel
);

CREATE OPERATOR <(
	LEFTARG = varchar,
	RIGHTARG = bpchar,
	PROCEDURE = varcharbpcharlt,
	COMMUTATOR = >,
	NEGATOR = >=,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OPERATOR >(
	LEFTARG = varchar,
	RIGHTARG = bpchar,
	PROCEDURE = varcharbpchargt,
	COMMUTATOR = <,
	NEGATOR = <=,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OPERATOR <=(
	LEFTARG = varchar,
	RIGHTARG = bpchar,
	PROCEDURE = varcharbpcharle,
	COMMUTATOR = >=,
	NEGATOR = >,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OPERATOR >=(
	LEFTARG = varchar,
	RIGHTARG = bpchar,
	PROCEDURE = varcharbpcharge,
	COMMUTATOR = <=,
	NEGATOR = <,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

------------------------------------------------------------------------
----------------varchar operator (<. <=, =, <>, >, >=)------------------
------------------------------------------------------------------------
-- operator dependent functions
CREATE INTERNAL FUNCTION VARCHAREQ(VARCHAR, VARCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','varchareq'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION VARCHARNE(VARCHAR, VARCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','varcharne'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION VARCHARLT(VARCHAR, VARCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','varcharlt'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION VARCHARLE(VARCHAR, VARCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','varcharle'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION VARCHARGT(VARCHAR, VARCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','varchargt'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION VARCHARGE(VARCHAR, VARCHAR)
RETURNS bool
AS 'MODULE_PATHNAME','varcharge'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

-- create operators
CREATE OPERATOR =(
	LEFTARG = varchar,
	RIGHTARG = varchar,
	PROCEDURE = varchareq,
	COMMUTATOR = =,
	NEGATOR = <>,
	RESTRICT = eqsel,
	JOIN = eqjoinsel,
	HASHES, MERGES
);

CREATE OPERATOR <>(
	LEFTARG = varchar,
	RIGHTARG = varchar,
	PROCEDURE = varcharne,
	COMMUTATOR = <>,
	NEGATOR = =,
	RESTRICT = neqsel,
	JOIN = neqjoinsel
);

CREATE OPERATOR <(
	LEFTARG = varchar,
	RIGHTARG = varchar,
	PROCEDURE = varcharlt,
	COMMUTATOR = >,
	NEGATOR = >=,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OPERATOR <=(
	LEFTARG = varchar,
	RIGHTARG = varchar,
	PROCEDURE = varcharle,
	COMMUTATOR = >=,
	NEGATOR = >,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OPERATOR >(
	LEFTARG = varchar,
	RIGHTARG = varchar,
	PROCEDURE = varchargt,
	COMMUTATOR = <,
	NEGATOR = <=,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OPERATOR >=(
	LEFTARG = varchar,
	RIGHTARG = varchar,
	PROCEDURE = varcharge,
	COMMUTATOR = <=,
	NEGATOR = <,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

------------------------------------------------------------------------
---------------------------text operator (-)----------------------------
------------------------------------------------------------------------
-- operator dependent functions
CREATE INTERNAL FUNCTION TEXT_NUMERIC(BPCHAR)
RETURNS numeric
AS 'MODULE_PATHNAME', 'text_numeric'
LANGUAGE C
STRICT
IMMUTABLE
PARALLEL SAFE;

CREATE INTERNAL FUNCTION TEXT_NUMERIC(VARCHAR)
RETURNS numeric
AS 'MODULE_PATHNAME', 'text_numeric'
LANGUAGE C
STRICT
IMMUTABLE
PARALLEL SAFE;

CREATE INTERNAL FUNCTION TEXT_NUMERIC(TEXT)
RETURNS numeric
AS 'MODULE_PATHNAME','text_numeric'
LANGUAGE C
STRICT
IMMUTABLE
PARALLEL SAFE;

CREATE INTERNAL FUNCTION NUMERIC_TEXT(NUMERIC)
RETURNS text
AS 'MODULE_PATHNAME','numeric_text'
LANGUAGE C
STRICT
IMMUTABLE
PARALLEL SAFE;

--numeric and text conversion methods
CREATE CAST (bpchar as numeric) WITH FUNCTION text_numeric(bpchar) 	AS IMPLICIT;
CREATE CAST (varchar as numeric) WITH FUNCTION text_numeric(varchar) AS IMPLICIT;
CREATE CAST (text AS numeric) WITH FUNCTION text_numeric(text) AS IMPLICIT;
CREATE CAST (numeric AS text) WITH FUNCTION numeric_text(numeric) AS IMPLICIT;

/* operators for + -, have different priority in Oracle, we will deal with lator
CREATE INTERNAL FUNCTION textminus(text, text)
RETURNS text
AS 'MODULE_PATHNAME','textminus'
LANGUAGE C
IMMUTABLE
PARALLEL SAFE
STRICT;
*/

--create operators
/* the operator is from SQL Server, and have bad effect on cast rules, just remove it
CREATE OPERATOR +(
	LEFTARG = text,
	RIGHTARG = text,
	PROCEDURE = textcat
);
*/

/* operators for + -, have different priority in Oracle, we will deal with lator
CREATE OPERATOR -(
	LEFTARG = text,
	RIGHTARG = text,
	PROCEDURE = textminus
);
*/

------------------------------------------------------------------------
----------for index(btree, brin, hash) about bpchar vs varchar----------
-------------varchar vs bpchar and varchar vs varchar-------------------
------------------------------------------------------------------------
-- functions for index
CREATE INTERNAL FUNCTION BTBPCHARVARCHARCMP(BPCHAR, VARCHAR)
RETURNS int4
AS 'MODULE_PATHNAME','btbpcharvarcharcmp'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION BTVARCHARBPCHARCMP(VARCHAR, BPCHAR)
RETURNS int4
AS 'MODULE_PATHNAME','btvarcharbpcharcmp'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION BTVARCHARCMP(VARCHAR, VARCHAR)
returns INT4
AS 'MODULE_PATHNAME','btvarcharcmp'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

CREATE INTERNAL FUNCTION HASHVARCHAR(VARCHAR)
returns INT4
AS 'MODULE_PATHNAME','hashvarchar'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

/* varchar btree index, original varchar index is build on text
 * in order to support btree index on varchar
 * if we want to support to use index on varchar vs bpchar or bpchar vs varchar
 * we must add them in a some index family
 */
-- create btree index
CREATE OPERATOR CLASS SYS_CATALOG.BPVARCHAR_OPS
DEFAULT FOR TYPE varchar USING btree FAMILY bpchar_ops AS
-- standard varchar vs varchar
	OPERATOR 1 <  ,
	OPERATOR 2 <= ,
	OPERATOR 3 =  ,
	OPERATOR 4 >= ,
	OPERATOR 5 >  ,
	FUNCTION 1 btvarcharcmp(varchar, varchar) ,
	FUNCTION 2 bttextsortsupport(internal) ,

-- standard varchar vs char
	OPERATOR 1 < (varchar, bpchar) ,
	OPERATOR 2 <= (varchar, bpchar) ,
	OPERATOR 3 = (varchar, bpchar) ,
	OPERATOR 4 >= (varchar, bpchar) ,
	OPERATOR 5 > (varchar, bpchar) ,
	FUNCTION 1 (varchar, bpchar)btvarcharbpcharcmp(varchar, bpchar) ,

	-- standard char vs varchar
	OPERATOR 1 < (bpchar, varchar) ,
	OPERATOR 2 <= (bpchar, varchar) ,
	OPERATOR 3 = (bpchar, varchar) ,
	OPERATOR 4 >= (bpchar, varchar) ,
	OPERATOR 5 > (bpchar, varchar) ,
	FUNCTION 1 (bpchar, varchar)btbpcharvarcharcmp(bpchar, varchar) ;

/* varchar hash index, original varchar index is build on text
 * in order to support hash index on varchar
 * if we want to support to use index on varchar vs bpchar or bpchar vs varchar
 * we must add them in a some index family
 */
-- create hash index
CREATE OPERATOR CLASS SYS_CATALOG.BPVARCHAR_OPS
DEFAULT FOR TYPE varchar USING hash FAMILY bpchar_ops AS
-- standard char vs varchar
	OPERATOR 1 = (varchar, varchar) ,
	OPERATOR 1 = (bpchar, varchar) ,
	OPERATOR 1 = (varchar, bpchar) ,
	FUNCTION 1 hashvarchar(varchar) ;

/* varchar brin index, original varchar index is build on text
 * in order to support brin index on varchar
 * if we want to support to use index on varchar vs bpchar or bpchar vs varchar
 * we must add them in a some index family
 */
-- create brin index
CREATE OPERATOR CLASS SYS_CATALOG.VARCHAR_MINMAX_OPS
DEFAULT FOR TYPE varchar USING brin FAMILY bpchar_minmax_ops AS
-- standard varchar vs varchar
	OPERATOR 1 < (varchar, varchar) ,
	OPERATOR 2 <=(varchar, varchar) ,
	OPERATOR 3 = (varchar, varchar) ,
	OPERATOR 4 >=(varchar, varchar) ,
	OPERATOR 5 > (varchar, varchar) ,
	FUNCTION 1 (varchar, varchar) brin_minmax_opcinfo(internal) ,
	FUNCTION 2 (varchar, varchar) brin_minmax_add_value(internal, internal, internal, internal) ,
	FUNCTION 3 (varchar, varchar) brin_minmax_consistent(internal, internal, internal) ,
	FUNCTION 4 (varchar, varchar) brin_minmax_union(internal, internal, internal) ,

-- standard varchar vs bpchar
	OPERATOR 1 < (varchar, char) ,
	OPERATOR 2 <=(varchar, char) ,
	OPERATOR 3 = (varchar, char) ,
	OPERATOR 4 >=(varchar, char) ,
	OPERATOR 5 > (varchar, char) ,
	FUNCTION 1 (varchar, char) brin_minmax_opcinfo(internal) ,
	FUNCTION 2 (varchar, char) brin_minmax_add_value(internal, internal, internal, internal) ,
	FUNCTION 3 (varchar, char) brin_minmax_consistent(internal, internal, internal) ,
	FUNCTION 4 (varchar, char) brin_minmax_union(internal, internal, internal) ,

-- standard char vs varchar
	OPERATOR 1 < (char, varchar) ,
	OPERATOR 2 <=(char, varchar) ,
	OPERATOR 3 = (char, varchar) ,
	OPERATOR 4 >=(char, varchar) ,
	OPERATOR 5 > (char, varchar) ,
	FUNCTION 1 (char, varchar) brin_minmax_opcinfo(internal) ,
	FUNCTION 2 (char, varchar) brin_minmax_add_value(internal, internal, internal, internal) ,
	FUNCTION 3 (char, varchar) brin_minmax_consistent(internal, internal, internal) ,
	FUNCTION 4 (char, varchar) brin_minmax_union(internal, internal, internal) ;

------------------------------------------------------------------------
----------disable text || anynonarray (influnced by cast rules) --------
----------support text || json/jsonb  ----------------------------------
----------text || othertype should be here if required------------------
CREATE INTERNAL FUNCTION JSON_TEXT_CAT(JSON, TEXT)
RETURNS text
AS $$
    select $1::sys_catalog.text || $2;
$$ LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

CREATE INTERNAL FUNCTION TEXT_JSON_CAT(TEXT, JSON)
RETURNS text
AS $$
    select $1 || $2::sys_catalog.text;
$$ LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

CREATE INTERNAL FUNCTION JSONB_TEXT_CAT(JSONB, TEXT)
RETURNS text
AS $$
    select $1::sys_catalog.text || $2;
$$ LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

CREATE INTERNAL FUNCTION TEXT_JSONB_CAT(TEXT, JSONB)
RETURNS text
AS $$
    select $1 || $2::sys_catalog.text;
$$ LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

CREATE OPERATOR ||(
                LEFTARG = json,
                RIGHTARG = text,
                PROCEDURE = json_text_cat
);
CREATE OPERATOR ||(
                LEFTARG = text,
                RIGHTARG = json,
                PROCEDURE = text_json_cat
);
CREATE OPERATOR ||(
                LEFTARG = jsonb,
                RIGHTARG = text,
                PROCEDURE = jsonb_text_cat
);
CREATE OPERATOR ||(
                LEFTARG = text,
                RIGHTARG = jsonb,
                PROCEDURE = text_jsonb_cat
);
reset search_path;

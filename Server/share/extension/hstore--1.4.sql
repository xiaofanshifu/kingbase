/* contrib/hstore/hstore--1.4.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION HSTORE" to load this file. \quit

CREATE TYPE HSTORE;

CREATE INTERNAL FUNCTION HSTORE_IN(cstring)
RETURNS hstore
AS 'MODULE_PATHNAME', 'hstore_in'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION HSTORE_OUT(hstore)
RETURNS cstring
AS 'MODULE_PATHNAME', 'hstore_out'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION HSTORE_RECV(internal)
RETURNS hstore
AS 'MODULE_PATHNAME', 'hstore_recv'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION HSTORE_SEND(hstore)
RETURNS bytea
AS 'MODULE_PATHNAME','hstore_send'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE TYPE HSTORE (
        INTERNALLENGTH = -1,
        INPUT = hstore_in,
        OUTPUT = hstore_out,
        RECEIVE = hstore_recv,
        SEND = hstore_send,
        STORAGE = extended
);

CREATE INTERNAL FUNCTION HSTORE_VERSION_DIAG(hstore)
RETURNS integer
AS 'MODULE_PATHNAME','hstore_version_diag'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION FETCHVAL(hstore,text)
RETURNS text
AS 'MODULE_PATHNAME','hstore_fetchval'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR -> (
	LEFTARG = hstore,
	RIGHTARG = text,
	PROCEDURE = FETCHVAL
);

CREATE INTERNAL FUNCTION SLICE_ARRAY(hstore,text[])
RETURNS text[]
AS 'MODULE_PATHNAME','hstore_slice_to_array'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR -> (
	LEFTARG = hstore,
	RIGHTARG = text[],
	PROCEDURE = slice_array
);

CREATE INTERNAL FUNCTION SLICE(hstore,text[])
RETURNS hstore
AS 'MODULE_PATHNAME','hstore_slice_to_hstore'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION ISEXISTS(hstore,text)
RETURNS bool
AS 'MODULE_PATHNAME','hstore_exists'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION EXIST(hstore,text)
RETURNS bool
AS 'MODULE_PATHNAME','hstore_exists'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR ? (
	LEFTARG = hstore,
	RIGHTARG = text,
	PROCEDURE = exist,
	RESTRICT = contsel,
	JOIN = contjoinsel
);

CREATE INTERNAL FUNCTION EXISTS_ANY(hstore,text[])
RETURNS bool
AS 'MODULE_PATHNAME','hstore_exists_any'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR ?| (
	LEFTARG = hstore,
	RIGHTARG = text[],
	PROCEDURE = exists_any,
	RESTRICT = contsel,
	JOIN = contjoinsel
);

CREATE INTERNAL FUNCTION EXISTS_ALL(hstore,text[])
RETURNS bool
AS 'MODULE_PATHNAME','hstore_exists_all'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR ?& (
	LEFTARG = hstore,
	RIGHTARG = text[],
	PROCEDURE = exists_all,
	RESTRICT = contsel,
	JOIN = contjoinsel
);

CREATE INTERNAL FUNCTION ISDEFINED(hstore,text)
RETURNS bool
AS 'MODULE_PATHNAME','hstore_defined'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION DEFINED(hstore,text)
RETURNS bool
AS 'MODULE_PATHNAME','hstore_defined'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION DELETE(hstore,text)
RETURNS hstore
AS 'MODULE_PATHNAME','hstore_delete'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION DELETE(hstore,text[])
RETURNS hstore
AS 'MODULE_PATHNAME','hstore_delete_array'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION DELETE(hstore,hstore)
RETURNS hstore
AS 'MODULE_PATHNAME','hstore_delete_hstore'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR - (
	LEFTARG = hstore,
	RIGHTARG = text,
	PROCEDURE = delete
);

CREATE OPERATOR - (
	LEFTARG = hstore,
	RIGHTARG = text[],
	PROCEDURE = delete
);

CREATE OPERATOR - (
	LEFTARG = hstore,
	RIGHTARG = hstore,
	PROCEDURE = delete
);

CREATE INTERNAL FUNCTION HS_CONCAT(hstore,hstore)
RETURNS hstore
AS 'MODULE_PATHNAME','hstore_concat'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR || (
	LEFTARG = hstore,
	RIGHTARG = hstore,
	PROCEDURE = hs_concat
);

CREATE INTERNAL FUNCTION HS_CONTAINS(hstore,hstore)
RETURNS bool
AS 'MODULE_PATHNAME','hstore_contains'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION HS_CONTAINED(hstore,hstore)
RETURNS bool
AS 'MODULE_PATHNAME','hstore_contained'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR @> (
	LEFTARG = hstore,
	RIGHTARG = hstore,
	PROCEDURE = hs_contains,
	COMMUTATOR = '<@',
	RESTRICT = contsel,
	JOIN = contjoinsel
);

CREATE OPERATOR <@ (
	LEFTARG = hstore,
	RIGHTARG = hstore,
	PROCEDURE = hs_contained,
	COMMUTATOR = '@>',
	RESTRICT = contsel,
	JOIN = contjoinsel
);

-- obsolete:
CREATE OPERATOR @ (
	LEFTARG = hstore,
	RIGHTARG = hstore,
	PROCEDURE = hs_contains,
	COMMUTATOR = '~',
	RESTRICT = contsel,
	JOIN = contjoinsel
);

CREATE OPERATOR ~ (
	LEFTARG = hstore,
	RIGHTARG = hstore,
	PROCEDURE = hs_contained,
	COMMUTATOR = '@',
	RESTRICT = contsel,
	JOIN = contjoinsel
);

CREATE INTERNAL FUNCTION TCONVERT(text,text)
RETURNS hstore
AS 'MODULE_PATHNAME','hstore_from_text'
LANGUAGE C IMMUTABLE PARALLEL SAFE; -- not STRICT; needs to allow (key,NULL)

CREATE INTERNAL FUNCTION HSTORE(text,text)
RETURNS hstore
AS 'MODULE_PATHNAME','hstore_from_text'
LANGUAGE C IMMUTABLE PARALLEL SAFE; -- not STRICT; needs to allow (key,NULL)

CREATE INTERNAL FUNCTION HSTORE(text[],text[])
RETURNS hstore
AS 'MODULE_PATHNAME', 'hstore_from_arrays'
LANGUAGE C IMMUTABLE PARALLEL SAFE; -- not STRICT; allows (keys,null)

CREATE INTERNAL FUNCTION HSTORE(text[])
RETURNS hstore
AS 'MODULE_PATHNAME', 'hstore_from_array'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (text[] AS hstore)
  WITH FUNCTION hstore(text[]);

CREATE INTERNAL FUNCTION HSTORE_TO_JSON(hstore)
RETURNS json
AS 'MODULE_PATHNAME', 'hstore_to_json'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (hstore AS json)
  WITH FUNCTION hstore_to_json(hstore);

CREATE INTERNAL FUNCTION HSTORE_TO_JSON_LOOSE(hstore)
RETURNS json
AS 'MODULE_PATHNAME', 'hstore_to_json_loose'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION HSTORE_TO_JSONB(hstore)
RETURNS jsonb
AS 'MODULE_PATHNAME', 'hstore_to_jsonb'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (hstore AS jsonb)
  WITH FUNCTION hstore_to_jsonb(hstore);

CREATE INTERNAL FUNCTION HSTORE_TO_JSONB_LOOSE(hstore)
RETURNS jsonb
AS 'MODULE_PATHNAME', 'hstore_to_jsonb_loose'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION HSTORE(record)
RETURNS hstore
AS 'MODULE_PATHNAME', 'hstore_from_record'
LANGUAGE C IMMUTABLE PARALLEL SAFE; -- not STRICT; allows (null::recordtype)

CREATE INTERNAL FUNCTION HSTORE_TO_ARRAY(hstore)
RETURNS text[]
AS 'MODULE_PATHNAME','hstore_to_array'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR %% (
       RIGHTARG = hstore,
       PROCEDURE = hstore_to_array
);

CREATE INTERNAL FUNCTION HSTORE_TO_MATRIX(hstore)
RETURNS text[]
AS 'MODULE_PATHNAME','hstore_to_matrix'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR %# (
       RIGHTARG = hstore,
       PROCEDURE = hstore_to_matrix
);

CREATE INTERNAL FUNCTION AKEYS(hstore)
RETURNS text[]
AS 'MODULE_PATHNAME','hstore_akeys'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION AVALS(hstore)
RETURNS text[]
AS 'MODULE_PATHNAME','hstore_avals'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION SKEYS(hstore)
RETURNS setof text
AS 'MODULE_PATHNAME','hstore_skeys'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION SVALS(hstore)
RETURNS setof text
AS 'MODULE_PATHNAME','hstore_svals'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION EACH(IN hs hstore,
    OUT key text,
    OUT value text)
RETURNS SETOF record
AS 'MODULE_PATHNAME','hstore_each'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION POPULATE_RECORD(anyelement,hstore)
RETURNS anyelement
AS 'MODULE_PATHNAME', 'hstore_populate_record'
LANGUAGE C IMMUTABLE PARALLEL SAFE; -- not STRICT; allows (null::rectype,hstore)

CREATE OPERATOR #= (
	LEFTARG = anyelement,
	RIGHTARG = hstore,
	PROCEDURE = populate_record
);

-- btree support

CREATE INTERNAL FUNCTION HSTORE_EQ(hstore,hstore)
RETURNS boolean
AS 'MODULE_PATHNAME','hstore_eq'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION HSTORE_NE(hstore,hstore)
RETURNS boolean
AS 'MODULE_PATHNAME','hstore_ne'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION HSTORE_GT(hstore,hstore)
RETURNS boolean
AS 'MODULE_PATHNAME','hstore_gt'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION HSTORE_GE(hstore,hstore)
RETURNS boolean
AS 'MODULE_PATHNAME','hstore_ge'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION HSTORE_LT(hstore,hstore)
RETURNS boolean
AS 'MODULE_PATHNAME','hstore_lt'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION HSTORE_LE(hstore,hstore)
RETURNS boolean
AS 'MODULE_PATHNAME','hstore_le'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION HSTORE_CMP(hstore,hstore)
RETURNS integer
AS 'MODULE_PATHNAME','hstore_cmp'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR = (
       LEFTARG = hstore,
       RIGHTARG = hstore,
       PROCEDURE = hstore_eq,
       COMMUTATOR = =,
       NEGATOR = <>,
       RESTRICT = eqsel,
       JOIN = eqjoinsel,
       MERGES,
       HASHES
);
CREATE OPERATOR <> (
       LEFTARG = hstore,
       RIGHTARG = hstore,
       PROCEDURE = hstore_ne,
       COMMUTATOR = <>,
       NEGATOR = =,
       RESTRICT = neqsel,
       JOIN = neqjoinsel
);

-- the comparison operators have funky names (and are undocumented)
-- in an attempt to discourage anyone from actually using them. they
-- only exist to support the btree opclass

CREATE OPERATOR #<# (
       LEFTARG = hstore,
       RIGHTARG = hstore,
       PROCEDURE = hstore_lt,
       COMMUTATOR = #>#,
       NEGATOR = #>=#,
       RESTRICT = scalarltsel,
       JOIN = scalarltjoinsel
);
CREATE OPERATOR #<=# (
       LEFTARG = hstore,
       RIGHTARG = hstore,
       PROCEDURE = hstore_le,
       COMMUTATOR = #>=#,
       NEGATOR = #>#,
       RESTRICT = scalarltsel,
       JOIN = scalarltjoinsel
);
CREATE OPERATOR #># (
       LEFTARG = hstore,
       RIGHTARG = hstore,
       PROCEDURE = hstore_gt,
       COMMUTATOR = #<#,
       NEGATOR = #<=#,
       RESTRICT = scalargtsel,
       JOIN = scalargtjoinsel
);
CREATE OPERATOR #>=# (
       LEFTARG = hstore,
       RIGHTARG = hstore,
       PROCEDURE = hstore_ge,
       COMMUTATOR = #<=#,
       NEGATOR = #<#,
       RESTRICT = scalargtsel,
       JOIN = scalargtjoinsel
);

CREATE OPERATOR CLASS BTREE_HSTORE_OPS
DEFAULT FOR TYPE hstore USING btree
AS
	OPERATOR	1	#<# ,
	OPERATOR	2	#<=# ,
	OPERATOR	3	= ,
	OPERATOR	4	#>=# ,
	OPERATOR	5	#># ,
	FUNCTION	1	hstore_cmp(hstore,hstore);

-- hash support

CREATE INTERNAL FUNCTION HSTORE_HASH(hstore)
RETURNS integer
AS 'MODULE_PATHNAME','hstore_hash'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR CLASS HASH_HSTORE_OPS
DEFAULT FOR TYPE hstore USING hash
AS
	OPERATOR	1	= ,
	FUNCTION	1	hstore_hash(hstore);

-- GiST support

CREATE TYPE GHSTORE;

CREATE INTERNAL FUNCTION GHSTORE_IN(cstring)
RETURNS ghstore
AS 'MODULE_PATHNAME', 'ghstore_in'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION GHSTORE_OUT(ghstore)
RETURNS cstring
AS 'MODULE_PATHNAME', 'ghstore_out'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE TYPE GHSTORE (
        INTERNALLENGTH = -1,
        INPUT = ghstore_in,
        OUTPUT = ghstore_out
);

CREATE INTERNAL FUNCTION GHSTORE_COMPRESS(internal)
RETURNS internal
AS 'MODULE_PATHNAME', 'ghstore_compress'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GHSTORE_DECOMPRESS(internal)
RETURNS internal
AS 'MODULE_PATHNAME', 'ghstore_decompress'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GHSTORE_PENALTY(internal,internal,internal)
RETURNS internal
AS 'MODULE_PATHNAME', 'ghstore_penalty'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GHSTORE_PICKSPLIT(internal, internal)
RETURNS internal
AS 'MODULE_PATHNAME', 'ghstore_picksplit'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GHSTORE_UNION(internal, internal)
RETURNS ghstore
AS 'MODULE_PATHNAME', 'ghstore_union'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GHSTORE_SAME(ghstore, ghstore, internal)
RETURNS internal
AS 'MODULE_PATHNAME', 'ghstore_same'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GHSTORE_CONSISTENT(internal,hstore,smallint,oid,internal)
RETURNS bool
AS 'MODULE_PATHNAME', 'ghstore_consistent'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS GIST_HSTORE_OPS
DEFAULT FOR TYPE hstore USING gist
AS
	OPERATOR        7       @> ,
	OPERATOR        9       ?(hstore,text) ,
	OPERATOR        10      ?|(hstore,text[]) ,
	OPERATOR        11      ?&(hstore,text[]) ,
        --OPERATOR        8       <@ ,
        OPERATOR        13      @ ,
        --OPERATOR        14      ~ ,
        FUNCTION        1       ghstore_consistent (internal, hstore, smallint, oid, internal),
        FUNCTION        2       ghstore_union (internal, internal),
        FUNCTION        3       ghstore_compress (internal),
        FUNCTION        4       ghstore_decompress (internal),
        FUNCTION        5       ghstore_penalty (internal, internal, internal),
        FUNCTION        6       ghstore_picksplit (internal, internal),
        FUNCTION        7       ghstore_same (ghstore, ghstore, internal),
        STORAGE         ghstore;

-- GIN support

CREATE INTERNAL FUNCTION GIN_EXTRACT_HSTORE(hstore, internal)
RETURNS internal
AS 'MODULE_PATHNAME', 'gin_extract_hstore'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GIN_EXTRACT_HSTORE_QUERY(hstore, internal, int2, internal, internal)
RETURNS internal
AS 'MODULE_PATHNAME', 'gin_extract_hstore_query'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GIN_CONSISTENT_HSTORE(internal, int2, hstore, int4, internal, internal)
RETURNS bool
AS 'MODULE_PATHNAME', 'gin_consistent_hstore'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS GIN_HSTORE_OPS
DEFAULT FOR TYPE hstore USING gin
AS
	OPERATOR        7       @>,
	OPERATOR        9       ?(hstore,text),
	OPERATOR        10      ?|(hstore,text[]),
	OPERATOR        11      ?&(hstore,text[]),
	FUNCTION        1       bttextcmp(text,text),
	FUNCTION        2       gin_extract_hstore(hstore, internal),
	FUNCTION        3       gin_extract_hstore_query(hstore, internal, int2, internal, internal),
	FUNCTION        4       gin_consistent_hstore(internal, int2, hstore, int4, internal, internal),
	STORAGE         text;

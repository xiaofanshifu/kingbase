/* contrib/sys_trgm/sys_trgm--1.3.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION sys_trgm" to load this file. \quit

-- Deprecated function
CREATE INTERNAL FUNCTION SET_LIMIT(float4)
RETURNS float4
AS 'MODULE_PATHNAME' , 'set_limit'
LANGUAGE C STRICT VOLATILE PARALLEL UNSAFE;

-- Deprecated function
CREATE INTERNAL FUNCTION SHOW_LIMIT()
RETURNS float4
AS 'MODULE_PATHNAME' , 'show_limit'
LANGUAGE C STRICT STABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION SHOW_TRGM(text)
RETURNS _text
AS 'MODULE_PATHNAME' , 'show_trgm'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION SIMILARITY(text,text)
RETURNS float4
AS 'MODULE_PATHNAME' , 'similarity'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION SIMILARITY_OP(text,text)
RETURNS bool
AS 'MODULE_PATHNAME' , 'similarity_op'
LANGUAGE C STRICT STABLE PARALLEL SAFE;  -- stable because depends on sys_trgm.similarity_threshold

CREATE OPERATOR % (
        LEFTARG = text,
        RIGHTARG = text,
        PROCEDURE = similarity_op,
        COMMUTATOR = '%',
        RESTRICT = contsel,
        JOIN = contjoinsel
);

CREATE INTERNAL FUNCTION WORD_SIMILARITY(text,text)
RETURNS float4
AS 'MODULE_PATHNAME' , 'word_similarity'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION WORD_SIMILARITY_OP(text,text)
RETURNS bool
AS 'MODULE_PATHNAME' , 'word_similarity_op'
LANGUAGE C STRICT STABLE PARALLEL SAFE;  -- stable because depends on sys_trgm.word_similarity_threshold

CREATE INTERNAL FUNCTION WORD_SIMILARITY_COMMUTATOR_OP(text,text)
RETURNS bool
AS 'MODULE_PATHNAME', 'word_similarity_commutator_op'
LANGUAGE C STRICT STABLE PARALLEL SAFE;  -- stable because depends on sys_trgm.word_similarity_threshold

CREATE OPERATOR <% (
        LEFTARG = text,
        RIGHTARG = text,
        PROCEDURE = word_similarity_op,
        COMMUTATOR = '%>',
        RESTRICT = contsel,
        JOIN = contjoinsel
);

CREATE OPERATOR %> (
        LEFTARG = text,
        RIGHTARG = text,
        PROCEDURE = word_similarity_commutator_op,
        COMMUTATOR = '<%',
        RESTRICT = contsel,
        JOIN = contjoinsel
);

CREATE INTERNAL FUNCTION SIMILARITY_DIST(text,text)
RETURNS float4
AS 'MODULE_PATHNAME' , 'similarity_dist'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR <-> (
        LEFTARG = text,
        RIGHTARG = text,
        PROCEDURE = similarity_dist,
        COMMUTATOR = '<->'
);

CREATE INTERNAL FUNCTION WORD_SIMILARITY_DIST_OP(text,text)
RETURNS float4
AS 'MODULE_PATHNAME' , 'word_similarity_dist_op'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION WORD_SIMILARITY_DIST_COMMUTATOR_OP(text,text)
RETURNS float4
AS 'MODULE_PATHNAME' , 'word_similarity_dist_commutator_op'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR <<-> (
        LEFTARG = text,
        RIGHTARG = text,
        PROCEDURE = word_similarity_dist_op,
        COMMUTATOR = '<->>'
);

CREATE OPERATOR <->> (
        LEFTARG = text,
        RIGHTARG = text,
        PROCEDURE = word_similarity_dist_commutator_op,
        COMMUTATOR = '<<->'
);

-- gist key
CREATE INTERNAL FUNCTION GTRGM_IN(cstring)
RETURNS gtrgm
AS 'MODULE_PATHNAME' , 'gtrgm_in'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE INTERNAL FUNCTION GTRGM_OUT(gtrgm)
RETURNS cstring
AS 'MODULE_PATHNAME' , 'gtrgm_out'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE TYPE GTRGM (
        INTERNALLENGTH = -1,
        INPUT = gtrgm_in,
        OUTPUT = gtrgm_out
);

-- support functions for gist
CREATE INTERNAL FUNCTION GTRGM_CONSISTENT(internal,text,smallint,oid,internal)
RETURNS bool
AS 'MODULE_PATHNAME' , 'gtrgm_consistent'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GTRGM_DISTANCE(internal,text,smallint,oid,internal)
RETURNS float8
AS 'MODULE_PATHNAME' , 'gtrgm_distance'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GTRGM_COMPRESS(internal)
RETURNS internal
AS 'MODULE_PATHNAME' , 'gtrgm_compress'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GTRGM_DECOMPRESS(internal)
RETURNS internal
AS 'MODULE_PATHNAME' , 'gtrgm_decompress'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GTRGM_PENALTY(internal,internal,internal)
RETURNS internal
AS 'MODULE_PATHNAME' , 'gtrgm_penalty'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GTRGM_PICKSPLIT(internal, internal)
RETURNS internal
AS 'MODULE_PATHNAME' , 'gtrgm_picksplit'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GTRGM_UNION(internal, internal)
RETURNS gtrgm
AS 'MODULE_PATHNAME' , 'gtrgm_union'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GTRGM_SAME(gtrgm, gtrgm, internal)
RETURNS internal
AS 'MODULE_PATHNAME' , 'gtrgm_same'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- create the operator class for gist
CREATE OPERATOR CLASS GIST_TRGM_OPS
FOR TYPE text USING gist
AS
        OPERATOR        1       % (text, text),
        FUNCTION        1       gtrgm_consistent (internal, text, smallint, oid, internal),
        FUNCTION        2       gtrgm_union (internal, internal),
        FUNCTION        3       gtrgm_compress (internal),
        FUNCTION        4       gtrgm_decompress (internal),
        FUNCTION        5       gtrgm_penalty (internal, internal, internal),
        FUNCTION        6       gtrgm_picksplit (internal, internal),
        FUNCTION        7       gtrgm_same (gtrgm, gtrgm, internal),
        STORAGE         gtrgm;

-- Add operators and support functions that are new in 9.1.  We do it like
-- this, leaving them "loose" in the operator family rather than bound into
-- the gist_trgm_ops opclass, because that's the only state that can be
-- reproduced during an upgrade from 9.0 (see sys_trgm--unpackaged--1.0.sql).

ALTER OPERATOR FAMILY gist_trgm_ops USING gist ADD
        OPERATOR        2       <-> (text, text) FOR ORDER BY sys_catalog.float_ops,
        OPERATOR        3       sys_catalog.~~ (text, text),
        OPERATOR        4       sys_catalog.~~* (text, text),
        FUNCTION        8 (text, text)  gtrgm_distance (internal, text, smallint, oid, internal);

-- Add operators that are new in 9.3.

ALTER OPERATOR FAMILY gist_trgm_ops USING gist ADD
        OPERATOR        5       sys_catalog.~ (text, text),
        OPERATOR        6       sys_catalog.~* (text, text);

-- Add operators that are new in 9.6 (sys_trgm 1.2).

ALTER OPERATOR FAMILY gist_trgm_ops USING gist ADD
        OPERATOR        7       %> (text, text),
        OPERATOR        8       <->> (text, text) FOR ORDER BY sys_catalog.float_ops;

-- support functions for gin
CREATE INTERNAL FUNCTION GIN_EXTRACT_VALUE_TRGM(text, internal)
RETURNS internal
AS 'MODULE_PATHNAME' , 'gin_extract_value_trgm'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GIN_EXTRACT_QUERY_TRGM(text, internal, int2, internal, internal, internal, internal)
RETURNS internal
AS 'MODULE_PATHNAME' , 'gin_extract_query_trgm'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION GIN_TRGM_CONSISTENT(internal, int2, text, int4, internal, internal, internal, internal)
RETURNS bool
AS 'MODULE_PATHNAME' , 'gin_trgm_consistent'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- create the operator class for gin
CREATE OPERATOR CLASS GIN_TRGM_OPS
FOR TYPE text USING gin
AS
        OPERATOR        1       % (text, text),
        FUNCTION        1       btint4cmp (int4, int4),
        FUNCTION        2       gin_extract_value_trgm (text, internal),
        FUNCTION        3       gin_extract_query_trgm (text, internal, int2, internal, internal, internal, internal),
        FUNCTION        4       gin_trgm_consistent (internal, int2, text, int4, internal, internal, internal, internal),
        STORAGE         int4;

-- Add operators that are new in 9.1.

ALTER OPERATOR FAMILY gin_trgm_ops USING gin ADD
        OPERATOR        3       sys_catalog.~~ (text, text),
        OPERATOR        4       sys_catalog.~~* (text, text);

-- Add operators that are new in 9.3.

ALTER OPERATOR FAMILY gin_trgm_ops USING gin ADD
        OPERATOR        5       sys_catalog.~ (text, text),
        OPERATOR        6       sys_catalog.~* (text, text);

-- Add functions that are new in 9.6 (sys_trgm 1.2).

CREATE INTERNAL FUNCTION GIN_TRGM_TRICONSISTENT(internal, int2, text, int4, internal, internal, internal)
RETURNS "char"
AS 'MODULE_PATHNAME' , 'gin_trgm_triconsistent'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

ALTER OPERATOR FAMILY gin_trgm_ops USING gin ADD
        OPERATOR        7       %> (text, text),
        FUNCTION        6      (text,text) gin_trgm_triconsistent (internal, int2, text, int4, internal, internal, internal);

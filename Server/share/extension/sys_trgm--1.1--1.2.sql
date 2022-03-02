/* contrib/sys_trgm/sys_trgm--1.1--1.2.sql */

-- complain if script is sourced in ksql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION sys_trgm UPDATE TO '1.2'" to load this file. \quit

CREATE INTERNAL FUNCTION WORD_SIMILARITY(text,text)
RETURNS float4
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

CREATE INTERNAL FUNCTION WORD_SIMILARITY_OP(text,text)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT STABLE;  -- stable because depends on sys_trgm.word_similarity_threshold

CREATE INTERNAL FUNCTION WORD_SIMILARITY_COMMUTATOR_OP(text,text)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT STABLE;  -- stable because depends on sys_trgm.word_similarity_threshold

CREATE INTERNAL FUNCTION WORD_SIMILARITY_DIST_OP(text,text)
RETURNS float4
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

CREATE INTERNAL FUNCTION WORD_SIMILARITY_DIST_COMMUTATOR_OP(text,text)
RETURNS float4
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

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

CREATE INTERNAL FUNCTION GIN_TRGM_TRICONSISTENT(internal, int2, text, int4, internal, internal, internal)
RETURNS "char"
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

ALTER OPERATOR FAMILY gist_trgm_ops USING gist ADD
        OPERATOR        7       %> (text, text),
        OPERATOR        8       <->> (text, text) FOR ORDER BY sys_catalog.float_ops;

ALTER OPERATOR FAMILY gin_trgm_ops USING gin ADD
        OPERATOR        7       %> (text, text),
        FUNCTION        6      (text, text)   gin_trgm_triconsistent (internal, int2, text, int4, internal, internal, internal);

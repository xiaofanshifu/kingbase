/* contrib/kbcrypto/kbcrypto--1.1--1.2.sql */

-- complain if script is sourced in ksql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION kbcrypto UPDATE TO '1.2'" to load this file. \quit

CREATE INTERNAL FUNCTION armor(bytea, text[], text[])
RETURNS text
AS 'MODULE_PATHNAME', 'sys_armor'
LANGUAGE C IMMUTABLE STRICT;

CREATE INTERNAL FUNCTION pgp_armor_headers(text, key OUT text, value OUT text)
RETURNS SETOF record
AS 'MODULE_PATHNAME', 'pgp_armor_headers'
LANGUAGE C IMMUTABLE STRICT;

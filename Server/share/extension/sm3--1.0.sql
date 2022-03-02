/* sm3/separate_power--1.1.1.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION SM3" to load this file.\quit
CREATE INTERNAL FUNCTION sm3(text)
RETURNS text
AS 'MODULE_PATHNAME', 'sm3'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

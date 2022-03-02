/* contrib/kbcrypto/kbcrypto--1.0--1.1.sql */

-- complain if script is sourced in ksql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION kbcrypto UPDATE TO '1.1'" to load this file. \quit

CREATE INTERNAL FUNCTION gen_random_uuid()
RETURNS uuid
AS 'MODULE_PATHNAME', 'sys_random_uuid'
LANGUAGE C VOLATILE;

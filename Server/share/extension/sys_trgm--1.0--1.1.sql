/* contrib/sys_trgm/sys_trgm--1.0--1.1.sql */

-- complain if script is sourced in ksql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION sys_trgm UPDATE TO '1.1'" to load this file. \quit

ALTER OPERATOR FAMILY gist_trgm_ops USING gist ADD
        OPERATOR        5       sys_catalog.~ (text, text),
        OPERATOR        6       sys_catalog.~* (text, text);

ALTER OPERATOR FAMILY gin_trgm_ops USING gin ADD
        OPERATOR        5       sys_catalog.~ (text, text),
        OPERATOR        6       sys_catalog.~* (text, text);

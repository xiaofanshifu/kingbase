/* contrib/kdb_license/kdb_license--1.0.sql */

\echo Use "CREATE EXTENSION kdb_license" to load this file. \quit

CREATE FUNCTION sys_catalog.get_license_rman() RETURNS BOOL AS 'MODULE_PATHNAME', 'get_license_rman' LANGUAGE C; 

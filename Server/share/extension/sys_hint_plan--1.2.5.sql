/* sys_hint_plan/sys_hint_plan--1.2.5.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION sys_hint_plan" to load this file. \quit

--CREATE SCHEMA HINT_PLAN;

CREATE TABLE hint_plan.hints (
	id					serial	NOT NULL,
	norm_query_string	text	NOT NULL,
	application_name	text,
	hints				text	NOT NULL,
	PRIMARY KEY (id)
);
CREATE UNIQUE INDEX hints_norm_and_app ON hint_plan.hints (
 	norm_query_string,
	application_name
);

GRANT SELECT ON hint_plan.hints TO PUBLIC;
GRANT USAGE ON SCHEMA hint_plan TO PUBLIC;

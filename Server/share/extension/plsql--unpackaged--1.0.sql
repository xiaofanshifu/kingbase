/* src/pl/plsql/src/plsql--unpackaged--1.0.sql */

ALTER EXTENSION PLSQL ADD PROCEDURAL LANGUAGE plsql;
-- ALTER ADD LANGUAGE doesn't pick up the support functions, so we have to.
ALTER EXTENSION PLSQL ADD FUNCTION plsql_call_handler();
ALTER EXTENSION PLSQL ADD FUNCTION plsql_inline_handler(internal);
ALTER EXTENSION PLSQL ADD FUNCTION plsql_package_handler(internal);
ALTER EXTENSION PLSQL ADD FUNCTION plsql_validator(oid);
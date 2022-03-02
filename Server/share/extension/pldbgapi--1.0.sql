-- pldbg.sql
--  This script creates the data types and functions defined by the PL debugger API
--
-- Copyright (c) 2004-2013 EnterpriseDB Corporation. All Rights Reserved.
--
-- Licensed under the Artistic License, see 
--		http://www.opensource.org/licenses/artistic-license.php
-- for full details

\echo Installing pldebugger as unpackaged objects. If you are using Kingbase
\echo version 9.1 or above, use "CREATE EXTENSION pldbgapi" instead.

CREATE TYPE BREAKPOINT AS ( func OID, linenumber INTEGER, targetName TEXT );
CREATE TYPE FRAME      AS ( targetlevel INT, targetname TEXT, func OID, linenumber INTEGER, args TEXT );

CREATE TYPE VAR		   AS ( name TEXT, varClass char, lineNumber INTEGER, isUnique bool, isConst bool, isNotNull bool, dtype OID, value TEXT );
CREATE TYPE PROXYINFO  AS ( serverVersionStr TEXT, serverVersionNum INT, proxyAPIVer INT, serverProcessID INT );

CREATE INTERNAL FUNCTION PLDBG_OID_DEBUG( functionOID OID ) RETURNS INTEGER AS '$libdir/plugin_debugger', 'pldbg_oid_debug' LANGUAGE C STRICT;

-- for backwards-compatibility
CREATE INTERNAL FUNCTION PLPGSQL_OID_DEBUG( functionOID OID ) RETURNS INTEGER AS $$ SELECT pldbg_oid_debug($1) $$ LANGUAGE sql STRICT;

CREATE INTERNAL FUNCTION PLDBG_INLINE_CODE() RETURNS INTEGER AS $$ SELECT 0 $$ LANGUAGE sql STRICT;

CREATE INTERNAL FUNCTION PLDBG_ABORT_TARGET( session INTEGER ) RETURNS SETOF boolean AS  '$libdir/plugin_debugger', 'pldbg_abort_target' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_ATTACH_TO_PORT( portNumber INTEGER ) RETURNS INTEGER AS '$libdir/plugin_debugger', 'pldbg_attach_to_port' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_CONTINUE( session INTEGER ) RETURNS BREAKPOINT AS '$libdir/plugin_debugger', 'pldbg_continue' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_CREATE_LISTENER() RETURNS INTEGER AS '$libdir/plugin_debugger', 'pldbg_create_listener' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_DEPOSIT_VALUE( session INTEGER, varName TEXT, lineNumber INTEGER, value TEXT ) RETURNS boolean AS  '$libdir/plugin_debugger', 'pldbg_deposit_value' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_DROP_BREAKPOINT( session INTEGER, func OID, linenumber INTEGER ) RETURNS boolean AS  '$libdir/plugin_debugger', 'pldbg_get_breakpoints' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_GET_BREAKPOINTS( session INTEGER ) RETURNS SETOF BREAKPOINT AS '$libdir/plugin_debugger', 'pldbg_get_breakpoints' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_GET_SOURCE( session INTEGER, func OID ) RETURNS TEXT AS '$libdir/plugin_debugger', 'pldbg_get_source' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_GET_STACK( session INTEGER ) RETURNS SETOF FRAME AS '$libdir/plugin_debugger', 'pldbg_get_stack' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_GET_PROXY_INFO( ) RETURNS PROXYINFO AS '$libdir/plugin_debugger', 'pldbg_get_proxy_info' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_GET_VARIABLES( session INTEGER ) RETURNS SETOF VAR AS '$libdir/plugin_debugger', 'pldbg_get_variables' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_SELECT_FRAME( session INTEGER, FRAME INTEGER ) RETURNS BREAKPOINT AS '$libdir/plugin_debugger', 'pldbg_select_frame' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_SET_BREAKPOINT( session INTEGER, func OID, linenumber INTEGER ) RETURNS boolean AS  '$libdir/plugin_debugger', 'pldbg_set_breakpoint' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_SET_GLOBAL_BREAKPOINT( session INTEGER, func OID, linenumber INTEGER, targetPID INTEGER ) RETURNS boolean AS  '$libdir/plugin_debugger', 'pldbg_set_global_breakpoint' LANGUAGE C;
CREATE INTERNAL FUNCTION PLDBG_STEP_INTO( session INTEGER ) RETURNS BREAKPOINT AS '$libdir/plugin_debugger', 'pldbg_step_into' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_STEP_OVER( session INTEGER ) RETURNS BREAKPOINT AS '$libdir/plugin_debugger', 'pldbg_step_over' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_WAIT_FOR_BREAKPOINT( session INTEGER ) RETURNS BREAKPOINT  AS '$libdir/plugin_debugger', 'pldbg_wait_for_breakpoint' LANGUAGE C STRICT;
CREATE INTERNAL FUNCTION PLDBG_WAIT_FOR_TARGET( session INTEGER ) RETURNS INTEGER AS '$libdir/plugin_debugger', 'pldbg_wait_for_target' LANGUAGE C STRICT;

/*
 * pldbg_get_target_info() function can be used to return information about
 * a function.
 *
 * Deprecated. This is used by the pgAdmin debugger GUI, but new applications
 * should just query the catalogs directly.
 */
CREATE TYPE TARGETINFO AS ( target OID, schema OID, nargs INT, argTypes oidvector, targetName NAME, argModes "CHAR"[], argNames TEXT[], targetLang OID, fqName TEXT, returnsSet BOOL, returnType OID,

  -- The following columns are only needed when running in an EnterpriseDB
  -- server. On Kingbase, we return just dummy values for them.
  --
  -- 'isFunc' and 'pkg' only make sense on EnterpriseDB.  'isfunc' is true
  -- if the function is a regular function, not a stored procedure or a
  -- function that was created implictly to back a trigger created with the
  -- Oracle-compatible CREATE TRIGGER syntax. If the function belongs to a
  -- package, 'pkg' is the package's OID, or 0 otherwise.
  --
  -- 'argDefVals' is a representation of the function's argument DEFAULTs.
  -- That would be nice to have on Kingbase as well. Unfortunately our
  -- current implementation relies on an EDB-only function to get that
  -- information, so we cannot just use it as is. TODO: rewrite that using
  -- sys_get_expr(sys_proc.proargdefaults).
  isFunc BOOL,
  pkg OID,
  argDefVals TEXT[]
);

-- Create the PLDBG_GET_TARGET_INFO() function. We use an inline code block
-- so that we can check and create it slightly differently if running on
-- an EnterpriseDB server.

DO $do$

declare
  isedb bool;
  createstmt text;
begin

  isedb = (SELECT version() LIKE 'EnterpriseDB%');

  createstmt := $create_stmt$

CREATE INTERNAL FUNCTION PLDBG_GET_TARGET_INFO(signature text, targetType "CHAR") returns targetinfo AS $$
  SELECT p.oid AS target,
         pronamespace AS schema,
         pronargs::int4 AS nargs,
         -- The returned argtypes column is of type oidvector, but unlike
         -- proargtypes, it's supposed to include OUT params. So we
         -- essentially have to return proallargtypes, converted to an
         -- oidvector. There is no oid[] -> oidvector cast, so we have to
         -- do it via text.
         CASE WHEN proallargtypes IS NOT NULL THEN
           translate(proallargtypes::text, ',{}', ' ')::oidvector
         ELSE
           proargtypes
         END AS argtypes,
         proname AS targetname,
         proargmodes AS argmodes,
         proargnames AS proargnames,
         prolang AS targetlang,
         quote_ident(nspname) || '.' || quote_ident(proname) AS fqname,
         proretset AS returnsset,
         prorettype AS returntype,
$create_stmt$;

-- Add the three EDB-columns to the query (as dummies if we're installing
-- to Kingbase)
IF isedb THEN
  createstmt := createstmt ||
$create_stmt$
         p.protype='0' AS isfunc,
         CASE WHEN n.nspparent <> 0 THEN n.oid ELSE 0 END AS pkg,
	 edb_get_func_defvals(p.oid) AS argdefvals
$create_stmt$;
ELSE
  createstmt := createstmt ||
$create_stmt$
         't'::bool AS isfunc,
         0::oid AS pkg,
	 NULL::text[] AS argdefvals
$create_stmt$;
END IF;
  -- End of conditional part

  createstmt := createstmt ||
$create_stmt$
  FROM sys_proc p, sys_namespace n
  WHERE p.pronamespace = n.oid
  AND p.oid = $1::oid
  -- We used to support querying by function name or trigger name/oid as well,
  -- but that was never used in the client, so the support for that has been
  -- removed. The targeType argument remains as a legacy of that. You're
  -- expected to pass 'o' as target type, but it doesn't do anything.
  AND $2 = 'o'
$$ LANGUAGE SQL;
$create_stmt$;

  execute createstmt;

-- Add a couple of EDB specific functions
IF isedb THEN
   CREATE INTERNAL FUNCTION EDB_OID_DEBUG(functionOID oid) RETURNS integer AS $$
     select pldbg_oid_debug($1);
   $$ LANGUAGE SQL;

   CREATE INTERNAL FUNCTION PLDBG_GET_PKG_CONS(packageOID oid) RETURNS oid AS $$
     select oid from sys_proc where pronamespace=$1 and proname='CONS';
   $$ LANGUAGE SQL;
END IF;

end;
$do$;

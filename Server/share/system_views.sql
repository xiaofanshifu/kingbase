/*
 * Kingbase System Views
 *
 * Copyright (c) 1996-2016, Kingbase Corporation
 *
 * src/backend/catalog/system_views.sql
 *
 * Note: this file is read in single-user -j mode, which means that the
 * command terminator is semicolon-newline-newline; whenever the backend
 * sees that, it stops and executes what it's got.  If you write a lot of
 * statements without empty lines between, they'll all get quoted to you
 * in any error message about one of them, so don't do that.  Also, you
 * cannot write a semicolon immediately followed by an empty line in a
 * string literal (including a function body!) or a multiline comment.
 */

CREATE VIEW sys_roles AS
    SELECT
        rolname,
        rolsuper,
        rolinherit,
        rolcreaterole,
        rolcreatedb,
        rolcanlogin,
        rolreplication,
        rolconnlimit,
        '********'::text as rolpassword,
        rolvaliduntil,
        rolbypassrls,
        setconfig as rolconfig,
        sys_authid.oid
    FROM sys_authid LEFT JOIN sys_db_role_setting s
    ON (sys_authid.oid = setrole AND setdatabase = 0);

CREATE VIEW sys_shadow AS
    SELECT
        rolname AS usename,
		rolusertype AS usetype,
        sys_authid.oid AS usesysid,
        rolcreatedb AS usecreatedb,
        rolsuper AS usesuper,
        rolreplication AS userepl,
        rolbypassrls AS usebypassrls,
        rolpassword AS passwd,
        rolvaliduntil::abstime AS valuntil,
        pwdexpiretime AS pwdexpiretime,
        setconfig AS useconfig
    FROM sys_authid LEFT JOIN sys_db_role_setting s
    ON (sys_authid.oid = setrole AND setdatabase = 0)
    WHERE rolcanlogin;

REVOKE ALL on sys_shadow FROM public;

CREATE VIEW sys_group AS
    SELECT
        rolname AS groname,
        oid AS grosysid,
        ARRAY(SELECT member FROM sys_auth_members WHERE roleid = oid) AS grolist
    FROM sys_authid
    WHERE NOT rolcanlogin;

CREATE VIEW sys_user AS
    SELECT
        usename,
		usetype,
        usesysid,
        usecreatedb,
        usesuper,
        userepl,
        usebypassrls,
        '********'::text as passwd,
        valuntil,
        pwdexpiretime,
        useconfig
    FROM sys_shadow;

CREATE VIEW sys_policies AS
    SELECT
        N.nspname AS schemaname,
        C.relname AS tablename,
        pol.polname AS policyname,
        CASE
            WHEN pol.polroles = '{0}' THEN
                string_to_array('PUBLIC', '')
            ELSE
                ARRAY
                (
                    SELECT rolname
                    FROM sys_catalog.sys_authid
                    WHERE oid = ANY (pol.polroles) ORDER BY 1
                )
        END AS roles,
        CASE pol.polcmd
            WHEN 'r' THEN 'SELECT'
            WHEN 'a' THEN 'INSERT'
            WHEN 'w' THEN 'UPDATE'
            WHEN 'd' THEN 'DELETE'
            WHEN '*' THEN 'ALL'
        END AS cmd,
        sys_catalog.sys_get_expr(pol.polqual, pol.polrelid) AS qual,
        sys_catalog.sys_get_expr(pol.polwithcheck, pol.polrelid) AS with_check
    FROM sys_catalog.sys_policy pol
    JOIN sys_catalog.sys_class C ON (C.oid = pol.polrelid)
    LEFT JOIN sys_catalog.sys_namespace N ON (N.oid = C.relnamespace);

CREATE VIEW sys_rules AS
    SELECT
        N.nspname AS schemaname,
        C.relname AS tablename,
        R.rulename AS rulename,
        sys_get_ruledef(R.oid) AS definition
    FROM (sys_rewrite R JOIN sys_class C ON (C.oid = R.ev_class))
        LEFT JOIN sys_namespace N ON (N.oid = C.relnamespace)
    WHERE R.rulename != '_RETURN';

CREATE VIEW sys_views AS
    SELECT
        N.nspname AS schemaname,
        C.relname AS viewname,
        sys_get_userbyid(C.relowner) AS viewowner,
        sys_get_viewdef(C.oid) AS definition,
        sys_relation_is_updatable(C.oid, true) AS isupdatable,
        C.relstatus AS status
    FROM sys_class C LEFT JOIN sys_namespace N ON (N.oid = C.relnamespace)
    WHERE C.relkind = 'v';

CREATE VIEW sys_tables AS
    SELECT
        N.nspname AS schemaname,
        C.relname AS tablename,
        sys_get_userbyid(C.relowner) AS tableowner,
        T.spcname AS tablespace,
        C.relhasindex AS hasindexes,
        C.relhasrules AS hasrules,
        C.relhastriggers AS hastriggers,
        C.relrowsecurity AS rowsecurity
    FROM sys_class C LEFT JOIN sys_namespace N ON (N.oid = C.relnamespace)
         LEFT JOIN sys_tablespace T ON (T.oid = C.reltablespace)
    WHERE C.relkind = 'r';

CREATE VIEW sys_matviews AS
    SELECT
        N.nspname AS schemaname,
        C.relname AS matviewname,
        sys_get_userbyid(C.relowner) AS matviewowner,
        T.spcname AS tablespace,
        C.relhasindex AS hasindexes,
        C.relispopulated AS ispopulated,
        sys_get_viewdef(C.oid) AS definition
    FROM sys_class C LEFT JOIN sys_namespace N ON (N.oid = C.relnamespace)
         LEFT JOIN sys_tablespace T ON (T.oid = C.reltablespace)
    WHERE C.relkind = 'm';

CREATE VIEW sys_indexes AS
    SELECT
        N.nspname AS schemaname,
        C.relname AS tablename,
        I.relname AS indexname,
        T.spcname AS tablespace,
        sys_get_indexdef(I.oid) AS indexdef
    FROM sys_index X JOIN sys_class C ON (C.oid = X.indrelid)
         JOIN sys_class I ON (I.oid = X.indexrelid)
         LEFT JOIN sys_namespace N ON (N.oid = C.relnamespace)
         LEFT JOIN sys_tablespace T ON (T.oid = I.reltablespace)
    WHERE C.relkind IN ('r', 'm') AND I.relkind = 'i';

CREATE VIEW sys_stats WITH (security_barrier) AS
    SELECT
        nspname AS schemaname,
        relname AS tablename,
        attname AS attname,
        stainherit AS inherited,
        stanullfrac AS null_frac,
        stawidth AS avg_width,
        stadistinct AS n_distinct,
        CASE
            WHEN stakind1 = 1 THEN stavalues1
            WHEN stakind2 = 1 THEN stavalues2
            WHEN stakind3 = 1 THEN stavalues3
            WHEN stakind4 = 1 THEN stavalues4
            WHEN stakind5 = 1 THEN stavalues5
        END AS most_common_vals,
        CASE
            WHEN stakind1 = 1 THEN stanumbers1
            WHEN stakind2 = 1 THEN stanumbers2
            WHEN stakind3 = 1 THEN stanumbers3
            WHEN stakind4 = 1 THEN stanumbers4
            WHEN stakind5 = 1 THEN stanumbers5
        END AS most_common_freqs,
        CASE
            WHEN stakind1 = 2 THEN stavalues1
            WHEN stakind2 = 2 THEN stavalues2
            WHEN stakind3 = 2 THEN stavalues3
            WHEN stakind4 = 2 THEN stavalues4
            WHEN stakind5 = 2 THEN stavalues5
        END AS histogram_bounds,
        CASE
            WHEN stakind1 = 3 THEN stanumbers1[1]
            WHEN stakind2 = 3 THEN stanumbers2[1]
            WHEN stakind3 = 3 THEN stanumbers3[1]
            WHEN stakind4 = 3 THEN stanumbers4[1]
            WHEN stakind5 = 3 THEN stanumbers5[1]
        END AS correlation,
        CASE
            WHEN stakind1 = 4 THEN stavalues1
            WHEN stakind2 = 4 THEN stavalues2
            WHEN stakind3 = 4 THEN stavalues3
            WHEN stakind4 = 4 THEN stavalues4
            WHEN stakind5 = 4 THEN stavalues5
        END AS most_common_elems,
        CASE
            WHEN stakind1 = 4 THEN stanumbers1
            WHEN stakind2 = 4 THEN stanumbers2
            WHEN stakind3 = 4 THEN stanumbers3
            WHEN stakind4 = 4 THEN stanumbers4
            WHEN stakind5 = 4 THEN stanumbers5
        END AS most_common_elem_freqs,
        CASE
            WHEN stakind1 = 5 THEN stanumbers1
            WHEN stakind2 = 5 THEN stanumbers2
            WHEN stakind3 = 5 THEN stanumbers3
            WHEN stakind4 = 5 THEN stanumbers4
            WHEN stakind5 = 5 THEN stanumbers5
        END AS elem_count_histogram
    FROM sys_statistic s JOIN sys_class c ON (c.oid = s.starelid)
         JOIN sys_attribute a ON (c.oid = attrelid AND attnum = s.staattnum)
         LEFT JOIN sys_namespace n ON (n.oid = c.relnamespace)
    WHERE NOT attisdropped
    AND has_column_privilege(c.oid, a.attnum, 'SELECT')
    AND (c.relrowsecurity = false OR NOT row_security_active(c.oid));

REVOKE ALL on sys_statistic FROM public;

CREATE VIEW sys_triggers AS SELECT TG.oid AS TRIOID, TG.tgname,
    N.oid AS SCHEMAID, N.nspname AS SCHEMANAME,
		TG.tgenabled AS TGENABLED,
		C.relname AS TABLENAME, TG.tgtype, TG.tgfoid,
         TG.TGCONSTRRELID, TG.TGDEFERRABLE, TG.TGINITDEFERRED,
        SYS_GET_TRIGGERDEF(TG.oid) AS TRIDEF,
        SYS_GET_USERBYID(C.relowner) AS OWNER,
        TG.tgisinternal AS ISINTERNAL
	FROM sys_class AS C
        JOIN sys_trigger AS TG ON(C.oid=TG.tgrelid)
        LEFT JOIN sys_description AS DES ON(TG.oid = DES.objoid)
        JOIN sys_namespace AS N ON(N.oid = C.relnamespace)
	WHERE (DES.objoid IS NULL
			OR DES.classoid = (SELECT oid FROM sys_class WHERE relname = 'sys_trigger'))
		AND C.relkind IN ('r', 'v', 'm');

CREATE VIEW sys_locks AS
    SELECT * FROM sys_lock_status() AS L;

CREATE VIEW sys_cursors AS
    SELECT * FROM sys_cursor() AS C;

CREATE VIEW sys_available_extensions AS
    SELECT E.name, E.default_version, X.extversion AS installed_version,
           E.comment
      FROM sys_available_extensions() AS E
           LEFT JOIN sys_extension AS X ON E.name = X.extname;

CREATE VIEW sys_available_extension_versions AS
    SELECT E.name, E.version, (X.extname IS NOT NULL) AS installed,
           E.superuser, E.relocatable, E.schema, E.requires, E.comment
      FROM sys_available_extension_versions() AS E
           LEFT JOIN sys_extension AS X
             ON E.name = X.extname AND E.version = X.extversion;

CREATE VIEW sys_prepared_xacts AS
    SELECT P.transaction, P.gid, P.prepared,
           U.rolname AS owner, D.datname AS database
    FROM sys_prepared_xact() AS P
         LEFT JOIN sys_authid U ON P.ownerid = U.oid
         LEFT JOIN sys_database D ON P.dbid = D.oid;

CREATE VIEW sys_prepared_statements AS
    SELECT * FROM sys_prepared_statement() AS P;

CREATE VIEW sys_seclabels AS
SELECT
	l.objoid, l.classoid, l.objsubid,
	CASE WHEN rel.relkind = 'r' THEN 'table'::text
		 WHEN rel.relkind = 'v' THEN 'view'::text
		 WHEN rel.relkind = 'm' THEN 'materialized view'::text
		 WHEN rel.relkind = 'S' THEN 'sequence'::text
		 WHEN rel.relkind = 'f' THEN 'foreign table'::text END AS objtype,
	rel.relnamespace AS objnamespace,
	CASE WHEN sys_table_is_visible(rel.oid)
	     THEN quote_ident(rel.relname)
	     ELSE quote_ident(nsp.nspname) || '.' || quote_ident(rel.relname)
	     END AS objname,
	l.provider, l.label
FROM
	sys_seclabel l
	JOIN sys_class rel ON l.classoid = rel.tableoid AND l.objoid = rel.oid
	JOIN sys_namespace nsp ON rel.relnamespace = nsp.oid
WHERE
	l.objsubid = 0
UNION ALL
SELECT
	l.objoid, l.classoid, l.objsubid,
	'column'::text AS objtype,
	rel.relnamespace AS objnamespace,
	CASE WHEN sys_table_is_visible(rel.oid)
	     THEN quote_ident(rel.relname)
	     ELSE quote_ident(nsp.nspname) || '.' || quote_ident(rel.relname)
	     END || '.' || att.attname AS objname,
	l.provider, l.label
FROM
	sys_seclabel l
	JOIN sys_class rel ON l.classoid = rel.tableoid AND l.objoid = rel.oid
	JOIN sys_attribute att
	     ON rel.oid = att.attrelid AND l.objsubid = att.attnum
	JOIN sys_namespace nsp ON rel.relnamespace = nsp.oid
WHERE
	l.objsubid != 0
UNION ALL
SELECT
	l.objoid, l.classoid, l.objsubid,
	CASE WHEN pro.proisagg = true THEN 'aggregate'::text
	     WHEN pro.proisagg = false THEN 'function'::text
	END AS objtype,
	pro.pronamespace AS objnamespace,
	CASE WHEN sys_function_is_visible(pro.oid)
	     THEN quote_ident(pro.proname)
	     ELSE quote_ident(nsp.nspname) || '.' || quote_ident(pro.proname)
	END || '(' || sys_catalog.sys_get_function_arguments(pro.oid) || ')' AS objname,
	l.provider, l.label
FROM
	sys_seclabel l
	JOIN sys_proc pro ON l.classoid = pro.tableoid AND l.objoid = pro.oid
	JOIN sys_namespace nsp ON pro.pronamespace = nsp.oid
WHERE
	l.objsubid = 0
UNION ALL
SELECT
	l.objoid, l.classoid, l.objsubid,
	CASE WHEN typ.typtype = 'd' THEN 'domain'::text
	ELSE 'type'::text END AS objtype,
	typ.typnamespace AS objnamespace,
	CASE WHEN sys_type_is_visible(typ.oid)
	THEN quote_ident(typ.typname)
	ELSE quote_ident(nsp.nspname) || '.' || quote_ident(typ.typname)
	END AS objname,
	l.provider, l.label
FROM
	sys_seclabel l
	JOIN sys_type typ ON l.classoid = typ.tableoid AND l.objoid = typ.oid
	JOIN sys_namespace nsp ON typ.typnamespace = nsp.oid
WHERE
	l.objsubid = 0
UNION ALL
SELECT
	l.objoid, l.classoid, l.objsubid,
	'language'::text AS objtype,
	NULL::oid AS objnamespace,
	quote_ident(lan.lanname) AS objname,
	l.provider, l.label
FROM
	sys_seclabel l
	JOIN sys_language lan ON l.classoid = lan.tableoid AND l.objoid = lan.oid
WHERE
	l.objsubid = 0
UNION ALL
SELECT
	l.objoid, l.classoid, l.objsubid,
	'schema'::text AS objtype,
	nsp.oid AS objnamespace,
	quote_ident(nsp.nspname) AS objname,
	l.provider, l.label
FROM
	sys_seclabel l
	JOIN sys_namespace nsp ON l.classoid = nsp.tableoid AND l.objoid = nsp.oid
WHERE
	l.objsubid = 0
UNION ALL
SELECT
	l.objoid, l.classoid, l.objsubid,
	'event trigger'::text AS objtype,
	NULL::oid AS objnamespace,
	quote_ident(evt.evtname) AS objname,
	l.provider, l.label
FROM
	sys_seclabel l
	JOIN sys_event_trigger evt ON l.classoid = evt.tableoid
		AND l.objoid = evt.oid
WHERE
	l.objsubid = 0
UNION ALL
SELECT
	l.objoid, l.classoid, 0::int4 AS objsubid,
	'database'::text AS objtype,
	NULL::oid AS objnamespace,
	quote_ident(dat.datname) AS objname,
	l.provider, l.label
FROM
	sys_shseclabel l
	JOIN sys_database dat ON l.classoid = dat.tableoid AND l.objoid = dat.oid
UNION ALL
SELECT
	l.objoid, l.classoid, 0::int4 AS objsubid,
	'tablespace'::text AS objtype,
	NULL::oid AS objnamespace,
	quote_ident(spc.spcname) AS objname,
	l.provider, l.label
FROM
	sys_shseclabel l
	JOIN sys_tablespace spc ON l.classoid = spc.tableoid AND l.objoid = spc.oid
UNION ALL
SELECT
	l.objoid, l.classoid, 0::int4 AS objsubid,
	'role'::text AS objtype,
	NULL::oid AS objnamespace,
	quote_ident(rol.rolname) AS objname,
	l.provider, l.label
FROM
	sys_shseclabel l
	JOIN sys_authid rol ON l.classoid = rol.tableoid AND l.objoid = rol.oid;


CREATE VIEW sys_depends AS
      (SELECT DISTINCT
		C.OID AS OID,
		C.RELNAME AS NAME,
		C.RELKIND AS TYPE,
        BASE.OID AS REFRELID,
        BASE.RELNAME AS REFRELNAME,
        BASE.RELKIND AS REFRELTYPE
   FROM sys_class C, sys_rewrite R, sys_depend D, sys_class BASE
   WHERE C.OID=R.EV_CLASS AND R.OID=D.OBJID AND REFOBJID=BASE.OID AND BASE.OID!=C.OID)
UNION ALL
      (SELECT DISTINCT
		R.OID AS OID,
		R.TGNAME AS NAME,
		't' AS TYPE,
        BASE.OID AS REFRELID,
        BASE.RELNAME AS REFRELNAME,
        BASE.RELKIND AS REFRELTYPE
	FROM sys_class C, sys_trigger R, sys_depend D , sys_class BASE
	WHERE C.OID=R.TGRELID AND R.OID=D.OBJID AND REFOBJID=BASE.OID
	ORDER BY BASE.OID);


CREATE VIEW sys_auto_triggers AS
  SELECT relnamespace,
          relname,
          tgrelid,
          tgname
  FROM sys_trigger, sys_class
  WHERE tgisinternal = 'true'
      AND tgrelid = sys_class.oid;

CREATE VIEW sys_primarykey_indexes AS
  SELECT rel.relnamespace,
          rel.relname,
          con.conname AS primaryconname,
          idx.relnamespace AS indexnamespace,
          idx.relname AS indexname
  FROM sys_class rel, sys_class idx, sys_index,
        sys_depend, sys_constraint con, sys_namespace nsp
  WHERE sys_depend.refobjid = con.oid
      AND idx.oid = sys_depend.objid
      AND con.conrelid = rel.oid
      AND idx.oid = sys_index.indexrelid
      AND rel.relnamespace = nsp.oid
      AND con.contype = 'p';

CREATE VIEW sys_uniquekey_indexes AS
  SELECT rel.relnamespace,
          rel.relname,
          con.conname AS uniconname,
          idx.relnamespace AS indexnamespace,
          idx.relname AS indexname
  FROM  sys_class rel, sys_class idx, sys_index,
        sys_depend, sys_constraint con, sys_namespace nsp
  WHERE sys_depend.refobjid = con.oid
      AND idx.oid = sys_depend.objid
      AND con.conrelid = rel.oid
      AND idx.oid = sys_index.indexrelid
      AND rel.relnamespace = nsp.oid
      AND con.contype = 'u';


CREATE VIEW sys_settings AS
    SELECT * FROM sys_show_all_settings() AS A;

CREATE RULE sys_settings_u AS
    ON UPDATE TO sys_settings
    WHERE new.name = old.name DO
    SELECT set_config(old.name, new.setting, 'f');

CREATE RULE sys_settings_n AS
    ON UPDATE TO sys_settings
    DO INSTEAD NOTHING;

GRANT SELECT, UPDATE ON sys_settings TO PUBLIC;

CREATE VIEW sys_file_settings AS
   SELECT * FROM sys_show_all_file_settings() AS A;

REVOKE ALL on sys_file_settings FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION sys_show_all_file_settings() FROM PUBLIC;

CREATE VIEW sys_timezone_abbrevs AS
    SELECT * FROM sys_timezone_abbrevs();

CREATE VIEW sys_timezone_names AS
    SELECT * FROM sys_timezone_names();

CREATE VIEW sys_config AS
    SELECT * FROM sys_config();

REVOKE ALL on sys_config FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION sys_config() FROM PUBLIC;

-- Statistics views

CREATE VIEW sys_stat_all_tables AS
    SELECT
            C.oid AS relid,
            N.nspname AS schemaname,
            C.relname AS relname,
            sys_stat_get_numscans(C.oid) AS seq_scan,
            sys_stat_get_tuples_returned(C.oid) AS seq_tup_read,
            sum(sys_stat_get_numscans(I.indexrelid))::bigint AS idx_scan,
            sum(sys_stat_get_tuples_fetched(I.indexrelid))::bigint +
            sys_stat_get_tuples_fetched(C.oid) AS idx_tup_fetch,
            sys_stat_get_tuples_inserted(C.oid) AS n_tup_ins,
            sys_stat_get_tuples_updated(C.oid) AS n_tup_upd,
            sys_stat_get_tuples_deleted(C.oid) AS n_tup_del,
            sys_stat_get_tuples_hot_updated(C.oid) AS n_tup_hot_upd,
            sys_stat_get_live_tuples(C.oid) AS n_live_tup,
            sys_stat_get_dead_tuples(C.oid) AS n_dead_tup,
            sys_stat_get_mod_since_analyze(C.oid) AS n_mod_since_analyze,
            sys_stat_get_last_vacuum_time(C.oid) as last_vacuum,
            sys_stat_get_last_autovacuum_time(C.oid) as last_autovacuum,
            sys_stat_get_last_analyze_time(C.oid) as last_analyze,
            sys_stat_get_last_autoanalyze_time(C.oid) as last_autoanalyze,
            sys_stat_get_vacuum_count(C.oid) AS vacuum_count,
            sys_stat_get_autovacuum_count(C.oid) AS autovacuum_count,
            sys_stat_get_analyze_count(C.oid) AS analyze_count,
            sys_stat_get_autoanalyze_count(C.oid) AS autoanalyze_count
    FROM sys_class C LEFT JOIN
         sys_index I ON C.oid = I.indrelid
         LEFT JOIN sys_namespace N ON (N.oid = C.relnamespace)
    WHERE C.relkind IN ('r', 't', 'm')
    GROUP BY C.oid, N.nspname, C.relname;


CREATE VIEW sys_stat_xact_all_tables AS
    SELECT
            C.oid AS relid,
            N.nspname AS schemaname,
            C.relname AS relname,
            sys_stat_get_xact_numscans(C.oid) AS seq_scan,
            sys_stat_get_xact_tuples_returned(C.oid) AS seq_tup_read,
            sum(sys_stat_get_xact_numscans(I.indexrelid))::bigint AS idx_scan,
            sum(sys_stat_get_xact_tuples_fetched(I.indexrelid))::bigint +
            sys_stat_get_xact_tuples_fetched(C.oid) AS idx_tup_fetch,
            sys_stat_get_xact_tuples_inserted(C.oid) AS n_tup_ins,
            sys_stat_get_xact_tuples_updated(C.oid) AS n_tup_upd,
            sys_stat_get_xact_tuples_deleted(C.oid) AS n_tup_del,
            sys_stat_get_xact_tuples_hot_updated(C.oid) AS n_tup_hot_upd
    FROM sys_class C LEFT JOIN
         sys_index I ON C.oid = I.indrelid
         LEFT JOIN sys_namespace N ON (N.oid = C.relnamespace)
    WHERE C.relkind IN ('r', 't', 'm')
    GROUP BY C.oid, N.nspname, C.relname;

CREATE VIEW sys_stat_sys_tables AS
    SELECT * FROM sys_stat_all_tables
    WHERE schemaname IN ('SYS_CATALOG', 'INFORMATION_SCHEMA') OR
          schemaname ~ '^SYS_TOAST';

CREATE VIEW sys_stat_xact_sys_tables AS
    SELECT * FROM sys_stat_xact_all_tables
    WHERE schemaname IN ('SYS_CATALOG', 'INFORMATION_SCHEMA') OR
          schemaname ~ '^SYS_TOAST';

CREATE VIEW sys_stat_user_tables AS
    SELECT * FROM sys_stat_all_tables
    WHERE schemaname NOT IN ('SYS_CATALOG', 'INFORMATION_SCHEMA') AND
          schemaname !~ '^SYS_TOAST';

CREATE VIEW sys_stat_xact_user_tables AS
    SELECT * FROM sys_stat_xact_all_tables
    WHERE schemaname NOT IN ('SYS_CATALOG', 'INFORMATION_SCHEMA') AND
          schemaname !~ '^SYS_TOAST';

CREATE VIEW sys_statio_all_tables AS
    SELECT
            C.oid AS relid,
            N.nspname AS schemaname,
            C.relname AS relname,
            sys_stat_get_blocks_fetched(C.oid) -
                    sys_stat_get_blocks_hit(C.oid) AS heap_blks_read,
            sys_stat_get_blocks_hit(C.oid) AS heap_blks_hit,
            sum(sys_stat_get_blocks_fetched(I.indexrelid) -
                    sys_stat_get_blocks_hit(I.indexrelid))::bigint AS idx_blks_read,
            sum(sys_stat_get_blocks_hit(I.indexrelid))::bigint AS idx_blks_hit,
            sys_stat_get_blocks_fetched(T.oid) -
                    sys_stat_get_blocks_hit(T.oid) AS toast_blks_read,
            sys_stat_get_blocks_hit(T.oid) AS toast_blks_hit,
            sum(sys_stat_get_blocks_fetched(X.indexrelid) -
                    sys_stat_get_blocks_hit(X.indexrelid))::bigint AS tidx_blks_read,
            sum(sys_stat_get_blocks_hit(X.indexrelid))::bigint AS tidx_blks_hit
    FROM sys_class C LEFT JOIN
            sys_index I ON C.oid = I.indrelid LEFT JOIN
            sys_class T ON C.reltoastrelid = T.oid LEFT JOIN
            sys_index X ON T.oid = X.indrelid
            LEFT JOIN sys_namespace N ON (N.oid = C.relnamespace)
    WHERE C.relkind IN ('r', 't', 'm')
    GROUP BY C.oid, N.nspname, C.relname, T.oid, X.indrelid;

CREATE VIEW sys_statio_sys_tables AS
    SELECT * FROM sys_statio_all_tables
    WHERE schemaname IN ('SYS_CATALOG', 'INFORMATION_SCHEMA') OR
          schemaname ~ '^SYS_TOAST';

CREATE VIEW sys_statio_user_tables AS
    SELECT * FROM sys_statio_all_tables
    WHERE schemaname NOT IN ('SYS_CATALOG', 'INFORMATION_SCHEMA') AND
          schemaname !~ '^SYS_TOAST';

CREATE VIEW sys_stat_all_indexes AS
    SELECT
            C.oid AS relid,
            I.oid AS indexrelid,
            N.nspname AS schemaname,
            C.relname AS relname,
            I.relname AS indexrelname,
            sys_stat_get_numscans(I.oid) AS idx_scan,
            sys_stat_get_tuples_returned(I.oid) AS idx_tup_read,
            sys_stat_get_tuples_fetched(I.oid) AS idx_tup_fetch
    FROM sys_class C JOIN
            sys_index X ON C.oid = X.indrelid JOIN
            sys_class I ON I.oid = X.indexrelid
            LEFT JOIN sys_namespace N ON (N.oid = C.relnamespace)
    WHERE C.relkind IN ('r', 't', 'm');

CREATE VIEW sys_stat_sys_indexes AS
    SELECT * FROM sys_stat_all_indexes
    WHERE schemaname IN ('SYS_CATALOG', 'INFORMATION_SCHEMA') OR
          schemaname ~ '^SYS_TOAST';

CREATE VIEW sys_stat_user_indexes AS
    SELECT * FROM sys_stat_all_indexes
    WHERE schemaname NOT IN ('SYS_CATALOG', 'INFORMATION_SCHEMA') AND
          schemaname !~ '^SYS_TOAST';

CREATE VIEW sys_statio_all_indexes AS
    SELECT
            C.oid AS relid,
            I.oid AS indexrelid,
            N.nspname AS schemaname,
            C.relname AS relname,
            I.relname AS indexrelname,
            sys_stat_get_blocks_fetched(I.oid) -
                    sys_stat_get_blocks_hit(I.oid) AS idx_blks_read,
            sys_stat_get_blocks_hit(I.oid) AS idx_blks_hit
    FROM sys_class C JOIN
            sys_index X ON C.oid = X.indrelid JOIN
            sys_class I ON I.oid = X.indexrelid
            LEFT JOIN sys_namespace N ON (N.oid = C.relnamespace)
    WHERE C.relkind IN ('r', 't', 'm');

CREATE VIEW sys_statio_sys_indexes AS
    SELECT * FROM sys_statio_all_indexes
    WHERE schemaname IN ('SYS_CATALOG', 'INFORMATION_SCHEMA') OR
          schemaname ~ '^SYS_TOAST';

CREATE VIEW sys_statio_user_indexes AS
    SELECT * FROM sys_statio_all_indexes
    WHERE schemaname NOT IN ('SYS_CATALOG', 'INFORMATION_SCHEMA') AND
          schemaname !~ '^SYS_TOAST';

CREATE VIEW sys_statio_all_sequences AS
    SELECT
            C.oid AS relid,
            N.nspname AS schemaname,
            C.relname AS relname,
            sys_stat_get_blocks_fetched(C.oid) -
                    sys_stat_get_blocks_hit(C.oid) AS blks_read,
            sys_stat_get_blocks_hit(C.oid) AS blks_hit
    FROM sys_class C
            LEFT JOIN sys_namespace N ON (N.oid = C.relnamespace)
    WHERE C.relkind = 'S';

CREATE VIEW sys_statio_sys_sequences AS
    SELECT * FROM sys_statio_all_sequences
    WHERE schemaname IN ('SYS_CATALOG', 'INFORMATION_SCHEMA') OR
          schemaname ~ '^SYS_TOAST';

CREATE VIEW sys_statio_user_sequences AS
    SELECT * FROM sys_statio_all_sequences
    WHERE schemaname NOT IN ('SYS_CATALOG', 'INFORMATION_SCHEMA') AND
          schemaname !~ '^SYS_TOAST';

CREATE VIEW sys_stat_activity AS
    SELECT
            S.datid AS datid,
            D.datname AS datname,
            S.pid,
            S.usesysid,
            U.rolname AS usename,
            S.application_name,
            S.client_addr,
            S.client_hostname,
            S.client_port,
            S.backend_start,
            S.xact_start,
            S.query_start,
            S.state_change,
            S.wait_event_type,
            S.wait_event,
            S.state,
            S.backend_xid,
            s.backend_xmin,
            S.query
    FROM sys_database D, sys_stat_get_activity(NULL) AS S, sys_authid U
    WHERE S.datid = D.oid AND
            S.usesysid = U.oid;

CREATE VIEW sys_stat_replication AS
    SELECT
            S.pid,
            S.usesysid,
            U.rolname AS usename,
            S.application_name,
            S.client_addr,
            S.client_hostname,
            S.client_port,
            S.backend_start,
            S.backend_xmin,
            W.state,
            W.sent_location,
            W.write_location,
            W.flush_location,
            W.replay_location,
            W.sync_priority,
            W.sync_state
    FROM sys_stat_get_activity(NULL) AS S, sys_authid U,
            sys_stat_get_wal_senders() AS W
    WHERE S.usesysid = U.oid AND
            S.pid = W.pid;

CREATE VIEW sys_stat_wal_receiver AS
    SELECT
            s.pid,
            s.status,
            s.receive_start_lsn,
            s.receive_start_tli,
            s.received_lsn,
            s.received_tli,
            s.last_msg_send_time,
            s.last_msg_receipt_time,
            s.latest_end_lsn,
            s.latest_end_time,
            s.slot_name,
            s.conninfo
    FROM sys_stat_get_wal_receiver() s
    WHERE s.pid IS NOT NULL;

CREATE VIEW sys_stat_ssl AS
    SELECT
            S.pid,
            S.ssl,
            S.sslversion AS version,
            S.sslcipher AS cipher,
            S.sslbits AS bits,
            S.sslcompression AS compression,
            S.sslclientdn AS clientdn
    FROM sys_stat_get_activity(NULL) AS S;

CREATE VIEW sys_replication_slots AS
    SELECT
            L.slot_name,
            L.plugin,
            L.slot_type,
            L.datoid,
            D.datname AS database,
            L.active,
            L.active_pid,
            L.xmin,
            L.catalog_xmin,
            L.restart_lsn,
            L.confirmed_flush_lsn
    FROM sys_get_replication_slots() AS L
            LEFT JOIN sys_database D ON (L.datoid = D.oid);

CREATE VIEW sys_stat_database AS
    SELECT
            D.oid AS datid,
            D.datname AS datname,
            sys_stat_get_db_numbackends(D.oid) AS numbackends,
            sys_stat_get_db_xact_commit(D.oid) AS xact_commit,
            sys_stat_get_db_xact_rollback(D.oid) AS xact_rollback,
            sys_stat_get_db_blocks_fetched(D.oid) -
                    sys_stat_get_db_blocks_hit(D.oid) AS blks_read,
            sys_stat_get_db_blocks_hit(D.oid) AS blks_hit,
            sys_stat_get_db_tuples_returned(D.oid) AS tup_returned,
            sys_stat_get_db_tuples_fetched(D.oid) AS tup_fetched,
            sys_stat_get_db_tuples_inserted(D.oid) AS tup_inserted,
            sys_stat_get_db_tuples_updated(D.oid) AS tup_updated,
            sys_stat_get_db_tuples_deleted(D.oid) AS tup_deleted,
            sys_stat_get_db_conflict_all(D.oid) AS conflicts,
            sys_stat_get_db_temp_files(D.oid) AS temp_files,
            sys_stat_get_db_temp_bytes(D.oid) AS temp_bytes,
            sys_stat_get_db_deadlocks(D.oid) AS deadlocks,
            sys_stat_get_db_blk_read_time(D.oid) AS blk_read_time,
            sys_stat_get_db_blk_write_time(D.oid) AS blk_write_time,
            sys_stat_get_db_stat_reset_time(D.oid) AS stats_reset
    FROM sys_database D;

CREATE VIEW sys_stat_database_conflicts AS
    SELECT
            D.oid AS datid,
            D.datname AS datname,
            sys_stat_get_db_conflict_tablespace(D.oid) AS confl_tablespace,
            sys_stat_get_db_conflict_lock(D.oid) AS confl_lock,
            sys_stat_get_db_conflict_snapshot(D.oid) AS confl_snapshot,
            sys_stat_get_db_conflict_bufferpin(D.oid) AS confl_bufferpin,
            sys_stat_get_db_conflict_startup_deadlock(D.oid) AS confl_deadlock
    FROM sys_database D;

CREATE VIEW sys_stat_user_functions AS
    SELECT
            P.oid AS funcid,
            N.nspname AS schemaname,
            P.proname AS funcname,
            sys_stat_get_function_calls(P.oid) AS calls,
            sys_stat_get_function_total_time(P.oid) AS total_time,
            sys_stat_get_function_self_time(P.oid) AS self_time
    FROM sys_proc P LEFT JOIN sys_namespace N ON (N.oid = P.pronamespace)
    WHERE P.prolang != 12  -- fast check to eliminate built-in functions
          AND sys_stat_get_function_calls(P.oid) IS NOT NULL;

CREATE VIEW sys_stat_xact_user_functions AS
    SELECT
            P.oid AS funcid,
            N.nspname AS schemaname,
            P.proname AS funcname,
            sys_stat_get_xact_function_calls(P.oid) AS calls,
            sys_stat_get_xact_function_total_time(P.oid) AS total_time,
            sys_stat_get_xact_function_self_time(P.oid) AS self_time
    FROM sys_proc P LEFT JOIN sys_namespace N ON (N.oid = P.pronamespace)
    WHERE P.prolang != 12  -- fast check to eliminate built-in functions
          AND sys_stat_get_xact_function_calls(P.oid) IS NOT NULL;

CREATE VIEW sys_stat_archiver AS
    SELECT
        s.archived_count,
        s.last_archived_wal,
        s.last_archived_time,
        s.failed_count,
        s.last_failed_wal,
        s.last_failed_time,
        s.stats_reset
    FROM sys_stat_get_archiver() s;

CREATE VIEW sys_stat_bgwriter AS
    SELECT
        sys_stat_get_bgwriter_timed_checkpoints() AS checkpoints_timed,
        sys_stat_get_bgwriter_requested_checkpoints() AS checkpoints_req,
        sys_stat_get_checkpoint_write_time() AS checkpoint_write_time,
        sys_stat_get_checkpoint_sync_time() AS checkpoint_sync_time,
        sys_stat_get_bgwriter_buf_written_checkpoints() AS buffers_checkpoint,
        sys_stat_get_bgwriter_buf_written_clean() AS buffers_clean,
        sys_stat_get_bgwriter_maxwritten_clean() AS maxwritten_clean,
        sys_stat_get_buf_written_backend() AS buffers_backend,
        sys_stat_get_buf_fsync_backend() AS buffers_backend_fsync,
        sys_stat_get_buf_alloc() AS buffers_alloc,
        sys_stat_get_bgwriter_stat_reset_time() AS stats_reset;

CREATE VIEW sys_stat_progress_vacuum AS
	SELECT
		S.pid AS pid, S.datid AS datid, D.datname AS datname,
		S.relid AS relid,
		CASE S.param1 WHEN 0 THEN 'initializing'
					  WHEN 1 THEN 'scanning heap'
					  WHEN 2 THEN 'vacuuming indexes'
					  WHEN 3 THEN 'vacuuming heap'
					  WHEN 4 THEN 'cleaning up indexes'
					  WHEN 5 THEN 'truncating heap'
					  WHEN 6 THEN 'performing final cleanup'
					  END AS phase,
		S.param2 AS heap_blks_total, S.param3 AS heap_blks_scanned,
		S.param4 AS heap_blks_vacuumed, S.param5 AS index_vacuum_count,
		S.param6 AS max_dead_tuples, S.param7 AS num_dead_tuples
    FROM sys_stat_get_progress_info('VACUUM') AS S
		 JOIN sys_database D ON S.datid = D.oid;

CREATE VIEW sys_user_mappings AS
    SELECT
        U.oid       AS umid,
        S.oid       AS srvid,
        S.srvname   AS srvname,
        U.umuser    AS umuser,
        CASE WHEN U.umuser = 0 THEN
            'public'
        ELSE
            A.rolname
        END AS usename,
        CASE WHEN sys_has_role(S.srvowner, 'USAGE') OR has_server_privilege(S.oid, 'USAGE') THEN
            U.umoptions
        ELSE
            NULL
        END AS umoptions
    FROM sys_user_mapping U
         LEFT JOIN sys_authid A ON (A.oid = U.umuser) JOIN
        sys_foreign_server S ON (U.umserver = S.oid);

REVOKE ALL on sys_user_mapping FROM public;


CREATE VIEW sys_replication_origin_status AS
    SELECT *
    FROM sys_show_replication_origin_status();

REVOKE ALL ON sys_replication_origin_status FROM public;

--
-- We have a few function definitions in here, too.
-- At some point there might be enough to justify breaking them out into
-- a separate "system_functions.sql" file.
--

-- Tsearch debug function.  Defined here because it'd be pretty unwieldy
-- to put it into sys_proc.h

CREATE INTERNAL FUNCTION ts_debug(IN config regconfig, IN document text,
    OUT alias text,
    OUT description text,
    OUT token text,
    OUT dictionaries regdictionary[],
    OUT dictionary regdictionary,
    OUT lexemes text[])
RETURNS SETOF record AS
$$
SELECT
    tt.alias AS alias,
    tt.description AS description,
    parse.token AS token,
    ARRAY ( SELECT m.mapdict::sys_catalog.regdictionary
            FROM sys_catalog.sys_ts_config_map AS m
            WHERE m.mapcfg = $1 AND m.maptokentype = parse.tokid
            ORDER BY m.mapseqno )
    AS dictionaries,
    ( SELECT mapdict::sys_catalog.regdictionary
      FROM sys_catalog.sys_ts_config_map AS m
      WHERE m.mapcfg = $1 AND m.maptokentype = parse.tokid
      ORDER BY sys_catalog.ts_lexize(mapdict, parse.token) IS NULL, m.mapseqno
      LIMIT 1
    ) AS dictionary,
    ( SELECT sys_catalog.ts_lexize(mapdict, parse.token)
      FROM sys_catalog.sys_ts_config_map AS m
      WHERE m.mapcfg = $1 AND m.maptokentype = parse.tokid
      ORDER BY sys_catalog.ts_lexize(mapdict, parse.token) IS NULL, m.mapseqno
      LIMIT 1
    ) AS lexemes
FROM sys_catalog.ts_parse(
        (SELECT cfgparser FROM sys_catalog.sys_ts_config WHERE oid = $1 ), $2
    ) AS parse,
     sys_catalog.ts_token_type(
        (SELECT cfgparser FROM sys_catalog.sys_ts_config WHERE oid = $1 )
    ) AS tt
WHERE tt.tokid = parse.tokid
$$
LANGUAGE SQL STRICT STABLE PARALLEL SAFE;

COMMENT ON FUNCTION ts_debug(regconfig,text) IS
    'debug function for text search configuration';

CREATE INTERNAL FUNCTION ts_debug(IN document text,
    OUT alias text,
    OUT description text,
    OUT token text,
    OUT dictionaries regdictionary[],
    OUT dictionary regdictionary,
    OUT lexemes text[])
RETURNS SETOF record AS
$$
    SELECT * FROM ts_debug(sys_catalog.get_current_ts_config(), $1);
$$
LANGUAGE SQL STRICT STABLE PARALLEL SAFE;

COMMENT ON FUNCTION ts_debug(text) IS
    'debug function for current text search configuration';

--
-- Redeclare built-in functions that need default values attached to their
-- arguments.  It's impractical to set those up directly in sys_proc.h because
-- of the complexity and platform-dependency of the expression tree
-- representation.  (Note that internal functions still have to have entries
-- in sys_proc.h; we are merely causing their proargnames and proargdefaults
-- to get filled in.)
--

CREATE OR REPLACE INTERNAL FUNCTION
  sys_start_backup(label text, fast boolean DEFAULT false, exclusive boolean DEFAULT true)
  RETURNS sys_lsn STRICT VOLATILE LANGUAGE internal AS 'sys_start_backup'
  PARALLEL RESTRICTED;

-- legacy definition for compatibility with 9.3
CREATE OR REPLACE INTERNAL FUNCTION
  json_populate_record(base anyelement, from_json json, use_json_as_text boolean DEFAULT false)
  RETURNS anyelement LANGUAGE internal STABLE AS 'json_populate_record' PARALLEL SAFE;

-- legacy definition for compatibility with 9.3
CREATE OR REPLACE INTERNAL FUNCTION
  json_populate_recordset(base anyelement, from_json json, use_json_as_text boolean DEFAULT false)
  RETURNS SETOF anyelement LANGUAGE internal STABLE ROWS 100  AS 'json_populate_recordset' PARALLEL SAFE;

CREATE OR REPLACE INTERNAL FUNCTION sys_logical_slot_get_changes(
    IN slot_name name, IN upto_lsn sys_lsn, IN upto_nchanges int, VARIADIC options text[] DEFAULT '{}',
    OUT location sys_lsn, OUT xid xid, OUT data text)
RETURNS SETOF RECORD
LANGUAGE INTERNAL
VOLATILE ROWS 1000 COST 1000
AS 'sys_logical_slot_get_changes';

CREATE OR REPLACE INTERNAL FUNCTION sys_logical_slot_peek_changes(
    IN slot_name name, IN upto_lsn sys_lsn, IN upto_nchanges int, VARIADIC options text[] DEFAULT '{}',
    OUT location sys_lsn, OUT xid xid, OUT data text)
RETURNS SETOF RECORD
LANGUAGE INTERNAL
VOLATILE ROWS 1000 COST 1000
AS 'sys_logical_slot_peek_changes';

CREATE OR REPLACE INTERNAL FUNCTION sys_logical_slot_get_binary_changes(
    IN slot_name name, IN upto_lsn sys_lsn, IN upto_nchanges int, VARIADIC options text[] DEFAULT '{}',
    OUT location sys_lsn, OUT xid xid, OUT data bytea)
RETURNS SETOF RECORD
LANGUAGE INTERNAL
VOLATILE ROWS 1000 COST 1000
AS 'sys_logical_slot_get_binary_changes';

CREATE OR REPLACE INTERNAL FUNCTION sys_logical_slot_peek_binary_changes(
    IN slot_name name, IN upto_lsn sys_lsn, IN upto_nchanges int, VARIADIC options text[] DEFAULT '{}',
    OUT location sys_lsn, OUT xid xid, OUT data bytea)
RETURNS SETOF RECORD
LANGUAGE INTERNAL
VOLATILE ROWS 1000 COST 1000
AS 'sys_logical_slot_peek_binary_changes';

CREATE OR REPLACE INTERNAL FUNCTION sys_create_physical_replication_slot(
    IN slot_name name, IN immediately_reserve boolean DEFAULT false,
    OUT slot_name name, OUT xlog_position sys_lsn)
RETURNS RECORD
LANGUAGE INTERNAL
STRICT VOLATILE
AS 'sys_create_physical_replication_slot';

CREATE OR REPLACE INTERNAL FUNCTION
  jsonb_set(jsonb_in jsonb, path text[] , replacement jsonb,
            create_if_missing boolean DEFAULT true)
RETURNS jsonb
LANGUAGE INTERNAL
STRICT IMMUTABLE PARALLEL SAFE
AS 'jsonb_set';

CREATE OR REPLACE INTERNAL FUNCTION
  parse_ident(str text, strict boolean DEFAULT true)
RETURNS text[]
LANGUAGE INTERNAL
STRICT IMMUTABLE PARALLEL SAFE
AS 'parse_ident';

CREATE OR REPLACE INTERNAL FUNCTION
  jsonb_insert(jsonb_in jsonb, path text[] , replacement jsonb,
            insert_after boolean DEFAULT false)
RETURNS jsonb
LANGUAGE INTERNAL
STRICT IMMUTABLE PARALLEL SAFE
AS 'jsonb_insert';

-- The default permissions for functions mean that anyone can execute them.
-- A number of functions shouldn't be executable by just anyone, but rather
-- than use explicit 'superuser()' checks in those functions, we use the GRANT
-- system to REVOKE access to those functions at initdb time.  Administrators
-- can later change who can access these functions, or leave them as only
-- available to superuser / cluster owner, if they choose.
REVOKE EXECUTE ON FUNCTION sys_start_backup(text, boolean, boolean) FROM public;
REVOKE EXECUTE ON FUNCTION sys_stop_backup() FROM public;
REVOKE EXECUTE ON FUNCTION sys_stop_backup(boolean) FROM public;
REVOKE EXECUTE ON FUNCTION sys_create_restore_point(text) FROM public;
REVOKE EXECUTE ON FUNCTION sys_switch_xlog() FROM public;
REVOKE EXECUTE ON FUNCTION sys_xlog_replay_pause() FROM public;
REVOKE EXECUTE ON FUNCTION sys_xlog_replay_resume() FROM public;
REVOKE EXECUTE ON FUNCTION sys_rotate_logfile() FROM public;
REVOKE EXECUTE ON FUNCTION sys_reload_conf() FROM public;

REVOKE EXECUTE ON FUNCTION sys_stat_reset() FROM public;
REVOKE EXECUTE ON FUNCTION sys_stat_reset_shared(text) FROM public;
REVOKE EXECUTE ON FUNCTION sys_stat_reset_single_table_counters(oid) FROM public;
REVOKE EXECUTE ON FUNCTION sys_stat_reset_single_function_counters(oid) FROM public;

/* show the grant information */
CREATE VIEW sys_grant_privileges AS
--table, view, sequence
                SELECT
                        grantor.name AS grantor,
                        grantor.type AS grantortype,
                        grantee.name AS grantee,
                        grantee.type AS granteetype,
                        c.relname AS object_name,
                        (
                                CASE WHEN c.relkind = 'r' THEN 'table'
                                WHEN c.relkind = 'v' THEN 'view'
                                ELSE 'sequence' END
                        ) AS object_type,
                        nsp.nspname AS object_schema,
                        pr.type AS privilege_type,
                        (
                        CASE WHEN
                        (
                                aclcontains (c.relacl, makeaclitem(grantee.usesysid, grantor.usesysid, pr.type, true))
                                OR grantor.name = grantee.name
                        )
                        THEN 'YES' ELSE 'NO' END ) AS is_grantable
                FROM sys_class c,
                         sys_namespace nsp,
                        (
                                SELECT usesysid, usename, 'user' FROM sys_user
                                UNION ALL
                                SELECT OID, ROLNAME, 'role' from sys_roles
                        )as grantor(usesysid, name, type),
                        (
                                SELECT usesysid, usename, 'user' FROM sys_user
                                UNION ALL
                                SELECT OID, ROLNAME, 'role' from sys_roles
                        ) AS grantee (usesysid, name, type),
            ( SELECT 'SELECT' UNION ALL
                        SELECT 'DELETE' UNION ALL
                        SELECT 'INSERT' UNION ALL
                        SELECT 'UPDATE' UNION ALL
                        SELECT 'REFERENCES' UNION ALL
                        SELECT 'TRIGGER' UNION ALL
                        SELECT 'TRUNCATE' UNION ALL
                        SELECT 'RULE'
                ) AS pr (type)
                WHERE
                        (
                                ((c.relacl is null) AND (grantor.name=grantee.name) AND (c.relowner = grantee.usesysid))
                                 OR  aclcontains(c.relacl, makeaclitem(grantee.usesysid, grantor.usesysid, pr.type, false))
                        )
                        AND (c.relkind = 'r' OR c.relkind = 'v' OR c.relkind = 'S')
                        AND c.relnamespace != 11
                        AND c.relnamespace = nsp.oid
                        AND grantor.name != grantee.name
--function, procedure
 UNION ALL
                SELECT
                        grantor.name AS grantor,
                        grantor.type AS grantortype,
                        grantee.name AS grantee,
                        grantee.type AS granteetype,
                        p.proname AS object_name,
                        (case p.protype when 'p' then 'PROCEDURE'::TEXT  when 'f' then 'FUNCTION' end ) AS object_type, /* FIXME */
                        nsp.nspname AS object_schema,
                        pr.type AS privilege_type,
                        (
                        CASE WHEN
                        (
                                aclcontains (p.proacl, makeaclitem(grantee.usesysid, grantor.usesysid, pr.type, true))
                                OR grantor.name = grantee.name
                        )
                        THEN 'YES' ELSE 'NO' END ) AS is_grantable
                FROM sys_proc p,
                         sys_namespace nsp,
                        (
                                SELECT usesysid, usename, 'user' FROM sys_user
                                UNION ALL
                                SELECT OID, ROLNAME, 'role' from sys_roles
                        )as grantor(usesysid, name, type),
                        (
                                SELECT usesysid, usename, 'user' FROM sys_user
                                UNION ALL
                                SELECT OID, ROLNAME, 'role' from sys_roles
                        ) AS grantee (usesysid, name, type),
            ( SELECT 'EXECUTE'::TEXT) AS pr (type)
                WHERE
                        (
                                ((p.proacl is null) AND (grantor.name=grantee.name) AND (p.proowner = grantee.usesysid))
                                 OR  aclcontains(p.proacl, makeaclitem(grantee.usesysid, grantor.usesysid, pr.type, false))
                        )
                        AND (p.protype = 'f' OR p.protype = 'p')  /* FIXME */
                        AND p.pronamespace != 11
                        AND p.pronamespace = nsp.oid
                        AND grantor.name != grantee.name
--database
 UNION ALL
                SELECT
                        grantor.name AS grantor,
                        grantor.type AS grantortype,
                        grantee.name AS grantee,
                        grantee.type AS granteetype,
                        d.datname AS object_name,
                        'DATABASE' AS object_type,
                        NULL AS object_schema,
                        pr.type AS privilege_type,
                        (
                        CASE WHEN
                        (
                                aclcontains (d.datacl, makeaclitem(grantee.usesysid, grantor.usesysid, pr.type, true))
                                OR grantor.name = grantee.name
                        )
                        THEN 'YES' ELSE 'NO' END ) AS is_grantable
                FROM sys_database d,
                        (
                                SELECT usesysid, usename, 'user' FROM sys_user
                                UNION ALL
                                SELECT OID, ROLNAME, 'role' from sys_roles
                        )as grantor(usesysid, name, type),
                        (
                                SELECT usesysid, usename, 'user' FROM sys_user
                                UNION ALL
                                SELECT OID, ROLNAME, 'role' from sys_roles
                        ) AS grantee (usesysid, name, type),
            ( SELECT 'CREATE' UNION ALL
                        SELECT 'TEMPORARY' UNION ALL
                        SELECT 'CONNECT') AS pr (type)
                WHERE
                        (
                                ((d.datacl is null) AND (grantor.name=grantee.name) AND (d.datdba = grantee.usesysid))
                                 OR  aclcontains(d.datacl, makeaclitem(grantee.usesysid, grantor.usesysid, pr.type, false))
                        )
                        AND grantor.name != grantee.name
--tablespace
 UNION ALL
                SELECT
                        grantor.name AS grantor,
                        grantor.type AS grantortype,
                        grantee.name AS grantee,
                        grantee.type AS granteetype,
                        t.spcname AS object_name,
                        'TABLESPACE' AS object_type,
                        NULL AS object_schema,
                        pr.type AS privilege_type,
                        (
                        CASE WHEN
                        (
                                aclcontains (t.spcacl, makeaclitem(grantee.usesysid, grantor.usesysid, pr.type, true))
                                OR grantor.name = grantee.name
                        )
                        THEN 'YES' ELSE 'NO' END ) AS is_grantable
                FROM sys_tablespace t,
                        (
                                SELECT usesysid, usename, 'user' FROM sys_user
                                UNION ALL
                                SELECT OID, ROLNAME, 'role' from sys_roles
                        )as grantor(usesysid, name, type),
                        (
                                SELECT usesysid, usename, 'user' FROM sys_user
                                UNION ALL
                                SELECT OID, ROLNAME, 'role' from sys_roles
                        ) AS grantee (usesysid, name, type),
            (SELECT 'CREATE'::TEXT) AS pr (type)
                WHERE
                        (
                                ((t.spcacl is null) AND (grantor.name=grantee.name) AND (t.spcowner = grantee.usesysid))
                                 OR  aclcontains(t.spcacl, makeaclitem(grantee.usesysid, grantor.usesysid, pr.type, false))
                        )
                        AND grantor.name != grantee.name
--SCHEMA
 UNION ALL
                SELECT
                        grantor.name AS grantor,
                        grantor.type AS grantortype,
                        grantee.name AS grantee,
                        grantee.type AS granteetype,
                        n.nspname AS object_name,
                        'SCHEMA' AS object_type,
                        NULL AS object_schema,
                        pr.type AS privilege_type,
                        (
                        CASE WHEN
                        (
                                aclcontains (n.nspacl, makeaclitem(grantee.usesysid, grantor.usesysid, pr.type, true))
                                OR grantor.name = grantee.name
                        )
                        THEN 'YES' ELSE 'NO' END ) AS is_grantable
                FROM sys_namespace n,
                        (
                                SELECT usesysid, usename, 'user' FROM sys_user
                                UNION ALL
                                SELECT OID, ROLNAME, 'role' from sys_roles
                        )as grantor(usesysid, name, type),
                        (
                                SELECT usesysid, usename, 'user' FROM sys_user
                                UNION ALL
                                SELECT OID, ROLNAME, 'role' from sys_roles
                        ) AS grantee (usesysid, name, type),
            (SELECT 'CREATE' UNION ALL
                        SELECT 'USAGE') AS pr (type)

                WHERE
                        (
                                ((n.nspacl is null) AND (grantor.name=grantee.name) AND (n.nspowner = grantee.usesysid))
                                 OR  aclcontains(n.nspacl, makeaclitem(grantee.usesysid, grantor.usesysid, pr.type, false))
                        )
                        AND grantor.name != grantee.name
                        ORDER BY object_type, object_name, grantee;

CREATE VIEW sys_grant_roles AS
        SELECT grantor.USENAME AS grantor,
                grantee.name AS grantee,
                grantee.type AS granteetype,
                r.rolname AS role_name,
                (CASE WHEN m.admin_option THEN 'YES' ELSE 'NO' END) AS admin_option
        FROM sys_user AS grantor,
                (
                        SELECT usesysid, usename, 'user' FROM sys_user
                        UNION ALL
                        SELECT OID, ROLNAME, 'role' from sys_roles
                ) AS grantee (usesysid, name, type),
                sys_roles r,
                sys_auth_members m
        WHERE m.GRANTOR = grantor.usesysid
        AND m.MEMBER = grantee.usesysid
        AND m.ROLEID = r.oid;

CREATE OR REPLACE VIEW X$KZSRO AS
       SELECT 00000000 ADDR, 0 INDX, 1 INST_ID, oid KZSROROL
       from sys_authid where rolname = current_user;

CREATE OR REPLACE VIEW session_roles AS
       SELECT sys_authid.ROLNAME FROM sys_authid,X$KZSRO
       WHERE X$KZSRO.KZSROROL = sys_authid.OID;

CREATE OR REPLACE VIEW sys_shared_buffer_info AS
		SELECT COALESCE(C.relname, '<N/A>') AS tablename,
		    relblocknumber as blockid,
				usagecount,
				isdirty,
				pinning_backends
		FROM sys_buffers B
			LEFT JOIN sys_class C on C.relfilenode <> 0 AND B.relfilenode = C.relfilenode;

CREATE VIEW sys_session AS
    SELECT
        sys_stat_get_backend_pid(S.backendid) AS sess_id,
		cast(NULL as varchar(32 byte)) as curr_sch,
        U.rolname AS usename,
        sys_stat_get_backend_client_addr(S.backendid) AS client_ip,
        sys_stat_get_backend_start(S.backendid) AS create_start,
        case sys_stat_get_backend_activity(S.backendid) = '<IDLE>'
				   when true then null else sys_stat_get_backend_activity(S.backendid)
				   end AS current_query,
			 case sys_stat_get_backend_activity(S.backendid) = '<IDLE>'
           when true then '<IDLE>' else '<BUSY>' end as status
    FROM (SELECT sys_stat_get_backend_idset() AS backendid) AS S,
            sys_authid U
    WHERE sys_stat_get_backend_userid(S.backendid) = U.oid;

REVOKE ALL ON  sys_session FROM public;
GRANT SELECT ON sys_session TO public;

CREATE VIEW sys_tablespace_info AS
	select cast (NULL as varchar(30 byte)) as database_name,
			c.spcname as tablespace_name,
			a.usename  as tablespace_owner,
			cast (NULL as numeric(38,0))  totle_size,
			cast (NULL as numeric(38,0)) as free_size,
			cast(NULL as varchar(63 byte)) filename
	from sys_tablespace c, sys_user a
	where c.spcowner = a.usesysid ;

REVOKE ALL ON  sys_tablespace_info FROM PUBLIC;
GRANT SELECT ON sys_tablespace_info TO PUBLIC;

-- KingbaseES_BEGIN
-- Firstly creating some function used for creating the sys_packages view
CREATE FUNCTION get_function_definition(funcid OID) RETURNS TEXT AS $$
DECLARE
  funcInfo       RECORD;
  definition     TEXT;
  funcParams     TEXT DEFAULT '';
  funcReturnType TEXT DEFAULT '';
BEGIN
  SELECT proname, protype, pronargs INTO funcInfo FROM sys_catalog.sys_proc WHERE oid = funcid;
  IF SQL%NOTFOUND THEN
    RETURN NULL;
  END IF;
  IF funcInfo.pronargs > 0 THEN
    funcParams := sys_get_function_arguments(funcid);
  END IF;
  IF funcInfo.protype = 'f' THEN
    funcReturnType := ' RETURN ' || sys_get_function_result(funcid);
  END IF;
  definition := funcInfo.proname || '(' || funcParams || ')' || funcReturnType || ';';
  RETURN definition;
END;
$$ LANGUAGE plsql;

CREATE FUNCTION get_pkg_function_type(funcid OID) RETURNS TEXT AS $$
DECLARE
  funcTypeInfo RECORD;
  typ          TEXT;
BEGIN
  SELECT proname, protype INTO funcTypeInfo FROM sys_catalog.sys_proc WHERE oid = funcid;
  IF SQL%NOTFOUND THEN
    RETURN NULL;
  END IF;
  IF funcTypeInfo.proname = '__CONSTRUCTOR__' THEN typ := 'INIT PROCEDURE';
  ELSIF funcTypeInfo.protype = 'p' THEN typ := 'PROCEDURE';
  ELSIF funcTypeInfo.protype = 'f' THEN typ := 'FUNCTION';
  END IF;
  RETURN typ;
END;
$$ LANGUAGE plsql;

CREATE FUNCTION get_pkg_variable_type(varid OID) RETURNS TEXT AS $$
DECLARE
  varInfo RECORD;
BEGIN
  SELECT pvtype, pvncols INTO varInfo FROM sys_catalog.sys_pkgvariable WHERE oid = varid;
  IF SQL%NOTFOUND THEN
    RETURN NULL;
  END IF;
  IF varInfo.pvtype = 'v' THEN RETURN 'SCALAR VARIABLE';
  ELSIF varInfo.pvtype = 'c' AND varInfo.pvncols <> -3 THEN RETURN 'CURSOR VARIABLE';
  ELSIF varInfo.pvtype = 'c' AND varInfo.pvncols = -3 THEN RETURN 'REF CURSOR VARIABLE';
  ELSIF varInfo.pvtype = 'r' THEN RETURN 'RECORD VARIABLE';
  ELSIF varInfo.pvtype = 'w' THEN RETURN 'ROW VARIABLE';
  END IF;
END;
$$ LANGUAGE plsql;

CREATE FUNCTION get_pkg_type_type(typid OID) RETURNS TEXT AS $$
DECLARE
  typInfo RECORD;
BEGIN
  SELECT typtype, typbasetype INTO typInfo FROM sys_catalog.sys_type WHERE oid = typid;
  IF SQL%NOTFOUND THEN
    RETURN NULL;
  END IF;
  IF    typInfo.typtype = 'a' THEN RETURN 'ASSICIATIVE-VARRAY TYPE';
  ELSIF typInfo.typtype = 'd' AND sys_catalog.format_type(typInfo.typbasetype, NULL) = 'REFCURSOR' THEN RETURN 'REF CURSOR TYPE';
  ELSIF typInfo.typtype = 'n' THEN RETURN 'NESTED-TABLE TYPE';
  ELSIF typInfo.typtype = 'o' THEN RETURN 'RECORD TYPE';
  ELSIF typInfo.typtype = 'v' THEN RETURN 'VARRAY TYPE';
  ELSE RETURN 'OTHER TYPE';
  END IF;
END;
$$ LANGUAGE plsql;

CREATE FUNCTION get_pkg_type_definition(typid OID) RETURNS TEXT AS $$
DECLARE
  typInfo     RECORD;
  typTypeInfo RECORD;
  attrInfo    RECORD;
  typIs       TEXT;
  typNull     TEXT DEFAULT '';
  typIndex    TEXT DEFAULT '';
  recText     TEXT DEFAULT '';
BEGIN
  SELECT typname, typtype, typbasetype, typelem, typrelid, typnotnull, typndims INTO typInfo FROM sys_catalog.sys_type WHERE oid = typid;
  IF SQL%NOTFOUND THEN
    RETURN NULL;
  END IF;
  IF    typInfo.typtype = 'a' THEN
    SELECT typname, typrelid INTO typTypeInfo FROM sys_catalog.sys_type WHERE oid = typInfo.typelem;
    typIndex := ' INDEX BY ' || sys_catalog.format_type(typInfo.typbasetype, NULL);
    IF typTypeInfo.typrelid <> 0 THEN
      typIs := ' IS TABLE OF ' || typTypeInfo.typname || '%ROWTYPE';
    ELSE
      typIs := ' IS TABLE OF ' || typTypeInfo.typname;
    END IF;
    IF typInfo.typnotnull THEN
      typNull := ' NOT NULL';
    END IF;
  ELSIF typInfo.typtype = 'd' AND sys_catalog.format_type(typInfo.typbasetype, NULL) = 'REFCURSOR' THEN
    typIs := ' IS REF CURSOR';
  ELSIF typInfo.typtype = 'n' THEN
    SELECT typname, typrelid INTO typTypeInfo FROM sys_catalog.sys_type WHERE oid = typInfo.typelem;
    IF typTypeInfo.typrelid <> 0 THEN
      typIs := ' IS TABLE OF ' || typTypeInfo.typname || '%ROWTYPE';
    ELSE
      typIs := ' IS TABLE OF ' || typTypeInfo.typname;
    END IF;
    IF typInfo.typnotnull THEN
      typNull := ' NOT NULL';
    END IF;
  ELSIF typInfo.typtype = 'o' THEN
    DECLARE
      CURSOR attrCsr(typrelid int) FOR SELECT attname, atttypid, attnotnull FROM sys_catalog.sys_attribute WHERE attrelid = typrelid;
      attrInfo RECORD;
      recText  TEXT DEFAULT '';
    BEGIN
      OPEN attrCsr(typInfo.typrelid);
      FETCH attrCsr INTO attrInfo;
      WHILE attrCsr%found LOOP
        IF attrInfo.attnotnull THEN
          recText := recText || attrInfo.attname || ' ' || sys_catalog.format_type(attrInfo.atttypid, NULL) || ' NOT NULL';
        ELSE
          recText := recText || attrInfo.attname || ' ' || sys_catalog.format_type(attrInfo.atttypid, NULL);
        END IF;
        FETCH attrCsr INTO attrInfo;
        EXIT WHEN attrCsr%notfound;
        recText := recText || ', ';
      END LOOP;
      CLOSE attrCsr;
      typIs := 'IS RECORD (' || recText || ')';
    END;
  ELSIF typInfo.typtype = 'v' THEN
    SELECT typname, typrelid INTO typTypeInfo FROM sys_catalog.sys_type WHERE oid = typInfo.typelem;
    IF typTypeInfo.typrelid <> 0 THEN
      typIs := ' IS VARRAY(' || typInfo.typndims || ') OF ' || typTypeInfo.typname || '%ROWTYPE';
    ELSE
      typIs := ' IS VARRAY(' || typInfo.typndims || ') OF ' || typTypeInfo.typname;
    END IF;
    IF typInfo.typnotnull THEN
      typNull := ' NOT NULL';
    END IF;
  ELSE RETURN 'OTHER';
  END IF;
  RETURN 'TYPE ' || typInfo.typname || typIs || typNull || typIndex || ';';
END;
$$ LANGUAGE plsql;

-- Create view for Package: sys_packages
CREATE VIEW sys_packages AS
    SELECT
      (SELECT nspname FROM sys_namespace WHERE oid = sp.pkgnamespace) AS NAMESPACE,
                                                          sp.pkgname AS PACKAGENAME,
                                        sys_get_userbyid(sp.pkgowner) AS OWNER,
       CASE WHEN sd.classid = regclassin('SYS_PKGVARIABLE') THEN
              (SELECT get_pkg_variable_type(oid)
                      FROM sys_pkgvariable WHERE oid = sd.objid)
            WHEN sd.classid = regclassin('SYS_TYPE') THEN
              (SELECT get_pkg_type_type(oid)
                      FROM sys_type WHERE oid = sd.objid)
                                                                 END AS TYPE,
       CASE WHEN sd.classid = regclassin('SYS_PKGVARIABLE') THEN
              (SELECT pvsrc
                      FROM sys_pkgvariable WHERE oid = sd.objid)
            WHEN sd.classid = regclassin('SYS_TYPE') THEN
              (SELECT get_pkg_type_definition(oid)
                      FROM sys_type WHERE oid = sd.objid)
                                                                 END AS OBJ,
       CASE sp.PKGSTATUS
            WHEN 't' THEN 'VALID'
            WHEN 'f' THEN 'INVALID'
                                                                 END AS STATUS
    FROM       sys_depend AS sd
        JOIN sys_package AS sp
        ON sd.refclassid = regclassin('SYS_PACKAGE') AND sd.refobjid = sp.oid
    WHERE sd.classid <> (SELECT oid FROM sys_class WHERE relname = 'SYS_NAMESPACE')
  UNION
    SELECT
      (SELECT nspname FROM sys_namespace WHERE oid = sp.pkgnamespace) AS NAMESPACE,
                                                          sp.pkgname AS PACKAGENAME,
                                        sys_get_userbyid(sp.pkgowner) AS OWNER,
                                       get_pkg_function_type(sf.oid) AS TYPE,
                                     get_function_definition(sf.oid) AS OBJ,
       CASE sp.PKGSTATUS
            WHEN 't' THEN 'VALID'
            WHEN 'f' THEN 'INVALID'
                                                                 END AS STATUS
    FROM         sys_proc AS sf
        JOIN sys_package AS sp
        ON sf.pronamespace IN (SELECT oid FROM sys_namespace WHERE nspname IN (sp.pkgname))
  ORDER BY NAMESPACE, PACKAGENAME, OWNER, TYPE, OBJ;

REVOKE ALL ON  sys_packages FROM PUBLIC;
GRANT SELECT ON sys_packages TO PUBLIC;

/*
 * MAC policy views
 *
 *  policy:
 *    SYS_MAC_POLICIES
 *    SYS_MAC_LEVELS
 *    SYS_MAC_COMPARTMENTS
 *    SYS_MAC_TABLE_POLICIES
 *  label:
 *    SYS_MAC_LABELS
 *    SYS_MAC_LABEL_LEVELS
 *    SYS_MAC_LABEL_COMPARTMENTS
 *  user:
 *    SYS_MAC_USER_PRIVS
 *    SYS_MAC_USER_LEVELS
 *    SYS_MAC_USER_COMPARTMENTS
 *  session:
 *    SYS_MAC_SESSION
 *    SYS_MAC_SESSION_LABEL_LOOKUP_INFO(debug)
 *    SYS_MAC_SESSION_LABEL_MEDIATION(debug)
 */
CREATE VIEW sys_mac_levels AS
	SELECT
		P.policy_name AS policy_name,
		L.level_id AS level_id,
		L.level_shortname AS short_name,
		L.level_longname AS long_name
	FROM sys_mac_level L INNER JOIN sys_mac_policy P ON (L.policy_id = P.oid);

CREATE VIEW sys_mac_compartments AS
	SELECT
		P.policy_name AS policy_name,
		C.compartment_id AS comp_id,
		C.compartment_shortname AS short_name,
		C.compartment_longname AS long_name
	FROM sys_mac_compartment C INNER JOIN sys_mac_policy P ON (C.policy_id = P.oid);

CREATE VIEW sys_mac_labels AS
	SELECT
		P.policy_name AS policy_name,
		L.label_id AS label_id,
		label_to_char(label_id) AS label
	FROM sys_mac_label L INNER JOIN sys_mac_policy P ON (L.policy_id = P.oid);

CREATE VIEW sys_mac_policies AS
	SELECT
		policy_name AS policy_name,
		policy_col_name AS column_name,
		policy_col_hidden AS column_hide,
		policy_enable AS policy_enable,
		oid AS policy_id
	FROM sys_mac_policy;

CREATE VIEW sys_mac_table_policies AS
	SELECT
		P.policy_name AS policy_name,
		N.nspname AS schema_name,
		C.relname AS table_name,
		P.policy_col_name AS policy_col_column,
		P.policy_col_hidden AS policy_table_hide
	FROM sys_mac_policy P INNER JOIN sys_mac_policy_enforcement E ON (E.policy_id = P.oid)
		INNER JOIN sys_class C ON (E.relation_id = C.Oid)
		INNER JOIN sys_namespace N ON (c.relnamespace = N.Oid);

CREATE VIEW sys_mac_user_levels AS
	SELECT
		policy_name AS policy_name,
		rolname AS user_name,
		(SELECT level_shortname FROM sys_mac_level WHERE policy_id = U.policy_id AND level_id = U.max_levelid) AS max_level,
		(SELECT level_shortname FROM sys_mac_level WHERE policy_id = U.policy_id AND level_id = U.min_levelid) AS min_level,
		(SELECT level_shortname FROM sys_mac_level WHERE policy_id = U.policy_id AND level_id = U.def_levelid) AS def_level,
		(SELECT level_shortname FROM sys_mac_level WHERE policy_id = U.policy_id AND level_id = U.row_levelid) AS row_level
	FROM sys_mac_user U INNER JOIN sys_authid A ON U.role_id = A.oid
		INNER JOIN sys_mac_policy P ON U.policy_id = P.oid;

CREATE VIEW sys_mac_user_compartments AS
	SELECT
			(SELECT policy_name FROM sys_mac_policy WHERE oid = policy_id) AS policy_name,
			(SELECT rolname FROM sys_authid WHERE oid = role_id) AS user_name,
			(SELECT compartment_shortname FROM sys_mac_compartment WHERE policy_id = UC.policy_id AND compartment_id = UC.compartment_id) AS comp,
			CASE WHEN ARRAY[UC.compartment_id] <@ (SELECT write_compartmentids::int2[] FROM sys_mac_user U WHERE policy_id = UC.policy_id AND role_id = UC.role_id) THEN 'WRITE' ELSE 'READ' END AS rw_access,
			CASE WHEN ARRAY[UC.compartment_id] <@ (SELECT def_compartmentids::int2[] FROM sys_mac_user U WHERE policy_id = UC.policy_id AND role_id = UC.role_id) THEN 'Y' ELSE 'N' END AS def_comp,
			CASE WHEN ARRAY[UC.compartment_id] <@ (SELECT row_compartmentids::int2[] FROM sys_mac_user U WHERE policy_id = UC.policy_id AND role_id = UC.role_id) THEN 'Y' ELSE 'N' END AS row_comp,
			CASE WHEN ARRAY[UC.compartment_id] <@ (SELECT min_write_compartmentids::int2[] FROM sys_mac_user U WHERE policy_id = UC.policy_id AND role_id = UC.role_id) THEN 'Y' ELSE 'N' END AS min_write_comp
		FROM (SELECT policy_id, role_id, unnest(read_compartmentids) AS compartment_id FROM sys_mac_user) UC;

CREATE VIEW sys_mac_user_privs AS
	SELECT
		rolname AS user_name,
		policy_name AS policy_name,
		mac_privs_to_char(privilege) AS user_privileges
	FROM sys_mac_user U INNER JOIN sys_authid A ON U.role_id = A.oid
		INNER JOIN sys_mac_policy P ON U.policy_id = P.oid;

CREATE VIEW sys_mac_session AS
	SELECT
			COALESCE((SELECT policy_name FROM sys_mac_policy WHERE oid = policy_id), 'ERROR:DORPPED POLICY:' || policy_id) AS policy_name,
			(SELECT rolname FROM sys_authid WHERE oid = role_id) AS user_name,
			privs,
			max_read_label,
			max_write_label,
			min_write_label,
			def_read_label,
			def_write_label,
			def_row_label
	FROM SHOW_LABEL() AS foo(policy_id oid, role_id oid, privs text,
							max_read_label text, max_write_label text,
							min_write_label text, def_read_label text,
							def_write_label text,  def_row_label text)
	ORDER BY policy_id;

CREATE VIEW sys_mac_label_levels AS
	SELECT
		policy_name,
		LABEL_TO_CHAR(label_id) AS label,
		L.level_shortname AS level_shortname
	FROM sys_mac_label LL INNER JOIN sys_mac_policy P ON P.oid = LL.policy_id
		INNER JOIN sys_mac_level L ON LL.policy_id = L.policy_id and LL.level_id = L.level_id;

CREATE VIEW sys_mac_label_compartments AS
	SELECT
		policy_name,
		LABEL_TO_CHAR(label_id) AS label,
		compartment_shortname AS compartment_shortname
	FROM (SELECT policy_id, label_id, unnest(compartment_ids) AS compartment_id FROM sys_mac_label) LC INNER JOIN sys_mac_policy P ON P.oid = LC.policy_id
		INNER JOIN sys_mac_compartment C ON C.policy_id = LC.policy_id AND C.compartment_id = LC.compartment_id;

CREATE VIEW sys_mac_session_label_lookup_info AS
	SELECT
		policy_id AS policy_id,
		COALESCE((SELECT policy_name FROM sys_mac_policy WHERE oid = policy_id), 'ERROR:DORPPED POLICY') AS policy_name,
		default_row_label_id,
		max_label_id,
		min_label_id,
		label_count
	FROM show_session_label_lookup() AS foo(policy_id OID, default_row_label_id INT,
											max_label_id INT, min_label_id INT, label_count INT)
	ORDER BY policy_id;

CREATE VIEW sys_mac_session_label_mediation AS
	SELECT
		label_id AS label_id,
		CASE WHEN EXISTS (SELECT label_id FROM sys_mac_label WHERE label_id = foo.label_id) THEN LABEL_TO_CHAR(label_id) ELSE 'ERROR:DROPPED LEVEL:' || policy_id END AS label,
		policy_id AS policy_id,
		COALESCE((SELECT policy_name FROM sys_mac_policy WHERE oid = policy_id), 'ERROR:DORPPED POLICY') AS policy_name,
		CASE WHEN informations & 2 THEN 'READ_PRIV_ACCESS' WHEN informations & 1 THEN 'READ_ACCESS' ELSE 'NO_ACCESS' END AS read_access,
		CASE WHEN informations & 8 THEN 'WRITE_PRIV_ACCESS' WHEN informations & 4 THEN 'WRITE_ACCESS' ELSE 'NO_ACCESS' END AS write_access,
		CASE WHEN informations & 32 THEN 'INSERT_PRIV_ACCESS' WHEN informations & 16 THEN 'INSERT_ACCESS' ELSE 'NO_ACCESS' END AS insert_access,
		CASE WHEN informations & 64 THEN 'USED' ELSE 'NOT USED' END AS priv_read_used,
		CASE WHEN informations & 128 THEN 'USED' ELSE 'NOT USED' END AS priv_full_used
	FROM show_session_label_mediation() AS foo(label_id INT, policy_id OID, informations INT)
	ORDER BY policy_id, label_id;

-- Create view for user logon: sys_audit_userlog
CREATE VIEW sys_user_audit_userlog AS
    SELECT audusername AS USER_NAME,
               audhost AS HOST,
          audtimestamp AS LOGON_TIME,
       CASE audtype
           WHEN 's' THEN 'SUCCESSFUL'
           WHEN 'f' THEN 'FAILED'
           WHEN 'u' THEN 'BLOCKED'
                   END AS LOGON_STATUS
    FROM sys_audit_userlog
    WHERE audusername = CURRENT_USER
    ORDER BY audtimestamp DESC;

GRANT SELECT ON sys_user_audit_userlog TO PUBLIC;
REVOKE ALL on sys_audit_userlog FROM public;

-- KingbaseES_END

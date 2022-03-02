-- set up compatibility shemas.

-- DBA_OBJECTS describes all objects in the database.
CREATE OR REPLACE VIEW dba_objects(
		  owner
        , object_name
        , subobject_name
        , object_id, data_object_id
        , object_type, created
        , last_ddl_time, timestamp
        , status, temporary, generated, secondary
        , namespace
		)
AS
SELECT    CAST(u.usename AS VARCHAR2(63 BYTE)) -- TODO: Oracle uses 32.
        , CAST(relname AS VARCHAR2(63 BYTE))
        , CAST(NULL AS VARCHAR2(63 BYTE))
        , CAST(CAST(c.oid AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
        , CAST(NULL AS NUMERIC(38,0))
        , CAST(
            (CASE relkind
	            -- when 'c' THEN 'COMPOSITE'
	            WHEN 'r' THEN 'TABLE'
	            WHEN 'S' THEN 'SEQUENCE'
	            -- WHEN 's' THEN 'SPECIAL'
	            WHEN 't' THEN 'TYPE'
	            WHEN 'v' THEN 'VIEW'
	            WHEN 'i' THEN 'INDEX'
	            ELSE 'UNKNOWN'
			END)
            AS VARCHAR2(19 BYTE))
        , CAST(NULL AS DATE)
        , CAST(NULL AS DATE)
        , CAST(NULL AS VARCHAR2(20 BYTE))
        , CAST(
 			(CASE c.relkind
				WHEN 'v' THEN
				(CASE c.relstatus
				WHEN 't' THEN 'VALID'
				ELSE 'INVALID'
				END)
			ELSE 'VALID'
		END) AS VARCHAR2(7 BYTE))
        , CAST((CASE WHEN relpersistence = 't' THEN 'Y' ELSE 'N' END) AS VARCHAR2(1 BYTE))
        , CAST(NULL AS VARCHAR2(1 BYTE))
        , CAST(NULL AS VARCHAR2(1 BYTE))
        , CAST(CAST(relnamespace AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
    FROM sys_class c JOIN sys_user u
        ON c.relowner = u.usesysid
    WHERE c.RELNAMESPACE != sys_my_temp_schema()

UNION

SELECT    CAST(u.usename AS VARCHAR2(63 BYTE))
        , CAST(synname AS VARCHAR2(63 BYTE))
        , CAST(NULL AS VARCHAR2(63 BYTE))
        , CAST(CAST(syn.oid AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
        , CAST(NULL AS NUMERIC(38,0))
        , CAST('SYNONYM' AS VARCHAR2(19 BYTE))
        , CAST(NULL AS DATE)
        , CAST(NULL AS DATE)
        , CAST(NULL AS VARCHAR2(20 BYTE))
        , CAST('VALID' AS VARCHAR2(7 BYTE))
        , CAST(NULL AS VARCHAR2(1 BYTE))
        , CAST(NULL AS VARCHAR2(1 BYTE))
        , CAST(NULL AS VARCHAR2(1 BYTE))
        , CAST(CAST(synnamespace AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
    FROM sys_synonym syn JOIN sys_user u
        ON syn.synowner = u.usesysid
    WHERE syn.synnamespace != sys_my_temp_schema()

/*
UNION
SELECT    CAST(u.usename AS VARCHAR2(63 BYTE)) -- TODO: Oracle uses 32.
        , CAST(l.relname AS VARCHAR2(63 BYTE))
        , CAST(c.relname AS VARCHAR2(63 BYTE))
        , CAST(CAST(c.oid AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
        , CAST(CAST(c.oid AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
        , CAST(
			(CASE c.relkind
				WHEN 'r' THEN 'TABLE PARTITION'
				WHEN 'i' THEN 'INDEX PARTITON'
				ELSE 'UNKNOWN'
			END)
		  AS VARCHAR2(19 BYTE))
        , CAST(NULL AS DATE)
        , CAST(NULL AS DATE)
        , CAST(NULL AS VARCHAR2(20 BYTE))
        , CAST('VALID' AS VARCHAR2(7 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(CAST(c.relnamespace AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
    FROM sys_class c JOIN sys_user u ON c.relowner = u.usesysid,
	     sys_class l, sys_partition p
    WHERE c.relparttyp = 'p' AND p.partitionrelid = c.oid
	      AND p.partrelid = l.oid
*/
UNION

SELECT    CAST(current_user AS VARCHAR2(63 BYTE)) -- TODO: Oracle uses 32.
        , CAST('TRIGGER_PKG' AS VARCHAR2(63 BYTE))
        , CAST(NULL AS VARCHAR2(63 BYTE))
        , CAST(0 AS NUMERIC(38,0))
        , CAST(NULL AS NUMERIC(38,0))
        , CAST('PACKAGE'  AS VARCHAR2(19 BYTE))
        , CAST(NULL AS DATE)
        , CAST(NULL AS DATE)
        , CAST(NULL AS VARCHAR2(20 BYTE))
        , CAST('VALID' AS VARCHAR2(7 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(0 AS NUMERIC(38,0))

UNION

SELECT    CAST(current_user AS VARCHAR2(63 BYTE)) -- TODO: Oracle uses 32.
        , CAST('OPEN2000E_PKG' AS VARCHAR2(63 BYTE))
        , CAST(NULL AS VARCHAR2(63 BYTE))
        , CAST(0 AS NUMERIC(38,0))
        , CAST(NULL AS NUMERIC(38,0))
        , CAST('PACKAGE'  AS VARCHAR2(19 BYTE))
        , CAST(NULL AS DATE)
        , CAST(NULL AS DATE)
        , CAST(NULL AS VARCHAR2(20 BYTE))
        , CAST('VALID' AS VARCHAR2(7 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(0 AS NUMERIC(38,0))

UNION

SELECT    CAST(current_user AS VARCHAR2(63 BYTE)) -- TODO: Oracle uses 32.
        , CAST('FORM_TM_ND_TAP_MEAS' AS VARCHAR2(63 BYTE))
        , CAST(NULL AS VARCHAR2(63 BYTE))
        , CAST(0 AS NUMERIC(38,0))
        , CAST(NULL AS NUMERIC(38,0))
        , CAST('PACKAGE'  AS VARCHAR2(19 BYTE))
        , CAST(NULL AS DATE)
        , CAST(NULL AS DATE)
        , CAST(NULL AS VARCHAR2(20 BYTE))
        , CAST('VALID' AS VARCHAR2(7 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(0 AS NUMERIC(38,0))

UNION

SELECT    CAST(current_user AS VARCHAR2(63 BYTE)) -- TODO: Oracle uses 32.
        , CAST('NEW_STATISTICS_SAMPLE_PKG' AS VARCHAR2(63 BYTE))
        , CAST(NULL AS VARCHAR2(63 BYTE))
        , CAST(0 AS NUMERIC(38,0))
        , CAST(NULL AS NUMERIC(38,0))
        , CAST('PACKAGE'  AS VARCHAR2(19 BYTE))
        , CAST(NULL AS DATE)
        , CAST(NULL AS DATE)
        , CAST(NULL AS VARCHAR2(20 BYTE))
        , CAST('VALID' AS VARCHAR2(7 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(0 AS NUMERIC(38,0))

UNION

SELECT    CAST(u.usename AS VARCHAR2(63 BYTE)) -- TODO: Oracle uses 32.
        , CAST(proname AS VARCHAR2(63 BYTE))
        , CAST(NULL AS VARCHAR2(63 BYTE))
        , CAST(CAST(p.oid AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
        , CAST(NULL AS NUMERIC(38,0))
        , CAST(
            (CASE protype
	            WHEN 'f' THEN 'FUNCTION'
	            WHEN 'p' THEN 'PROCEDURE'
	            ELSE 'UNKNOWN'
			END)
            AS VARCHAR2(19 BYTE))
        , CAST(NULL AS DATE)
        , CAST(NULL AS DATE)
        , CAST(NULL AS VARCHAR2(20 BYTE))
        , CAST('VALID' AS VARCHAR2(7 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(CAST(pronamespace AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
    FROM sys_proc p JOIN sys_user u
        ON p.proowner = u.usesysid
        AND p.pronamespace IN (SELECT oid FROM sys_namespace WHERE nspparent = 0) -- Filter packege function

UNION

SELECT    CAST(u.usename AS VARCHAR2(63 BYTE)) -- TODO: Oracle uses 32.
        , CAST(t.tgname AS VARCHAR2(63 BYTE))
        , CAST(NULL AS VARCHAR2(63 BYTE))
        , CAST(CAST(t.oid AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
        , CAST(NULL AS NUMERIC(38,0))
        , CAST('TRIGGER'AS VARCHAR2(19 BYTE))
        , CAST(NULL AS DATE)
        , CAST(NULL AS DATE)
        , CAST(NULL AS VARCHAR2(20 BYTE))
        , CAST('VALID' AS VARCHAR2(7 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(CAST(c.relnamespace AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
	FROM sys_trigger t JOIN sys_class c ON t.tgrelid = c.oid ,
	     sys_user u
	WHERE  c.relowner = u.usesysid

UNION

SELECT    CAST(u.usename AS VARCHAR2(63 BYTE)) -- TODO: Oracle uses 32.
        , CAST(syn.synname AS VARCHAR2(63 BYTE))
        , CAST(NULL AS VARCHAR2(63 BYTE))
        , CAST(CAST(syn.oid AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
        , CAST(NULL AS NUMERIC(38,0))
        , CAST('SYNONYM'AS VARCHAR2(19 BYTE))
        , CAST(NULL AS DATE)
        , CAST(NULL AS DATE)
        , CAST(NULL AS VARCHAR2(20 BYTE))
        , CAST('VALID' AS VARCHAR2(7 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(CAST(syn.synnamespace AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
    FROM sys_synonym syn JOIN sys_user u
        ON syn.synowner = u.usesysid

UNION

SELECT    CAST(u.usename AS VARCHAR2(63 BYTE)) -- TODO: Oracle uses 32.
        , CAST(pkgname AS VARCHAR2(63 BYTE))
        , CAST(NULL AS VARCHAR2(63 BYTE))
        , CAST(CAST(pkg.oid AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
        , CAST(NULL AS NUMERIC(38,0))
        , CAST('PACKAGE' AS VARCHAR2(19 BYTE))
        , CAST(NULL AS DATE)
        , CAST(NULL AS DATE)
        , CAST(NULL AS VARCHAR2(20 BYTE))
        , CAST(
              (CASE pkg.PKGSTATUS
              WHEN 't' THEN 'VALID'
              WHEN 'f' THEN 'INVALID'
              END) AS VARCHAR2(7 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(CAST(pkgnamespace AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
    FROM sys_package pkg JOIN sys_user u
        ON pkg.pkgowner = u.usesysid

UNION

SELECT    CAST(u.usename AS VARCHAR2(63 BYTE)) -- TODO: Oracle uses 32.
        , CAST(pkgname AS VARCHAR2(63 BYTE))
        , CAST(NULL AS VARCHAR2(63 BYTE))
        , CAST(CAST(pkg.oid AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
        , CAST(NULL AS NUMERIC(38,0))
        , CAST('PACKAGE BODY' AS VARCHAR2(19 BYTE))
        , CAST(NULL AS DATE)
        , CAST(NULL AS DATE)
        , CAST(NULL AS VARCHAR2(20 BYTE))
        , CAST(
              (CASE pkg.PKGSTATUS
              WHEN 't' THEN 'VALID'
              WHEN 'f' THEN 'INVALID'
              END) AS VARCHAR2(7 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(NULL AS VARCHAR(1 BYTE))
        , CAST(CAST(pkgnamespace AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
    FROM sys_package pkg JOIN sys_user u
        ON pkg.pkgowner = u.usesysid AND pkg.pkgbodysrc IS NOT NULL
;

REVOKE ALL ON dba_objects FROM PUBLIC;

-- USER_OBJECTS describes all objects owned by the current user.
-- This VIEW does not display the OWNER column.
CREATE OR REPLACE VIEW user_objects
   AS
	SELECT object_name, subobject_name
	       , object_id, data_object_id
		   , object_type
		   , created, last_ddl_time, timestamp
		   , status
		   , temporary, generated, secondary
		   , namespace
    FROM dba_objects
	WHERE owner = CAST(current_user AS VARCHAR(63 BYTE))
;

-- an abnormity with qurrying to all_objects view.
-- test current user has privilege to the trigger.
CREATE OR REPLACE FUNCTION has_trigger_privilege(triggeroid OID, operation NAME)
RETURNS BOOL AS
DECLARE
	funcoid OID;
	relid OID;
BEGIN
	funcoid := NULL;
	relid := NULL;
	SELECT TGRELID, TGFOID INTO relid, funcoid FROM sys_trigger WHERE OID=triggeroid;
	IF funcoid IS NOT NULL AND has_table_privilege(CAST(CAST(relid AS VARCHAR(38 BYTE)) AS oid), 'TRIGGER') THEN
		RETURN has_function_privilege(CAST(CAST(funcoid AS VARCHAR(38 BYTE)) AS oid), operation);
	ELSE
		RETURN FALSE;
	END IF;
END;

-- ALL_OBJECTS describes all objects accessible to the current user.
CREATE OR REPLACE VIEW all_objects
    AS
    SELECT * FROM dba_objects
	WHERE owner = CAST(current_user AS VARCHAR2(63 BYTE)) OR object_type = 'SYNONYM'
	    OR ((object_type = 'PROCEDURE' OR object_type = 'FUNCTION')
		     AND has_function_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'EXECUTE')
			 )
		OR ((object_type = 'PACKAGE' OR object_type = 'PACKAGE BODY')
			 AND has_package_privilege(CAST(object_name AS NAME), 'EXECUTE')
			 )
		OR ((object_type = 'TRIGGER') AND has_trigger_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'EXECUTE')
			 )
		OR ((object_type <> 'PROCEDURE' AND object_type <> 'FUNCTION'
			AND object_type <> 'PACKAGE' AND object_type <> 'PACKAGE BODY' AND object_type <> 'TRIGGER')
                     AND (has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'SELECT')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'INSERT')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'UPDATE')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'DELETE')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'REFERENCES')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'TRIGGER')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'SELECT WITH GRANT OPTION')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'INSERT WITH GRANT OPTION')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'UPDATE WITH GRANT OPTION')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'DELETE WITH GRANT OPTION')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'TRUNCATE')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'TRUNCATE WITH GRANT OPTION')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'REFERENCES WITH GRANT OPTION')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'TRIGGER WITH GRANT OPTION')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'RULE')
                     OR has_table_privilege(CAST(CAST(object_id AS VARCHAR(38 BYTE)) AS oid), 'RULE WITH GRANT OPTION')
		   ))
;

-- DBA_TABLES describes all (partition) tables in the database.
CREATE OR REPLACE VIEW dba_tables(OWNER
		, TABLE_NAME
		, TABLESPACE_NAME
		, CLUSTER_NAME
		, IOT_NAME
		, STATUS
		, PCT_FREE
		, PCT_USED
		, INI_TRANS
		, MAX_TRANS
		, INITIAL_EXTENT
		, NEXT_EXTENT
		, MIN_EXTENTS
		, MAX_EXTENTS
		, PCT_INCREASE
		, FREELISTS
		, FREELIST_GROUPS
		, LOGGING
		, BACKED_UP
		, NUM_ROWS
		, BLOCKS
		, EMPTY_BLOCKS
		, AVG_SPACE
		, CHAIN_CNT
		, AVG_ROW_LEN
		, AVG_SPACE_FREELIST_BLOCKS
		, NUM_FREELIST_BLOCKS
		, DEGREE
		, INSTANCES
		, CACHE
		, TABLE_LOCK
		, SAMPLE_SIZE
		, LAST_ANALYZED
		, PARTITIONED
		, IOT_TYPE
		, TEMPORARY
		, SECONDARY
		, NESTED
		, BUFFER_POOL
		, ROW_MOVEMENT
		, GLOBAL_STATS
		, USER_STATS
		, DURATION
		, SKIP_CORRUPT
		, MONITORING
		, CLUSTER_OWNER
		, DEPENDENCIES
		, COMPRESSION
		, DROPPED
		)
AS
SELECT DISTINCT CAST(sys_GET_USERBYID(c.relowner) AS VARCHAR(63 BYTE))
        , CAST(relname AS VARCHAR(63 BYTE))
        , CAST((case c.reltablespace when 0 then 'database default tablespace'  else ts.spcname end) AS VARCHAR(63 BYTE))
        , CAST(NULL AS VARCHAR(63 BYTE))
        , CAST(NULL AS VARCHAR(63 BYTE))
        , CAST('valid' AS VARCHAR(63 BYTE))
        , 50
        , 50
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , CAST('yes' AS VARCHAR(3 BYTE))
        , CAST('N' AS VARCHAR(1 BYTE))
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , CAST('1' AS VARCHAR(10 BYTE))
        , CAST('1' AS VARCHAR(10 BYTE))
        , CAST('N' AS VARCHAR(5 BYTE))
        , CAST('ENABLED' AS VARCHAR(8 BYTE))
        , 0
        , CAST(NULL AS DATE)
        , CAST('yes' AS VARCHAR(3 BYTE))
		, CAST(NULL AS VARCHAR(12 BYTE))
		, CAST((CASE WHEN relpersistence = 't' THEN 'Y' ELSE 'N' END) AS VARCHAR(1 BYTE))
		, CAST('N' AS VARCHAR(1 BYTE))
		, CAST('no' AS VARCHAR(3 BYTE))
		, CAST('DEFAULT' AS VARCHAR(7 BYTE))
		, CAST('DISABLED' AS VARCHAR(8 BYTE))
        , CAST('yes' AS VARCHAR(3 BYTE))
        , CAST('yes' AS VARCHAR(3 BYTE))
        , CAST(
			(CASE WHEN relpersistence = 't' THEN
			  (CASE (array_to_string(c.reloptions, ', ') ilike '%oncommit=1%')
				WHEN true THEN 'SYS$SESSION'
				ELSE 'SYS$TRANSACTION'
				END)
			  ELSE ' '
			  END
			)AS VARCHAR(15 BYTE))
		, CAST('DISABLED' AS VARCHAR(8 BYTE))
        , CAST('yes' AS VARCHAR(3 BYTE))
        , CAST(NULL AS VARCHAR(63 BYTE))
		, CAST('DISABLED' AS VARCHAR(8 BYTE))
		, CAST('DISABLED' AS VARCHAR(8 BYTE))
		, CAST('no' AS VARCHAR(3 BYTE))
    FROM sys_class c left join sys_index i on c.oid = i.indrelid , sys_tablespace ts
	WHERE relkind = 'r'
		AND (c.reltablespace=ts.oid or c.reltablespace = 0)
		AND c.RELNAMESPACE != sys_my_temp_schema();


REVOKE ALL ON dba_tables FROM PUBLIC;

-- USER_TABLES describes all (partition) tables owned by the current user.
CREATE OR REPLACE VIEW user_tables
AS
	SELECT TABLE_NAME
		, TABLESPACE_NAME
		, CLUSTER_NAME
		, IOT_NAME
		, STATUS
		, PCT_FREE
		, PCT_USED
		, INI_TRANS
		, MAX_TRANS
		, INITIAL_EXTENT
		, NEXT_EXTENT
		, MIN_EXTENTS
		, MAX_EXTENTS
		, PCT_INCREASE
		, FREELISTS
		, FREELIST_GROUPS
		, LOGGING
		, BACKED_UP
		, NUM_ROWS
		, BLOCKS
		, EMPTY_BLOCKS
		, AVG_SPACE
		, CHAIN_CNT
		, AVG_ROW_LEN
		, AVG_SPACE_FREELIST_BLOCKS
		, NUM_FREELIST_BLOCKS
		, DEGREE
		, INSTANCES
		, CACHE
		, TABLE_LOCK
		, SAMPLE_SIZE
		, LAST_ANALYZED
		, PARTITIONED
		, IOT_TYPE
		, TEMPORARY
		, SECONDARY
		, NESTED
		, BUFFER_POOL
		, ROW_MOVEMENT
		, GLOBAL_STATS
		, USER_STATS
		, DURATION
		, SKIP_CORRUPT
		, MONITORING
		, CLUSTER_OWNER
		, DEPENDENCIES
		, COMPRESSION
		, DROPPED
    FROM dba_tables
        WHERE owner = CAST(current_user AS VARCHAR(63 BYTE))
;

-- ALL_TABLES describes all (partition) tables accessible to the current user.
CREATE OR REPLACE VIEW all_tables(OWNER
		, TABLE_NAME
		, TABLESPACE_NAME
		, CLUSTER_NAME
		, IOT_NAME
		, STATUS
		, PCT_FREE
		, PCT_USED
		, INI_TRANS
		, MAX_TRANS
		, INITIAL_EXTENT
		, NEXT_EXTENT
		, MIN_EXTENTS
		, MAX_EXTENTS
		, PCT_INCREASE
		, FREELISTS
		, FREELIST_GROUPS
		, LOGGING
		, BACKED_UP
		, NUM_ROWS
		, BLOCKS
		, EMPTY_BLOCKS
		, AVG_SPACE
		, CHAIN_CNT
		, AVG_ROW_LEN
		, AVG_SPACE_FREELIST_BLOCKS
		, NUM_FREELIST_BLOCKS
		, DEGREE
		, INSTANCES
		, CACHE
		, TABLE_LOCK
		, SAMPLE_SIZE
		, LAST_ANALYZED
		, PARTITIONED
		, IOT_TYPE
		, TEMPORARY
		, SECONDARY
		, NESTED
		, BUFFER_POOL
		, ROW_MOVEMENT
		, GLOBAL_STATS
		, USER_STATS
		, DURATION
		, SKIP_CORRUPT
		, MONITORING
		, CLUSTER_OWNER
		, DEPENDENCIES
		, COMPRESSION
		, DROPPED
		)
AS
SELECT DISTINCT CAST(sys_GET_USERBYID(c.relowner) AS VARCHAR(63 BYTE))
        , CAST(relname AS VARCHAR(63 BYTE))
        , CAST((case reltablespace when 0 then 'database default tablespace' else ts.spcname end) AS VARCHAR(63 BYTE))
        , CAST(NULL AS VARCHAR(63 BYTE))
        , CAST(NULL AS VARCHAR(63 BYTE))
        , CAST('valid' AS VARCHAR(63 BYTE))
        , 50
        , 50
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , CAST('yes' AS VARCHAR(3 BYTE))
        , CAST('N' AS VARCHAR(1 BYTE))
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , CAST('1' AS VARCHAR(10 BYTE))
        , CAST('1' AS VARCHAR(10 BYTE))
        , CAST('N' AS VARCHAR(5 BYTE))
        , CAST('ENABLED' AS VARCHAR(8 BYTE))
        , 0
        , CAST(NULL AS DATE)
        , CAST('yes' AS VARCHAR(3 BYTE))
		, CAST(NULL AS VARCHAR(12 BYTE))
		, CAST((CASE WHEN relpersistence = 't' THEN 'Y' ELSE 'N' END)AS VARCHAR(1 BYTE))
		, CAST('N' AS VARCHAR(1 BYTE))
		, CAST('no' AS VARCHAR(3 BYTE))
		, CAST('DEFAULT' AS VARCHAR(7 BYTE))
		, CAST('DISABLED' AS VARCHAR(8 BYTE))
        , CAST('yes' AS VARCHAR(3 BYTE))
        , CAST('yes' AS VARCHAR(3 BYTE))
        , CAST(
			(CASE WHEN relpersistence = 't' THEN
			  (CASE (array_to_string(c.reloptions, ', ') ilike '%oncommit=1%')
				WHEN true THEN 'SYS$SESSION'
				ELSE 'SYS$TRANSACTION'
				END)
			  ELSE ' '
			  END
			)AS VARCHAR(15 BYTE))
		, CAST('DISABLED' AS VARCHAR(8 BYTE))
        , CAST('yes' AS VARCHAR(3 BYTE))
        , CAST(NULL AS VARCHAR(63 BYTE))
		, CAST('DISABLED' AS VARCHAR(8 BYTE))
		, CAST('DISABLED' AS VARCHAR(8 BYTE))
		, CAST('no' AS VARCHAR(3 BYTE))
    FROM sys_class c left join sys_index i on c.oid = i.indrelid, sys_tablespace ts,
    sys_authid a
	WHERE relkind = 'r'
		AND (c.reltablespace=ts.oid or c.reltablespace = 0)
		AND c.RELNAMESPACE != sys_my_temp_schema()
		and ((c.relowner=a.oid and a.rolname=current_user )
			OR has_table_privilege(c.oid, 'SELECT')
			OR has_table_privilege(c.oid, 'INSERT')
			OR has_table_privilege(c.oid, 'UPDATE')
			OR has_table_privilege(c.oid, 'DELETE')
			OR has_table_privilege(c.oid, 'REFERENCES')
			OR has_table_privilege(c.oid, 'TRIGGER')
			OR has_table_privilege(c.oid, 'SELECT WITH GRANT OPTION')
      OR has_table_privilege(c.oid, 'INSERT WITH GRANT OPTION')
      OR has_table_privilege(c.oid, 'UPDATE WITH GRANT OPTION')
      OR has_table_privilege(c.oid, 'DELETE WITH GRANT OPTION')
      OR has_table_privilege(c.oid, 'REFERENCES WITH GRANT OPTION')
      OR has_table_privilege(c.oid, 'TRIGGER WITH GRANT OPTION')
      OR has_table_privilege(c.oid, 'TRUNCATE WITH GRANT OPTION')
      OR has_table_privilege(c.oid, 'RULE WITH GRANT OPTION')
      )
;

-- DBA_SYNONYMS describes all synonyms in the database.
CREATE OR REPLACE VIEW DBA_SYNONYMS(OWNER
		, SYNONYM_NAMESPACE_NAME
		, SYNONYM_NAME
		, TABLE_OWNER
		, TABLE_NAMESPACE_NAME
		, TABLE_NAME
		, DBLINK
		)
AS
SELECT DISTINCT CAST(sys_GET_USERBYID(syn.synowner) AS VARCHAR(63 BYTE))
        , CAST(nsp.nspname AS VARCHAR(63 BYTE))
        , CAST(synname AS VARCHAR(63 BYTE))
        , CAST(refobjnspname AS VARCHAR(63 BYTE))
        , CAST(refobjnspname AS VARCHAR(63 BYTE))
        , CAST(refobjname AS VARCHAR(63 BYTE))
        , NULL
    FROM sys_synonym syn left join sys_namespace nsp on syn.synnamespace = nsp.oid
	WHERE syn.synnamespace != sys_my_temp_schema();

-- USER_SYNONYMS describes all synonyms owned by the current user.
CREATE OR REPLACE VIEW USER_SYNONYMS(OWNER
		, SYNONYM_NAMESPACE_NAME
		, SYNONYM_NAME
		, TABLE_OWNER
		, TABLE_NAMESPACE_NAME
		, TABLE_NAME
		, DBLINK
		)
AS
SELECT OWNER
		, SYNONYM_NAMESPACE_NAME
		, SYNONYM_NAME
		, TABLE_OWNER
		, TABLE_NAMESPACE_NAME
		, TABLE_NAME
		, DBLINK
    FROM DBA_SYNONYMS
	WHERE owner = CAST(current_user AS VARCHAR(63 BYTE));

-- ALL_SYNONYMS describes all synonyms accessible to the current user.
CREATE OR REPLACE VIEW ALL_SYNONYMS(OWNER
		, SYNONYM_NAMESPACE_NAME
		, SYNONYM_NAME
		, TABLE_OWNER
		, TABLE_NAMESPACE_NAME
		, TABLE_NAME
		, DBLINK
		)
AS
SELECT OWNER
		, SYNONYM_NAMESPACE_NAME
		, SYNONYM_NAME
		, TABLE_OWNER
		, TABLE_NAMESPACE_NAME
		, TABLE_NAME
		, DBLINK
    FROM DBA_SYNONYMS;

-- DBA_USER describes all the user's information.
CREATE OR REPLACE VIEW dba_users(USERNAME
	, USER_ID
	, PASSWORD
	, ACCOUNT_STATUS
	, LOCK_DATE
	, EXPIRY_DATE
	, DEFAULT_TABLESPACE
	, TEMPORARY_TABLESPACE
	, CREATED
	, PROFILE
	, INITIAL_RSRC_CONSUMER_GROUP
	, EXTERNAL_NAME
	, PASSWORD_VERSIONS
	, EDITIONS_ENABLED
	)
AS
SELECT CAST(usename AS VARCHAR(63 BYTE))
	, CAST(CAST(usesysid AS VARCHAR(38 BYTE)) AS NUMERIC(38,0))
	, CAST(NULL AS VARCHAR(63 BYTE))
	, CAST(CASE WHEN CURRENT_TIMESTAMP <= case valuntil when null then CURRENT_TIMESTAMP end THEN 'open' ELSE 'expired' END AS VARCHAR(32 BYTE))
	, CAST(NULL AS DATE)
	, CAST(valuntil AS DATE)
	, CAST('SYSTEM' AS VARCHAR(63 BYTE))
	, CAST(NULL AS VARCHAR(63 BYTE))
	, CAST(NULL AS DATE)
	, CAST(NULL AS VARCHAR(63 BYTE))
	, CAST(NULL AS VARCHAR(63 BYTE))
	, CAST(NULL AS VARCHAR(4000 BYTE))
	, CAST(LEFT(SUBSTRING(version(), INSTR(version(), ' ') + 1, INSTR(version(), ' ', 1, 2) - INSTR(version(), ' ') - 1), 5) AS VARCHAR(8 BYTE))
	, CAST('N' as VARCHAR(1 BYTE))
	FROM sys_user;


-- DBA_COL_PRIVS describes all the user's or role's column privileges.
CREATE OR REPLACE VIEW dba_col_privs AS
    SELECT CAST(u_grantor.rolname AS character varying(63 BYTE)) AS grantor,
 		   CAST(u_owner.rolname AS character varying(63 BYTE)) AS owner,
		   CAST(grantee.rolname AS character varying(63 BYTE)) AS grantee,
           CAST(current_database() AS character varying(63 BYTE)) AS table_catalog,
           CAST(nc.nspname AS character varying(63 BYTE)) AS table_schema,
           CAST(c.relname AS character varying(63 BYTE)) AS table_name,
           CAST(a.attname AS character varying(63 BYTE)) AS column_name,
           CAST(pr.type AS character varying(40 char)) AS privilege_type,
           CAST(
             CASE WHEN aclcontains(a.attacl,
                                   makeaclitem(grantee.oid, u_grantor.oid, pr.type, true))
                  THEN 'YES' ELSE 'NO' END AS character varying(3 char)) AS is_grantable
    FROM sys_attribute a,
         sys_class c,
         sys_authid u_owner,
         sys_namespace nc,
         sys_authid u_grantor,
         ( SELECT oid, rolname FROM sys_authid
		   UNION ALL
		   SELECT 0::oid,'PUBLIC'
         ) AS grantee (oid, rolname),
         (SELECT 'SELECT' UNION ALL
          SELECT 'INSERT' UNION ALL
          SELECT 'UPDATE' UNION ALL
          SELECT 'REFERENCES') AS pr (type)
    WHERE a.attrelid = c.oid
		  AND c.relowner=u_owner.oid
          AND c.relkind IN ('r', 'v')
		  AND NOT a.attisdropped
		  AND aclcontains(a.attacl,
                          makeaclitem(grantee.oid, u_grantor.oid, pr.type, false))
          AND substr(nc.nspname,1,4)<>'sys_'
		  AND substr(nc.nspname,1,12)<>'INFORMATION_'
      AND c.relnamespace = nc.oid;


-- USER_COL_PRIVS describes the current user's column privileges.
CREATE VIEW USER_COL_PRIVS AS
	SELECT * FROM dba_col_privs
	WHERE grantor=cast(current_user as varchar(63 BYTE))
	      OR grantee=cast(current_user as varchar(63 BYTE))
		  OR owner=cast(current_user as varchar(63 BYTE));


-- ALL_COL_PRIVS describes the current user's and active role's(including PUBLIC) column privileges.
CREATE VIEW ALL_COL_PRIVS AS
	SELECT dba_col_privs.* FROM dba_col_privs
	WHERE grantee='PUBLIC'
          OR grantor=cast(current_user as varchar(63 BYTE))
	      OR grantee=cast(current_user as varchar(63 BYTE))
		  OR owner=cast(current_user as varchar(63 BYTE))
          OR grantee in (select cast(current_role as varchar(63 BYTE)));

REVOKE ALL ON dba_col_privs FROM PUBLIC;

CREATE VIEW sys_COL_PRIVS AS SELECT * FROM ALL_COL_PRIVS;

-- add ALL_CONSTRAINTS view
CREATE OR REPLACE  VIEW ALL_CONSTRAINTS AS
SELECT (sys_get_userbyid(c.relowner))::CHARACTER VARYING(63 BYTE) AS "OWNER" ,
(cs1.CONNAME)::CHARACTER VARYING(63 BYTE) AS CONSTRAINT_NAME,
(
   	CASE WHEN (cs1.CONTYPE = 'c'::"CHAR") THEN 'C'::TEXT
  	     WHEN (cs1.CONTYPE = 'p'::"CHAR") THEN 'P'::TEXT
         WHEN (cs1.CONTYPE = 'u'::"CHAR") THEN 'U'::TEXT
         WHEN (cs1.CONTYPE = 'f'::"CHAR") THEN 'R'::TEXT
         WHEN (cs1.CONTYPE = 't'::"CHAR") THEN 'T'::TEXT
         WHEN (cs1.CONTYPE = 'x'::"CHAR") THEN 'X'::TEXT
         ELSE NULL::TEXT
    END
)::CHARACTER VARYING(1 BYTE) AS CONSTRAINT_TYPE,
(C.RELNAME)::CHARACTER VARYING(63 BYTE) AS TABLE_NAME,
cs1.CONSRC AS SEARCH_CONDITION,
sys_GET_USERBYID(c_ref.RELOWNER)::CHARACTER VARYING(63 BYTE) AS R_OWNER,
(
	cs2.conname::CHARACTER VARYING(63 BYTE)
) AS R_CONSTRAINT_NAME,
  (
  	CASE WHEN (cs1.CONFDELTYPE = 'a'::"CHAR") THEN 'NO ACTION'::TEXT
      	WHEN (cs1.CONFDELTYPE = 'c'::"CHAR") THEN 'CASCADE'::TEXT
      	WHEN (cs1.CONFDELTYPE = 'r'::"CHAR") THEN 'RESTRICT'::TEXT
      	WHEN (cs1.CONFDELTYPE = 'n'::"CHAR") THEN 'SET NULL'::TEXT
      	WHEN (cs1.CONFDELTYPE = 'd'::"CHAR") THEN 'SET DEFAULT'::TEXT
      	ELSE NULL::TEXT END
  )::CHARACTER VARYING(9 BYTE) AS DELETE_RULE,
/* KingbaseES_BEGIN constraint status
  (
    CASE WHEN (cs1.CONTYPE = 'f'::"CHAR") THEN
    (
        SELECT DISTINCT (CASE WHEN (TRG.TGENABLED!='D') THEN 'ENABLED'::TEXT
                                ELSE 'DISABLED'::TEXT END )
        FROM sys_TRIGGER TRG
        WHERE  TRG.tgconstraint = cs1.oid
        AND TRG.TGRELID = cs1.CONRELID
    )
    ELSE 'ENABLED'::TEXT
	  END
)::CHARACTER VARYING(8 BYTE) AS "STATUS",
*/
(
  CASE WHEN (cs1.CONSTATUS ='t') THEN 'ENABLE'::TEXT
       WHEN (cs1.CONSTATUS ='f') THEN 'DISABLE'::TEXT
      ELSE NULL::TEXT END
)::CHARACTER VARYING(8 BYTE) AS "STATUS",
/* KingbaseES_END */
  (
     	CASE WHEN (cs1.CONDEFERRABLE = false) THEN 'NOT DEFERRABLE'::TEXT
     	ELSE 'DEFERRABLE'::TEXT END
   )::CHARACTER VARYING(14 CHAR) AS "DEFERRABLE",
  (
     	CASE WHEN (cs1.CONDEFERRED = false) THEN 'IMMEDIATE'::TEXT
     	ELSE 'DEFERRED'::TEXT END
  )::CHARACTER VARYING(9 CHAR) AS "DEFERRED",
(
  CASE WHEN (cs1.CONVALIDATED ='t') THEN 'VALIDATED'::TEXT
       WHEN (cs1.CONVALIDATED ='f') THEN 'NOVALIDATED'::TEXT
      ELSE NULL::TEXT END
)::CHARACTER VARYING(13 BYTE) AS "VALIDATED",
  'USER NAME'::CHARACTER VARYING(14 BYTE) AS GENERATED,
  NULL::CHARACTER VARYING(3 CHAR) AS BAD,
  NULL::CHARACTER VARYING(4 CHAR) AS RELY,
  NULL::TIMESTAMP(0) WITHOUT TIME ZONE AS LAST_CHANGE,
(
	CASE WHEN (cs1.CONTYPE = 'p' OR cs1.CONTYPE = 'u') THEN
		(
			SELECT sys_get_userbyid(t.relowner) FROM sys_INDEX IND, sys_CLASS T, sys_DEPEND DEP
			WHERE INDEXRELID = DEP.OBJID
			AND DEP.REFOBJID = cs1.OID
			AND T.OID = IND.INDEXRELID
		)
	ELSE
		NULL
	END
 )::CHARACTER VARYING(63 BYTE) AS "INDEX_OWNER",
 (
	CASE WHEN (cs1.CONTYPE = 'p' OR cs1.CONTYPE = 'u') THEN
		(
			SELECT T.RELNAME FROM sys_INDEX IND ,sys_CLASS T,sys_DEPEND DEP
			WHERE INDEXRELID = DEP.OBJID
			AND DEP.REFOBJID = cs1.OID
			AND T.OID = IND.INDEXRELID
		)
	ELSE
		NULL
	END
 )::CHARACTER VARYING(63 BYTE) AS "INDEX_NAME",
 NULL::CHARACTER VARYING(7 BYTE) AS INVALID,
  NULL::CHARACTER VARYING(14 BYTE) AS VIEW_RELATED
 from ( sys_constraint cs1 left outer join sys_constraint cs2 on
		(
			cs1.confrelid = cs2.conrelid and
			(cs2.contype = 'u' or cs2.contype = 'p') and
			cs1.contype = 'f' and
			cs2.conkey = cs1.confkey
		)
	)
	left outer join sys_class c_ref on cs1.confrelid = c_ref.oid,
	sys_class c
 WHERE cs1.CONRELID = C.OID
  AND (HAS_TABLE_PRIVILEGE(C.OID,'SELECT') = TRUE
	OR has_table_privilege(c.oid, 'INSERT') = TRUE
	OR has_table_privilege(c.oid, 'UPDATE') = TRUE
	OR has_table_privilege(c.oid, 'DELETE') = TRUE
	OR has_table_privilege(c.oid, 'REFERENCES') = TRUE
	OR has_table_privilege(c.oid, 'TRIGGER'));


CREATE OR REPLACE VIEW USER_CONSTRAINTS AS
SELECT * FROM ALL_CONSTRAINTS
WHERE "OWNER" = (SELECT cast(CURRENT_USER as varchar2(63 BYTE)));



CREATE OR REPLACE  VIEW DBA_TAB_COLS AS
SELECT
U.USENAME ::CHARACTER VARYING(63 BYTE) AS "OWNER",
C.RELNAME ::CHARACTER VARYING(63 BYTE) AS TABLE_NAME,
ATTR.ATTNAME ::CHARACTER VARYING(63 BYTE) AS COLUMN_NAME,
(
  CASE T.TYPNAME
    WHEN 'BPCHAR' THEN 'CHAR'
  ELSE
    T.TYPNAME
  END
)::CHARACTER VARYING(106 BYTE) AS DATA_TYPE,
NULL ::CHARACTER VARYING(3 CHAR) AS DATA_TYPE_MOD,
AU.ROLNAME ::CHARACTER VARYING(63 BYTE) AS DATA_TYPE_OWNER,
(
	CASE WHEN ATTR.ATTLEN = -1 THEN
	(
		CASE T.TYPNAME WHEN 'BIT' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'BIT VARYING' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'TIMETZ' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'TIME' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'TIMESTAMPTZ' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'TIMESTAMP' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'INTERVAL' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'VARBIT' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
			WHEN 'VARCHAR' THEN (CASE ATTR.ATTTYPMOD WHEN -1 THEN NULL ELSE ABS(ATTR.ATTTYPMOD) - 4 END)
			WHEN 'BPCHAR' THEN (CASE ATTR.ATTTYPMOD WHEN -1 THEN NULL ELSE ABS(ATTR.ATTTYPMOD) - 4 END)
  			ELSE (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)-4) ELSE 0 END)
		END
	)
  	ELSE
		ATTR.ATTLEN
  	END
  )::number AS DATA_LENGTH,
(
	CASE T.TYPNAME
		WHEN 'NUMERIC' THEN
    (
      CASE WHEN ATTR.ATTTYPMOD = -1 THEN 38
      ELSE ((ATTR.ATTTYPMOD - 4) >> 16) & 65535
      END
    )
		WHEN 'FLOAT4' THEN 7
		WHEN 'FLOAT8' THEN 15
	ELSE
		NULL
	END
)::number AS DATA_PRECISION,
(
	CASE T.TYPNAME
		WHEN 'NUMERIC' THEN (ATTR.ATTTYPMOD - 4) & 65535
	ELSE
		NULL
	END
)::number AS DATA_SCALE,
(
	case ATTR.ATTNOTNULL when true then 'N' else 'Y' end
) ::CHARACTER VARYING(1 CHAR) AS NULLABLE,
ATTR.ATTNUM ::number AS COLUMN_ID,
(
	CASE ATTR.ATTHASDEF WHEN FALSE THEN NULL
	ELSE DATA_LENGTH
	END
) ::number AS DEFAULT_LENGTH,
DEF.ADSRC::TEXT AS DATA_DEFAULT,
0 ::number AS NUM_DISTINCT,
0 ::number AS LOW_VALUE,
0 ::number AS HIGH_VALUE,
0 ::number AS DENSITY,
0 ::number AS NUM_NULLS,
0 ::number AS NUM_BUCKETS,
NULL::TIMESTAMP(0) WITHOUT TIME ZONE AS LAST_ANALYZED,
0 ::number AS SAMPLE_SIZE,
NULL ::CHARACTER VARYING(44 CHAR) AS CHARACTER_SET_NAME,
0 ::number AS CHAR_COL_DECL_LENGTH,
'NO' ::CHARACTER VARYING(3 CHAR) AS GLOBAL_STATS,
'NO' ::CHARACTER VARYING(3 CHAR) AS USER_STATS,
0 ::number AS AVG_COL_LEN,
(
	CASE T.TYPNAME IN('VARCHAR', 'BPCHAR', 'NCHAR', 'NVARCHAR') WHEN TRUE THEN DATA_LENGTH
	ELSE 0
	END
) :: number AS CHAR_LENGTH,
(
	CASE T.TYPNAME IN ('VARCHAR', 'BPCHAR', 'NCHAR', 'NVARCHAR') AND ATTR.ATTTYPMOD <> -1 WHEN TRUE THEN
	(
		CASE ATTR.ATTTYPMOD >> 16 WHEN 0 THEN 'C'
		ELSE 'B'
		END
	)
	ELSE
		NULL
	END
) ::CHARACTER VARYING(1 CHAR) AS CHAR_USED,
'NO' ::CHARACTER VARYING(3 CHAR) AS V80_FMT_IMAGE,
'NO' ::CHARACTER VARYING(3 CHAR) AS DATA_UPGRADED,
'NO' ::CHARACTER VARYING(3 CHAR) AS HIDDEN_COLUMN,
'NO' ::CHARACTER VARYING(3 CHAR) AS VIRTUAL_COLUMN,
0 ::number AS SEGMENT_COLUMN_ID,
ATTR.ATTNUM ::number AS INTERNAL_COLUMN_ID,
NULL ::CHARACTER VARYING(15 CHAR) AS HISTOGRAM,
NULL ::CHARACTER VARYING(4000 CHAR) AS QUALIFIED_COL_NAME
FROM sys_USER U,sys_CLASS C,sys_TYPE T,sys_AUTHID AU,sys_ATTRIBUTE ATTR left join sys_ATTRDEF DEF
 on (ATTR.ATTNUM = DEF.ADNUM AND ATTR.ATTRELID = DEF.ADRELID)
WHERE C.RELOWNER = U.USESYSID
AND ATTR.ATTNUM > 0
AND ATTR.ATTTYPID = T.OID
AND ATTR.ATTRELID = C.OID
AND T.TYPOWNER = AU.OID;


REVOKE ALL ON DBA_TAB_COLS FROM PUBLIC;



CREATE OR REPLACE  VIEW ALL_TAB_COLS AS
SELECT
U.USENAME ::CHARACTER VARYING(63 BYTE) AS "OWNER",
C.RELNAME ::CHARACTER VARYING(63 BYTE) AS TABLE_NAME,
ATTR.ATTNAME ::CHARACTER VARYING(63 BYTE) AS COLUMN_NAME,
(
  CASE T.TYPNAME
    WHEN 'BPCHAR' THEN 'CHAR'
  ELSE
    T.TYPNAME
  END
)::CHARACTER VARYING(106 BYTE) AS DATA_TYPE,
NULL ::CHARACTER VARYING(3 CHAR) AS DATA_TYPE_MOD,
AU.ROLNAME ::CHARACTER VARYING(63 BYTE) AS DATA_TYPE_OWNER,
(
	CASE WHEN ATTR.ATTLEN = -1 THEN
	(
		CASE T.TYPNAME WHEN 'BIT' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'BIT VARYING' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'TIMETZ' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'TIME' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'TIMESTAMPTZ' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'TIMESTAMP' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'INTERVAL' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'VARBIT' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
			WHEN 'VARCHAR' THEN (CASE ATTR.ATTTYPMOD WHEN -1 THEN NULL ELSE ABS(ATTR.ATTTYPMOD) - 4 END)
			WHEN 'BPCHAR' THEN (CASE ATTR.ATTTYPMOD WHEN -1 THEN NULL ELSE ABS(ATTR.ATTTYPMOD) - 4 END)
  			ELSE (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)-4) ELSE 0 END)
		END
	)
  	ELSE
		ATTR.ATTLEN
  	END
  )::number AS DATA_LENGTH,
(
	CASE DATA_TYPE
		WHEN 'NUMERIC' THEN
    (
      CASE WHEN ATTR.ATTTYPMOD = -1 THEN 38
      ELSE ((ATTR.ATTTYPMOD - 4) >> 16) & 65535
      END
    )
		WHEN 'FLOAT4' THEN 7
		WHEN 'FLOAT8' THEN 15
	ELSE
		NULL
	END
)::number AS DATA_PRECISION,
(
	CASE DATA_TYPE
		WHEN 'NUMERIC' THEN (ATTR.ATTTYPMOD - 4) & 65535
	ELSE
		NULL
	END
)::number AS DATA_SCALE,
(
	case ATTR.ATTNOTNULL when true then 'N' else 'Y' end
) ::CHARACTER VARYING(1 CHAR) AS NULLABLE,
ATTR.ATTNUM ::number AS COLUMN_ID,
(
	CASE ATTR.ATTHASDEF WHEN FALSE THEN NULL
	ELSE DATA_LENGTH
	END
) ::number AS DEFAULT_LENGTH,
DEF.ADSRC::TEXT AS DATA_DEFAULT,
0 ::number AS NUM_DISTINCT,
0 ::number AS LOW_VALUE,
0 ::number AS HIGH_VALUE,
0 ::number AS DENSITY,
0 ::number AS NUM_NULLS,
0 ::number AS NUM_BUCKETS,
NULL::TIMESTAMP(0) WITHOUT TIME ZONE AS LAST_ANALYZED,
0 ::number AS SAMPLE_SIZE,
NULL ::CHARACTER VARYING(44 CHAR) AS CHARACTER_SET_NAME,
0 ::number AS CHAR_COL_DECL_LENGTH,
'NO' ::CHARACTER VARYING(3 CHAR) AS GLOBAL_STATS,
'NO' ::CHARACTER VARYING(3 CHAR) AS USER_STATS,
0 ::number AS AVG_COL_LEN,
(
	CASE DATA_TYPE IN('VARCHAR', 'BPCHAR', 'NCHAR', 'NVARCHAR') WHEN TRUE THEN DATA_LENGTH
	ELSE 0
	END
) :: number AS CHAR_LENGTH,
(
	CASE DATA_TYPE IN ('VARCHAR', 'BPCHAR', 'NCHAR', 'NVARCHAR') AND ATTR.ATTTYPMOD <> -1 WHEN TRUE THEN
	(
		CASE ATTR.ATTTYPMOD >> 16 WHEN 0 THEN 'C'
		ELSE 'B'
		END
	)
	ELSE
		NULL
	END
) ::CHARACTER VARYING(1 CHAR) AS CHAR_USED,
'NO' ::CHARACTER VARYING(3 CHAR) AS V80_FMT_IMAGE,
'NO' ::CHARACTER VARYING(3 CHAR) AS DATA_UPGRADED,
'NO' ::CHARACTER VARYING(3 CHAR) AS HIDDEN_COLUMN,
'NO' ::CHARACTER VARYING(3 CHAR) AS VIRTUAL_COLUMN,
0 ::number AS SEGMENT_COLUMN_ID,
ATTR.ATTNUM ::number AS INTERNAL_COLUMN_ID,
NULL ::CHARACTER VARYING(15 CHAR) AS HISTOGRAM,
NULL ::CHARACTER VARYING(4000 CHAR) AS QUALIFIED_COL_NAME
 FROM sys_USER U,sys_CLASS C,sys_TYPE T,sys_AUTHID AU, sys_ATTRIBUTE ATTR left outer join sys_ATTRDEF DEF on (attr.attnum = def.adnum and attr.attrelid = def.adrelid)
 WHERE C.RELOWNER = U.USESYSID
AND ATTR.ATTNUM > 0
AND ATTR.ATTTYPID = T.OID
AND ATTR.ATTRELID = C.OID
AND T.TYPOWNER = AU.OID
AND (HAS_TABLE_PRIVILEGE(C.OID,'SELECT') = TRUE
OR has_table_privilege(c.oid, 'INSERT') = TRUE
OR has_table_privilege(c.oid, 'UPDATE') = TRUE
OR has_table_privilege(c.oid, 'DELETE') = TRUE
OR has_table_privilege(c.oid, 'REFERENCES') = TRUE
OR has_table_privilege(c.oid, 'TRIGGER'));




CREATE OR REPLACE  VIEW USER_TAB_COLS AS
SELECT
C.RELNAME ::CHARACTER VARYING(63 BYTE) AS TABLE_NAME,
ATTR.ATTNAME ::CHARACTER VARYING(63 BYTE) AS COLUMN_NAME,
(
  CASE T.TYPNAME
    WHEN 'BPCHAR' THEN 'CHAR'
  ELSE
    T.TYPNAME
  END
)::CHARACTER VARYING(106 BYTE) AS DATA_TYPE,
NULL ::CHARACTER VARYING(3 CHAR) AS DATA_TYPE_MOD,
AU.ROLNAME ::CHARACTER VARYING(63 BYTE) AS DATA_TYPE_OWNER,
(
	CASE WHEN ATTR.ATTLEN = -1 THEN
	(
		CASE T.TYPNAME WHEN 'BIT' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'BIT VARYING' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'TIMETZ' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'TIME' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'TIMESTAMPTZ' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'TIMESTAMP' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'INTERVAL' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
  			WHEN 'VARBIT' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
			WHEN 'VARCHAR' THEN (CASE ATTR.ATTTYPMOD WHEN -1 THEN NULL ELSE ABS(ATTR.ATTTYPMOD) - 4 END)
			WHEN 'BPCHAR' THEN (CASE ATTR.ATTTYPMOD WHEN -1 THEN NULL ELSE ABS(ATTR.ATTTYPMOD) - 4 END)
			ELSE (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)-4) ELSE 0 END)
		END
	)
  	ELSE
		ATTR.ATTLEN
  	END
  )::number AS DATA_LENGTH,
(
	CASE DATA_TYPE
		WHEN 'NUMERIC' THEN
    (
      CASE WHEN ATTR.ATTTYPMOD = -1 THEN 38
      ELSE ((ATTR.ATTTYPMOD - 4) >> 16) & 65535
      END
    )
		WHEN 'FLOAT4' THEN 7
		WHEN 'FLOAT8' THEN 15
	ELSE
		NULL
	END
)::number AS DATA_PRECISION,
(
	CASE DATA_TYPE
		WHEN 'NUMERIC' THEN (ATTR.ATTTYPMOD - 4) & 65535
	ELSE
		NULL
	END
)::number AS DATA_SCALE,
(
	case ATTR.ATTNOTNULL when true then 'N' else 'Y' end
) ::CHARACTER VARYING(1 CHAR) AS NULLABLE,
ATTR.ATTNUM ::number AS COLUMN_ID,
(
	CASE ATTR.ATTHASDEF WHEN FALSE THEN NULL
	ELSE DATA_LENGTH
	END
) ::number AS DEFAULT_LENGTH,
DEF.ADSRC::TEXT AS DATA_DEFAULT,
0 ::number AS NUM_DISTINCT,
0 ::number AS LOW_VALUE,
0 ::number AS HIGH_VALUE,
0 ::number AS DENSITY,
0 ::number AS NUM_NULLS,
0 ::number AS NUM_BUCKETS,
NULL::TIMESTAMP(0) WITHOUT TIME ZONE AS LAST_ANALYZED,
0 ::number AS SAMPLE_SIZE,
NULL ::CHARACTER VARYING(44 CHAR) AS CHARACTER_SET_NAME,
0 ::number AS CHAR_COL_DECL_LENGTH,
'NO' ::CHARACTER VARYING(3 CHAR) AS GLOBAL_STATS,
'NO' ::CHARACTER VARYING(3 CHAR) AS USER_STATS,
0 ::number AS AVG_COL_LEN,
(
	CASE DATA_TYPE IN('VARCHAR', 'BPCHAR', 'NCHAR', 'NVARCHAR') WHEN TRUE THEN DATA_LENGTH
	ELSE 0
	END
) :: number AS CHAR_LENGTH,
(
	CASE DATA_TYPE IN ('VARCHAR', 'BPCHAR', 'NCHAR', 'NVARCHAR') AND ATTR.ATTTYPMOD <> -1 WHEN TRUE THEN
	(
		CASE ATTR.ATTTYPMOD >> 16 WHEN 0 THEN 'C'
		ELSE 'B'
		END
	)
	ELSE
		NULL
	END
) ::CHARACTER VARYING(1 CHAR) AS CHAR_USED,
'NO' ::CHARACTER VARYING(3 CHAR) AS V80_FMT_IMAGE,
'NO' ::CHARACTER VARYING(3 CHAR) AS DATA_UPGRADED,
'NO' ::CHARACTER VARYING(3 CHAR) AS HIDDEN_COLUMN,
'NO' ::CHARACTER VARYING(3 CHAR) AS VIRTUAL_COLUMN,
0 ::number AS SEGMENT_COLUMN_ID,
ATTR.ATTNUM ::number AS INTERNAL_COLUMN_ID,
NULL ::CHARACTER VARYING(15 CHAR) AS HISTOGRAM,
NULL ::CHARACTER VARYING(4000 CHAR) AS QUALIFIED_COL_NAME
FROM sys_CLASS C, sys_TYPE T,sys_AUTHID AU, sys_ATTRIBUTE ATTR left join sys_ATTRDEF DEF
 on (ATTR.ATTRELID = DEF.ADRELID and ATTR.ATTNUM = DEF.ADNUM)
WHERE C.RELOWNER = UID
AND ATTR.ATTNUM > 0
AND ATTR.ATTTYPID = T.OID
AND ATTR.ATTRELID = C.OID
AND T.TYPOWNER = AU.OID;



-- with the table oid, colnum, get the uniques constraint text of the column
CREATE OR REPLACE FUNCTION get_col_uniques(taboid OID, colnum INT)
RETURNS TEXT
AS
DECLARE
	uniques_text TEXT;
	unique_record RECORD;
	col_number INT;
BEGIN
	uniques_text := NULL;
	col_number := 0;
	FOR unique_record IN SELECT CONNAME, CONKEY FROM sys_CONSTRAINT CONSTR
		WHERE taboid = CONSTR.CONRELID AND CONSTR.CONTYPE = 'u' AND colnum = any(CONSTR.CONKEY)
	LOOP
		IF uniques_text IS NOT NULL THEN
			uniques_text := CONCAT(uniques_text, ', ');
		ELSE
			uniques_text := '';
		END IF;
		uniques_text := CONCAT(uniques_text, unique_record.CONNAME);
		uniques_text := CONCAT(uniques_text, '(');
		FOR col_number in 1..array_length(unique_record.CONKEY, 1)
		LOOP
			IF col_number > 1 THEN
				uniques_text := CONCAT(uniques_text, ', ');
			END IF;
			uniques_text := CONCAT(uniques_text, unique_record.CONKEY[col_number]);
		END LOOP;
		uniques_text := CONCAT(uniques_text, ')');
	END LOOP;
	RETURN uniques_text;
END;

-- with the table oid, colnum, get the primary key constraint text of the column
CREATE OR REPLACE FUNCTION get_col_primary(taboid OID, colnum INT)
RETURNS TEXT
AS
DECLARE
	primary_text TEXT;
	con_key_id INT;
	con_key_row RECORD;
BEGIN
	primary_text := NULL;
	FOR con_key_row IN SELECT CONNAME, CONKEY FROM sys_CONSTRAINT CONSTR
	WHERE taboid = CONSTR.CONRELID AND CONSTR.CONTYPE = 'p' AND colnum = any(CONSTR.CONKEY)
	LOOP
		IF con_key_row.CONNAME IS NOT NULL THEN
			primary_text := CONCAT(con_key_row.CONNAME, '(');
			FOR con_key_id in 1..array_length(con_key_row.CONKEY, 1)
			LOOP
				IF con_key_id > 1 THEN
					primary_text := CONCAT(primary_text, ', ');
				END IF;
				primary_text := CONCAT(primary_text, con_key_row.CONKEY[con_key_id]);
			END LOOP;
			primary_text := CONCAT(primary_text, ')');
		END IF;
	END LOOP;
	RETURN primary_text;
END;

-- with the table oid ,colnum, get the checks constraint text of the column
CREATE OR REPLACE FUNCTION get_col_checks(taboid OID, colnum INT)
RETURNS TEXT
AS
DECLARE
	checks_text TEXT;
	check_record RECORD;
BEGIN
	checks_text := NULL;
	FOR check_record IN SELECT CONSRC FROM sys_CONSTRAINT CONSTR
		WHERE taboid = CONSTR.CONRELID AND CONSTR.CONTYPE = 'c' AND colnum = any(CONSTR.CONKEY)
	LOOP
		IF checks_text IS NOT NULL THEN
			checks_text := CONCAT(checks_text, ', ');
		ELSE
			checks_text := '';
		END IF;
		checks_text := CONCAT(checks_text, check_record.CONSRC);
	END LOOP;
	RETURN checks_text;
END;

-- with the table oid ,colnum ,get the foreigns constraint text of the column
CREATE OR REPLACE FUNCTION get_col_foreigns(taboid OID, colnum INT)
RETURNS TEXT
AS
DECLARE
	foreigns_text TEXT;
	foreign_record record;
	temp_table_oid OID;
BEGIN
	foreigns_text := NULL;
	temp_table_oid := NULL;
	FOR foreign_record IN SELECT CONSTR.CONFRELID tableoid, CLASS.RELNAME tablename, ATTR.ATTNAME colname
		FROM sys_CONSTRAINT CONSTR, sys_CLASS CLASS, sys_ATTRIBUTE ATTR
		WHERE taboid = CONSTR.CONRELID AND CONSTR.CONFRELID = CLASS.OID AND colnum = any(CONSTR.CONKEY) AND CONSTR.CONTYPE = 'f'
		AND ATTR.ATTRELID = CONSTR.CONFRELID AND ATTR.ATTNUM = any(CONSTR.confkey) ORDER BY tableoid
	LOOP -- get tables and foreign constraints information
		IF temp_table_oid = foreign_record.tableoid THEN
			foreigns_text := CONCAT(foreigns_text, ',');
			foreigns_text := CONCAT(foreigns_text, foreign_record.colname);
		ELSE
			IF foreigns_text IS NOT NULL THEN
				foreigns_text := CONCAT(foreigns_text, ')');
				foreigns_text := CONCAT(foreigns_text, ', ');
			ELSE
				foreigns_text := '';
			END IF;
			foreigns_text := CONCAT(foreigns_text, foreign_record.tablename);
			foreigns_text := CONCAT(foreigns_text, '(');
			foreigns_text := CONCAT(foreigns_text, foreign_record.colname);
			temp_table_oid := foreign_record.tableoid;
		END IF;
	END LOOP;
	IF foreigns_text IS NOT NULL THEN
		foreigns_text := CONCAT(foreigns_text, ')');
	END IF;
	RETURN foreigns_text;
END;

-- with the table oid ,colnum, get the indexs text of the column
CREATE OR REPLACE FUNCTION get_col_indexs(taboid OID, colnum INT)
RETURNS TEXT
AS
DECLARE
	indexs_text TEXT;
	index_record record;
	temp_index_oid OID;
BEGIN
	indexs_text := NULL;
	temp_index_oid := NULL;
	FOR index_record IN SELECT CLASS.RELNAME indexname, ATTR.ATTNAME colname, INDEX.INDEXRELID indexoid
		FROM sys_INDEX INDEX, sys_CLASS CLASS, sys_ATTRIBUTE ATTR
		WHERE taboid = INDEX.INDRELID AND colnum = any(INDEX.INDKEY) AND INDEX.INDEXRELID = CLASS.OID
		AND ATTR.ATTRELID = INDEX.INDRELID AND ATTR.ATTNUM = any(INDEX.INDKEY) ORDER BY indexoid
	LOOP
		IF temp_index_oid = index_record.indexoid THEN
			indexs_text := CONCAT(indexs_text, ', ');
			indexs_text := CONCAT(indexs_text, index_record.colname);
		ELSE
			IF  indexs_text IS NOT NULL THEN
				indexs_text := CONCAT(indexs_text, ')');
				indexs_text := CONCAT(indexs_text, ', ');
			ELSE
				indexs_text := '';
			END IF;
			indexs_text := CONCAT(indexs_text, index_record.indexname);
			indexs_text := CONCAT(indexs_text, '(');
			indexs_text := CONCAT(indexs_text, index_record.colname);
			temp_index_oid := index_record.indexoid;
		END IF;
	END LOOP;
	IF indexs_text IS NOT NULL  THEN
		indexs_text := CONCAT(indexs_text, ')');
	END IF;
	RETURN indexs_text;
END;

-- Add view user_table_cols similar to user_tab_columns view, can querry to all the information about column
CREATE OR REPLACE  VIEW USER_TABLE_COLS AS
SELECT
(
    SELECT NSPNAME FROM sys_NAMESPACE
    WHERE sys_NAMESPACE.OID = C.RELNAMESPACE
) ::CHARACTER VARYING(63 BYTE) AS NSPNAME,
C.RELNAME ::CHARACTER VARYING(63 BYTE) AS TABLE_NAME,
ATTR.ATTNAME ::CHARACTER VARYING(63 BYTE) AS COLUMN_NAME,
(
  CASE T.TYPNAME
    WHEN 'BPCHAR' THEN 'CHAR'
  ELSE
    T.TYPNAME
  END
)::CHARACTER VARYING(106 BYTE) AS DATA_TYPE,
NULL ::CHARACTER VARYING(3 CHAR) AS DATA_TYPE_MOD,
AU.ROLNAME ::CHARACTER VARYING(63 BYTE) AS DATA_TYPE_OWNER,
(
    CASE WHEN ATTR.ATTLEN = -1 THEN
    (
        CASE T.TYPNAME WHEN 'BIT' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
            WHEN 'BIT VARYING' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
            WHEN 'TIMETZ' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
            WHEN 'TIME' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
            WHEN 'TIMESTAMPTZ' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
            WHEN 'TIMESTAMP' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
            WHEN 'INTERVAL' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
            WHEN 'VARBIT' THEN (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)) ELSE 0 END)
            WHEN 'VARCHAR' THEN (CASE ATTR.ATTTYPMOD WHEN -1 THEN NULL ELSE ABS(ATTR.ATTTYPMOD) - 4 END)
            WHEN 'BPCHAR' THEN (CASE ATTR.ATTTYPMOD WHEN -1 THEN NULL ELSE ABS(ATTR.ATTTYPMOD) - 4 END)
            ELSE (CASE(ATTR.ATTTYPMOD >> 16) WHEN 0 THEN (ATTR.ATTTYPMOD - ((ATTR.ATTTYPMOD >> 16) <<16)-4) ELSE 0 END)
        END
    )
    ELSE
        ATTR.ATTLEN
END
  )::number AS DATA_LENGTH,
(
    CASE DATA_TYPE
        WHEN 'NUMERIC' THEN
    (
      CASE WHEN ATTR.ATTTYPMOD = -1 THEN 38
      ELSE ((ATTR.ATTTYPMOD - 4) >> 16) & 65535
      END
    )
        WHEN 'FLOAT4' THEN 7
        WHEN 'FLOAT8' THEN 15
    ELSE
        NULL
    END
)::number AS DATA_PRECISION,
(
    CASE DATA_TYPE
        WHEN 'NUMERIC' THEN (ATTR.ATTTYPMOD - 4) & 65535
    ELSE
        NULL
    END
)::number AS DATA_SCALE,
(
    case ATTR.ATTNOTNULL when true then 'N' else 'Y' end
) ::CHARACTER VARYING(1 CHAR) AS NULLABLE,
ATTR.ATTNUM ::number AS COLUMN_ID,
(
    CASE ATTR.ATTHASDEF WHEN FALSE THEN NULL
    ELSE DATA_LENGTH
    END
) ::number AS DEFAULT_LENGTH,
DEF.ADSRC::TEXT AS DATA_DEFAULT,
0 ::number AS NUM_DISTINCT,
0 ::number AS LOW_VALUE,
0 ::number AS HIGH_VALUE,
0 ::number AS DENSITY,
0 ::number AS NUM_NULLS,
0 ::number AS NUM_BUCKETS,
NULL::TIMESTAMP(0) WITHOUT TIME ZONE AS LAST_ANALYZED,
0 ::number AS SAMPLE_SIZE,
NULL ::CHARACTER VARYING(44 CHAR) AS CHARACTER_SET_NAME,
0 ::number AS CHAR_COL_DECL_LENGTH,
'NO' ::CHARACTER VARYING(3 CHAR) AS GLOBAL_STATS,
'NO' ::CHARACTER VARYING(3 CHAR) AS USER_STATS,
0 ::number AS AVG_COL_LEN,
(
    CASE DATA_TYPE IN('VARCHAR', 'BPCHAR', 'NCHAR', 'NVARCHAR') WHEN TRUE THEN DATA_LENGTH
    ELSE 0
    END
) :: number AS CHAR_LENGTH,
(
    CASE DATA_TYPE IN ('VARCHAR', 'BPCHAR', 'NCHAR', 'NVARCHAR') AND ATTR.ATTTYPMOD <> -1 WHEN TRUE THEN
    (
        CASE ATTR.ATTTYPMOD >> 16 WHEN 0 THEN 'C'
        ELSE 'B'
        END
    )
    ELSE
        NULL
    END
) ::CHARACTER VARYING(1 CHAR) AS CHAR_USED,
'NO' ::CHARACTER VARYING(3 CHAR) AS V80_FMT_IMAGE,
'NO' ::CHARACTER VARYING(3 CHAR) AS DATA_UPGRADED,
'NO' ::CHARACTER VARYING(3 CHAR) AS HIDDEN_COLUMN,
'NO' ::CHARACTER VARYING(3 CHAR) AS VIRTUAL_COLUMN,
0 ::number AS SEGMENT_COLUMN_ID,
ATTR.ATTNUM ::number AS INTERNAL_COLUMN_ID,
NULL ::CHARACTER VARYING(15 CHAR) AS HISTOGRAM,
NULL ::CHARACTER VARYING(4000 CHAR) AS QUALIFIED_COL_NAME,
'f'::BOOLEAN AS  ISENCRYPTED,
'n' ::CHARACTER VARYING(1 CHAR) AS COMPMETHOD,
ATTR.ATTSTORAGE ::CHARACTER VARYING(1 CHAR) AS STORAGE,
null ::CHARACTER VARYING(63 BYTE)   AS IDENTITY_NAME,
get_col_checks(ATTR.ATTRELID, ATTR.ATTNUM)::TEXT AS CHECKS,
get_col_foreigns(ATTR.ATTRELID, ATTR.ATTNUM)::TEXT AS FOREIGNS,
get_col_primary(ATTR.ATTRELID, ATTR.ATTNUM) ::TEXT AS PRIMARY_KEY,
get_col_uniques(ATTR.ATTRELID, ATTR.ATTNUM)::TEXT AS UNIQUES,
(
	array_cat(ATTR.ATTACL,C.RELACL)
)::ACLITEM[] AS GRANTS,
get_col_indexs(C.OID, ATTR.ATTNUM)::TEXT AS INDEXS,
null ::CHARACTER VARYING(63 BYTE) AS PARTITIONTYPE,
null ::TEXT AS PARTITIONKEY
FROM sys_CLASS C, sys_TYPE T, sys_AUTHID AU, sys_ATTRIBUTE ATTR left join sys_ATTRDEF DEF
 on (ATTR.ATTNUM = DEF.ADNUM AND ATTR.ATTRELID = DEF.ADRELID)
WHERE C.RELOWNER = UID
AND ATTR.ATTNUM > 0
AND ATTR.ATTTYPID = T.OID
AND ATTR.ATTRELID = C.OID
AND T.TYPOWNER = AU.OID;

REVOKE ALL ON USER_TABLE_COLS from PUBLIC;
GRANT select on USER_TABLE_COLS to PUBLIC;

/* null means user has no privilege,then will check "* ANY TABLE" privilege exists or not.
 * true means user has the privilege.
 * false means user has no privilege.
 */
create or replace function sys_has_any_table_priv(id oid default uid, priv text default null) returns boolean as
declare
	rolspr char(10);
begin
	select usesuper into rolspr from sys_user where usesysid = id;
	
	if rolspr in ('true', 'D', 't') then --"D" means DBA,equals ture.t is short for true.
		return true;
	end if;
	
	if upper(priv) not in('SELECT ANY TABLE', 'INSERT ANY TABLE', 'UPDATE ANY TABLE', 'DELETE ANY TABLE', 'LOCK ANY TABLE') then
		raise 'invalid PRIV value : %, must be one of ''SELECT ANY TABLE'', ''INSERT ANY TABLE'', ''UPDATE ANY TABLE'', ''DELETE ANY TABLE'', ''LOCK ANY TABLE''', priv;
	end if;
	
	if priv is null or length(priv) = 0 then
		if exists(
			select null from sys_sysauth where GRANTEE = id and privilege in (select PRIVILEGE from sys_sysauth_map where upper(name) in ('SELECT ANY TABLE', 'INSERT ANY TABLE', 'UPDATE ANY TABLE', 'DELETE ANY TABLE', 'LOCK ANY TABLE'))) then
			return true;
		end if;
	else
		if exists(
			select null from sys_sysauth where GRANTEE = id and privilege in (select PRIVILEGE from sys_sysauth_map where upper(name) = upper(priv) )) then
			return true;
		end if;
	end if;
	
	return false;
end;

-- Compatible with ORACLE, add USER_INDEXES view
CREATE OR REPLACE  VIEW USER_INDEXES AS
SELECT C.RELNAME ::CHARACTER VARYING(63 BYTE) AS INDEX_NAME,
A.AMNAME ::CHARACTER VARYING(63 BYTE) AS INDEX_TYPE,
sys_GET_USERBYID(D.RELOWNER) ::CHARACTER VARYING(63 BYTE) AS TABLE_OWNER,
(SELECT RELNAME FROM sys_CLASS WHERE  OID = INDRELID )::CHARACTER VARYING(63 BYTE) AS TABLE_NAME,
'TABLE'::TEXT AS TABLE_TYPE,
(case I.INDISUNIQUE or I.INDISPRIMARY when true then 'UNIQUE' else 'NONUNIQUE' end)::CHARACTER VARYING(9 CHAR) AS UNIQUENESS,
'DISABLED'::CHARACTER VARYING(8 CHAR)  AS COMPRESSION,
0 ::number AS PREFIX_LENGTH,
(case c.reltablespace when 0 then 'database default tablespace' else ( SELECT SPCNAME FROM sys_TABLESPACE WHERE OID = C.RELTABLESPACE) end)::CHARACTER VARYING(63 BYTE) AS TABLESPACE_NAME,
NULL::CHARACTER VARYING(7 CHAR) AS INI_TRANS,
NULL::CHARACTER VARYING(7 CHAR) AS MAX_TRANS,
NULL::CHARACTER VARYING(7 CHAR) AS INITIAL_EXTENT,
NULL::CHARACTER VARYING(7 CHAR) AS NEXT_EXTENT,
NULL::CHARACTER VARYING(7 CHAR) AS MIN_EXTENTS,
NULL::CHARACTER VARYING(7 CHAR) AS MAX_EXTENTS,
NULL::CHARACTER VARYING(7 CHAR) AS PCT_INCREASE,
NULL::CHARACTER VARYING(7 CHAR) AS PCT_THRESHOLD,
NULL::CHARACTER VARYING(7 CHAR) AS INCLUDE_COLUMN,
NULL::CHARACTER VARYING(7 CHAR) AS FREELISTS,
NULL::CHARACTER VARYING(7 CHAR) AS FREELIST_GROUPS,
NULL::CHARACTER VARYING(7 CHAR) AS PCT_FREE,
NULL::CHARACTER VARYING(7 CHAR) AS LOGGING,
NULL::CHARACTER VARYING(7 CHAR) AS BLEVEL,
NULL::CHARACTER VARYING(7 CHAR) AS LEAF_BLOCKS,
NULL::CHARACTER VARYING(7 CHAR) AS DISTINCT_KEYS,
NULL::CHARACTER VARYING(7 CHAR) AS AVG_LEAF_BLOCKS_PER_KEY,
NULL::CHARACTER VARYING(7 CHAR) AS AVG_DATA_BLOCKS_PER_KEY,
NULL::CHARACTER VARYING(7 CHAR) AS CLUSTERING_FACTOR,
NULL::CHARACTER VARYING(8 CHAR) AS STATUS,
NULL::CHARACTER VARYING(7 CHAR) AS NUM_ROWS,
NULL::CHARACTER VARYING(7 CHAR) AS SAMPLE_SIZE,
NULL::CHARACTER VARYING(20 CHAR) AS LAST_ANALYZED,
NULL::CHARACTER VARYING(40 CHAR) AS DEGREE,
NULL::CHARACTER VARYING(40 CHAR)AS INSTANCES,
NULL::CHARACTER VARYING(3 CHAR) AS PARTITIONED,
NULL::CHARACTER VARYING(1 CHAR) AS "TEMPORARY",
NULL::CHARACTER VARYING(1 CHAR) AS GENERATED,
NULL::CHARACTER VARYING(1 CHAR) AS SECONDARY,
NULL::CHARACTER VARYING(7 CHAR) AS BUFFER_POOL,
NULL::CHARACTER VARYING(3 CHAR) AS USER_STATS,
NULL::CHARACTER VARYING(15 CHAR) AS "DURATION",
NULL::CHARACTER VARYING(7 CHAR) AS PCT_DIRECT_ACCESS,
NULL::CHARACTER VARYING(63 BYTE) AS ITYP_OWNER,
NULL::CHARACTER VARYING(63 BYTE) AS ITYP_NAME,
NULL::CHARACTER VARYING(1000 CHAR) AS PARAMETERS,
NULL::CHARACTER VARYING(3 CHAR) AS GLOBAL_STATS,
NULL::CHARACTER VARYING(12 CHAR) AS DOMIDX_STATUS,
NULL::CHARACTER VARYING(6 CHAR) AS DOMIDX_OPSTATUS,
NULL::CHARACTER VARYING(8 CHAR) AS FUNCIDX_STATUS,
'NO'::TEXT AS JOIN_INDEX,
'NO'::TEXT AS IOT_REDUNDANT_PKEY_ELIM,
'NO'::TEXT AS DROPPED
FROM  sys_INDEX I, sys_CLASS C,sys_CLASS D,sys_AM A
WHERE
C.RELOWNER = UID
AND I.INDRELID = D.OID
AND I.INDEXRELID = C.OID
AND A.OID = C.RELAM;
comment on view USER_INDEXES is 'Description of the user''s own indexes';
comment on column USER_INDEXES.INDEX_NAME is 'Name of the index';
comment on column USER_INDEXES.TABLE_OWNER is'Owner of the indexed object';
comment on column USER_INDEXES.TABLE_NAME is 'Name of the indexed object';
comment on column USER_INDEXES.TABLE_TYPE is 'Type of the indexed object';
comment on column USER_INDEXES.UNIQUENESS is 'Uniqueness status of the index:  "UNIQUE",  "NONUNIQUE", or "BITMAP"';
comment on column USER_INDEXES.COMPRESSION is 'Compression property of the index: "ENABLED",  "DISABLED", or NULL';
comment on column USER_INDEXES.PREFIX_LENGTH is 'Number of key columns in the prefix used for compression';
comment on column USER_INDEXES.TABLESPACE_NAME is 'Name of the tablespace containing the index';
comment on column USER_INDEXES.INI_TRANS is 'Initial number of transactions';
comment on column USER_INDEXES.MAX_TRANS is 'Maximum number of transactions';
comment on column USER_INDEXES.INITIAL_EXTENT is 'Size of the initial extent in bytes';
comment on column USER_INDEXES.NEXT_EXTENT is 'Size of secondary extents in bytes';
comment on column USER_INDEXES.MIN_EXTENTS is 'Minimum number of extents allowed in the segment';
comment on column USER_INDEXES.MAX_EXTENTS is 'Maximum number of extents allowed in the segment';
comment on column USER_INDEXES.PCT_INCREASE is 'Percentage increase in extent size';
comment on column USER_INDEXES.PCT_THRESHOLD is 'Threshold percentage of block space allowed per index entry';
comment on column USER_INDEXES.INCLUDE_COLUMN is 'User column-id for last column to be included in index-only table top index';
comment on column USER_INDEXES.FREELISTS is 'Number of process freelists allocated in this segment';
comment on column USER_INDEXES.FREELIST_GROUPS is 'Number of freelist groups allocated to this segment';
comment on column USER_INDEXES.PCT_FREE is 'Minimum percentage of free space in a block';
comment on column USER_INDEXES.LOGGING is 'Logging attribute';
comment on column USER_INDEXES.BLEVEL is 'B-Tree level';
comment on column USER_INDEXES.LEAF_BLOCKS is 'The number of leaf blocks in the index';
comment on column USER_INDEXES.DISTINCT_KEYS is 'The number of distinct keys in the index';
comment on column USER_INDEXES.AVG_LEAF_BLOCKS_PER_KEY is 'The average number of leaf blocks per key';
comment on column USER_INDEXES.AVG_DATA_BLOCKS_PER_KEY is 'The average number of data blocks per key';
comment on column USER_INDEXES.CLUSTERING_FACTOR is 'A measurement of the amount of (dis)order of the table this index is for';
comment on column USER_INDEXES.NUM_ROWS is 'Number of rows in the index';
comment on column USER_INDEXES.SAMPLE_SIZE is 'The sample size used in analyzing this index';
comment on column USER_INDEXES.LAST_ANALYZED is 'The date of the most recent time this index was analyzed';
comment on column USER_INDEXES.DEGREE is 'The number of threads per instance for scanning the partitioned index';
comment on column USER_INDEXES.INSTANCES is 'The number of instances across which the partitioned index is to be scanned';
comment on column USER_INDEXES.PARTITIONED is 'Is this index partitioned? YES or NO';
comment on column USER_INDEXES.GENERATED is 'Was the name of this index system generated?';
comment on column USER_INDEXES.SECONDARY is 'Is the index object created as part of icreate for domain indexes?';
comment on column USER_INDEXES.BUFFER_POOL is 'The default buffer pool to be used for index blocks';
comment on column USER_INDEXES.USER_STATS is 'Were the statistics entered directly by the user?';
comment on column USER_INDEXES.PCT_DIRECT_ACCESS is 'If index on IOT, then this is percentage of rows with Valid guess';
comment on column USER_INDEXES.ITYP_OWNER is 'If domain index, then this is the indextype owner';
comment on column USER_INDEXES.ITYP_NAME is 'If domain index, then this is the name of the associated indextype';
comment on column USER_INDEXES.PARAMETERS is 'If domain index, then this is the parameter string';
comment on column USER_INDEXES.GLOBAL_STATS is 'Are the statistics calculated without merging underlying partitions?';
comment on column USER_INDEXES.DOMIDX_STATUS is 'Is the indextype of the domain index valid';
comment on column USER_INDEXES.DOMIDX_OPSTATUS is 'Status of the operation on the domain index';
comment on column USER_INDEXES.FUNCIDX_STATUS is 'Is the Function-based Index DISABLED or ENABLED?';
comment on column USER_INDEXES.JOIN_INDEX is 'Is this index a join index?';
comment on column USER_INDEXES.IOT_REDUNDANT_PKEY_ELIM is 'Were redundant primary key columns eliminated from iot secondary index?';
comment on column USER_INDEXES.DROPPED is 'Whether index is dropped and is in Recycle Bin';

-- Compatible with ORACLE, add ALL_INDEXES view
CREATE OR REPLACE  VIEW ALL_INDEXES AS
SELECT U.USENAME ::CHARACTER VARYING(63 BYTE)  AS "OWNER",
C.RELNAME ::CHARACTER VARYING(63 BYTE) AS INDEX_NAME,
A.AMNAME ::CHARACTER VARYING(27 BYTE) AS INDEX_TYPE,
U.USENAME ::CHARACTER VARYING(63 BYTE) AS TABLE_OWNER,
(SELECT RELNAME FROM sys_CLASS WHERE  OID = INDRELID )::CHARACTER VARYING(63 BYTE) AS TABLE_NAME,
'TABLE'::TEXT AS TABLE_TYPE,
case I.INDISUNIQUE or I.INDISPRIMARY when true then 'UNIQUE' else 'NONUNIQUE' end::CHARACTER VARYING(9 CHAR) AS UNIQUENESS,
'DISABLED'::CHARACTER VARYING(8 CHAR)  AS COMPRESSION,
0 ::number AS PREFIX_LENGTH,
(CASE c.reltablespace when 0 then 'database default tablespace'  else (SELECT SPCNAME FROM sys_TABLESPACE WHERE OID = C.RELTABLESPACE) end)::CHARACTER VARYING(63 BYTE) AS TABLESPACE_NAME,
NULL::CHARACTER VARYING(7 CHAR) AS INI_TRANS,
NULL::CHARACTER VARYING(7 CHAR) AS MAX_TRANS,
NULL::CHARACTER VARYING(7 CHAR) AS INITIAL_EXTENT,
NULL::CHARACTER VARYING(7 CHAR) AS NEXT_EXTENT,
NULL::CHARACTER VARYING(7 CHAR) AS MIN_EXTENTS,
NULL::CHARACTER VARYING(7 CHAR) AS MAX_EXTENTS,
NULL::CHARACTER VARYING(7 CHAR) AS PCT_INCREASE,
NULL::CHARACTER VARYING(7 CHAR) AS PCT_THRESHOLD,
NULL::CHARACTER VARYING(7 CHAR) AS INCLUDE_COLUMN,
NULL::CHARACTER VARYING(7 CHAR) AS FREELISTS,
NULL::CHARACTER VARYING(7 CHAR) AS FREELIST_GROUPS,
NULL::CHARACTER VARYING(7 CHAR) AS PCT_FREE,
NULL::CHARACTER VARYING(7 CHAR) AS LOGGING,
NULL::CHARACTER VARYING(7 CHAR) AS BLEVEL,
NULL::CHARACTER VARYING(7 CHAR) AS LEAF_BLOCKS,
NULL::CHARACTER VARYING(7 CHAR) AS DISTINCT_KEYS,
NULL::CHARACTER VARYING(7 CHAR) AS AVG_LEAF_BLOCKS_PER_KEY,
NULL::CHARACTER VARYING(7 CHAR) AS AVG_DATA_BLOCKS_PER_KEY,
NULL::CHARACTER VARYING(7 CHAR) AS CLUSTERING_FACTOR,
NULL::CHARACTER VARYING(8 CHAR) AS STATUS,
NULL::CHARACTER VARYING(7 CHAR) AS NUM_ROWS,
NULL::CHARACTER VARYING(7 CHAR) AS SAMPLE_SIZE,
NULL::CHARACTER VARYING(20 CHAR) AS LAST_ANALYZED,
NULL::CHARACTER VARYING(40 CHAR) AS DEGREE,
NULL::CHARACTER VARYING(40 CHAR)AS INSTANCES,
NULL::CHARACTER VARYING(3 CHAR) AS PARTITIONED,
NULL::CHARACTER VARYING(1 CHAR) AS "TEMPORARY",
NULL::CHARACTER VARYING(1 CHAR) AS GENERATED,
NULL::CHARACTER VARYING(1 CHAR) AS SECONDARY,
NULL::CHARACTER VARYING(7 CHAR) AS BUFFER_POOL,
NULL::CHARACTER VARYING(3 CHAR) AS USER_STATS,
NULL::CHARACTER VARYING(15 CHAR) AS "DURATION",
NULL::CHARACTER VARYING(7 CHAR) AS PCT_DIRECT_ACCESS,
NULL::CHARACTER VARYING(63 BYTE) AS ITYP_OWNER,
NULL::CHARACTER VARYING(63 BYTE) AS ITYP_NAME,
NULL::CHARACTER VARYING(1000 CHAR) AS PARAMETERS,
NULL::CHARACTER VARYING(3 CHAR) AS GLOBAL_STATS,
NULL::CHARACTER VARYING(12 CHAR) AS DOMIDX_STATUS,
NULL::CHARACTER VARYING(6 CHAR) AS DOMIDX_OPSTATUS,
NULL::CHARACTER VARYING(8 CHAR) AS FUNCIDX_STATUS,
'NO'::TEXT AS JOIN_INDEX,
'NO'::TEXT AS IOT_REDUNDANT_PKEY_ELIM,
'NO'::TEXT AS DROPPED
FROM sys_USER U, sys_INDEX I, sys_CLASS C,sys_CLASS D,
sys_AM A
WHERE
U.USESYSID = C.RELOWNER
AND I.INDRELID = D.OID
AND I.INDEXRELID = C.OID
AND A.OID = C.RELAM
AND
(
   (
     HAS_TABLE_PRIVILEGE(D.OID,'SELECT') = TRUE
	 OR HAS_TABLE_PRIVILEGE(D.OID, 'INSERT') = TRUE
	 OR HAS_TABLE_PRIVILEGE(D.OID, 'UPDATE') = TRUE
	 OR HAS_TABLE_PRIVILEGE(D.OID, 'DELETE') = TRUE
	 OR HAS_TABLE_PRIVILEGE(D.OID, 'REFERENCES') = TRUE
	 OR HAS_TABLE_PRIVILEGE(D.OID, 'TRIGGER')
   )
     OR
   (
     sys_has_any_table_priv()
   )
)
;


comment on view ALL_INDEXES is 'Descriptions of indexes on tables accessible to the user';
comment on column ALL_INDEXES."OWNER" is 'Username of the owner of the index';
comment on column ALL_INDEXES.STATUS is 'Whether the non-partitioned index is in USABLE or not';
comment on column ALL_INDEXES.INDEX_NAME is 'Name of the index';
comment on column ALL_INDEXES.TABLE_OWNER is 'Owner of the indexed object';
comment on column ALL_INDEXES.TABLE_NAME is 'Name of the indexed object';
comment on column ALL_INDEXES.TABLE_TYPE is 'Type of the indexed object';
comment on column ALL_INDEXES.UNIQUENESS is 'Uniqueness status of the index: "UNIQUE",  "NONUNIQUE", or "BITMAP"';
comment on column ALL_INDEXES.COMPRESSION is 'Compression property of the index: "ENABLED",  "DISABLED", or NULL';
comment on column ALL_INDEXES.PREFIX_LENGTH is 'Number of key columns in the prefix used for compression';
comment on column ALL_INDEXES.TABLESPACE_NAME is 'Name of the tablespace containing the index';
comment on column ALL_INDEXES.INI_TRANS is 'Initial number of transactions';
comment on column ALL_INDEXES.MAX_TRANS is 'Maximum number of transactions';
comment on column ALL_INDEXES.INITIAL_EXTENT is 'Size of the initial extent';
comment on column ALL_INDEXES.NEXT_EXTENT is 'Size of secondary extents';
comment on column ALL_INDEXES.MIN_EXTENTS is 'Minimum number of extents allowed in the segment';
comment on column ALL_INDEXES.MAX_EXTENTS is 'Maximum number of extents allowed in the segment';
comment on column ALL_INDEXES.PCT_INCREASE is 'Percentage increase in extent size';
comment on column ALL_INDEXES.PCT_THRESHOLD is 'Threshold percentage of block space allowed per index entry';
comment on column ALL_INDEXES.INCLUDE_COLUMN is 'User column-id for last column to be included in index-organized table top index';
comment on column ALL_INDEXES.FREELISTS is 'Number of process freelists allocated in this segment';
comment on column ALL_INDEXES.FREELIST_GROUPS is 'Number of freelist groups allocated to this segment';
comment on column ALL_INDEXES.PCT_FREE is 'Minimum percentage of free space in a block';
comment on column ALL_INDEXES.LOGGING is 'Logging attribute';
comment on column ALL_INDEXES.BLEVEL is 'B-Tree level';
comment on column ALL_INDEXES.LEAF_BLOCKS is 'The number of leaf blocks in the index';
comment on column ALL_INDEXES.DISTINCT_KEYS is 'The number of distinct keys in the index';
comment on column ALL_INDEXES.AVG_LEAF_BLOCKS_PER_KEY is 'The average number of leaf blocks per key';
comment on column ALL_INDEXES.AVG_DATA_BLOCKS_PER_KEY is 'The average number of data blocks per key';
comment on column ALL_INDEXES.CLUSTERING_FACTOR is 'A measurement of the amount of (dis)order of the table this index is for';
comment on column ALL_INDEXES.SAMPLE_SIZE is 'The sample size used in analyzing this index';
comment on column ALL_INDEXES.LAST_ANALYZED is 'The date of the most recent time this index was analyzed';
comment on column ALL_INDEXES.DEGREE is 'The number of threads per instance for scanning the partitioned index';
comment on column ALL_INDEXES.INSTANCES is 'The number of instances across which the partitioned index is to be scanned';
comment on column ALL_INDEXES.PARTITIONED is 'Is this index partitioned? YES or NO';
comment on column ALL_INDEXES."TEMPORARY" is 'Can the current session only see data that it place in this object itself?';
comment on column ALL_INDEXES.GENERATED is 'Was the name of this index system generated?';
comment on column ALL_INDEXES.SECONDARY is 'Is the index object created as part of icreate for domain indexes?';
comment on column ALL_INDEXES.BUFFER_POOL is 'The default buffer pool to be used for index blocks';
comment on column ALL_INDEXES.USER_STATS is 'Were the statistics entered directly by the user?';
comment on column ALL_INDEXES."DURATION" is 'If index on temporary table, then duration is sys$session or sys$transaction else NULL';
comment on column ALL_INDEXES.PCT_DIRECT_ACCESS is 'If index on IOT, then this is percentage of rows with Valid guess';
comment on column ALL_INDEXES.ITYP_OWNER is 'If domain index, then this is the indextype owner';
comment on column ALL_INDEXES.ITYP_NAME is 'If domain index, then this is the name of the associated indextype';
comment on column ALL_INDEXES.PARAMETERS is 'If domain index, then this is the parameter string';
comment on column ALL_INDEXES.GLOBAL_STATS is 'Are the statistics calculated without merging underlying partitions?';
comment on column ALL_INDEXES.DOMIDX_STATUS is 'Is the indextype of the domain index valid';
comment on column ALL_INDEXES.DOMIDX_OPSTATUS is 'Status of the operation on the domain index';
comment on column ALL_INDEXES.FUNCIDX_STATUS is 'Is the Function-based Index DISABLED or ENABLED?';
comment on column ALL_INDEXES.JOIN_INDEX is 'Is this index a join index?';
comment on column ALL_INDEXES.IOT_REDUNDANT_PKEY_ELIM is 'Were redundant primary key columns eliminated from iot secondary index?';
comment on column ALL_INDEXES.DROPPED is 'Whether index is dropped and is in Recycle Bin';

-- Compatible with ORACLE, add DBA_INDEXES view
CREATE OR REPLACE  VIEW DBA_INDEXES AS
SELECT U.USENAME ::CHARACTER VARYING(63 BYTE)  AS "OWNER",
C.RELNAME ::CHARACTER VARYING(63 BYTE) AS INDEX_NAME,
A.AMNAME ::CHARACTER VARYING(63 BYTE) AS INDEX_TYPE,
U.USENAME ::CHARACTER VARYING(63 BYTE) AS TABLE_OWNER,
(SELECT RELNAME FROM sys_CLASS WHERE  OID = INDRELID )::CHARACTER VARYING(63 BYTE) AS TABLE_NAME,
'TABLE'::TEXT AS TABLE_TYPE,
case I.INDISUNIQUE or I.INDISPRIMARY when true then 'UNIQUE' else 'NONUNIQUE' end ::CHARACTER VARYING(9 CHAR) AS UNIQUENESS,
'DISABLED'::CHARACTER VARYING(8 CHAR)  AS COMPRESSION,
0 ::number AS PREFIX_LENGTH,
(case c.reltablespace when 0 then 'database default tablespace' else (SELECT SPCNAME FROM sys_TABLESPACE WHERE OID = C.RELTABLESPACE) end)::CHARACTER VARYING(63 BYTE) AS TABLESPACE_NAME,
NULL::CHARACTER VARYING(7 CHAR) AS INI_TRANS,
NULL::CHARACTER VARYING(7 CHAR) AS MAX_TRANS,
NULL::CHARACTER VARYING(7 CHAR) AS INITIAL_EXTENT,
NULL::CHARACTER VARYING(7 CHAR) AS NEXT_EXTENT,
NULL::CHARACTER VARYING(7 CHAR) AS MIN_EXTENTS,
NULL::CHARACTER VARYING(7 CHAR) AS MAX_EXTENTS,
NULL::CHARACTER VARYING(7 CHAR) AS PCT_INCREASE,
NULL::CHARACTER VARYING(7 CHAR) AS PCT_THRESHOLD,
NULL::CHARACTER VARYING(7 CHAR) AS INCLUDE_COLUMN,
NULL::CHARACTER VARYING(7 CHAR) AS FREELISTS,
NULL::CHARACTER VARYING(7 CHAR) AS FREELIST_GROUPS,
NULL::CHARACTER VARYING(7 CHAR) AS PCT_FREE,
NULL::CHARACTER VARYING(7 CHAR) AS LOGGING,
NULL::CHARACTER VARYING(7 CHAR) AS BLEVEL,
NULL::CHARACTER VARYING(7 CHAR) AS LEAF_BLOCKS,
NULL::CHARACTER VARYING(7 CHAR) AS DISTINCT_KEYS,
NULL::CHARACTER VARYING(7 CHAR) AS AVG_LEAF_BLOCKS_PER_KEY,
NULL::CHARACTER VARYING(7 CHAR) AS AVG_DATA_BLOCKS_PER_KEY,
NULL::CHARACTER VARYING(7 CHAR) AS CLUSTERING_FACTOR,
NULL::CHARACTER VARYING(8 CHAR) AS STATUS,
NULL::CHARACTER VARYING(7 CHAR) AS NUM_ROWS,
NULL::CHARACTER VARYING(7 CHAR) AS SAMPLE_SIZE,
NULL::CHARACTER VARYING(20 CHAR) AS LAST_ANALYZED,
NULL::CHARACTER VARYING(40 CHAR) AS DEGREE,
NULL::CHARACTER VARYING(40 CHAR)AS INSTANCES,
NULL::CHARACTER VARYING(3 CHAR) AS PARTITIONED,
NULL::CHARACTER VARYING(1 CHAR) AS "TEMPORARY",
NULL::CHARACTER VARYING(1 CHAR) AS GENERATED,
NULL::CHARACTER VARYING(1 CHAR) AS SECONDARY,
NULL::CHARACTER VARYING(7 CHAR) AS BUFFER_POOL,
NULL::CHARACTER VARYING(3 CHAR) AS USER_STATS,
NULL::CHARACTER VARYING(15 CHAR) AS "DURATION",
NULL::CHARACTER VARYING(7 CHAR) AS PCT_DIRECT_ACCESS,
NULL::CHARACTER VARYING(63 BYTE) AS ITYP_OWNER,
NULL::CHARACTER VARYING(63 BYTE) AS ITYP_NAME,
NULL::CHARACTER VARYING(1000 CHAR) AS PARAMETERS,
NULL::CHARACTER VARYING(3 CHAR) AS GLOBAL_STATS,
NULL::CHARACTER VARYING(12 CHAR) AS DOMIDX_STATUS,
NULL::CHARACTER VARYING(6 CHAR) AS DOMIDX_OPSTATUS,
NULL::CHARACTER VARYING(8 CHAR) AS FUNCIDX_STATUS,
'NO'::TEXT AS JOIN_INDEX,
'NO'::TEXT AS IOT_REDUNDANT_PKEY_ELIM,
'NO'::TEXT AS DROPPED
FROM sys_USER U, sys_INDEX I, sys_CLASS C,sys_CLASS D,
sys_AM A
WHERE
U.USESYSID = C.RELOWNER
AND I.INDRELID = D.OID
AND I.INDEXRELID = C.OID
AND A.OID = C.RELAM;
REVOKE ALL ON DBA_INDEXES FROM PUBLIC;



comment on view DBA_INDEXES is 'Description for all indexes in the database';
comment on column DBA_INDEXES."OWNER" is 'Username of the owner of the index';
comment on column DBA_INDEXES.INDEX_NAME is 'Name of the index';
comment on column DBA_INDEXES.TABLE_OWNER is 'Owner of the indexed object';
comment on column DBA_INDEXES.TABLE_NAME is 'Name of the indexed object';
comment on column DBA_INDEXES.TABLE_TYPE is 'Type of the indexed object';
comment on column DBA_INDEXES.UNIQUENESS is 'Uniqueness status of the index: "UNIQUE",  "NONUNIQUE", or "BITMAP"';
comment on column DBA_INDEXES.COMPRESSION is 'Compression property of the index: "ENABLED",  "DISABLED", or NULL';
comment on column DBA_INDEXES.PREFIX_LENGTH is 'Number of key columns in the prefix used for compression';
comment on column DBA_INDEXES.TABLESPACE_NAME is 'Name of the tablespace containing the index';
comment on column DBA_INDEXES.INI_TRANS is 'Initial number of transactions';
comment on column DBA_INDEXES.MAX_TRANS is 'Maximum number of transactions';
comment on column DBA_INDEXES.INITIAL_EXTENT is 'Size of the initial extent';
comment on column DBA_INDEXES.NEXT_EXTENT is 'Size of secondary extents';
comment on column DBA_INDEXES.MIN_EXTENTS is 'Minimum number of extents allowed in the segment';
comment on column DBA_INDEXES.MAX_EXTENTS is 'Maximum number of extents allowed in the segment';
comment on column DBA_INDEXES.PCT_INCREASE is 'Percentage increase in extent size';
comment on column DBA_INDEXES.PCT_THRESHOLD is 'Threshold percentage of block space allowed per index entry';
comment on column DBA_INDEXES.INCLUDE_COLUMN is 'User column-id for last column to be included in index-only table top index';
comment on column DBA_INDEXES.FREELISTS is 'Number of process freelists allocated in this segment';
comment on column DBA_INDEXES.FREELIST_GROUPS is 'Number of freelist groups allocated to this segment';
comment on column DBA_INDEXES.PCT_FREE is 'Minimum percentage of free space in a block';
comment on column DBA_INDEXES.LOGGING is 'Logging attribute';
comment on column DBA_INDEXES.BLEVEL is 'B-Tree level';
comment on column DBA_INDEXES.LEAF_BLOCKS is 'The number of leaf blocks in the index';
comment on column DBA_INDEXES.DISTINCT_KEYS is 'The number of distinct keys in the index';
comment on column DBA_INDEXES.AVG_LEAF_BLOCKS_PER_KEY is 'The average number of leaf blocks per key';
comment on column DBA_INDEXES.AVG_DATA_BLOCKS_PER_KEY is 'The average number of data blocks per key';
comment on column DBA_INDEXES.CLUSTERING_FACTOR is 'A measurement of the amount of (dis)order of the table this index is for';
comment on column DBA_INDEXES.SAMPLE_SIZE is 'The sample size used in analyzing this index';
comment on column DBA_INDEXES.LAST_ANALYZED is 'The date of the most recent time this index was analyzed';
comment on column DBA_INDEXES.DEGREE is 'The number of threads per instance for scanning the partitioned index';
comment on column DBA_INDEXES.INSTANCES is 'The number of instances across which the partitioned index is to be scanned';
comment on column DBA_INDEXES.PARTITIONED is 'Is this index partitioned? YES or NO';
comment on column DBA_INDEXES."TEMPORARY" is 'Can the current session only see data that it place in this object itself?';
comment on column DBA_INDEXES.GENERATED is 'Was the name of this index system generated?';
comment on column DBA_INDEXES.SECONDARY is 'Is the index object created as part of icreate for domain indexes?';
comment on column DBA_INDEXES.BUFFER_POOL is 'The default buffer pool to be used for index blocks';
comment on column DBA_INDEXES.USER_STATS is 'Were the statistics entered directly by the user?';
comment on column DBA_INDEXES."DURATION" is 'If index on temporary table, then duration is sys$session or sys$transaction else NULL';
comment on column DBA_INDEXES.PCT_DIRECT_ACCESS is 'If index on IOT, then this is percentage of rows with Valid guess';
comment on column DBA_INDEXES.ITYP_OWNER is 'If domain index, then this is the indextype owner';
comment on column DBA_INDEXES.ITYP_NAME is 'If domain index, then this is the name of the associated indextype';
comment on column DBA_INDEXES.PARAMETERS is 'If domain index, then this is the parameter string';
comment on column DBA_INDEXES.GLOBAL_STATS is 'Are the statistics calculated without merging underlying partitions?';
comment on column DBA_INDEXES.DOMIDX_STATUS is 'Is the indextype of the domain index valid';
comment on column DBA_INDEXES.DOMIDX_OPSTATUS is 'Status of the operation on the domain index';
comment on column DBA_INDEXES.FUNCIDX_STATUS is 'Is the Function-based Index DISABLED or ENABLED?';
comment on column DBA_INDEXES.JOIN_INDEX is 'Is this index a join index?';
comment on column DBA_INDEXES.IOT_REDUNDANT_PKEY_ELIM is 'Were redundant primary key columns eliminated from iot secondary index?';
comment on column DBA_INDEXES.DROPPED is 'Whether index is dropped and is in Recycle Bin';

--these view are for jobs
/*
CREATE OR REPLACE VIEW DBA_JOBS AS
		SELECT 	J.JOB_ID::NUMBER(38)		AS JOB,
				(SELECT USENAME FROM sys_USER U WHERE U.USESYSID = J.CREATOR)::VARCHAR(63 BYTE)	AS LOG_USER,
				(SELECT USENAME FROM sys_USER U WHERE U.USESYSID = J.PRIV_USER)::VARCHAR(63 BYTE)	AS PRIV_USER,
				(SELECT USENAME FROM sys_USER U WHERE U.USESYSID = J.PRIV_USER)::VARCHAR(63 BYTE)	AS SCHEMA_USER,
				J.LAST_START_DATE::DATE	AS LAST_DATE,
				J.LAST_START_DATE::TIME(0)::VARCHAR(8 BYTE)	AS LAST_SEC,
				J.THIS_RUN_DATE::DATE	AS THIS_DATE,
				J.THIS_RUN_DATE::TIME(0)::VARCHAR(8 BYTE)	AS THIS_SEC,
				J.NEXT_RUN_DATE::DATE	AS NEXT_DATE,
				J.NEXT_RUN_DATE::TIME(0)::VARCHAR(8 BYTE) 	AS NEXT_SEC,
				J.TOTAL_TIME::NUMBER						AS TOTAL_TIME,
				(CASE WHEN J.JOB_STATUS & 0X08=0X08 THEN 'Y' ELSE 'N' END)::VARCHAR(1 BYTE) AS BROKEN,
				S.RECURRENCE_EXPR::VARCHAR(4000 BYTE) AS "INTERVAL",
				J.FAILURE_COUNT::NUMBER						AS FAILURES,
				P.ACTION::VARCHAR(4000 BYTE) 				AS WHAT,
				''::VARCHAR(4000 BYTE)						AS NLS_ENV,
				'0000000000000000'::BYTEA 					AS MISC_ENV,
				J.INSTANCE_ID::NUMBER						AS INSTANCE,
				(SELECT DATNAME FROM sys_DATABASE D WHERE D.OID = J.DB) AS DBNAME
		FROM sys_SCHEDULER_JOB J, sys_SCHEDULER_SCHEDULE S, sys_SCHEDULER_PROGRAM P
		WHERE J.PROGRAM_ID = P.OID AND J.SCHEDULE_ID = S.OID AND (J.JOB_STATUS & 0x20000 = 0 ) ORDER BY JOB;
*/
/*
REVOKE ALL ON DBA_JOBS FROM PUBLIC;
comment on view DBA_JOBS 				is 'All jobs in the database';
comment on column DBA_JOBS.JOB 			is 'Identifier of job.  Neither import/export nor repeated executions change it.';
comment on column DBA_JOBS.LOG_USER 	is 'USER who was logged in when the job was submitted';
comment on column DBA_JOBS.PRIV_USER 	is 'USER whose default privileges apply to this job';
comment on column DBA_JOBS.SCHEMA_USER 	is 'select * from bar  means  select * from schema_user.bar ' ;
comment on column DBA_JOBS.LAST_DATE 	is 'Date that this job last successfully executed';
comment on column DBA_JOBS.LAST_SEC 	is 'Same as LAST_DATE.  This is when the last successful execution started.';
comment on column DBA_JOBS.THIS_DATE 	is 'Date that this job started executing (usually null if not executing)';
comment on column DBA_JOBS.THIS_SEC 	is 'Same as THIS_DATE.  This is when the last successful execution started.';
comment on column DBA_JOBS.TOTAL_TIME 	is 'Total wallclock time spent by the system on this job, in seconds';
comment on column DBA_JOBS.NEXT_DATE 	is 'Date that this job will next be executed';
comment on column DBA_JOBS.NEXT_SEC 	is 'Same as NEXT_DATE.  The job becomes due for execution at this time.';
comment on column DBA_JOBS.BROKEN 		is 'If Y, no attempt is being made to run this job.  See dbms_jobq.broken(job).';
comment on column DBA_JOBS."INTERVAL" 	is 'A date function, evaluated at the start of execution, becomes next NEXT_DATE';
comment on column DBA_JOBS.FAILURES 	is 'How many times has this job started and failed since its last success?';
comment on column DBA_JOBS.WHAT 		is 'Body of the anonymous PL/SQL block that this job executes';
comment on column DBA_JOBS.NLS_ENV 		is 'alter session parameters describing the NLS environment of the job';
comment on column DBA_JOBS.MISC_ENV 	is 'a versioned raw maintained by the kernel, for other session parameters';
comment on column DBA_JOBS.INSTANCE 	is 'Instance number restricted to run the job';
comment on column DBA_JOBS.DBNAME 		is 'The database which this job resides in.';
*/


--system views compatible with oracle.
create or replace view USER_TAB_COLUMNS
    (TABLE_NAME, COLUMN_NAME, DATA_TYPE, DATA_TYPE_MOD, DATA_TYPE_OWNER,
     DATA_LENGTH, DATA_PRECISION, DATA_SCALE, NULLABLE, COLUMN_ID,
     DEFAULT_LENGTH, DATA_DEFAULT, NUM_DISTINCT, LOW_VALUE, HIGH_VALUE,
     DENSITY, NUM_NULLS, NUM_BUCKETS, LAST_ANALYZED, SAMPLE_SIZE,
     CHARACTER_SET_NAME, CHAR_COL_DECL_LENGTH,
     GLOBAL_STATS, USER_STATS, AVG_COL_LEN, CHAR_LENGTH, CHAR_USED,
     V80_FMT_IMAGE, DATA_UPGRADED, HISTOGRAM)
as
select TABLE_NAME, COLUMN_NAME, DATA_TYPE, DATA_TYPE_MOD, DATA_TYPE_OWNER,
       DATA_LENGTH, DATA_PRECISION, DATA_SCALE, NULLABLE, COLUMN_ID,
       DEFAULT_LENGTH, DATA_DEFAULT, NUM_DISTINCT, LOW_VALUE, HIGH_VALUE,
       DENSITY, NUM_NULLS, NUM_BUCKETS, LAST_ANALYZED, SAMPLE_SIZE,
       CHARACTER_SET_NAME, CHAR_COL_DECL_LENGTH,
       GLOBAL_STATS, USER_STATS, AVG_COL_LEN, CHAR_LENGTH, CHAR_USED,
       V80_FMT_IMAGE, DATA_UPGRADED, HISTOGRAM
  from USER_TAB_COLS
 where HIDDEN_COLUMN = 'NO';

comment on view USER_TAB_COLUMNS is 'Columns of user''s tables, views and clusters';
comment on column USER_TAB_COLUMNS.TABLE_NAME is 'Table, view or cluster name';
comment on column USER_TAB_COLUMNS.COLUMN_NAME is 'Column name';
comment on column USER_TAB_COLUMNS.DATA_LENGTH is 'Length of the column in bytes';
comment on column USER_TAB_COLUMNS.DATA_TYPE is 'Datatype of the column';
comment on column USER_TAB_COLUMNS.DATA_TYPE_MOD is 'Datatype modifier of the column';
comment on column USER_TAB_COLUMNS.DATA_TYPE_OWNER is 'Owner of the datatype of the column';
comment on column USER_TAB_COLUMNS.DATA_PRECISION is 'Length: decimal digits (NUMBER) or binary digits (FLOAT)';
comment on column USER_TAB_COLUMNS.DATA_SCALE is 'Digits to right of decimal point in a number';
comment on column USER_TAB_COLUMNS.NULLABLE is 'Does column allow NULL values?';
comment on column USER_TAB_COLUMNS.COLUMN_ID is 'Sequence number of the column as created';
comment on column USER_TAB_COLUMNS.DEFAULT_LENGTH is 'Length of default value for the column';
comment on column USER_TAB_COLUMNS.DATA_DEFAULT is 'Default value for the column';
comment on column USER_TAB_COLUMNS.NUM_DISTINCT is 'The number of distinct values in the column';
comment on column USER_TAB_COLUMNS.LOW_VALUE is 'The low value in the column';
comment on column USER_TAB_COLUMNS.HIGH_VALUE is 'The high value in the column';
comment on column USER_TAB_COLUMNS.DENSITY is 'The density of the column';
comment on column USER_TAB_COLUMNS.NUM_NULLS is 'The number of nulls in the column';
comment on column USER_TAB_COLUMNS.NUM_BUCKETS is 'The number of buckets in histogram for the column';
comment on column USER_TAB_COLUMNS.LAST_ANALYZED is 'The date of the most recent time this column was analyzed';
comment on column USER_TAB_COLUMNS.SAMPLE_SIZE is 'The sample size used in analyzing this column';
comment on column USER_TAB_COLUMNS.CHARACTER_SET_NAME is 'Character set name';
comment on column USER_TAB_COLUMNS.CHAR_COL_DECL_LENGTH is 'Declaration length of character type column';
comment on column USER_TAB_COLUMNS.GLOBAL_STATS is 'Are the statistics calculated without merging underlying partitions?';
comment on column USER_TAB_COLUMNS.USER_STATS is 'Were the statistics entered directly by the user?';
comment on column USER_TAB_COLUMNS.AVG_COL_LEN is 'The average length of the column in bytes';
comment on column USER_TAB_COLUMNS.CHAR_LENGTH is 'The maximum length of the column in characters';
comment on column USER_TAB_COLUMNS.CHAR_USED is 'C is maximum length given in characters, B if in bytes';
comment on column USER_TAB_COLUMNS.V80_FMT_IMAGE is 'Is column data in 8.0 image format?';
comment on column USER_TAB_COLUMNS.DATA_UPGRADED is 'Has column data been upgraded to the latest type version format?';
grant select on USER_TAB_COLUMNS to PUBLIC;

create or replace view ALL_TAB_COLUMNS
    ("OWNER", TABLE_NAME,
     COLUMN_NAME, DATA_TYPE, DATA_TYPE_MOD, DATA_TYPE_OWNER,
     DATA_LENGTH, DATA_PRECISION, DATA_SCALE, NULLABLE, COLUMN_ID,
     DEFAULT_LENGTH, DATA_DEFAULT, NUM_DISTINCT, LOW_VALUE, HIGH_VALUE,
     DENSITY, NUM_NULLS, NUM_BUCKETS, LAST_ANALYZED, SAMPLE_SIZE,
     CHARACTER_SET_NAME, CHAR_COL_DECL_LENGTH,
     GLOBAL_STATS, USER_STATS, AVG_COL_LEN, CHAR_LENGTH, CHAR_USED,
     V80_FMT_IMAGE, DATA_UPGRADED, HISTOGRAM)
as
select "OWNER", TABLE_NAME,
       COLUMN_NAME, DATA_TYPE, DATA_TYPE_MOD, DATA_TYPE_OWNER,
       DATA_LENGTH, DATA_PRECISION, DATA_SCALE, NULLABLE, COLUMN_ID,
       DEFAULT_LENGTH, DATA_DEFAULT, NUM_DISTINCT, LOW_VALUE, HIGH_VALUE,
       DENSITY, NUM_NULLS, NUM_BUCKETS, LAST_ANALYZED, SAMPLE_SIZE,
       CHARACTER_SET_NAME, CHAR_COL_DECL_LENGTH,
       GLOBAL_STATS, USER_STATS, AVG_COL_LEN, CHAR_LENGTH, CHAR_USED,
       V80_FMT_IMAGE, DATA_UPGRADED, HISTOGRAM
  from ALL_TAB_COLS
 where HIDDEN_COLUMN = 'NO';


comment on view ALL_TAB_COLUMNS is 'Columns of user''s tables, views and clusters';
comment on column ALL_TAB_COLUMNS.TABLE_NAME is 'Table, view or cluster name';
comment on column ALL_TAB_COLUMNS.COLUMN_NAME is 'Column name';
comment on column ALL_TAB_COLUMNS.DATA_LENGTH is 'Length of the column in bytes';
comment on column ALL_TAB_COLUMNS.DATA_TYPE is 'Datatype of the column';
comment on column ALL_TAB_COLUMNS.DATA_TYPE_MOD is 'Datatype modifier of the column';
comment on column ALL_TAB_COLUMNS.DATA_TYPE_OWNER is 'Owner of the datatype of the column';
comment on column ALL_TAB_COLUMNS.DATA_PRECISION is 'Length: decimal digits (NUMBER) or binary digits (FLOAT)';
comment on column ALL_TAB_COLUMNS.DATA_SCALE is 'Digits to right of decimal point in a number';
comment on column ALL_TAB_COLUMNS.NULLABLE is 'Does column allow NULL values?';
comment on column ALL_TAB_COLUMNS.COLUMN_ID is 'Sequence number of the column as created';
comment on column ALL_TAB_COLUMNS.DEFAULT_LENGTH is 'Length of default value for the column';
comment on column ALL_TAB_COLUMNS.DATA_DEFAULT is 'Default value for the column';
comment on column ALL_TAB_COLUMNS.NUM_DISTINCT is 'The number of distinct values in the column';
comment on column ALL_TAB_COLUMNS.LOW_VALUE is 'The low value in the column';
comment on column ALL_TAB_COLUMNS.HIGH_VALUE is 'The high value in the column';
comment on column ALL_TAB_COLUMNS.DENSITY is 'The density of the column';
comment on column ALL_TAB_COLUMNS.NUM_NULLS is 'The number of nulls in the column';
comment on column ALL_TAB_COLUMNS.NUM_BUCKETS is 'The number of buckets in histogram for the column';
comment on column ALL_TAB_COLUMNS.LAST_ANALYZED is 'The date of the most recent time this column was analyzed';
comment on column ALL_TAB_COLUMNS.SAMPLE_SIZE is 'The sample size used in analyzing this column';
comment on column ALL_TAB_COLUMNS.CHARACTER_SET_NAME is 'Character set name';
comment on column ALL_TAB_COLUMNS.CHAR_COL_DECL_LENGTH is 'Declaration length of character type column';
comment on column ALL_TAB_COLUMNS.GLOBAL_STATS is 'Are the statistics calculated without merging underlying partitions?';
comment on column ALL_TAB_COLUMNS.USER_STATS is 'Were the statistics entered directly by the user?';
comment on column ALL_TAB_COLUMNS.AVG_COL_LEN is 'The average length of the column in bytes';
comment on column ALL_TAB_COLUMNS.CHAR_LENGTH is 'The maximum length of the column in characters';
comment on column ALL_TAB_COLUMNS.CHAR_USED is 'C if maximum length is specified in characters, B if in bytes';
comment on column ALL_TAB_COLUMNS.V80_FMT_IMAGE is 'Is column data in 8.0 image format?';
comment on column ALL_TAB_COLUMNS.DATA_UPGRADED is 'Has column data been upgraded to the latest type version format?';
grant select on ALL_TAB_COLUMNS to PUBLIC;

create or replace view DBA_TAB_COLUMNS
    ("OWNER", TABLE_NAME,
     COLUMN_NAME, DATA_TYPE, DATA_TYPE_MOD, DATA_TYPE_OWNER,
     DATA_LENGTH, DATA_PRECISION, DATA_SCALE, NULLABLE, COLUMN_ID,
     DEFAULT_LENGTH, DATA_DEFAULT, NUM_DISTINCT, LOW_VALUE, HIGH_VALUE,
     DENSITY, NUM_NULLS, NUM_BUCKETS, LAST_ANALYZED, SAMPLE_SIZE,
     CHARACTER_SET_NAME, CHAR_COL_DECL_LENGTH,
     GLOBAL_STATS, USER_STATS, AVG_COL_LEN, CHAR_LENGTH, CHAR_USED,
     V80_FMT_IMAGE, DATA_UPGRADED, HISTOGRAM)
as
select "OWNER", TABLE_NAME,
       COLUMN_NAME, DATA_TYPE, DATA_TYPE_MOD, DATA_TYPE_OWNER,
       DATA_LENGTH, DATA_PRECISION, DATA_SCALE, NULLABLE, COLUMN_ID,
       DEFAULT_LENGTH, DATA_DEFAULT, NUM_DISTINCT, LOW_VALUE, HIGH_VALUE,
       DENSITY, NUM_NULLS, NUM_BUCKETS, LAST_ANALYZED, SAMPLE_SIZE,
       CHARACTER_SET_NAME, CHAR_COL_DECL_LENGTH,
       GLOBAL_STATS, USER_STATS, AVG_COL_LEN, CHAR_LENGTH, CHAR_USED,
       V80_FMT_IMAGE, DATA_UPGRADED, HISTOGRAM
  from DBA_TAB_COLS
 where HIDDEN_COLUMN = 'NO';

comment on view DBA_TAB_COLUMNS is 'Columns of user''s tables, views and clusters';
comment on column DBA_TAB_COLUMNS.TABLE_NAME is 'Table, view or cluster name';
comment on column DBA_TAB_COLUMNS.COLUMN_NAME is 'Column name';
comment on column DBA_TAB_COLUMNS.DATA_LENGTH is 'Length of the column in bytes';
comment on column DBA_TAB_COLUMNS.DATA_TYPE is 'Datatype of the column';
comment on column DBA_TAB_COLUMNS.DATA_TYPE_MOD is 'Datatype modifier of the column';
comment on column DBA_TAB_COLUMNS.DATA_TYPE_OWNER is 'Owner of the datatype of the column';
comment on column DBA_TAB_COLUMNS.DATA_PRECISION is 'Length: decimal digits (NUMBER) or binary digits (FLOAT)';
comment on column DBA_TAB_COLUMNS.DATA_SCALE is 'Digits to right of decimal point in a number';
comment on column DBA_TAB_COLUMNS.NULLABLE is 'Does column allow NULL values?';
comment on column DBA_TAB_COLUMNS.COLUMN_ID is 'Sequence number of the column as created';
comment on column DBA_TAB_COLUMNS.DEFAULT_LENGTH is 'Length of default value for the column';
comment on column DBA_TAB_COLUMNS.DATA_DEFAULT is 'Default value for the column';
comment on column DBA_TAB_COLUMNS.NUM_DISTINCT is 'The number of distinct values in the column';
comment on column DBA_TAB_COLUMNS.LOW_VALUE is 'The low value in the column';
comment on column DBA_TAB_COLUMNS.HIGH_VALUE is 'The high value in the column';
comment on column DBA_TAB_COLUMNS.DENSITY is 'The density of the column';
comment on column DBA_TAB_COLUMNS.NUM_NULLS is 'The number of nulls in the column';
comment on column DBA_TAB_COLUMNS.NUM_BUCKETS is 'The number of buckets in histogram for the column';
comment on column DBA_TAB_COLUMNS.LAST_ANALYZED is 'The date of the most recent time this column was analyzed';
comment on column DBA_TAB_COLUMNS.SAMPLE_SIZE is 'The sample size used in analyzing this column';
comment on column DBA_TAB_COLUMNS.CHARACTER_SET_NAME is 'Character set name';
comment on column DBA_TAB_COLUMNS.CHAR_COL_DECL_LENGTH is 'Declaration length of character type column';
comment on column DBA_TAB_COLUMNS.GLOBAL_STATS is 'Are the statistics calculated without merging underlying partitions?';
comment on column DBA_TAB_COLUMNS.USER_STATS is 'Were the statistics entered directly by the user?';
comment on column DBA_TAB_COLUMNS.AVG_COL_LEN is 'The average length of the column in bytes';
comment on column DBA_TAB_COLUMNS.CHAR_LENGTH is 'The maximum length of the column in characters';
comment on column DBA_TAB_COLUMNS.CHAR_USED is 'C if the width was specified in characters, B if in bytes';
comment on column DBA_TAB_COLUMNS.V80_FMT_IMAGE is 'Is column data in 8.0 image format?';
comment on column DBA_TAB_COLUMNS.DATA_UPGRADED is 'Has column data been upgraded to the latest type version format?';

revoke all on DBA_TAB_COLUMNS from public;


create or replace view DBA_IND_COLUMNS as
select
	sys_get_userbyid(ic.relowner)::CHARACTER VARYING(63 BYTE) as INDEX_OWNER
	,ic.relname::CHARACTER VARYING(63 BYTE) as INDEX_NAME
	,sys_get_userbyid(tc.relowner)::CHARACTER VARYING(63 BYTE) as TABLE_OWNER
	,tc.relname::CHARACTER VARYING(63 BYTE) as TABLE_NAME
	,a.attname::CHARACTER VARYING(4000 CHAR) as COLUMN_NAME
	,ia.attnum as COLUMN_POSITION
	,(
		case when a.attlen = -1 then
		(
			case t.typname
				when 'BIT' 			then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'BIT VARYING' 	then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'TIMETZ' 		then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'TIME' 		then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'TIMESTAMPTZ' 	then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'TIMESTAMP' 	then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'INTERVAL' 	then (case (a.atttypmod >> 16)=0 when true then abs(a.atttypmod) else 0 end)
				when 'VARBIT' 		then (case (a.atttypmod >> 16)=0 when true then abs(a.atttypmod) else 0 end)
				when 'VARCHAR' 		then ( case a.atttypmod = -1 when true then null else (case (a.atttypmod >> 16)=0 when true then null else abs(a.atttypmod)-4 end) end)
				when 'BPCHAR' 		then (case a.atttypmod = -1 when true then null else (case(a.atttypmod >> 16)=0 when true then null else abs(a.atttypmod)-4 end) end)
				else (case (a.atttypmod >> 16)=0 when true then a.atttypmod-4 else 0 end)
			end
		)
		else
			a.attlen
		end
	)::NUMBER AS COLUMN_LENGTH --Maximum length of column in bytes.
	,(
		case when a.attlen = -1 then
		(
			case T.typname
				when 'VARCHAR' 	then  (case(a.atttypmod>>16)=0 when true then a.atttypmod - 4 else null end)
				when 'BPCHAR' 	then  (case(a.atttypmod>>16)=0 when true then a.atttypmod - 4 else null end)
			end
		)
		else
			0
		end
	  )::NUMBER AS CHAR_LENGTH
	,(case (i.indoption[COLUMN_POSITION-1]&'01')=0 when true then 'ASC' else 'DESC' end)::CHARACTER VARYING(4 CHAR) as DESCEND
from
	sys_index i,
	sys_class tc,
	sys_class ic,
	sys_attribute a,
	sys_type t,
	sys_attribute ia
where
	(i.indrelid = a.attrelid and a.attnum = any(i.indkey))
	and i.indrelid = tc.oid
	and i.indexrelid = ic.oid
	and a.atttypid = t.oid
	and ia.attrelid = i.indexrelid
	and ia.attname = a.attname
;

revoke all on DBA_IND_COLUMNS from public;
comment on view DBA_IND_COLUMNS is 'COLUMNs comprising INDEXes on all TABLEs and CLUSTERs';
comment on column DBA_IND_COLUMNS.INDEX_OWNER is 'Index owner';
comment on column DBA_IND_COLUMNS.INDEX_NAME is 'Index name';
comment on column DBA_IND_COLUMNS.TABLE_OWNER is 'Table or cluster owner';
comment on column DBA_IND_COLUMNS.TABLE_NAME is 'Table or cluster name';
comment on column DBA_IND_COLUMNS.COLUMN_NAME is 'Column name or attribute of object column';
comment on column DBA_IND_COLUMNS.COLUMN_POSITION is 'Position of column or attribute within index';
comment on column DBA_IND_COLUMNS.COLUMN_LENGTH is 'Maximum length of the column or attribute, in bytes';
comment on column DBA_IND_COLUMNS.CHAR_LENGTH is 'Maximum length of the column or attribute, in characters';
comment on column DBA_IND_COLUMNS.DESCEND is 'DESC if this column is sorted in descending order on disk, otherwise ASC';

create or replace view ALL_IND_COLUMNS as
select
	sys_get_userbyid(ic.relowner)::CHARACTER VARYING(63 BYTE) as INDEX_OWNER
	,ic.relname::CHARACTER VARYING(63 BYTE) as INDEX_NAME
	,sys_get_userbyid(tc.relowner)::CHARACTER VARYING(63 BYTE) as TABLE_OWNER
	,tc.relname::CHARACTER VARYING(63 BYTE) as TABLE_NAME
	,a.attname::CHARACTER VARYING(4000 CHAR) as COLUMN_NAME
	,ia.attnum as COLUMN_POSITION
	,(
		case when a.attlen = -1 then
		(
			--atttypmod < 0 means it's in bytes.
			case t.typname
				when 'BIT' 			then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'BIT VARYING' 	then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'TIMETZ' 		then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'TIME' 		then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'TIMESTAMPTZ' 	then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'TIMESTAMP' 	then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'INTERVAL' 	then (case (a.atttypmod >> 16)=0 when true then abs(a.atttypmod) else 0 end)
				when 'VARBIT' 		then(case (a.atttypmod >> 16)=0 when true then abs(a.atttypmod) else 0 end)
				/* sys_class.relkeyid and sys_attribute.attkeyid all make a.atttypmod = -1, but they are not strings. */
				when 'VARCHAR' 		then ( case a.atttypmod = -1 when true then null else (case (a.atttypmod >> 16)=0 when true then null else abs(a.atttypmod)-4 end) end)
				when 'BPCHAR' 		then (case a.atttypmod = -1 when true then null else (case(a.atttypmod >> 16)=0 when true then null else abs(a.atttypmod)-4 end) end)
			  else (case (a.atttypmod >> 16)=0 when true then a.atttypmod-4 else 0 end)
			end
		)
		else
			a.attlen
		end
	)::NUMBER AS COLUMN_LENGTH --Maximum length of column in bytes.
	,(
		case when a.attlen = -1 then
		(
			case T.typname
				when 'VARCHAR' 	then (case(a.atttypmod>>16)=0 when true then a.atttypmod - 4 else null end)
				when 'BPCHAR' 	then (case(a.atttypmod>>16)=0 when true then a.atttypmod - 4 else null end)
			end
		)
		else
			0
		end
	  )::NUMBER AS CHAR_LENGTH --Maximum length of column in chars. This column will show strings in characters only.
	,(case (i.indoption[COLUMN_POSITION-1]&'01')=0 when true then 'ASC' else 'DESC' end) ::CHARACTER VARYING(4 CHAR) as DESCEND
from
	sys_index i,
	sys_class tc,	/* table in sys_class */
	sys_class ic,	/* index in sys_class */
	sys_attribute a,/* attribute of column */
	sys_type t,
	sys_attribute ia/* index's column: the columns in indexes will be shown in this table too. */
where
	(i.indrelid = a.attrelid and a.attnum = any(i.indkey))
	and i.indrelid = tc.oid -- table's oid
	and i.indexrelid = ic.oid -- index's oid
	and a.atttypid = t.oid
	and ia.attrelid = i.indexrelid
	and ia.attname = a.attname
	and
	(
	    (
		has_table_privilege(tc.oid, 'SELECT')
		or has_table_privilege(tc.oid, 'UPDATE')
		or has_table_privilege(tc.oid, 'DELETE')
	)
        or
		(
		  sys_has_any_table_priv()
		)
	)
;

grant select on ALL_IND_COLUMNS to public;
comment on view ALL_IND_COLUMNS is 'COLUMNs comprising INDEXes on accessible TABLES';
comment on column ALL_IND_COLUMNS.INDEX_OWNER is 'Index owner';
comment on column ALL_IND_COLUMNS.INDEX_NAME is 'Index name';
comment on column ALL_IND_COLUMNS.TABLE_OWNER is 'Table or cluster owner';
comment on column ALL_IND_COLUMNS.TABLE_NAME is 'Table or cluster name';
comment on column ALL_IND_COLUMNS.COLUMN_NAME is 'Column name or attribute of object column';
comment on column ALL_IND_COLUMNS.COLUMN_POSITION is 'Position of column or attribute within index';
comment on column ALL_IND_COLUMNS.COLUMN_LENGTH is 'Maximum length of the column or attribute, in bytes';
comment on column ALL_IND_COLUMNS.CHAR_LENGTH is 'Maximum length of the column or attribute, in characters';
comment on column ALL_IND_COLUMNS.DESCEND is 'DESC if this column is sorted in descending order on disk, otherwise ASC';


create or replace view USER_IND_COLUMNS as
select
	ic.relname::CHARACTER VARYING(63 BYTE) as INDEX_NAME
	,sys_get_userbyid(tc.relowner)::CHARACTER VARYING(63 BYTE) as TABLE_OWNER
	,tc.relname::CHARACTER VARYING(63 BYTE) as TABLE_NAME
	,a.attname::CHARACTER VARYING(4000 CHAR) as COLUMN_NAME
	,ia.attnum as COLUMN_POSITION
	,(
		case when a.attlen = -1 then
		(
			--atttypmod < 0 means it's in bytes.
			case t.typname
				when 'BIT' 			then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'BIT VARYING' 	then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'TIMETZ' 		then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'TIME' 		then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'TIMESTAMPTZ' 	then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'TIMESTAMP' 	then (case (a.atttypmod >> 16)!=0 when true then abs(a.atttypmod) else 0 end)
				when 'INTERVAL' 	then (case (a.atttypmod >> 16)=0 when true then abs(a.atttypmod) else 0 end)
				when 'VARBIT' 		then (case (a.atttypmod >> 16)=0 when true then abs(a.atttypmod) else 0 end)
				/* sys_class.relkeyid and sys_attribute.attkeyid all make a.atttypmod = -1, but they are not strings. */
				when 'VARCHAR' 		then ( case a.atttypmod = -1 when true then null else (case (a.atttypmod >> 16)=0 when true then null else abs(a.atttypmod)-4 end) end)
				when 'BPCHAR' 		then (case a.atttypmod = -1 when true then null else (case(a.atttypmod >> 16)=0 when true then null else abs(a.atttypmod)-4 end) end)
				else (case (a.atttypmod >> 16)=0 when true then a.atttypmod-4 else 0 end)
			end
		)
		else 	a.attlen end )::NUMBER AS COLUMN_LENGTH --Maximum length of column in bytes.
	,(
		case when a.attlen = -1 then
		(
			case T.typname
				when 'VARCHAR' 	then (case(a.atttypmod>>16)=0 when true then a.atttypmod - 4 else null end)
				when 'BPCHAR' 	then (case(a.atttypmod>>16)=0 when true then a.atttypmod - 4 else null end)
			end
		) else 0 end )::NUMBER AS CHAR_LENGTH --Maximum length of column in chars. This column will show strings in characters only.
	,(case (i.indoption[COLUMN_POSITION-1]&'01')=0 when true then 'ASC' else 'DESC' end)::CHARACTER VARYING(4 CHAR) as DESCEND
from
	sys_index i,
	sys_class tc,	/* table in sys_class */
	sys_class ic,	/* index in sys_class */
	sys_attribute a,/* attribute of column */
	sys_type t,
	sys_attribute ia/* index's column: the columns in indexes will be shown in this table too. */
where
	(i.indrelid = a.attrelid and a.attnum = any(i.indkey))
	and i.indrelid = tc.oid -- table's oid
	and i.indexrelid = ic.oid -- index's oid
	and ia.attrelid = i.indexrelid
	and ia.attname = a.attname
	and ic.relowner = uid
	and a.atttypid = t.oid
;

grant select on USER_IND_COLUMNS to public;
comment on view USER_IND_COLUMNS is 'COLUMNs comprising user''s INDEXes and INDEXes on user''s TABLES';
comment on column USER_IND_COLUMNS.INDEX_NAME is 'Index name';
comment on column USER_IND_COLUMNS.TABLE_NAME is 'Table or cluster name';
comment on column USER_IND_COLUMNS.COLUMN_NAME is 'Column name or attribute of object column';
comment on column USER_IND_COLUMNS.COLUMN_POSITION is 'Position of column or attribute within index';
comment on column USER_IND_COLUMNS.COLUMN_LENGTH is 'Maximum length of the column or attribute, in bytes';
comment on column USER_IND_COLUMNS.CHAR_LENGTH is 'Maximum length of the column or attribute, in characters';
comment on column USER_IND_COLUMNS.DESCEND is 'DESC if this column is sorted descending on disk, otherwise ASC';


create or replace view USER_VIEWS as
select
	c.relname::CHARACTER VARYING(63 BYTE) as VIEW_NAME
	, length(sys_get_viewdef(c.oid))::number as TEXT_LENGTH
	, sys_get_viewdef(c.oid) as TEXT
	, length(t.typname||'   ')::number as TYPE_TEXT_LENGTH
	, (t.typname||'   ')::CHARACTER VARYING(4000 CHAR) as TYPE_TEXT --with three blanks as tail.
	, null::NUMBER as OID_TEXT_LENGTH
	, null::CHARACTER VARYING(4000 CHAR) as OID_TEXT
	, sys_get_userbyid(t.TYPOWNER)::CHARACTER VARYING(63 BYTE) as VIEW_TYPE_OWNER
	, t.typname::CHARACTER VARYING(63 BYTE) as VIEW_TYPE
	, null::CHARACTER VARYING(63 BYTE) as SUPERVIEW_NAME
	, 'N'::CHARACTER VARYING(1 CHAR) as EDITIONING_VIEW
	, CAST(
            (CASE WHEN sys_relation_is_updatable(c.oid, 't') IN (0, 2) THEN 'N'
				  ELSE 'Y'
			END)
            AS VARCHAR(1 CHAR)) as READ_ONLY
 from
	sys_class c left join sys_type t on  c.oid = t.typrelid
 where
	upper(c.relkind) = 'V'
	and c.relowner = uid
;

grant select on USER_VIEWS to PUBLIC;
comment on view USER_VIEWS is 'Description of the user''s own views';
comment on column USER_VIEWS.VIEW_NAME is 'Name of the view';
comment on column USER_VIEWS.TEXT_LENGTH is 'Length of the view text';
comment on column USER_VIEWS.TEXT is 'View text';
comment on column USER_VIEWS.TYPE_TEXT_LENGTH is 'Length of the type clause of the object view';
comment on column USER_VIEWS.TYPE_TEXT is 'Type clause of the object view';
comment on column USER_VIEWS.OID_TEXT_LENGTH is 'Length of the WITH OBJECT OID clause of the object view';
comment on column USER_VIEWS.OID_TEXT is 'WITH OBJECT OID clause of the object view';
comment on column USER_VIEWS.VIEW_TYPE_OWNER is 'Owner of the type of the view if the view is a object view';
comment on column USER_VIEWS.VIEW_TYPE is 'Type of the view if the view is a object view';
comment on column USER_VIEWS.SUPERVIEW_NAME is 'Name of the superview, if view is a subview';
comment on column USER_VIEWS.EDITIONING_VIEW is 'An indicator of whether the view is an Editioning View';
comment on column USER_VIEWS.READ_ONLY is 'An indicator of whether the view is a Read Only View';


create or replace view ALL_VIEWS as
select
	sys_get_userbyid(c.relowner)::CHARACTER VARYING(63 BYTE) as OWNER
	, c.relname::CHARACTER VARYING(63 BYTE) as VIEW_NAME
	, length(sys_get_viewdef(c.oid))::number as TEXT_LENGTH
	, sys_get_viewdef(c.oid) as TEXT
	, length(t.typname||'   ')::number as TYPE_TEXT_LENGTH
	, (t.typname||'   ')::CHARACTER VARYING(4000 CHAR) as TYPE_TEXT --with three blanks as tail.
	, null::NUMBER as OID_TEXT_LENGTH
	, null::CHARACTER VARYING(4000 CHAR) as OID_TEXT
	, sys_get_userbyid(t.TYPOWNER)::CHARACTER VARYING(63 BYTE) as VIEW_TYPE_OWNER
	, t.typname::CHARACTER VARYING(63 BYTE) as VIEW_TYPE
	, null::CHARACTER VARYING(63 BYTE) as SUPERVIEW_NAME
	, 'N'::CHARACTER VARYING(1 CHAR) as EDITIONING_VIEW
	, CAST(
            (CASE WHEN sys_relation_is_updatable(c.oid, 't') IN (0, 2) THEN 'N'
				  ELSE 'Y'
			END)
            AS VARCHAR(1 CHAR)) as READ_ONLY
from
	sys_class c left outer join sys_type t on (c.oid = t.typrelid)
where
	upper(c.relkind) = 'V'
	and
	(
     	(
			has_table_privilege(c.oid, 'select')
			or has_table_privilege(c.oid, 'update')
			or has_table_privilege(c.oid, 'delete')
		)
		or
		(
		  sys_has_any_table_priv()
		)
	)
;

grant select on all_views to public;
comment on view ALL_VIEWS is 'Description of views accessible to the user';
comment on column ALL_VIEWS.OWNER is 'Owner of the view';
comment on column ALL_VIEWS.VIEW_NAME is 'Name of the view';
comment on column ALL_VIEWS.TEXT_LENGTH is 'Length of the view text';
comment on column ALL_VIEWS.TEXT is 'View text';
comment on column ALL_VIEWS.TYPE_TEXT_LENGTH is 'Length of the type clause of the object view';
comment on column ALL_VIEWS.TYPE_TEXT is 'Type clause of the object view';
comment on column ALL_VIEWS.OID_TEXT_LENGTH is 'Length of the WITH OBJECT OID clause of the object view';
comment on column ALL_VIEWS.OID_TEXT is 'WITH OBJECT OID clause of the object view';
comment on column ALL_VIEWS.VIEW_TYPE_OWNER is 'Owner of the type of the view if the view is an object view';
comment on column ALL_VIEWS.VIEW_TYPE is 'Type of the view if the view is an object view';
comment on column ALL_VIEWS.SUPERVIEW_NAME is 'Name of the superview, if view is a subview';
comment on column ALL_VIEWS.EDITIONING_VIEW is 'An indicator of whether the view is an Editioning View';
comment on column ALL_VIEWS.READ_ONLY is 'An indicator of whether the view is a Read Only View';

create or replace view DBA_VIEWS as
select
	sys_get_userbyid(c.relowner)::CHARACTER VARYING(63 BYTE) as OWNER
	, c.relname::CHARACTER VARYING(63 BYTE) as VIEW_NAME
	, length(sys_get_viewdef(c.oid))::number as TEXT_LENGTH
	, sys_get_viewdef(c.oid) as TEXT
	, length(t.typname||'   ')::number as TYPE_TEXT_LENGTH
	, (t.typname||'   ')::CHARACTER VARYING(4000 CHAR) as TYPE_TEXT --with three blanks as tail.
	, null::NUMBER as OID_TEXT_LENGTH
	, null::CHARACTER VARYING(4000 CHAR) as OID_TEXT
	, sys_get_userbyid(t.TYPOWNER)::CHARACTER VARYING(63 BYTE) as VIEW_TYPE_OWNER
	, t.typname::CHARACTER VARYING(63 BYTE) as VIEW_TYPE
	, null::CHARACTER VARYING(63 BYTE) as SUPERVIEW_NAME
	, 'N'::CHARACTER VARYING(1 CHAR) as EDITIONING_VIEW
	, CAST(
            (CASE WHEN sys_relation_is_updatable(c.oid, 't') IN (0, 2) THEN 'N'
				  ELSE 'Y'
			END)
            AS VARCHAR(1 CHAR)) as READ_ONLY
from
	sys_class c left join sys_type t on c.oid = t.typrelid
where
	upper(c.relkind) = 'V';

revoke all on dba_views from public;
comment on view DBA_VIEWS is 'Description of all views in the database';
comment on column DBA_VIEWS.OWNER is 'Owner of the view';
comment on column DBA_VIEWS.VIEW_NAME is 'Name of the view';
comment on column DBA_VIEWS.TEXT_LENGTH is 'Length of the view text';
comment on column DBA_VIEWS.TEXT is 'View text';
comment on column DBA_VIEWS.TYPE_TEXT_LENGTH is 'Length of the type clause of the object view';
comment on column DBA_VIEWS.TYPE_TEXT is 'Type clause of the object view';
comment on column DBA_VIEWS.OID_TEXT_LENGTH is 'Length of the WITH OBJECT OID clause of the object view';
comment on column DBA_VIEWS.OID_TEXT is 'WITH OBJECT OID clause of the object view';
comment on column DBA_VIEWS.VIEW_TYPE_OWNER is 'Owner of the type of the view if the view is an object view';
comment on column DBA_VIEWS.VIEW_TYPE is 'Type of the view if the view is an object view';
comment on column DBA_VIEWS.SUPERVIEW_NAME is 'Name of the superview, if view is a subview';
comment on column DBA_VIEWS.EDITIONING_VIEW is 'An indicator of whether the view is an Editioning View';
comment on column DBA_VIEWS.READ_ONLY is 'An indicator of whether the view is a Read Only View';

create or replace view DICTIONARY
    (TABLE_NAME, COMMENTS)
as
	select c.relname::CHARACTER VARYING(63 BYTE), d.description::CHARACTER VARYING(4000 CHAR)
	from sys_class c left outer join sys_description d on (c.oid = d.objoid)
	where
		c.relkind = 'v'
		and c.relowner = 10
		and (
				c.relname like 'USER%'
				or c.relname like 'ALL%'
				or (
						c.relname like 'DBA%'
						and (
							    (
							has_table_privilege(c.oid, 'SELECT')
							or has_table_privilege(c.oid, 'DELETE')
							or has_table_privilege(c.oid, 'UPDATE')
						)
							 or
							    (
							      sys_has_any_table_priv(priv => 'SELECT ANY TABLE')
							    )
						    )
					)
			)
		and ( d.objsubid = 0 or d.objsubid is null)
union
	select c.relname::CHARACTER VARYING(63 BYTE), d.description::CHARACTER VARYING(4000 CHAR)
	from sys_class c left join sys_description d on (c.oid = d.objoid)
	where
		c.relowner = 10
		and upper(c.relname) in
		('AUDIT_ACTIONS', 'COLUMN_PRIVILEGES', 'DICTIONARY',
        'DICT_COLUMNS', 'DUAL', 'GLOBAL_NAME', 'INDEX_HISTOGRAM',
        'INDEX_STATS', 'RESOURCE_COST', 'ROLE_ROLE_PRIVS', 'ROLE_sys_PRIVS',
        'ROLE_TAB_PRIVS', 'SESSION_PRIVS', 'SESSION_ROLES',
        'TABLE_PRIVILEGES','NLS_SESSION_PARAMETERS','NLS_INSTANCE_PARAMETERS',
        'NLS_DATABASE_PARAMETERS', 'DATABASE_COMPATIBLE_LEVEL',
        'DBMS_ALERT_INFO', 'DBMS_LOCK_ALLOCATED')
;

grant select on DICTIONARY to public;
create or replace view DICT as select * from DICTIONARY;
grant select on DICT to public;

--dba_sequences
--bugId#BUG2021020200383: get_sequences can not get the hump-name sequence
--when case_insensitive is on
create or replace function get_sequences(wherestmt text)
returns setof record as
declare
	rec record;
	seq record;
	retval record;
	sql  text;
begin
	for rec in execute 'select c.oid as oid, a.usename as usename, c.relname as relname, n.nspname as nspname
  from sys_class c, sys_user a, sys_namespace n
  where c.relowner = a.usesysid and c.relkind=''S'' and c.relnamespace=n.oid ' || wherestmt
	loop
		for seq in execute 'select * from '|| '"' || rec.nspname || '"' || '.' || '"' || rec.relname || '"' loop
		   SELECT into retval rec.usename, seq.sequence_name, seq.last_value, seq.increment_by,
            seq.max_value, seq.min_value, seq.cache_value, seq.log_cnt,seq.is_cycled, seq.is_called;
     	 return next retval;
	  end loop;
	end loop;
end;

create or replace view dba_sequences as
select
     cast(usename as character varying(63 BYTE)) as SEQUENCE_OWNER,
	   cast(seqname as character varying(63 BYTE)) as SEQUENCE_NAME,
	   cast(min_value as NUMBER(38,0)) as MIN_VALUE,
	   cast(max_value as NUMBER(38,0)) as MAX_VALUE,
	   cast(increment_by as NUMBER(38,0)) as INCREMENT_BY,
	   cast(is_cycled as character varying(1 char)) as CYCLE_FLAG,
	   cast('t' as character varying(1 char)) as ORDER_FLAG,
	   cast(cache_value as NUMBER(38,0)) as CACHE_SIZE,
	   cast(last_value as NUMBER(38,0)) as LAST_NUMBER
from get_sequences('') as
(usename name,
seqname name,
last_value bigint,
increment_by bigint,
max_value bigint,
min_value bigint,
cache_value bigint,
log_cnt bigint,
is_cycled boolean,
is_called boolean);

--all_sequencese
create or replace view all_sequences as
select
     cast(usename as character varying(63 BYTE)) as SEQUENCE_OWNER,
	   cast(seqname as character varying(63 BYTE)) as SEQUENCE_NAME,
	   cast(min_value as NUMBER(38,0)) as MIN_VALUE,
	   cast(max_value as NUMBER(38,0)) as MAX_VALUE,
	   cast(increment_by as NUMBER(38,0)) as INCREMENT_BY,
	   cast(is_cycled as character varying(1 byte)) as CYCLE_FLAG,
	   cast('t' as character varying(1 byte)) as ORDER_FLAG,
	   cast(cache_value as NUMBER(38,0)) as CACHE_SIZE,
	   cast(last_value as NUMBER(38,0)) as LAST_NUMBER
from get_sequences(' AND (has_table_privilege(c.oid,''SELECT'')
           or has_table_privilege(c.oid,''INSERT'')
           or has_table_privilege(c.oid,''UPDATE'')
           or has_table_privilege(c.oid,''DELETE'')
           or has_table_privilege(c.oid,''REFERENCES'')
           or has_table_privilege(c.oid,''TRIGGER''))')
as
(usename name,
seqname name,
last_value bigint,
increment_by bigint,
max_value bigint,
min_value bigint,
cache_value bigint,
log_cnt bigint,
is_cycled boolean,
is_called boolean);


--user_sequences
create or replace view user_sequences as
select
     cast(usename as character varying(63 BYTE)) as SEQUENCE_OWNER,
	   cast(seqname as character varying(63 BYTE)) as SEQUENCE_NAME,
	   cast(min_value as NUMBER(38,0)) as MIN_VALUE,
	   cast(max_value as NUMBER(38,0)) as MAX_VALUE,
	   cast(increment_by as NUMBER(38,0)) as INCREMENT_BY,
	   cast(is_cycled as character varying(1 byte)) as CYCLE_FLAG,
	   cast('t' as character varying(1 byte)) as ORDER_FLAG,
	   cast(cache_value as NUMBER(38,0)) as CACHE_SIZE,
	   cast(last_value as NUMBER(38,0)) as LAST_NUMBER
from get_sequences(' and usename = CAST("CURRENT_USER"() AS CHARACTER VARYING(63 BYTE))')
as
(usename name,
seqname name,
last_value bigint,
increment_by bigint,
max_value bigint,
min_value bigint,
cache_value bigint,
log_cnt bigint,
is_cycled boolean,
is_called boolean);


REVOKE ALL ON dba_sequences FROM PUBLIC;
GRANT SELECT ON all_sequences TO PUBLIC;
GRANT SELECT ON user_sequences TO PUBLIC;

-- Compatible with ORACLE, add DBA_CONSTRAINTS view
CREATE OR REPLACE  VIEW DBA_CONSTRAINTS AS
SELECT (sys_get_userbyid(c.relowner))::CHARACTER VARYING(63 BYTE) AS "OWNER" ,
(cs1.CONNAME)::CHARACTER VARYING(63 BYTE) AS CONSTRAINT_NAME,
(
   	CASE WHEN (cs1.CONTYPE = 'c'::"CHAR") THEN 'C'::TEXT
  	     WHEN (cs1.CONTYPE = 'p'::"CHAR") THEN 'P'::TEXT
         WHEN (cs1.CONTYPE = 'u'::"CHAR") THEN 'U'::TEXT
         WHEN (cs1.CONTYPE = 'f'::"CHAR") THEN 'R'::TEXT ELSE NULL::TEXT
    END
)::CHARACTER VARYING(1 BYTE) AS CONSTRAINT_TYPE,
(C.RELNAME)::CHARACTER VARYING(63 BYTE) AS TABLE_NAME,
cs1.CONSRC AS SEARCH_CONDITION,
sys_GET_USERBYID(c_ref.RELOWNER)::CHARACTER VARYING(63 BYTE) AS R_OWNER,
(
	cs2.conname::CHARACTER VARYING(63 BYTE)
) AS R_CONSTRAINT_NAME,
  (
  	CASE WHEN (cs1.CONFDELTYPE = 'a'::"CHAR") THEN 'NO ACTION'::TEXT
      	WHEN (cs1.CONFDELTYPE = 'c'::"CHAR") THEN 'CASCADE'::TEXT
      	WHEN (cs1.CONFDELTYPE = 'r'::"CHAR") THEN 'RESTRICT'::TEXT
      	WHEN (cs1.CONFDELTYPE = 'n'::"CHAR") THEN 'SET NULL'::TEXT
      	WHEN (cs1.CONFDELTYPE = 'd'::"CHAR") THEN 'SET DEFAULT'::TEXT
      	ELSE NULL::TEXT END
  )::CHARACTER VARYING(9 BYTE) AS DELETE_RULE,
(
    CASE WHEN (cs1.CONTYPE = 'f'::"CHAR") THEN
    (
        SELECT DISTINCT (CASE WHEN (TRG.TGENABLED=true) THEN 'ENABLED'::TEXT
                                ELSE 'DISABLED'::TEXT END )
        FROM sys_TRIGGER TRG
        WHERE  TRG.TGCONSTRAINT = cs1.OID
    )
      WHEN (cs1.CONTYPE = 'p'::"CHAR" OR cs1.CONTYPE = 'u'::"CHAR") THEN
      (
	         SELECT (CASE WHEN (IND.INDISVALID=false) THEN 'ENABLED'::TEXT
	                       ELSE  'DISABLED'::TEXT END )
           	  FROM sys_INDEX IND,sys_DEPEND DEP
	         WHERE DEP.REFOBJID=cs1.OID
           	  AND DEP.CLASSID='sys_CLASS'::REGCLASS
	         AND EXISTS (SELECT * FROM sys_CLASS WHERE OID=DEP.OBJID AND RELKIND='i')
	         AND IND.INDEXRELID=DEP.OBJID
      )
      WHEN (cs1.CONTYPE = 'c'::"CHAR") THEN
	  (
			CASE WHEN (cs1.CONvalidated = 'f') THEN 'DISABLE'::TEXT
			ELSE 'ENABLE'::TEXT END
	  )
	  END
)::CHARACTER VARYING(8 BYTE) AS "STATUS",
  (
     	CASE WHEN (cs1.CONDEFERRABLE = false) THEN 'NOT DEFERRABLE'::TEXT
     	ELSE 'DEFERRABLE'::TEXT END
   )::CHARACTER VARYING(14 CHAR) AS "DEFERRABLE",
  (
     	CASE WHEN (cs1.CONDEFERRED = false) THEN 'IMMEDIATE'::TEXT
     	ELSE 'DEFERRED'::TEXT END
  )::CHARACTER VARYING(9 CHAR) AS "DEFERRED",
(
  CASE WHEN (cs1.CONVALIDATEd ='t') THEN 'VALIDATED'::TEXT
       WHEN (cs1.CONVALIDATEd ='f') THEN 'NOVALIDATED'::TEXT
      ELSE NULL::TEXT END
)::CHARACTER VARYING(13 BYTE) AS "VALIDATED",
  'USER NAME'::CHARACTER VARYING(14 BYTE) AS GENERATED,
  NULL::CHARACTER VARYING(3 CHAR) AS BAD,
  NULL::CHARACTER VARYING(4 CHAR) AS RELY,
  NULL::TIMESTAMP(0) WITHOUT TIME ZONE AS LAST_CHANGE,
(
	CASE WHEN (cs1.CONTYPE = 'p' OR cs1.CONTYPE = 'u') THEN
		(
			SELECT sys_get_userbyid(t.relowner) FROM sys_INDEX IND, sys_CLASS T, sys_DEPEND DEP
			WHERE INDEXRELID = DEP.OBJID
			AND DEP.REFOBJID = cs1.OID
			AND T.OID = IND.INDEXRELID
		)
	ELSE
		NULL
	END
 )::CHARACTER VARYING(63 BYTE) AS "INDEX_OWNER",
 (
	CASE WHEN (cs1.CONTYPE = 'p' OR cs1.CONTYPE = 'u') THEN
		(
			SELECT T.RELNAME FROM sys_INDEX IND ,sys_CLASS T,sys_DEPEND DEP
			WHERE INDEXRELID = DEP.OBJID
			AND DEP.REFOBJID = cs1.OID
			AND T.OID = IND.INDEXRELID
		)
	ELSE
		NULL
	END
 )::CHARACTER VARYING(63 BYTE) AS "INDEX_NAME",
 NULL::CHARACTER VARYING(7 BYTE) AS INVALID,
  NULL::CHARACTER VARYING(14 BYTE) AS VIEW_RELATED
from( sys_constraint cs1 left outer join sys_constraint cs2 on
		(
			cs1.confrelid = cs2.conrelid and
			(cs2.contype = 'u' or cs2.contype = 'p') and  /* show only keys which can keep rows unique. */
			cs1.contype = 'f' and /* only foreign key make r_constraint_name not null */
			cs2.conkey = cs1.confkey	/* Does cs2.conname make the foreign key(cs1.conname) values unique? */
		)
	)
	-- The outer join bellowing is used to get the referenced relation's information.
	left outer join sys_class c_ref on cs1.confrelid = c_ref.oid
	,
	sys_class c
WHERE cs1.CONRELID = C.OID;

REVOKE ALL ON dba_constraints FROM PUBLIC;

create or replace function get_trigger_column(relid oid, tgattr int[])
returns text as
declare
retval text;
ndims   int;
i   int;
colname text;
begin
   retval := '';
  ndims = array_length(tgattr, 1);
  if (ndims is not null) then

  for i in 1.. ndims loop
     select attname into colname from sys_attribute where attrelid = relid and attnum = tgattr[i-1];
     retval := retval || colname;
     if (i != ndims) then
        retval := retval || ',';
     end if;
  end loop;
  end if;
  return retval;
end;


--dba_triggers
create or replace view dba_triggers as
select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(t.tgname as character varying(63 BYTE)) as TRIGGER_NAME,
	cast((case (t.tgtype&66)
	when 2 then(case t.tgtype&1 when 0 then 'BEFORE STATEMENT' else 'BEFORE EACH ROW' end)
	when 0 then(case t.tgtype&1 when 0 then 'AFTER STATEMENT' else 'AFTER EACH ROW' end)
	end) as character varying(16 byte)) as TRIGGER_TYPE,
	cast((case (t.tgtype&28)
	when 4 then 'INSERT'
	when 8 then 'DELETE'
	when 16 then 'UPDATE'
	when 12 then 'INSERT DELETE'
	when 20 then 'INSERT UPDATE'
	when 24 then 'DELETE UPDATE'
	when 28 then 'INSERT DELETE UPDATE'
	end) as character varying(216 byte)) as TRIGGERING_EVENT,
	cast(a.usename as character varying(63 BYTE)) as TABLE_OWNER,
	cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
	cast(get_trigger_column(c.oid, cast(t.tgattr as int[])) as character varying(4000 char)) as COLUMN_NAME,
	cast ((case t.tgenabled
		when 't' then 'ENABLED'
		when 'f' then 'DISABLED'
	end) as character varying(8 byte)) as STATUS,
	cast((sys_GET_TRIGGERDEF(t.OID)) as text) as TRIGGER_BODY
	from sys_trigger t, sys_class c, sys_user a
	where t.tgrelid = c.oid and c.relowner = a.usesysid;


--all_triggers
create or replace view all_triggers as
select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(t.tgname as character varying(63 BYTE)) as TRIGGER_NAME,
	cast((case (t.tgtype&66)
	when 2 then(case t.tgtype&1 when 0 then 'BEFORE STATEMENT' else 'BEFORE EACH ROW' end)
	when 0 then(case t.tgtype&1 when 0 then 'AFTER STATEMENT' else 'AFTER EACH ROW' end)
	end) as character varying(16 byte)) as TRIGGER_TYPE,
	cast((case (t.tgtype&28)
	when 4 then 'INSERT'
	when 8 then 'DELETE'
	when 16 then 'UPDATE'
	when 12 then 'INSERT DELETE'
	when 20 then 'INSERT UPDATE'
	when 24 then 'DELETE UPDATE'
	when 28 then 'INSERT DELETE UPDATE'
	end) as character varying(216 byte)) as TRIGGERING_EVENT,
	cast(a.usename as character varying(63 BYTE)) as TABLE_OWNER,
	cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
	cast(get_trigger_column(c.oid, cast(t.tgattr as int[])) as character varying(4000 char)) as COLUMN_NAME,
	cast ((case t.tgenabled
		when 't' then 'ENABLED'
		when 'f' then 'DISABLED'
	end) as character varying(8 byte)) as STATUS,
	cast((sys_GET_TRIGGERDEF(t.OID)) as text) as TRIGGER_BODY
	from sys_trigger t, sys_class c, sys_user a
	where t.tgrelid = c.oid and c.relowner = a.usesysid
	and (has_table_privilege(c.oid,'SELECT')
           or has_table_privilege(c.oid,'INSERT')
           or has_table_privilege(c.oid,'UPDATE')
           or has_table_privilege(c.oid,'DELETE')
           or has_table_privilege(c.oid,'REFERENCES')
           or has_table_privilege(c.oid,'TRIGGER'));

--user_triggers
create or replace view user_triggers as
select
	cast(t.tgname as character varying(63 BYTE)) as TRIGGER_NAME,
	cast((case (t.tgtype&66)
	when 2 then(case t.tgtype&1 when 0 then 'BEFORE STATEMENT' else 'BEFORE EACH ROW' end)
	when 0 then(case t.tgtype&1 when 0 then 'AFTER STATEMENT' else 'AFTER EACH ROW' end)
	end) as character varying(16 byte)) as TRIGGER_TYPE,
	cast((case (t.tgtype&28)
	when 4 then 'INSERT'
	when 8 then 'DELETE'
	when 16 then 'UPDATE'
	when 12 then 'INSERT DELETE'
	when 20 then 'INSERT UPDATE'
	when 24 then 'DELETE UPDATE'
	when 28 then 'INSERT DELETE UPDATE'
	end) as character varying(216 byte)) as TRIGGERING_EVENT,
	cast(a.usename as character varying(63 BYTE)) as TABLE_OWNER,
	cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
	cast(get_trigger_column(c.oid, cast(t.tgattr as int[])) as character varying(4000 char)) as COLUMN_NAME,
	cast ((case t.tgenabled
		when 't' then 'ENABLED'
		when 'f' then 'DISABLED'
	end) as character varying(8 byte)) as STATUS,
	cast((sys_GET_TRIGGERDEF(t.OID)) as text) as TRIGGER_BODY
	from sys_trigger t, sys_class c, sys_user a
	where t.tgrelid = c.oid and c.relowner = a.usesysid and a.usename = CAST(CURRENT_USER AS CHARACTER VARYING(63 BYTE));


REVOKE ALL ON dba_triggers FROM PUBLIC;
GRANT SELECT ON all_triggers TO PUBLIC;
GRANT SELECT ON user_triggers TO PUBLIC;

--dba_source
create or replace view dba_source as
(select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(p.proname as character varying(63 BYTE)) as NAME,
	cast((case p.protype when 'p' then 'PROCEDURE' when 'f' then 'FUNCTION' end)as character varying(12 byte)) as TYPE,
	cast(p.prosrc as character varying(4000 char)) as TEXT
	from sys_proc p, sys_user a
	where p.proowner = a.usesysid and
	p.pronamespace in (select oid from sys_namespace where nspparent = 0))
UNION ALL
(select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(p.pkgname as character varying(63 BYTE)) as NAME,
	cast('PACKAGE' as character varying(12 byte)) as TYPE,
	cast(p.pkgspecsrc as character varying(4000 char)) as TEXT
	from sys_package p, sys_user a
	where p.pkgowner = a.usesysid)
UNION ALL
(select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(p.pkgname as character varying(63 BYTE)) as NAME,
	cast('PACKAGE BODY' as character varying(12 byte)) as TYPE,
	cast(p.pkgbodysrc as character varying(4000 char)) as TEXT
	from sys_package p, sys_user a
	where p.pkgowner = a.usesysid and p.pkgbodysrc is not null)
UNION ALL
(select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(t.tgname as character varying(63 BYTE)) as NAME,
	cast( 'TRIGGER' as character varying(12 byte)) as TYPE,
	cast(sys_GET_TRIGGERDEF(t.OID) as character varying(4000 char)) as TEXT
	from  sys_trigger t, sys_user a, sys_proc p
	where t.tgfoid = p.oid and p.proowner = a.usesysid
);


create or replace view all_source as
(select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(p.proname as character varying(63 BYTE)) as NAME,
	cast((case p.protype when 'p' then 'PROCEDURE' when 'f' then 'FUNCTION' end)as character varying(12 byte)) as TYPE,
	cast(p.prosrc as character varying(4000 char)) as TEXT
	from sys_proc p, sys_user a
	where p.proowner = a.usesysid and
    (a.usename = CAST(current_user AS VARCHAR(63 BYTE))
     or has_function_privilege(p.oid, 'EXECUTE')) and
    p.pronamespace in (select oid from sys_namespace where nspparent = 0)
)
UNION ALL
(select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(p.pkgname as character varying(63 BYTE)) as NAME,
	cast('PACKAGE' as character varying(12 byte)) as TYPE,
	cast(p.pkgspecsrc as character varying(4000 char)) as TEXT
	from sys_package p, sys_user a
	where p.pkgowner = a.usesysid and
	      (a.usename = CAST(current_user AS VARCHAR(63 BYTE))
         or has_package_privilege(p.oid, 'EXECUTE'))
)
UNION ALL
(select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(p.pkgname as character varying(63 BYTE)) as NAME,
	cast('PACKAGE BODY' as character varying(12 byte)) as TYPE,
	cast(p.pkgbodysrc as character varying(4000 char)) as TEXT
	from sys_package p, sys_user a
	where p.pkgowner = a.usesysid and
	      (a.usename = CAST(current_user AS VARCHAR(63 BYTE))
         or has_package_privilege(p.oid, 'EXECUTE')) and
           p.pkgbodysrc is not null
)
UNION ALL
(select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(t.tgname as character varying(63 BYTE)) as NAME,
	cast( 'TRIGGER' as character varying(12 byte)) as TYPE,
	cast(sys_GET_TRIGGERDEF(t.OID) as character varying(4000 char)) as TEXT
	from  sys_trigger t, sys_user a, sys_proc p, sys_class c
	where t.tgfoid = p.oid and p.proowner = a.usesysid and t.tgrelid = c.oid
	and (has_table_privilege(c.oid,'SELECT')
           or has_table_privilege(c.oid,'INSERT')
           or has_table_privilege(c.oid,'UPDATE')
           or has_table_privilege(c.oid,'DELETE')
           or has_table_privilege(c.oid,'REFERENCES')
           or has_table_privilege(c.oid,'TRIGGER'))
);

--user_source
create or replace view user_source as
select * from dba_source where owner = CAST(CURRENT_USER AS CHARACTER VARYING(63 BYTE));


REVOKE ALL ON dba_source FROM PUBLIC;
GRANT SELECT ON all_source TO PUBLIC;
GRANT SELECT ON user_source TO PUBLIC;

--dba_tablespace
create or replace view dba_tablespace as
select
	cast(ts.spcname as varchar(63 BYTE)) as TABLESPACE_NAME,
	cast(8 as NUMBER )as INITIALEXTENT,
	cast(8 as NUMBER )as NEXT_EXTENT,
	cast(8 as NUMBER) as MIN_EXTENTS,
	cast(NULl as NUMBER ) as MAX_EXTENTS,
	cast(NULL as NUMBER )as PCT_INCREASE,
	cast(8 as NUMBER ) as MIN_EXTLEN,
	cast('ONLINE' as varchar(9 byte)) as STATUS,
	cast('PERMANENT' as varchar(9 byte)) as CONTENTS,
	cast('LOGGING' as varchar(9 byte)) as LOGGING,
	cast('LOCAL'as varchar(10 byte)) as EXTENT_MANAGEMENT,
	cast( 'SYSTEM' as varchar(9 byte)) as ALLOCATION_TYPE,
	cast('NO' as varchar(3 byte)) as PLUGGED_IN
	from sys_tablespace ts;

--dba_tablespaces
create or replace view dba_tablespaces as
select * from dba_tablespace;


--user_tablespace
create or replace view user_tablespace as
select
	cast(ts.spcname as character varying(63 BYTE)) as TABLESPACE_NAME,
	cast(8 as NUMBER)as INITIALEXTENT,
	cast(8 as NUMBER)as NEXT_EXTENT,
	cast(8 as NUMBER) as MIN_EXTENTS,
	cast(NULL as NUMBER) 	as MAX_EXTENTS,
	cast(NULL as NUMBER)as PCT_INCREASE,
	cast(8 as NUMBER) as MIN_EXTLEN,
	cast('ONLINE' as character varying(9 byte))as STATUS,
	cast('PERMANENT' as character varying(9 byte)) as CONTENTS,
	cast('LOGGING' as character varying(9 byte)) as LOGGING,
	cast('LOCAL'as character varying(10 byte)) as EXTENT_MANAGEMENT,
	cast('SYSTEM' as character varying(9 byte)) as ALLOCATION_TYPE
from sys_tablespace ts, sys_user a
where ts.spcowner = a.usesysid and a.usename = CAST(CURRENT_USER AS CHARACTER VARYING(63 BYTE));

--user_tablespaces
create or replace view user_tablespaces as
select * from user_tablespace;

REVOKE ALL ON dba_tablespace FROM PUBLIC;
REVOKE ALL ON dba_tablespaces FROM PUBLIC;
GRANT SELECT ON user_tablespace TO PUBLIC;
GRANT SELECT ON user_tablespaces TO PUBLIC;

--all_users
create or replace view all_users as
select cast(usename as varchar(63 BYTE)) as username,
       cast(cast(usesysid as bigint) as number(38,0)) as user_id,
       cast(null as date) as CREATED
from sys_user
where has_database_privilege(current_database(), 'CONNECT');

--user_users
create or replace view user_users as
select
cast(usename as varchar(63 BYTE)) as USERNAME,
cast(cast (usesysid as bigint) as number(38,0)) as USER_ID,
CAST(CASE WHEN CURRENT_TIMESTAMP <= (case VALUNTIL when null then CURRENT_TIMESTAMP end )
THEN 'OPEN' ELSE 'EXPIRED' END AS VARCHAR(32 BYTE)) as ACCOUNT_STATUS,
CAST(NULL AS DATE) as LOCK_DATE,
CAST(VALUNTIL AS DATE) as EXPIRY_DATE,
CAST('database default tablespace' AS VARCHAR(63 BYTE)) as DEFAULT_TABLESPACE,
CAST(NULL AS VARCHAR(63 BYTE)) as TEMPORARY_TABLESPACE,
CAST(NULL AS DATE) as CREATED,
CAST(NULL AS VARCHAR(63 BYTE)) as INITIAL_RSRC_CONSUMER_GROUP,
CAST(NULL AS VARCHAR(63 BYTE)) as EXTERNAL_NAME
FROM sys_user
WHERE sys_user.usename = CURRENT_USER;

GRANT SELECT ON all_users TO PUBLIC;
GRANT SELECT ON user_users TO PUBLIC;

--dba_tab_privs
create or replace view dba_tab_privs as
SELECT     CAST(grantee.rolname AS character varying(63 BYTE)) AS grantee,
           CAST(u_owner.usename AS character varying(63 BYTE)) AS owner,
           CAST(c.relname AS character varying(63 BYTE)) AS table_name,
           CAST(u_grantor.usename AS character varying(63 BYTE)) AS grantor,
           CAST(pr.type AS character varying(40 char)) AS privilege,
           CAST(
             CASE WHEN aclcontains(c.relacl,
                                   makeaclitem(grantee.oid, u_grantor.usesysid, pr.type, true))
                  THEN 'YES' ELSE 'NO' END AS character varying(3 byte)) AS grantable
FROM     sys_class c,
         sys_user u_owner,
         sys_user u_grantor,
         ( SELECT usesysid, usename FROM sys_user
           UNION ALL
           SELECT 0::oid,'PUBLIC'
         ) AS grantee (oid, rolname),
         (SELECT 'SELECT' UNION ALL
          SELECT 'INSERT' UNION ALL
          SELECT 'UPDATE' UNION ALL
          SELECT 'REFERENCES') AS pr (type)
where     c.relowner=u_owner.usesysid
          AND c.relkind IN ('r', 'v')
          AND aclcontains(c.relacl,
          makeaclitem(grantee.oid, u_grantor.usesysid, pr.type, false));


--all_tab_privs
create or replace view all_tab_privs as
SELECT   dba_tab_privs.*
FROM dba_tab_privs
WHERE     grantee='PUBLIC'
         OR grantor=cast(current_user as varchar2(63 BYTE))
	       OR grantee=cast(current_user as varchar2(63 BYTE))
		     OR owner=cast(current_user as varchar2(63 BYTE))
          OR grantee in (select r.rolname from sys_authid r,sys_authid u, sys_auth_members m
                         where u.rolname = current_role and u.oid = m.member and m.roleid = r.oid
                         UNION ALL
                         select cast(current_role as varchar2(63 BYTE)));

--user_tab_privs
create or replace view user_tab_privs as
SELECT dba_tab_privs.* FROM dba_tab_privs
WHERE grantor=cast(current_user as varchar2(63 BYTE))
	      OR grantee=cast(current_user as varchar2(63 BYTE))
		  OR owner=cast(current_user as varchar2(63 BYTE));

REVOKE ALL ON dba_tab_privs FROM PUBLIC;
GRANT SELECT ON all_tab_privs TO PUBLIC;
GRANT SELECT ON user_tab_privs TO PUBLIC;


--dba_cons_columns
create or replace view dba_cons_columns as
select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(ct.conname as character varying(63 BYTE)) as CONSTRAINT_NAME,
	cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
	cast(attr.attname as character varying(4000 char)) as COLUMN_NAME,
	cast(attr.attnum as number) as POSITION
	from sys_constraint ct, sys_class c, sys_user a, sys_attribute attr
	where ct.conrelid = c.oid and c.relowner = a.usesysid
	and attr.attrelid = c.oid and ARRAY[attr.attnum] <@ ct.conkey;

--all_cons_columns
create or replace view all_cons_columns as
select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(ct.conname as character varying(63 BYTE)) as CONSTRAINT_NAME,
	cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
	cast(attr.attname as character varying(4000 char)) as COLUMN_NAME,
	cast(attr.attnum as number) as POSITION
	from sys_constraint ct, sys_class c, sys_user a, sys_attribute attr
	where ct.conrelid = c.oid and c.relowner = a.usesysid
	and attr.attrelid = c.oid and ARRAY[attr.attnum] <@ ct.conkey
	and (has_table_privilege(c.oid,'SELECT')
           or has_table_privilege(c.oid,'INSERT')
           or has_table_privilege(c.oid,'UPDATE')
           or has_table_privilege(c.oid,'DELETE')
           or has_table_privilege(c.oid,'REFERENCES')
           or has_table_privilege(c.oid,'TRIGGER'));

--user_cons_columns
create or replace view user_cons_columns as
select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(ct.conname as character varying(63 BYTE)) as CONSTRAINT_NAME,
	cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
	cast(attr.attname as character varying(4000 char)) as COLUMN_NAME,
	cast(attr.attnum as number) as POSITION
	from sys_constraint ct, sys_class c, sys_user a, sys_attribute attr
	where ct.conrelid = c.oid and c.relowner = a.usesysid
	and attr.attrelid = c.oid and ARRAY[attr.attnum] <@ ct.conkey
	and a.usename = CAST(CURRENT_USER AS CHARACTER VARYING(63 BYTE));

REVOKE ALL ON dba_cons_columns FROM PUBLIC;
GRANT SELECT ON all_cons_columns TO PUBLIC;
GRANT SELECT ON user_cons_columns TO PUBLIC;

--dba_data_file
create or replace function getBlockSize()
returns int
immutable
as
 res int;
begin
   select cast (setting as int) into res from sys_settings where name='block_size';
   return res;
end;


create or replace view dba_roles as
select
	cast(a.rolname as character varying(63 BYTE)) as role,
	cast(case a.rolpassword when null then 'NO' else 'YES' end  as character varying(8 byte)) as PASSWORD_REQUIRED
    FROM sys_authid a
    where a.rolcanlogin='t';

REVOKE ALL ON dba_roles FROM PUBLIC;

--dba_role_privs
create or replace view dba_role_privs as
SELECT cast(SAI.ROLNAME as character varying(63 BYTE)) AS GRANTEE,
       cast(SA.ROLNAME as character varying(63 BYTE))AS GRANTED_ROLE,
       cast(case SAM.ADMIN_OPTION when true then 'YES' else 'NO' end as character varying(3 byte)) AS ADMIN_OPTION,
       cast('NO' as character varying(3 byte)) AS DEFAULT_ROLE
FROM sys_AUTHID SA, sys_AUTHID SAI, sys_AUTH_MEMBERS SAM
WHERE SA.OID=SAM.grantor
      AND SAI.OID=SAM.ROLEID;


--user_role_privs
create or replace view user_role_privs as
SELECT cast(SAI.ROLNAME as character varying(63 BYTE)) AS GRANTEE,
       cast(SA.ROLNAME as character varying(63 BYTE))AS GRANTED_ROLE,
       cast(case SAM.ADMIN_OPTION when true then 'YES' else 'NO' end as character varying(3 byte)) AS ADMIN_OPTION,
       cast( 'NO' as character varying(3 byte)) AS DEFAULT_ROLE
FROM sys_roles SA, sys_roles SAI, sys_AUTH_MEMBERS SAM
WHERE SA.OID=SAM.grantor
      AND SAI.OID=SAM.ROLEID
	  and SAI.rolname = CAST(CURRENT_USER AS CHARACTER VARYING(63 BYTE));

REVOKE ALL ON dba_role_privs FROM PUBLIC;
GRANT SELECT ON user_role_privs TO PUBLIC;

--dba_tab_comments
create or replace view dba_tab_comments as
select cast(au.usename as character varying(63 BYTE)) as OWNER,
       cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
       cast((case c.relkind when 'r' then 'TABLE' when 'v' then 'VIEW' else 'TABLE' end) as character varying(11 byte)) as TABLE_TYPE,
       cast(d.DESCRIPTION as character varying(4000 char)) as COMMENTS
 FROM  sys_CLASS C, sys_DESCRIPTION d, sys_user au
 where c.oid = d.objoid and d.classoid = 1259
      and d.objsubid=0
      and c.relowner=au.usesysid
      and c.relkind in ('r','v');

--all_tab_comments
create or replace view all_tab_comments as
select cast(au.usename as character varying(63 BYTE)) as OWNER,
       cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
       cast((case c.relkind when 'r' then 'TABLE' when 'v' then 'VIEW' else 'TABLE' end) as character varying(11 byte)) as TABLE_TYPE,
       cast(d.DESCRIPTION as character varying(4000 char)) as COMMENTS
 FROM  sys_CLASS C, sys_DESCRIPTION d, sys_user au
 where c.oid = d.objoid and d.classoid = 1259
      and d.objsubid=0
      and c.relowner=au.usesysid
      and c.relkind in ('r','v')
	  and (has_table_privilege(c.oid,'SELECT')
           or has_table_privilege(c.oid,'INSERT')
           or has_table_privilege(c.oid,'UPDATE')
           or has_table_privilege(c.oid,'DELETE')
           or has_table_privilege(c.oid,'REFERENCES')
           or has_table_privilege(c.oid,'TRIGGER'));

--user_tab_comments
create or replace view user_tab_comments as
select cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
       cast((case c.relkind when 'r' then 'TABLE' when 'v' then 'VIEW' else 'TABLE' end) as character varying(11 byte)) as TABLE_TYPE,
       cast(d.DESCRIPTION as character varying(4000 char)) as COMMENTS
FROM  sys_CLASS C, sys_DESCRIPTION d, sys_USER au
where c.oid = d.objoid and d.classoid = 1259
      and d.objsubid=0
      and c.relowner=au.usesysid
      and c.relkind in ('r','v')
	  and au.usename = CAST(CURRENT_USER AS CHARACTER VARYING(63 BYTE));

REVOKE ALL ON dba_tab_comments FROM PUBLIC;
GRANT SELECT ON all_tab_comments TO PUBLIC;
GRANT SELECT ON user_tab_comments TO PUBLIC;


--dba_col_comments
create or replace view dba_col_comments as
select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
    cast(at.ATTNAME as character varying(63 BYTE)) AS COLUMN_NAME,
    cast(d.DESCRIPTION as character varying(4000 char)) AS COMMENTS
FROM sys_user a, sys_CLASS c, sys_ATTRIBUTE at left join sys_DESCRIPTION d on (
   d.classoid = 1259 and d.objoid=at.attrelid and at.attnum=d.objsubid)
WHERE at.attrelid = c.oid
      and at.attnum > 0 and at.attisdropped = false
      and c.relkind in ('r','v')
	  and c.relowner = a.usesysid;


--all_col_comments
create or replace view all_col_comments as
select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
    cast(at.ATTNAME as character varying(63 BYTE)) AS COLUMN_NAME,
    cast(d.DESCRIPTION as character varying(4000 char)) AS COMMENTS
	FROM sys_USER a, sys_CLASS c, sys_ATTRIBUTE at left join sys_DESCRIPTION d on ( d.classoid = 1259
      and at.attnum=d.objsubid and d.objoid=at.attrelid )
	WHERE at.attrelid = c.oid
      and c.relkind in ('r','v')
	  and c.relowner = a.usesysid
	  and at.attnum > 0 and at.attisdropped = false
	  and (has_table_privilege(c.oid,'SELECT')
           or has_table_privilege(c.oid,'INSERT')
           or has_table_privilege(c.oid,'UPDATE')
           or has_table_privilege(c.oid,'DELETE')
           or has_table_privilege(c.oid,'REFERENCES')
           or has_table_privilege(c.oid,'TRIGGER'));

--user_col_comments
create or replace view user_col_comments as
select
	cast(a.usename as character varying(63 BYTE)) as OWNER,
	cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
    cast(at.ATTNAME as character varying(63 BYTE)) AS COLUMN_NAME,
    cast(d.DESCRIPTION as character varying(4000 char)) AS COMMENTS
FROM sys_USER a, sys_CLASS c, sys_ATTRIBUTE at left join sys_DESCRIPTION d on (
    d.classoid = 1259 and d.objoid=at.attrelid and at.attnum=d.objsubid)
	WHERE at.attrelid = c.oid
      and c.relkind in ('r','v')
      and at.attnum > 0 and at.attisdropped = false
	  and c.relowner = a.usesysid
	  and a.usename = CAST(CURRENT_USER AS CHARACTER VARYING(63 BYTE));


REVOKE ALL ON dba_col_comments FROM PUBLIC;
GRANT SELECT ON all_col_comments TO PUBLIC;
GRANT SELECT ON user_col_comments TO PUBLIC;

--dba_trigger_cols
create or replace view dba_trigger_cols as
select
	cast(a.usename as character varying(63 BYTE)) as TRIGGER_OWNER,
	cast(tg.tgname as character varying(63 BYTE)) as TRIGGER_NAME,
	cast(a.usename as character varying(63 BYTE)) as TABLE_OWNER,
	cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
	cast(get_trigger_column(tg.tgrelid, cast(tg.tgattr as int[])) as character varying(4000 char)) as COLUMN_NAME
	from sys_trigger tg, sys_class c, sys_user  a
	where tg.tgrelid = c.oid and c.relowner = a.usesysid ;

--all_trigger_cols
create or replace view all_trigger_cols as
select
	cast(a.usename as character varying(63 BYTE)) as TRIGGER_OWNER,
	cast(tg.tgname as character varying(63 BYTE)) as TRIGGER_NAME,
	cast(a.usename as character varying(63 BYTE)) as TABLE_OWNER,
	cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
	cast(get_trigger_column(tg.tgrelid, cast(tg.tgattr as int[])) as character varying(4000 char)) as COLUMN_NAME
	from sys_trigger tg, sys_class c, sys_user a
	where tg.tgrelid = c.oid and c.relowner = a.usesysid
		and (has_table_privilege(c.oid,'SELECT')
           or has_table_privilege(c.oid,'INSERT')
           or has_table_privilege(c.oid,'UPDATE')
           or has_table_privilege(c.oid,'DELETE')
           or has_table_privilege(c.oid,'REFERENCES')
           or has_table_privilege(c.oid,'TRIGGER'));

--user_trigger_cols
create or replace view user_trigger_cols as
select
	cast(a.usename as character varying(63 BYTE)) as TRIGGER_OWNER,
	cast(tg.tgname as character varying(63 BYTE)) as TRIGGER_NAME,
	cast(a.usename as character varying(63 BYTE)) as TABLE_OWNER,
	cast(c.relname as character varying(63 BYTE)) as TABLE_NAME,
	cast(get_trigger_column(tg.tgrelid, cast(tg.tgattr as int[])) as character varying(4000 char)) as COLUMN_NAME
	from sys_trigger tg, sys_class c, sys_user a
	where tg.tgrelid = c.oid and c.relowner = a.usesysid
	and a.usename = CAST(CURRENT_USER AS CHARACTER VARYING(63 BYTE));

REVOKE ALL ON dba_trigger_cols FROM PUBLIC;
GRANT SELECT ON all_trigger_cols TO PUBLIC;
GRANT SELECT ON user_trigger_cols TO PUBLIC;

--dynamic view
--V$DATABASE
create or replace function get_log_mode()
returns record as
declare
	mode cursor for show archive_mode;
	rec record;
begin
	open mode;
	fetch mode into rec;
	close mode;
	return rec;
end;


create or replace view V$DATABASE as
select
	cast(cast(db.oid as bigint) as number(38,0)) as DBID,
	cast(db.datname as character varying(63 BYTE)) as NAME,
	cast(null as date) as CREATED,
	cast((case when 'off'=(select * from get_log_mode() as (status text)) then 'NOARCHIVELOG' else 'ARCHIVELOG' end) as character varying(12 byte)) as LOG_MODE,
	cast(0 as number) as CHECKPOINT_CHANGE,
	cast(NULL as date) as CONTROLFILE_TIME,
	cast('READ WRITE' as character varying(10 byte)) as OPEN_MODE,
	cast(0 as number) as ARCHIVELOG_CHANGE,
	cast(0 as number) as CURRENT_SCN,
	cast(CAST(4294967295 AS NUMBER(38,0))*32*1024*1024*1024*1024 as number(38,0)) as MAX_SIZE,
	cast(sys_database_size(db.oid) as number(38,0)) as TOTAL_SIZE,
	cast('ONLINE' as character varying(10 byte)) as STATUS$
	from sys_database db;

GRANT SELECT ON V$DATABASE TO PUBLIC;

--V$SESSION
create or replace view V$SESSION as
select
	cast(sa.client_addr as character varying(20 byte)) as SADDR,
	cast(sa.pid as number) as SID,
	cast(null as number) as SERIAL#,
	cast(null as number) as AUDSID,
	cast(NULL as character varying(20 byte))as PADDR,
	cast(cast(sa.usesysid as bigint) as number(38,0)) as USER#,
	cast(sa.usename as varchar2(63 BYTE)) as USERNAME,
	cast(NULL as number) as COMMAND,
	cast(null as number) as OWNERID,
	cast(NULL as varchar2(20 byte)) as TADDR,
	cast((case sa.wait_event_type != 'BufferPin'
	when 't' then (select r.relname from sys_locks l, sys_class r where l.pid=sa.pid and l.granted=false and l.relation = r.oid)
	else NULL end) as varchar2(8 byte))as LOCKWAIT,
	cast((case
	when sa.query is null then 'INACTIVE' else 'ACTIVE'
	end)as varchar2(8 byte)) as STATUS,
	cast('SHARED' as varchar2(9 byte)) as SERVER,
	cast(cast(sa.usesysid as bigint) as number(38,0))as SCHEMA#,
	cast(NULL as varchar2(63 BYTE)) as SCHEMANAME,
	cast(NULL as varchar2(63 BYTE)) as OSUSER,
	cast(NULL as varchar2(12 byte)) as PROCESS,
	cast(NULL as varchar2(64 byte)) as MACHINE,
	cast(NULL as varchar2(63 BYTE)) as TERMINAL,
	cast(NULL as varchar2(48 byte)) as PROGRAM,
	cast(NULL as varchar2(10 byte)) as TYPE,
	cast(NULL as character varying(20 byte)) as SQL_ADDRESS,
	cast(NULL as number) as SQL_HASH_VALUE,
	cast(NULL as varchar2(13 byte)) as SQL_ID,
	cast(0 as number) as SQL_CHILD_NUMBER,
	cast(NULL as character varying(20 byte)) as PREV_SQL_ADDR,
	cast(NULL as number) as PREV_HASH_VALUE,
	cast(NULL as varchar2(13 byte)) as PREV_SQL_ID,
	cast(NULL as number) as PREV_CHILD_NUMBER,
	cast(null as varchar2(48)) as MODULE,
	cast(NULL as number) as MODULE_HASH,
	cast(null as varchar2(32)) as ACTION,
	cast(NULL as number) as ACTION_HASH,
	cast(null as varchar2(64)) as CLIENT_INFO,
	cast(NULL as number) as FIXED_TABLE_SEQUENCE,
	cast(NULL as number) as ROW_WAIT_OBJ#,
	cast(NULL as number) as ROW_WAIT_FILE#,
	cast(NULL as number) as ROW_WAIT_BLOCK#,
	cast(NULL as number) as ROW_WAIT_ROW#,
	cast(sa.backend_start as date) as LOGON_TIME,
	cast(NULL as number) as LAST_CALL_ET,
	cast(NULL as varchar2(3)) as PDML_ENABLED,
	cast('NONE' as varchar2(13)) as FAILOVER_TYPE,
	cast('NONE' as varchar2(10)) as FAILOVER_METHOD,
	cast('NO' as varchar2(3)) as FAILED_OVER,
	cast(NULL as varchar2(32)) as RESOURCE_CONSUMER_GROUP,
	cast('DISABLED' as varchar2(8)) as PDML_STATUS,
	cast('DISABLED' as varchar2(8)) as PDDL_STATUS,
	cast('DISABLED' as varchar2(8)) as PQ_STATUS,
	cast(null as number) as CURRENT_QUEUE_DURATION,
	cast(NULL as varchar2(64)) as CLIENT_IDENTIFIER,
	cast('UNKNOWN' as varchar2(11)) as BLOCKING_SESSION_STATUS,
	cast(null as number) as BLOCKING_INSTANCE,
	cast(null as number) as BLOCKING_SESSION,
	cast(null as number) as SEQ#,
	cast(null as number) as EVENT#,
	cast(NULL as varchar2(64)) as EVENT,
	cast(NULL as varchar2(64)) as P1TEXT,
	cast(null as number) as P1,
	cast(NULL as varchar2(20)) as P1RAW,
	cast(NULL as varchar2(64)) as P2TEXT,
	cast(null as number) as P2,
	cast(NULL as varchar2(20)) as P2RAW,
	cast(NULL as varchar2(64)) as P3TEXT,
	cast(null as number) as P3,
	cast(NULL as varchar2(20)) as P3RAW,
	cast(null as number) as WAIT_CLASS_ID,
	cast(null as number) as WAIT_CLASS#,
	cast(NULL as varchar2(64)) as WAIT_CLASS,
	cast(null as number) as WAIT_TIME,
	cast(null as number) as SECONDS_IN_WAIT,
	cast(sa.state as varchar2(19)) as STATE,
	cast(null as number) as SERVICE_NAME,
	cast('DISABLED' as varchar2(8)) as SQL_TRACE,
	cast('FALSE' as varchar2(5)) as SQL_TRACE_WAITS,
	cast('FALSE' as varchar2(5)) as SQL_TRACE_BINDS
	from sys_stat_activity sa;

GRANT SELECT ON V$SESSION TO PUBLIC;

--V$INSTANCE
create or replace view V$INSTANCE as
select
	cast('instance1' as character varying(16 byte)) as INSTANCE_NAME,
	cast(NULL as character varying(64 byte)) as HOST_NAME,
	cast((select version()) as character varying(17 byte)) as VERSION,
	cast(NULL as date) as STARTUP_TIME,
	cast('STARTED' as character varying(12 byte)) as STATUS,
	cast('STOPPED' as character varying(7 byte)) as ARCHIVER,
	cast('ALLOWED' as character varying(10 byte)) as LOGIN,
	cast('NO' as character varying(3 byte)) as SHUTDOWN_PENDING,
	cast('ONLINE' as character varying(17 byte)) as DATABASE_STATUS,
	cast('PRIMARY_INSTANCE' as character varying(18 byte)) as INSTANCE_ROLE,
	cast('NORMAL' as character varying(9 byte)) as ACTIVE_STATE,
	cast('NO' as character varying(3 byte)) as BLOCKED
from dual;

GRANT SELECT ON V$INSTANCE TO PUBLIC;

--V$SYSSTAT

create or replace function sys_stat()
returns setof record as
declare
	i int;
	ret record;
	rec record;
	sqlcmd text;
	statname cursor for select proname from sys_proc where proname like 'sys_STAT_GET_DB%';
	stat refcursor;
	dbname varchar(64);
	dbid oid;
	value int8;
begin
	open stat for select * from current_database();
	fetch stat into dbname;
	close stat;
	sqlcmd:='select oid from sys_database db where db.datname='''||dbname||'''';
	open stat for execute sqlcmd;
	fetch stat into dbid;
	close stat;
	i:=0;
	for rec in statname
	loop
		sqlcmd:='select * from '||rec.proname||'('||dbid||')';
		open stat for execute sqlcmd;
		fetch stat into value;
		select into ret cast(i as number), cast(rec.proname as varchar(63 byte)), cast(value as number);
		close stat;
		i:=i+1;
		return next ret;
	end loop;
end;


create or replace view V$SYSSTAT as
select * from sys_stat() as (STATISTIC# number, NAME varchar(63 byte), VALUE number);

--V$LOCK
create or replace view V$LOCK as
select
	cast(NULL as character varying(16 byte)) as ADDR,
	cast(NULL as character varying(16 byte)) as KADDR,
	cast(l.pid as number) as SID,
	cast((case l.locktype when 'transactionid' then 'TX' when 'userlock' then 'UL'
       else 'TM' end)  as character varying(2 byte)) as TYPE,
	cast(case  l.granted when false then null else( (case l.mode when 'ACCESS SHARE' then 4 when 'ROW SHARE' then 2
        when 'ROW EXCLUSIVE' then 3 when 'EXCLUSIVE' then 6 when 'ACCESS EXCLUSIVE' then 6 when 'SHARE' then 4 else 5 end)  ) end  as number) as LMODE,
	cast(case  l.granted when true then null else( (case l.mode when 'ACCESS SHARE' then 4 when 'ROW SHARE' then 2
        when 'ROW EXCLUSIVE' then 3 when 'EXCLUSIVE' then 6 when 'ACCESS EXCLUSIVE' then 6 when 'SHARE' then 4 else 5 end) )end  as number) as REQUEST,
	cast(NULL as number) as CTIME,
	cast(l.granted as number) as BLOCK
from sys_locks l;

GRANT SELECT ON V$LOCK TO PUBLIC;

--V$PARAMETER
create or replace function get_parameter()
returns setof record as
declare
	ret record;
	param record;
	setting cursor for select * from sys_settings;
	i int;
	isses_modifiable text;
	issys_modifiable text;
	ismodified text;
	typ int;
begin
	i:=1;
	open setting;
	for param in setting loop
  	if param.context='session' then
  	isses_modifiable='TRUE';
  	else
  	isses_modifiable='FALSE';
  	end if;
  	if param.context='system'  then
  	issys_modifiable='TRUE';
  	else
  	issys_modifiable='FALSE';
  	end if;
  	if param.source='default' then
  	ismodified='FALSE';
  	else
  	ismodified='TRUE';
  	end if;
  	if  param.vartype ='bool' then typ:=1;
  	elsif  param.vartype ='string' then typ:=2;
  	elsif param.vartype='integer' then typ:=3;
  	elsif param.vartype='real' then typ:=5;
  	end if;
 
  	select into ret cast(i as number), cast(param.name as varchar(80 byte)), cast(typ as number),
  	cast(param.setting as varchar(512 byte)), cast(param.setting as varchar(512 byte)),
  	cast(isses_modifiable as varchar(5 byte)), cast(issys_modifiable as varchar(9 byte)), cast(ismodified as varchar(10 byte)),
  	cast(param.short_desc as varchar(255 byte));
  
	  i:=i+1;
	  return next ret;
	end loop;
end;

create or replace view V$PARAMETER as
select * from get_parameter()
as(NUM number, NAME varchar(80 byte), TYPE number, VALUE varchar(512 byte), DISPLAY_VALUE varchar(512 byte),
ISSES_MODIFIABLE varchar(5 byte), ISsys_MODIFIALBE varchar(9 byte), ISMODIFIED varchar(10 byte), DESCRIPTION varchar(255 byte));

GRANT SELECT ON V$PARAMETER TO PUBLIC;


create or replace view dba_free_space
AS
SELECT
cast((case c.reltablespace when 0 then 'default' else ts.spcname end) as varchar2(63 BYTE)) as tablespace_name,
cast(cast(c.relfilenode as bigint) as number(38)) as file_id,
cast(fs.blockno as number(38)) as block_id,
cast(fs.avail * cast(getBlockSize() as number(38,0)) as number(38)) as bytes,
cast(c.relpages as number(38)) as blocks,
cast(cast(c.relfilenode as bigint )  as number(38)) as relative_fno
 FROM
 sys_class c, sys_freespaces fs, sys_tablespace ts, sys_namespace ns
 where c.relname = fs.relname and fs.nspname=ns.nspname and c.relnamespace = ns.oid and  (c.reltablespace = ts.oid or c.reltablespace = 0);

REVOKE ALL ON dba_free_space FROM PUBLIC;

create or replace view user_free_space
AS
SELECT
cast((case c.reltablespace when 0 then 'default' else ts.spcname end) as varchar2(63 BYTE)) as tablespace_name,
cast(cast(c.relfilenode as bigint) as number(38)) as file_id,
cast(fs.blockno as number(38)) as block_id,
cast(fs.avail * cast(getBlockSize() as number(38,0)) as number(38)) as bytes,
cast(c.relpages as number(38)) as blocks,
cast(cast(c.relfilenode as bigint )  as number(38)) as relative_fno
 FROM
 sys_class c, sys_freespaces fs, sys_tablespace ts, sys_namespace ns, sys_authid a
 where c.relname = fs.relname and fs.nspname=ns.nspname and c.relnamespace = ns.oid and  (c.reltablespace = ts.oid or c.reltablespace = 0)
	 and c.relowner = a.oid and a.rolname = cast(current_user as varchar(63 byte));

GRANT SELECT ON user_free_space TO PUBLIC;

CREATE OR REPLACE VIEW V$LOCKED_OBJECT AS
SELECT
CAST(null as number) AS XIDUSN,
CAST(null as number) AS XIDSLOT,
CAST(null as number) AS XIDSQN,
CAST(cast(l.objid as bigint) as number) AS OBJECT_ID,
CAST(l.pid as number) AS SESSION_ID,
CAST(a.usename as varchar2(63 BYTE)) AS ORACLE_USERNAME,
CAST(null as varchar2(63 BYTE)) AS OS_USER_NAME,
CAST(null as varchar2(63 BYTE)) AS PROCESS,
cast((case l.mode when 'ACCESS SHARE' then 4 when 'ROW SHARE' then 2
        when 'ROW EXCLUSIVE' then 3 when 'EXCLUSIVE' then 6 when 'ACCESS EXCLUSIVE' then 6 when 'SHARE' then 4 else 5 end)  as number) as LOCKED_MODE
FROM sys_locks l, sys_stat_activity t, sys_user a
WHERE l.granted = true and l.pid = t.pid and t.USESYSID = a.USESYSID;

GRANT SELECT ON V$LOCKED_OBJECT TO PUBLIC;

/*
 * bugId#30412:in order to guid_default_return_type parameter can change
 * the return type of function sys_guid()
 */
create or replace function alter_sys_guid() returns void as
declare
  return_type  text;
  stmt         text;
begin
  select setting into return_type from sys_catalog.sys_settings where name = 'guid_default_return_type';
  if lower(return_type) = 'bytea' then
    stmt = 'DROP FUNCTION IF EXISTS sys_catalog.sys_guid(); CREATE OR REPLACE INTERNAL FUNCTION sys_catalog.sys_guid() RETURNS BYTEA AS $$SELECT sys_catalog.sys_guid_bytea()$$ LANGUAGE sql;';
  else
    stmt = 'DROP FUNCTION IF EXISTS sys_catalog.sys_guid(); CREATE OR REPLACE INTERNAL FUNCTION sys_catalog.sys_guid() RETURNS NAME AS $$SELECT sys_catalog.sys_guid_name()$$ LANGUAGE sql;';
  end if;
  execute stmt;
  return;
end;
select alter_sys_guid();

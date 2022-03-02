/* ------------------------------------------------------------------------
 *
 * init.sql
 *		Creates config table and provides common utility functions
 *
 * Copyright (c) 2015-2016, Postgres Professional
 *
 * ------------------------------------------------------------------------
 */
--kingbase add internal in front of function

/*
 * Takes text representation of interval value and checks if it is corresponds
 * to partitioning key. The function throws an error if it fails to convert
 * text to Datum
 */
CREATE OR REPLACE internal FUNCTION @extschema@.validate_interval_value(
	partrel			REGCLASS,
	expr			TEXT,
	parttype		INTEGER,
	range_interval	TEXT)
RETURNS BOOL AS 'sys_pathman', 'validate_interval_value'
LANGUAGE C;


/*
 * Main config.
 *		partrel			- regclass (relation type, stored as Oid)
 *		expr			- partitioning expression (key)
 *		parttype		- partitioning type: (1 - HASH, 2 - RANGE)
 *		range_interval	- base interval for RANGE partitioning as string
 *		cooked_expr		- cooked partitioning expression (parsed & rewritten)
 */
CREATE TABLE IF NOT EXISTS @extschema@.pathman_config (
	partrel			REGCLASS NOT NULL PRIMARY KEY,
	expr			TEXT NOT NULL,
	parttype		INTEGER NOT NULL,
	range_interval	TEXT DEFAULT NULL,

	/* check for allowed part types */
	CONSTRAINT pathman_config_parttype_check CHECK (parttype IN (1, 2, 3)),

	/* check for correct interval */
	CONSTRAINT pathman_config_interval_check
	CHECK (@extschema@.validate_interval_value(partrel,
											   expr,
											   parttype,
											   range_interval))
);


/*
 * Checks that callback internal FUNCTION meets specific requirements.
 * Particularly it must have the only JSONB argument and VOID return type.
 *
 * NOTE: this internal FUNCTION is used in CHECK CONSTRAINT.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.validate_part_callback(
	callback		REGPROCEDURE,
	raise_error		BOOL DEFAULT TRUE)
RETURNS BOOL AS 'sys_pathman', 'validate_part_callback_pl'
LANGUAGE C STRICT;


/*
 * Optional parameters for partitioned tables.
 *		partrel			- regclass (relation type, stored as Oid)
 *		enable_parent	- add parent table to plan
 *		auto			- enable automatic partition creation
 *		init_callback	- text signature of cb to be executed on partition creation
 *		spawn_using_bgw	- use background worker in order to auto create partitions
 */
CREATE TABLE IF NOT EXISTS @extschema@.pathman_config_params (
	partrel			REGCLASS NOT NULL PRIMARY KEY,
	enable_parent	BOOLEAN NOT NULL DEFAULT FALSE,
	auto			BOOLEAN NOT NULL DEFAULT TRUE,
	init_callback	TEXT DEFAULT NULL,
	spawn_using_bgw	BOOLEAN NOT NULL DEFAULT FALSE

	/* check callback's signature */
	CHECK (@extschema@.validate_part_callback(CASE WHEN init_callback IS NULL
											  THEN 0::REGPROCEDURE
											  ELSE init_callback::REGPROCEDURE
											  END))
);

GRANT SELECT, INSERT, UPDATE, DELETE
ON @extschema@.pathman_config, @extschema@.pathman_config_params
TO public;

/*
 * Check if current user can alter/drop specified relation
 */
CREATE OR REPLACE internal FUNCTION @extschema@.check_security_policy(relation regclass)
RETURNS BOOL AS 'sys_pathman', 'check_security_policy' LANGUAGE C STRICT;

/*
 * Row security policy to restrict partitioning operations to owner and superusers only
 */
CREATE POLICY deny_modification ON @extschema@.pathman_config
FOR ALL USING (check_security_policy(partrel));

CREATE POLICY deny_modification ON @extschema@.pathman_config_params
FOR ALL USING (check_security_policy(partrel));

CREATE POLICY allow_select ON @extschema@.pathman_config FOR SELECT USING (true);

CREATE POLICY allow_select ON @extschema@.pathman_config_params FOR SELECT USING (true);

ALTER TABLE @extschema@.pathman_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE @extschema@.pathman_config_params ENABLE ROW LEVEL SECURITY;

/*
 * Invalidate relcache every time someone changes parameters config or pathman_config
 */
CREATE OR REPLACE internal FUNCTION @extschema@.pathman_config_params_trigger_func()
RETURNS TRIGGER AS 'sys_pathman', 'pathman_config_params_trigger_func'
LANGUAGE C;

CREATE TRIGGER pathman_config_params_trigger
AFTER INSERT OR UPDATE OR DELETE ON @extschema@.pathman_config_params
FOR EACH ROW EXECUTE PROCEDURE @extschema@.pathman_config_params_trigger_func();

CREATE TRIGGER pathman_config_trigger
AFTER INSERT OR UPDATE OR DELETE ON @extschema@.pathman_config
FOR EACH ROW EXECUTE PROCEDURE @extschema@.pathman_config_params_trigger_func();

/*
 * Enable dump of config tables with sys_dump.
 */
SELECT sys_catalog.sys_extension_config_dump('@extschema@.pathman_config', '1');
SELECT sys_catalog.sys_extension_config_dump('@extschema@.pathman_config_params', '1');


/*
 * Add a row describing the optional parameter to pathman_config_params.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.pathman_set_param(
	relation	REGCLASS,
	param		TEXT,
	value		ANYELEMENT)
RETURNS VOID AS $$
BEGIN
	EXECUTE format('INSERT INTO @extschema@.pathman_config_params
					(partrel, %1$s) VALUES ($1, $2)
					ON CONFLICT (partrel) DO UPDATE SET %1$s = $2', param)
	USING relation, value;
END
$$ LANGUAGE plsql;

/*
 * Include\exclude parent relation in query plan.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.set_enable_parent(
	relation	REGCLASS,
	value		BOOLEAN)
RETURNS VOID AS $$
BEGIN
	PERFORM @extschema@.pathman_set_param(relation, 'enable_parent', value);
END
$$ LANGUAGE plsql STRICT;

/*
 * Enable\disable automatic partition creation.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.set_auto(
	relation	REGCLASS,
	value		BOOLEAN)
RETURNS VOID AS $$
BEGIN
	PERFORM @extschema@.pathman_set_param(relation, 'auto', value);
END
$$ LANGUAGE plsql STRICT;

/*
 * Set partition creation callback
 */
CREATE OR REPLACE internal FUNCTION @extschema@.set_init_callback(
	relation	REGCLASS,
	callback	REGPROCEDURE DEFAULT 0)
RETURNS VOID AS $$
DECLARE
	regproc_text	TEXT := NULL;

BEGIN

	/* Fetch schema-qualified name of callback */
	IF callback != 0 THEN
		SELECT quote_ident(nspname) || '.' ||
			   quote_ident(proname) || '(' ||
					(SELECT string_agg(x.argtype::REGTYPE::TEXT, ',')
					 FROM unnest(proargtypes) AS x(argtype)) ||
			   ')'
		FROM sys_catalog.sys_proc p JOIN sys_catalog.sys_namespace n
		ON n.oid = p.pronamespace
		WHERE p.oid = callback
		INTO regproc_text; /* <= result */
	END IF;

	PERFORM @extschema@.pathman_set_param(relation, 'init_callback', regproc_text);
END
$$ LANGUAGE plsql STRICT;

/*
 * Set 'spawn using BGW' option
 */
CREATE OR REPLACE internal FUNCTION @extschema@.set_spawn_using_bgw(
	relation	REGCLASS,
	value		BOOLEAN)
RETURNS VOID AS $$
BEGIN
	PERFORM @extschema@.pathman_set_param(relation, 'spawn_using_bgw', value);
END
$$ LANGUAGE plsql STRICT;

/*
 * Set (or reset) default interval for auto created partitions
 */
CREATE OR REPLACE internal FUNCTION @extschema@.set_interval(
	relation		REGCLASS,
	value			ANYELEMENT)
RETURNS VOID AS $$
DECLARE
	affected	INTEGER;
BEGIN
	UPDATE @extschema@.pathman_config
	SET range_interval = value::text
	WHERE partrel = relation AND parttype = 2;

	/* Check number of affected rows */
	GET DIAGNOSTICS affected = ROW_COUNT;

	IF affected = 0 THEN
		RAISE EXCEPTION 'table "%" is not partitioned by RANGE', relation;
	END IF;
END
$$ LANGUAGE plsql;


/*
 * Show all existing parents and partitions.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.show_partition_list()
RETURNS TABLE (
	parent			REGCLASS,
	partitionid		REGCLASS,
	parttype		INT4,
	expr			TEXT,
	range_min		TEXT,
	range_max		TEXT)
AS 'sys_pathman', 'show_partition_list_internal'
LANGUAGE C STRICT;

/*
 * View for show_partition_list().
 */
CREATE OR REPLACE VIEW @extschema@.pathman_partition_list
AS SELECT * FROM @extschema@.show_partition_list();

GRANT SELECT ON @extschema@.pathman_partition_list TO PUBLIC;

/*
 * Show memory usage of sys_pathman's caches.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.show_cache_stats()
RETURNS TABLE (
	context			TEXT,
	size			INT8,
	used			INT8,
	entries			INT8)
AS 'sys_pathman', 'show_cache_stats_internal'
LANGUAGE C STRICT;

/*
 * View for show_cache_stats().
 */
CREATE OR REPLACE VIEW @extschema@.pathman_cache_stats
AS SELECT * FROM @extschema@.show_cache_stats();

/*
 * Show all existing concurrent partitioning tasks.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.show_concurrent_part_tasks()
RETURNS TABLE (
	userid		REGROLE,
	pid			INT,
	dbid		OID,
	relid		REGCLASS,
	processed	INT8,
	status		TEXT)
AS 'sys_pathman', 'show_concurrent_part_tasks_internal'
LANGUAGE C STRICT;

/*
 * View for show_concurrent_part_tasks().
 */
CREATE OR REPLACE VIEW @extschema@.pathman_concurrent_part_tasks
AS SELECT * FROM @extschema@.show_concurrent_part_tasks();

GRANT SELECT ON @extschema@.pathman_concurrent_part_tasks TO PUBLIC;

/*
 * Partition table using ConcurrentPartWorker.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.partition_table_concurrently(
	relation		REGCLASS,
	batch_size		INTEGER DEFAULT 1000,
	sleep_time		FLOAT8 DEFAULT 1.0)
RETURNS VOID AS 'sys_pathman', 'partition_table_concurrently'
LANGUAGE C STRICT;

/*
 * Stop concurrent partitioning task.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.stop_concurrent_part_task(
	relation		REGCLASS)
RETURNS BOOL AS 'sys_pathman', 'stop_concurrent_part_task'
LANGUAGE C STRICT;


/*
 * Copy rows to partitions concurrently.
 */
CREATE OR REPLACE internal FUNCTION @extschema@._partition_data_concurrent(
	relation		REGCLASS,
	p_min			ANYELEMENT DEFAULT NULL::text,
	p_max			ANYELEMENT DEFAULT NULL::text,
	p_limit			INT DEFAULT NULL,
	OUT p_total		BIGINT)
AS $$
DECLARE
	part_expr		TEXT;
	v_limit_clause	TEXT := '';
	v_where_clause	TEXT := '';
	ctids			TID[];

BEGIN
	part_expr := @extschema@.get_partition_key(relation);

	p_total := 0;

	/* Format LIMIT clause if needed */
	IF NOT p_limit IS NULL THEN
		v_limit_clause := format('LIMIT %s', p_limit);
	END IF;

	/* Format WHERE clause if needed */
	IF NOT p_min IS NULL THEN
		v_where_clause := format('%1$s >= $1', part_expr);
	END IF;

	IF NOT p_max IS NULL THEN
		IF NOT p_min IS NULL THEN
			v_where_clause := v_where_clause || ' AND ';
		END IF;
		v_where_clause := v_where_clause || format('%1$s < $2', part_expr);
	END IF;

	IF v_where_clause != '' THEN
		v_where_clause := 'WHERE ' || v_where_clause;
	END IF;

	/* Lock rows and copy data */
	RAISE NOTICE 'Copying data to partitions...';
	EXECUTE format('SELECT array(SELECT ctid FROM ONLY %1$s %2$s %3$s FOR UPDATE NOWAIT)',
				   relation, v_where_clause, v_limit_clause)
	INTO ctids
	USING p_min, p_max;

	EXECUTE format('WITH data AS (
					DELETE FROM ONLY %1$s WHERE ctid = ANY($1) RETURNING *)
					INSERT INTO %1$s SELECT * FROM data',
				   relation)
	USING ctids;

	/* Get number of inserted rows */
	GET DIAGNOSTICS p_total = ROW_COUNT;
	RETURN;
END
$$ LANGUAGE plsql
SET sys_pathman.enable_partitionfilter = on; /* ensures that PartitionFilter is ON */

/*
 * Old school way to distribute rows to partitions.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.partition_data(
	parent_relid	REGCLASS,
	OUT p_total		BIGINT)
AS $$
BEGIN
	p_total := 0;

	/* Create partitions and copy rest of the data */
	EXECUTE format('WITH part_data AS (DELETE FROM ONLY %1$s RETURNING *)
					INSERT INTO %1$s SELECT * FROM part_data',
				   parent_relid::TEXT);

	/* Get number of inserted rows */
	GET DIAGNOSTICS p_total = ROW_COUNT;
	RETURN;
END
$$ LANGUAGE plsql STRICT
SET sys_pathman.enable_partitionfilter = on; /* ensures that PartitionFilter is ON */

/*
 * Disable pathman partitioning for specified relation.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.disable_pathman_for(
	parent_relid	REGCLASS)
RETURNS VOID AS $$
BEGIN
	PERFORM @extschema@.validate_relname(parent_relid);

	/* Delete rows from both config tables */
	DELETE FROM @extschema@.pathman_config WHERE partrel = parent_relid;
	DELETE FROM @extschema@.pathman_config_params WHERE partrel = parent_relid;
END
$$ LANGUAGE plsql STRICT;

/*
 * Check a few things and take locks before partitioning.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.prepare_for_partitioning(
	parent_relid	REGCLASS,
	expression		TEXT,
	partition_data	BOOLEAN)
RETURNS VOID AS $$
DECLARE
	constr_name		TEXT;
	is_referenced	BOOLEAN;
	rel_persistence	CHAR;

BEGIN
	PERFORM @extschema@.validate_relname(parent_relid);
	PERFORM @extschema@.validate_expression(parent_relid, expression);

	IF partition_data = true THEN
		/* Acquire data modification lock */
		PERFORM @extschema@.prevent_data_modification(parent_relid);
	ELSE
		/* Acquire lock on parent */
		PERFORM @extschema@.prevent_part_modification(parent_relid);
	END IF;

	/* Ignore temporary tables */
	SELECT relpersistence FROM sys_catalog.sys_class
	WHERE oid = parent_relid INTO rel_persistence;

	IF rel_persistence = 't'::CHAR THEN
		RAISE EXCEPTION 'temporary table "%" cannot be partitioned', parent_relid;
	END IF;

	IF EXISTS (SELECT * FROM @extschema@.pathman_config
			   WHERE partrel = parent_relid) THEN
		RAISE EXCEPTION 'table "%" has already been partitioned', parent_relid;
	END IF;

	/* Check if there are foreign keys that reference the relation */
	FOR constr_name IN (SELECT conname FROM sys_catalog.sys_constraint
					WHERE confrelid = parent_relid::REGCLASS::OID)
	LOOP
		is_referenced := TRUE;
		RAISE WARNING 'foreign key "%" references table "%"', constr_name, parent_relid;
	END LOOP;

	IF is_referenced THEN
		RAISE EXCEPTION 'table "%" is referenced from other tables', parent_relid;
	END IF;

END
$$ LANGUAGE plsql;


/*
 * Returns relname without quotes or something.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.get_plain_schema_and_relname(
	cls				REGCLASS,
	OUT schema		TEXT,
	OUT relname		TEXT)
AS $$
BEGIN
	SELECT sys_catalog.sys_class.relnamespace::regnamespace,
		   sys_catalog.sys_class.relname
	FROM sys_catalog.sys_class WHERE oid = cls::oid
	INTO schema, relname;
END
$$ LANGUAGE plsql STRICT;

/*
 * DDL trigger that removes entry from pathman_config table.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.pathman_ddl_trigger_func()
RETURNS event_trigger AS $$
DECLARE
	obj				RECORD;
	sys_class_oid	OID;
	relids			REGCLASS[];

BEGIN
	sys_class_oid = 'sys_catalog.sys_class'::regclass;

	/* Find relids to remove from config */
	SELECT array_agg(cfg.partrel) INTO relids
	FROM sys_event_trigger_dropped_objects() AS events
	JOIN @extschema@.pathman_config AS cfg ON cfg.partrel::oid = events.objid
	WHERE events.classid = sys_class_oid AND events.objsubid = 0;

	/* Cleanup pathman_config */
	DELETE FROM @extschema@.pathman_config WHERE partrel = ANY(relids);

	/* Cleanup params table too */
	DELETE FROM @extschema@.pathman_config_params WHERE partrel = ANY(relids);
END
$$ LANGUAGE plsql;

/*
 * Drop partitions. If delete_data set to TRUE, partitions
 * will be dropped with all the data.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.drop_partitions(
	parent_relid	REGCLASS,
	delete_data		BOOLEAN DEFAULT FALSE)
RETURNS INTEGER AS $$
DECLARE
	child			REGCLASS;
	rows_count		BIGINT;
	part_count		INTEGER := 0;
	rel_kind		CHAR;

BEGIN
	PERFORM @extschema@.validate_relname(parent_relid);

	/* Acquire data modification lock */
	PERFORM @extschema@.prevent_data_modification(parent_relid);

	IF NOT EXISTS (SELECT FROM @extschema@.pathman_config
				   WHERE partrel = parent_relid) THEN
		RAISE EXCEPTION 'table "%" has no partitions', parent_relid::TEXT;
	END IF;

	/* Also drop naming sequence */
	PERFORM @extschema@.drop_naming_sequence(parent_relid);

	FOR child IN (SELECT inhrelid::REGCLASS
				  FROM sys_catalog.sys_inherits
				  WHERE inhparent::regclass = parent_relid
				  ORDER BY inhrelid ASC)
	LOOP
		IF NOT delete_data THEN
			EXECUTE format('INSERT INTO %s SELECT * FROM %s',
							parent_relid::TEXT,
							child::TEXT);
			GET DIAGNOSTICS rows_count = ROW_COUNT;

			/* Show number of copied rows */
			RAISE NOTICE '% rows copied from %', rows_count, child;
		END IF;

		SELECT relkind FROM sys_catalog.sys_class
		WHERE oid = child
		INTO rel_kind;

		/*
		 * Determine the kind of child relation. It can be either a regular
		 * table (r) or a foreign table (f). Depending on relkind we use
		 * DROP TABLE or DROP FOREIGN TABLE.
		 */
		IF rel_kind = 'f' THEN
			EXECUTE format('DROP FOREIGN TABLE %s', child);
		ELSE
			EXECUTE format('DROP TABLE %s', child);
		END IF;

		part_count := part_count + 1;
	END LOOP;

	/* Finally delete both config entries */
	DELETE FROM @extschema@.pathman_config WHERE partrel = parent_relid;
	DELETE FROM @extschema@.pathman_config_params WHERE partrel = parent_relid;

	RETURN part_count;
END
$$ LANGUAGE plsql
SET sys_pathman.enable_partitionfilter = off; /* ensures that PartitionFilter is OFF */


/*
 * Copy all of parent's foreign keys.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.copy_foreign_keys(
	parent_relid	REGCLASS,
	partition_relid	REGCLASS)
RETURNS VOID AS $$
DECLARE
	conid			OID;

BEGIN
	PERFORM @extschema@.validate_relname(parent_relid);
	PERFORM @extschema@.validate_relname(partition_relid);

	FOR conid IN (SELECT oid FROM sys_catalog.sys_constraint
				  WHERE conrelid = parent_relid AND contype = 'f')
	LOOP
		EXECUTE format('ALTER TABLE %s ADD %s',
					   partition_relid::TEXT,
					   sys_catalog.sys_get_constraintdef(conid));
	END LOOP;
END
$$ LANGUAGE plsql STRICT;


/*
 * Set new relname, schema and tablespace
 */
CREATE OR REPLACE internal FUNCTION @extschema@.alter_partition(
	relation		REGCLASS,
	new_name		TEXT,
	new_schema		REGNAMESPACE,
	new_tablespace	TEXT)
RETURNS VOID AS $$
DECLARE
	orig_name	TEXT;
	orig_schema	OID;

BEGIN
	SELECT relname, relnamespace FROM sys_class
	WHERE oid = relation
	INTO orig_name, orig_schema;

	/* Alter table name */
	IF new_name != orig_name THEN
		EXECUTE format('ALTER TABLE %s RENAME TO %s', relation, new_name);
	END IF;

	/* Alter table schema */
	IF new_schema != orig_schema THEN
		EXECUTE format('ALTER TABLE %s SET SCHEMA %s', relation, new_schema);
	END IF;

	/* Move to another tablespace */
	IF NOT new_tablespace IS NULL THEN
		EXECUTE format('ALTER TABLE %s SET TABLESPACE %s', relation, new_tablespace);
	END IF;
END
$$ LANGUAGE plsql;


/*
 * Create DDL trigger to call pathman_ddl_trigger_func().
 */
CREATE EVENT TRIGGER pathman_ddl_trigger
ON sql_drop
EXECUTE PROCEDURE @extschema@.pathman_ddl_trigger_func();


/*
 * Get partitioning key.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.get_partition_key(
	parent_relid	REGCLASS)
RETURNS TEXT AS
$$
	SELECT expr
	FROM @extschema@.pathman_config
	WHERE partrel = parent_relid;
$$
LANGUAGE sql STRICT;

/*
 * Get partitioning key type.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.get_partition_key_type(
	parent_relid	REGCLASS)
RETURNS REGTYPE AS 'sys_pathman', 'get_partition_key_type_pl'
LANGUAGE C STRICT;

/*
 * Get parsed and analyzed expression.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.get_partition_cooked_key(
	parent_relid	REGCLASS)
RETURNS TEXT AS 'sys_pathman', 'get_partition_cooked_key_pl'
LANGUAGE C STRICT;

/*
 * Get partitioning type.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.get_partition_type(
	parent_relid	REGCLASS)
RETURNS INT4 AS
$$
	SELECT parttype
	FROM @extschema@.pathman_config
	WHERE partrel = parent_relid;
$$
LANGUAGE sql STRICT;

/*
 * Get number of partitions managed by sys_pathman.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.get_number_of_partitions(
	parent_relid	REGCLASS)
RETURNS INT4 AS
$$
	SELECT count(*)::INT4
	FROM sys_catalog.sys_inherits
	WHERE inhparent = parent_relid;
$$
LANGUAGE sql STRICT;

/*
 * Get parent of sys_pathman's partition.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.get_parent_of_partition(
	partition_relid		REGCLASS)
RETURNS REGCLASS AS 'sys_pathman', 'get_parent_of_partition_pl'
LANGUAGE C STRICT;

/*
 * Extract basic type of a domain.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.get_base_type(
	typid	REGTYPE)
RETURNS REGTYPE AS 'sys_pathman', 'get_base_type_pl'
LANGUAGE C STRICT;

/*
 * Return tablespace name for specified relation.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.get_tablespace(
	relid	REGCLASS)
RETURNS TEXT AS 'sys_pathman', 'get_tablespace_pl'
LANGUAGE C STRICT;


/*
 * Check that relation exists.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.validate_relname(
	relid	REGCLASS)
RETURNS VOID AS 'sys_pathman', 'validate_relname'
LANGUAGE C;

/*
 * Check that expression is valid
 */
CREATE OR REPLACE internal FUNCTION @extschema@.validate_expression(
	relid	REGCLASS,
	expression TEXT)
RETURNS VOID AS 'sys_pathman', 'validate_expression'
LANGUAGE C;

/*
 * Check if regclass is date or timestamp.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.is_date_type(
	typid	REGTYPE)
RETURNS BOOLEAN AS 'sys_pathman', 'is_date_type'
LANGUAGE C STRICT;

/*
 * Check if TYPE supports the specified operator.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.is_operator_supported(
	type_oid	REGTYPE,
	opname		TEXT)
RETURNS BOOLEAN AS 'sys_pathman', 'is_operator_supported'
LANGUAGE C STRICT;

/*
 * Check if tuple from first relation can be converted to fit the second one.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.is_tuple_convertible(
	relation1	REGCLASS,
	relation2	REGCLASS)
RETURNS BOOL AS 'sys_pathman', 'is_tuple_convertible'
LANGUAGE C STRICT;


/*
 * Build check constraint name for a specified relation's column.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.build_check_constraint_name(
	partition_relid	REGCLASS)
RETURNS TEXT AS 'sys_pathman', 'build_check_constraint_name'
LANGUAGE C STRICT;

/*
 * Add record to pathman_config (RANGE) and validate partitions.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.add_to_pathman_config(
	parent_relid	REGCLASS,
	expression		TEXT,
	range_interval	TEXT)
RETURNS BOOLEAN AS 'sys_pathman', 'add_to_pathman_config'
LANGUAGE C;

/*
 * Add record to pathman_config (HASH) and validate partitions.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.add_to_pathman_config(
	parent_relid	REGCLASS,
	expression		TEXT)
RETURNS BOOLEAN AS 'sys_pathman', 'add_to_pathman_config'
LANGUAGE C;

/*
 * Add record to pathman_config (LIST) and validate partitions.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.add_to_pathman_config(
	parent_relid	REGCLASS,
	expression	TEXT,
	range_interval	TEXT,
	hash		TEXT)
RETURNS BOOLEAN AS 'sys_pathman', 'add_to_pathman_config'
LANGUAGE C;

/*
 * Lock partitioned relation to restrict concurrent
 * modification of partitioning scheme.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.prevent_part_modification(
	parent_relid	REGCLASS)
RETURNS VOID AS 'sys_pathman', 'prevent_part_modification'
LANGUAGE C STRICT;

/*
 * Lock relation to restrict concurrent modification of data.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.prevent_data_modification(
	parent_relid	REGCLASS)
RETURNS VOID AS 'sys_pathman', 'prevent_data_modification'
LANGUAGE C STRICT;


/*
 * Invoke init_callback on RANGE partition.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.invoke_on_partition_created_callback(
	parent_relid	REGCLASS,
	partition_relid	REGCLASS,
	init_callback	REGPROCEDURE,
	start_value		ANYELEMENT,
	end_value		ANYELEMENT)
RETURNS VOID AS 'sys_pathman', 'invoke_on_partition_created_callback'
LANGUAGE C;

/*
 * Invoke init_callback on HASH partition.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.invoke_on_partition_created_callback(
	parent_relid	REGCLASS,
	partition_relid	REGCLASS,
	init_callback	REGPROCEDURE)
RETURNS VOID AS 'sys_pathman', 'invoke_on_partition_created_callback'
LANGUAGE C;

/*
 * DEBUG: Place this inside some plsql fuction and set breakpoint.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.debug_capture()
RETURNS VOID AS 'sys_pathman', 'debug_capture'
LANGUAGE C STRICT;

CREATE OR REPLACE internal FUNCTION @extschema@.pathman_version()
RETURNS CSTRING AS 'sys_pathman', 'pathman_version'
LANGUAGE C STRICT;
/* ------------------------------------------------------------------------
 *
 * hash.sql
 *		HASH partitioning internal FUNCTIONs
 *
 * Copyright (c) 2015-2016, Postgres Professional
 *
 * ------------------------------------------------------------------------
 */
--kingbase add internal in front of function

/*
 * Creates hash partitions for specified relation
 */
CREATE OR REPLACE internal FUNCTION @extschema@.create_hash_partitions(
	parent_relid		REGCLASS,
	expression			TEXT,
	partitions_count	INT4,
	partition_data		BOOLEAN DEFAULT TRUE,
	partition_names		TEXT[] DEFAULT NULL,
	tablespaces			TEXT[] DEFAULT NULL)
RETURNS INTEGER AS $$
BEGIN
	PERFORM @extschema@.prepare_for_partitioning(parent_relid,
												 expression,
												 partition_data);

	/* Insert new entry to pathman config */
	PERFORM @extschema@.add_to_pathman_config(parent_relid, expression);

	/* Create partitions */
	PERFORM @extschema@.create_hash_partitions_internal(parent_relid,
														expression,
														partitions_count,
														partition_names,
														tablespaces);

	/* Copy data */
	IF partition_data = true THEN
		PERFORM @extschema@.set_enable_parent(parent_relid, false);
		PERFORM @extschema@.partition_data(parent_relid);
	ELSE
		PERFORM @extschema@.set_enable_parent(parent_relid, true);
	END IF;

	RETURN partitions_count;
END
$$ LANGUAGE plsql
SET client_min_messages = WARNING;

/*
 * Replace hash partition with another one. It could be useful in case when
 * someone wants to attach foreign table as a partition.
 *
 * lock_parent - should we take an exclusive lock?
 */
CREATE OR REPLACE internal FUNCTION @extschema@.replace_hash_partition(
	old_partition		REGCLASS,
	new_partition		REGCLASS,
	lock_parent			BOOL DEFAULT TRUE)
RETURNS REGCLASS AS $$
DECLARE
	parent_relid		REGCLASS;
	old_constr_name		TEXT;		/* name of old_partition's constraint */
	old_constr_def		TEXT;		/* definition of old_partition's constraint */
	rel_persistence		CHAR;
	p_init_callback		REGPROCEDURE;

BEGIN
	PERFORM @extschema@.validate_relname(old_partition);
	PERFORM @extschema@.validate_relname(new_partition);

	/* Parent relation */
	parent_relid := @extschema@.get_parent_of_partition(old_partition);

	IF lock_parent THEN
		/* Acquire data modification lock (prevent further modifications) */
		PERFORM @extschema@.prevent_data_modification(parent_relid);
	ELSE
		/* Acquire lock on parent */
		PERFORM @extschema@.prevent_part_modification(parent_relid);
	END IF;

	/* Acquire data modification lock (prevent further modifications) */
	PERFORM @extschema@.prevent_data_modification(old_partition);
	PERFORM @extschema@.prevent_data_modification(new_partition);

	/* Ignore temporary tables */
	SELECT relpersistence FROM sys_catalog.sys_class
	WHERE oid = new_partition INTO rel_persistence;

	IF rel_persistence = 't'::CHAR THEN
		RAISE EXCEPTION 'temporary table "%" cannot be used as a partition',
						new_partition::TEXT;
	END IF;

	/* Check that new partition has an equal structure as parent does */
	IF NOT @extschema@.is_tuple_convertible(parent_relid, new_partition) THEN
		RAISE EXCEPTION 'partition must have a compatible tuple format';
	END IF;

	/* Check that table is partitioned */
	IF @extschema@.get_partition_key(parent_relid) IS NULL THEN
		RAISE EXCEPTION 'table "%" is not partitioned', parent_relid::TEXT;
	END IF;

	/* Fetch name of old_partition's HASH constraint */
	old_constr_name = @extschema@.build_check_constraint_name(old_partition::REGCLASS);

	/* Fetch definition of old_partition's HASH constraint */
	SELECT sys_catalog.sys_get_constraintdef(oid) FROM sys_catalog.sys_constraint
	WHERE conrelid = old_partition AND quote_ident(conname) = old_constr_name
	INTO old_constr_def;

	/* Detach old partition */
	EXECUTE format('ALTER TABLE %s NO INHERIT %s', old_partition, parent_relid);
	EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %s',
				   old_partition,
				   old_constr_name);

	/* Attach the new one */
	EXECUTE format('ALTER TABLE %s INHERIT %s', new_partition, parent_relid);
	EXECUTE format('ALTER TABLE %s ADD CONSTRAINT %s %s',
				   new_partition,
				   @extschema@.build_check_constraint_name(new_partition::REGCLASS),
				   old_constr_def);

	/* Fetch init_callback from 'params' table */
	WITH stub_callback(stub) as (values (0))
	SELECT init_callback
	FROM stub_callback
	LEFT JOIN @extschema@.pathman_config_params AS params
	ON params.partrel = parent_relid
	INTO p_init_callback;

	/* Finally invoke init_callback */
	PERFORM @extschema@.invoke_on_partition_created_callback(parent_relid,
															 new_partition,
															 p_init_callback);

	RETURN new_partition;
END
$$ LANGUAGE plsql;

/*
 * Just create HASH partitions, called by create_hash_partitions().
 */
CREATE OR REPLACE internal FUNCTION @extschema@.create_hash_partitions_internal(
	parent_relid		REGCLASS,
	attribute			TEXT,
	partitions_count	INT4,
	partition_names		TEXT[] DEFAULT NULL,
	tablespaces			TEXT[] DEFAULT NULL)
RETURNS VOID AS 'sys_pathman', 'create_hash_partitions_internal'
LANGUAGE C;

/*
 * Calculates hash for integer value
 */
CREATE OR REPLACE internal FUNCTION @extschema@.get_hash_part_idx(INT4, INT4)
RETURNS INTEGER AS 'sys_pathman', 'get_hash_part_idx'
LANGUAGE C STRICT;

/*
 * Build hash condition for a CHECK CONSTRAINT
 */
CREATE OR REPLACE internal FUNCTION @extschema@.build_hash_condition(
	attribute_type		REGTYPE,
	attribute			TEXT,
	partitions_count	INT4,
	partition_index		INT4)
RETURNS TEXT AS 'sys_pathman', 'build_hash_condition'
LANGUAGE C STRICT;
/* ------------------------------------------------------------------------
 *
 * range.sql
 *		RANGE partitioning internal FUNCTIONs
 *
 * Copyright (c) 2015-2016, Postgres Professional
 *
 * ------------------------------------------------------------------------
 */
--kingbase add internal in front of function

/*
 * Check RANGE partition boundaries.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.check_boundaries(
	parent_relid	REGCLASS,
	expression		TEXT,
	start_value		ANYELEMENT,
	end_value		ANYELEMENT)
RETURNS VOID AS $$
DECLARE
	min_value		start_value%TYPE;
	max_value		start_value%TYPE;
	rows_count		BIGINT;

BEGIN
	/* Get min and max values */
	EXECUTE format('SELECT count(*), min(%1$s), max(%1$s)
					FROM %2$s WHERE NOT %1$s IS NULL',
				   expression, parent_relid::TEXT)
	INTO rows_count, min_value, max_value;

	/* Check if column has NULL values */
	IF rows_count > 0 AND (min_value IS NULL OR max_value IS NULL) THEN
		RAISE EXCEPTION 'expression "%" returns NULL values', expression;
	END IF;

	/* Check lower boundary */
	IF start_value > min_value THEN
		RAISE EXCEPTION 'start value is greater than min value of "%"', expression;
	END IF;

	/* Check upper boundary */
	IF end_value <= max_value THEN
		RAISE EXCEPTION 'not enough partitions to fit all values of "%"', expression;
	END IF;
END
$$ LANGUAGE plsql;

/*
 * Creates RANGE partitions for specified relation based on datetime attribute
 */
CREATE OR REPLACE internal FUNCTION @extschema@.create_range_partitions(
	parent_relid	REGCLASS,
	expression		TEXT,
	start_value		ANYELEMENT,
	p_interval		INTERVAL,
	p_count			INTEGER DEFAULT NULL,
	partition_data	BOOLEAN DEFAULT TRUE)
RETURNS INTEGER AS $$
DECLARE
	rows_count		BIGINT;
	max_value		start_value%TYPE;
	cur_value		start_value%TYPE := start_value;
	end_value		start_value%TYPE;
	part_count		INTEGER := 0;
	i				INTEGER;

BEGIN
	PERFORM @extschema@.prepare_for_partitioning(parent_relid,
												 expression,
												 partition_data);

	IF p_count < 0 THEN
		RAISE EXCEPTION '"p_count" must not be less than 0';
	END IF;

	/* Try to determine partitions count if not set */
	IF p_count IS NULL THEN
		EXECUTE format('SELECT count(*), max(%s) FROM %s', expression, parent_relid)
		INTO rows_count, max_value;

		IF rows_count = 0 THEN
			RAISE EXCEPTION 'cannot determine partitions count for empty table';
		END IF;

		p_count := 0;
		WHILE cur_value <= max_value
		LOOP
			cur_value := cur_value + p_interval;
			p_count := p_count + 1;
		END LOOP;
	END IF;

	/*
	 * In case when user doesn't want to automatically create partitions
	 * and specifies partition count as 0 then do not check boundaries
	 */
	IF p_count != 0 THEN
		/* Compute right bound of partitioning through additions */
		end_value := start_value;
		FOR i IN 1..p_count
		LOOP
			end_value := end_value + p_interval;
		END LOOP;

		/* Check boundaries */
		PERFORM @extschema@.check_boundaries(parent_relid,
											 expression,
											 start_value,
											 end_value);

	END IF;

	/* Create sequence for child partitions names */
	PERFORM @extschema@.create_naming_sequence(parent_relid);

	/* Insert new entry to pathman config */
	PERFORM @extschema@.add_to_pathman_config(parent_relid, expression,
											  p_interval::TEXT);

	IF p_count != 0 THEN
		part_count := @extschema@.create_range_partitions_internal(
									parent_relid,
									@extschema@.generate_range_bounds(start_value,
																	  p_interval,
																	  p_count),
									NULL,
									NULL);
	END IF;

	/* Relocate data if asked to */
	IF partition_data = true THEN
		PERFORM @extschema@.set_enable_parent(parent_relid, false);
		PERFORM @extschema@.partition_data(parent_relid);
	ELSE
		PERFORM @extschema@.set_enable_parent(parent_relid, true);
	END IF;

	RETURN part_count;
END
$$ LANGUAGE plsql;

/*
 * Creates RANGE partitions for specified relation based on numerical expression
 */
CREATE OR REPLACE internal FUNCTION @extschema@.create_range_partitions(
	parent_relid	REGCLASS,
	expression		TEXT,
	start_value		ANYELEMENT,
	p_interval		ANYELEMENT,
	p_count			INTEGER DEFAULT NULL,
	partition_data	BOOLEAN DEFAULT TRUE)
RETURNS INTEGER AS $$
DECLARE
	rows_count		BIGINT;
	max_value		start_value%TYPE;
	cur_value		start_value%TYPE := start_value;
	end_value		start_value%TYPE;
	part_count		INTEGER := 0;
	i				INTEGER;

BEGIN
	PERFORM @extschema@.prepare_for_partitioning(parent_relid,
												 expression,
												 partition_data);

	IF p_count < 0 THEN
		RAISE EXCEPTION 'partitions count must not be less than zero';
	END IF;

	/* Try to determine partitions count if not set */
	IF p_count IS NULL THEN
		EXECUTE format('SELECT count(*), max(%s) FROM %s', expression, parent_relid)
		INTO rows_count, max_value;

		IF rows_count = 0 THEN
			RAISE EXCEPTION 'cannot determine partitions count for empty table';
		END IF;

		IF max_value IS NULL THEN
			RAISE EXCEPTION 'expression "%" can return NULL values', expression;
		END IF;

		p_count := 0;
		WHILE cur_value <= max_value
		LOOP
			cur_value := cur_value + p_interval;
			p_count := p_count + 1;
		END LOOP;
	END IF;

	/*
	 * In case when user doesn't want to automatically create partitions
	 * and specifies partition count as 0 then do not check boundaries
	 */
	IF p_count != 0 THEN
		/* Compute right bound of partitioning through additions */
		end_value := start_value;
		FOR i IN 1..p_count
		LOOP
			end_value := end_value + p_interval;
		END LOOP;

		/* Check boundaries */
		PERFORM @extschema@.check_boundaries(parent_relid,
											 expression,
											 start_value,
											 end_value);
	END IF;

	/* Create sequence for child partitions names */
	PERFORM @extschema@.create_naming_sequence(parent_relid);

	/* Insert new entry to pathman config */
	PERFORM @extschema@.add_to_pathman_config(parent_relid, expression,
											  p_interval::TEXT);

	IF p_count != 0 THEN
		part_count := @extschema@.create_range_partitions_internal(
						parent_relid,
						@extschema@.generate_range_bounds(start_value,
														  p_interval,
														  p_count),
						NULL,
						NULL);
	END IF;

	/* Relocate data if asked to */
	IF partition_data = true THEN
		PERFORM @extschema@.set_enable_parent(parent_relid, false);
		PERFORM @extschema@.partition_data(parent_relid);
	ELSE
		PERFORM @extschema@.set_enable_parent(parent_relid, true);
	END IF;

	RETURN p_count;
END
$$ LANGUAGE plsql;

/*
 * Creates RANGE partitions for specified relation based on bounds array
 */
CREATE OR REPLACE internal FUNCTION @extschema@.create_range_partitions(
	parent_relid	REGCLASS,
	expression		TEXT,
	bounds			ANYARRAY,
	partition_names	TEXT[] DEFAULT NULL,
	tablespaces		TEXT[] DEFAULT NULL,
	partition_data	BOOLEAN DEFAULT TRUE)
RETURNS INTEGER AS $$
DECLARE
	part_count		INTEGER := 0;

BEGIN
	IF array_ndims(bounds) > 1 THEN
		RAISE EXCEPTION 'Bounds array must be a one dimensional array';
	END IF;

	IF array_length(bounds, 1) < 2 THEN
		RAISE EXCEPTION 'Bounds array must have at least two values';
	END IF;

	PERFORM @extschema@.prepare_for_partitioning(parent_relid,
												 expression,
												 partition_data);

	/* Check boundaries */
	PERFORM @extschema@.check_boundaries(parent_relid,
										 expression,
										 bounds[1],
										 bounds[array_length(bounds, 1)]);

	/* Create sequence for child partitions names */
	PERFORM @extschema@.create_naming_sequence(parent_relid);

	/* Insert new entry to pathman config */
	PERFORM @extschema@.add_to_pathman_config(parent_relid, expression, NULL);

	/* Create partitions */
	part_count := @extschema@.create_range_partitions_internal(parent_relid,
															   bounds,
															   partition_names,
															   tablespaces);

	/* Relocate data if asked to */
	IF partition_data = true THEN
		PERFORM @extschema@.set_enable_parent(parent_relid, false);
		PERFORM @extschema@.partition_data(parent_relid);
	ELSE
		PERFORM @extschema@.set_enable_parent(parent_relid, true);
	END IF;

	RETURN part_count;
END
$$
LANGUAGE plsql;

/*
 * Oracle syntax compatibility--Creates RANGE partitions
 */
CREATE OR REPLACE internal FUNCTION @extschema@.create_range_partitions_compat(
	parent_relid	REGCLASS,
	expression		TEXT,
	start_value		ANYELEMENT,
	end_value		ANYELEMENT,
	partition_name	TEXT DEFAULT NULL,
	tablespace		TEXT DEFAULT NULL,
	partition_data	BOOLEAN DEFAULT TRUE)
RETURNS REGCLASS AS $$
DECLARE
	exist_part		BIGINT;
	ret				REGCLASS;

BEGIN
	EXECUTE format('SELECT count(*) FROM pathman_config WHERE pathman_config.PARTREL = ''%s''::REGCLASS', parent_relid)
	INTO exist_part;
	IF exist_part <= 0 THEN
		PERFORM @extschema@.prepare_for_partitioning(parent_relid,
													 expression,
													 partition_data);

		/* Create sequence for child partitions names */
--		PERFORM @extschema@.create_naming_sequence(parent_relid);

		/* Insert new entry to pathman config */
		PERFORM @extschema@.add_to_pathman_config(parent_relid, expression,
											  NULL);

		SELECT @extschema@.create_single_range_partition($1, $3, $4, $5, $6) INTO ret;

		/* Relocate data if asked to */
		IF partition_data = true THEN
			PERFORM @extschema@.set_enable_parent(parent_relid, false);
			PERFORM @extschema@.partition_data(parent_relid);
		ELSE
			PERFORM @extschema@.set_enable_parent(parent_relid, true);
		END IF;

		PERFORM @extschema@.set_auto(parent_relid, false);
	ELSE
		SELECT @extschema@.add_range_partition_compat($1, $3, $4, $5, $6) INTO ret;
	END IF;

	RETURN ret;
END
$$ LANGUAGE plsql;


/*
 * Append new partition.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.append_range_partition(
	parent_relid	REGCLASS,
	partition_name	TEXT DEFAULT NULL,
	tablespace		TEXT DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
	part_expr_type	REGTYPE;
	part_name		TEXT;
	part_interval	TEXT;

BEGIN
	PERFORM @extschema@.validate_relname(parent_relid);

	/* Acquire lock on parent's scheme */
	PERFORM @extschema@.prevent_part_modification(parent_relid);

	part_expr_type := @extschema@.get_partition_key_type(parent_relid);

	IF NOT @extschema@.is_date_type(part_expr_type) AND
	   NOT @extschema@.is_operator_supported(part_expr_type, '+') THEN
		RAISE EXCEPTION 'type % does not support ''+'' operator', part_expr_type::REGTYPE;
	END IF;

	SELECT range_interval
	FROM @extschema@.pathman_config
	WHERE partrel = parent_relid
	INTO part_interval;

	EXECUTE
		format('SELECT @extschema@.append_partition_internal($1, $2, $3, ARRAY[]::%s[], $4, $5)',
			   @extschema@.get_base_type(part_expr_type)::TEXT)
	INTO
		part_name
	USING
		parent_relid,
		part_expr_type,
		part_interval,
		partition_name,
		tablespace;

	RETURN part_name;
END
$$ LANGUAGE plsql;

/*
 * Spawn logic for append_partition(). We have to
 * separate this in order to pass the 'p_range'.
 *
 * NOTE: we don't take a xact_handling lock here.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.append_partition_internal(
	parent_relid	REGCLASS,
	p_atttype		REGTYPE,
	p_interval		TEXT,
	p_range			ANYARRAY DEFAULT NULL,
	partition_name	TEXT DEFAULT NULL,
	tablespace		TEXT DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
	part_expr_type	REGTYPE;
	part_name		TEXT;
	v_args_format	TEXT;

BEGIN
	IF @extschema@.get_number_of_partitions(parent_relid) = 0 THEN
		RAISE EXCEPTION 'cannot append to empty partitions set';
	END IF;

	part_expr_type := @extschema@.get_base_type(p_atttype);

	/* We have to pass fake NULL casted to column's type */
	EXECUTE format('SELECT @extschema@.get_part_range($1, -1, NULL::%s)',
				   part_expr_type::TEXT)
	INTO p_range
	USING parent_relid;

	IF p_range[2] IS NULL THEN
		RAISE EXCEPTION 'Cannot append partition because last partition''s range is half open';
	END IF;

	IF @extschema@.is_date_type(p_atttype) THEN
		v_args_format := format('$1, $2, ($2 + $3::interval)::%s, $4, $5', part_expr_type::TEXT);
	ELSE
		v_args_format := format('$1, $2, $2 + $3::%s, $4, $5', part_expr_type::TEXT);
	END IF;

	EXECUTE
		format('SELECT @extschema@.create_single_range_partition(%s)', v_args_format)
	INTO
		part_name
	USING
		parent_relid,
		p_range[2],
		p_interval,
		partition_name,
		tablespace;

	RETURN part_name;
END
$$ LANGUAGE plsql;

/*
 * Prepend new partition.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.prepend_range_partition(
	parent_relid	REGCLASS,
	partition_name	TEXT DEFAULT NULL,
	tablespace		TEXT DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
	part_expr_type	REGTYPE;
	part_name		TEXT;
	part_interval	TEXT;

BEGIN
	PERFORM @extschema@.validate_relname(parent_relid);

	/* Acquire lock on parent's scheme */
	PERFORM @extschema@.prevent_part_modification(parent_relid);

	part_expr_type := @extschema@.get_partition_key_type(parent_relid);

	IF NOT @extschema@.is_date_type(part_expr_type) AND
	   NOT @extschema@.is_operator_supported(part_expr_type, '-') THEN
		RAISE EXCEPTION 'type % does not support ''-'' operator', part_expr_type::REGTYPE;
	END IF;

	SELECT range_interval
	FROM @extschema@.pathman_config
	WHERE partrel = parent_relid
	INTO part_interval;

	EXECUTE
		format('SELECT @extschema@.prepend_partition_internal($1, $2, $3, ARRAY[]::%s[], $4, $5)',
			   @extschema@.get_base_type(part_expr_type)::TEXT)
	INTO
		part_name
	USING
		parent_relid,
		part_expr_type,
		part_interval,
		partition_name,
		tablespace;

	RETURN part_name;
END
$$ LANGUAGE plsql;

/*
 * Spawn logic for prepend_partition(). We have to
 * separate this in order to pass the 'p_range'.
 *
 * NOTE: we don't take a xact_handling lock here.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.prepend_partition_internal(
	parent_relid	REGCLASS,
	p_atttype		REGTYPE,
	p_interval		TEXT,
	p_range			ANYARRAY DEFAULT NULL,
	partition_name	TEXT DEFAULT NULL,
	tablespace		TEXT DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
	part_expr_type	REGTYPE;
	part_name		TEXT;
	v_args_format	TEXT;

BEGIN
	IF @extschema@.get_number_of_partitions(parent_relid) = 0 THEN
		RAISE EXCEPTION 'cannot prepend to empty partitions set';
	END IF;

	part_expr_type := @extschema@.get_base_type(p_atttype);

	/* We have to pass fake NULL casted to column's type */
	EXECUTE format('SELECT @extschema@.get_part_range($1, 0, NULL::%s)',
				   part_expr_type::TEXT)
	INTO p_range
	USING parent_relid;

	IF p_range[1] IS NULL THEN
		RAISE EXCEPTION 'Cannot prepend partition because first partition''s range is half open';
	END IF;

	IF @extschema@.is_date_type(p_atttype) THEN
		v_args_format := format('$1, ($2 - $3::interval)::%s, $2, $4, $5', part_expr_type::TEXT);
	ELSE
		v_args_format := format('$1, $2 - $3::%s, $2, $4, $5', part_expr_type::TEXT);
	END IF;

	EXECUTE
		format('SELECT @extschema@.create_single_range_partition(%s)', v_args_format)
	INTO
		part_name
	USING
		parent_relid,
		p_range[1],
		p_interval,
		partition_name,
		tablespace;

	RETURN part_name;
END
$$ LANGUAGE plsql;

/*
 * Add new partition
 */
CREATE OR REPLACE internal FUNCTION @extschema@.add_range_partition(
	parent_relid	REGCLASS,
	start_value		ANYELEMENT,
	end_value		ANYELEMENT,
	partition_name	TEXT DEFAULT NULL,
	tablespace		TEXT DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
	part_name		TEXT;

BEGIN
	PERFORM @extschema@.validate_relname(parent_relid);

	/* Acquire lock on parent's scheme */
	PERFORM @extschema@.prevent_part_modification(parent_relid);

	IF start_value >= end_value THEN
		RAISE EXCEPTION 'failed to create partition: start_value is greater than end_value';
	END IF;

	/* Check range overlap */
	IF @extschema@.get_number_of_partitions(parent_relid) > 0 THEN
		PERFORM @extschema@.check_range_available(parent_relid,
												  start_value,
												  end_value);
	END IF;

	/* Create new partition */
	part_name := @extschema@.create_single_range_partition(parent_relid,
														   start_value,
														   end_value,
														   partition_name,
														   tablespace);

	RETURN part_name;
END
$$ LANGUAGE plsql;

/*
 * Oracle syntax compatibility--Add new partition
 */
CREATE OR REPLACE internal FUNCTION @extschema@.add_range_partition_compat(
	parent_relid	REGCLASS,
	start_value		ANYELEMENT,
	end_value		ANYELEMENT,
	partition_name	TEXT DEFAULT NULL,
	tablespace		TEXT DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
	part_name      TEXT;
	rstart_value   VARCHAR;

BEGIN
	PERFORM @extschema@.validate_relname(parent_relid);

	/* Acquire lock on parent's scheme */
	PERFORM @extschema@.prevent_part_modification(parent_relid);

	IF start_value >= end_value THEN
		RAISE EXCEPTION 'failed to create partition: start_value is greater than end_value';
	END IF;

	/* Check range overlap */
	IF @extschema@.get_number_of_partitions(parent_relid) > 0 THEN
		SELECT @extschema@.check_range_available_compat(parent_relid, end_value)
		INTO rstart_value;
	END IF;

	/* Create new partition */
	IF start_value IS NULL THEN
		part_name := @extschema@.create_single_range_partition(parent_relid,
														   rstart_value,
														   end_value::varchar,
														   partition_name,
														   tablespace);
	ELSE
		part_name := @extschema@.create_single_range_partition(parent_relid,
														   start_value,
														   end_value,
														   partition_name,
														   tablespace);
	END IF;

	RETURN part_name;
END
$$ LANGUAGE plsql;

/*
 * Drop range partition
 */
CREATE OR REPLACE internal FUNCTION @extschema@.drop_range_partition(
	partition_relid	REGCLASS,
	delete_data		BOOLEAN DEFAULT TRUE)
RETURNS TEXT AS $$
DECLARE
	parent_relid	REGCLASS;
	part_name		TEXT;
	part_type		INTEGER;
	v_relkind		CHAR;
	v_rows			BIGINT;

BEGIN
	parent_relid := @extschema@.get_parent_of_partition(partition_relid);

	PERFORM @extschema@.validate_relname(parent_relid);
	PERFORM @extschema@.validate_relname(partition_relid);

	part_name := partition_relid::TEXT; /* save the name to be returned */
	part_type := @extschema@.get_partition_type(parent_relid);

	/* Check if this is a RANGE partition */
	IF part_type != 2 THEN
		RAISE EXCEPTION '"%" is not a RANGE partition', partition_relid::TEXT;
	END IF;

	/* Acquire lock on parent's scheme */
	PERFORM @extschema@.prevent_part_modification(parent_relid);

	IF NOT delete_data THEN
		EXECUTE format('INSERT INTO %s SELECT * FROM %s',
						parent_relid::TEXT,
						partition_relid::TEXT);
		GET DIAGNOSTICS v_rows = ROW_COUNT;

		/* Show number of copied rows */
		RAISE NOTICE '% rows copied from %', v_rows, partition_relid::TEXT;
	END IF;

	SELECT relkind FROM sys_catalog.sys_class
	WHERE oid = partition_relid
	INTO v_relkind;

	/*
	 * Determine the kind of child relation. It can be either regular
	 * table (r) or foreign table (f). Depending on relkind we use
	 * DROP TABLE or DROP FOREIGN TABLE.
	 */
	IF v_relkind = 'f' THEN
		EXECUTE format('DROP FOREIGN TABLE %s', partition_relid::TEXT);
	ELSE
		EXECUTE format('DROP TABLE %s', partition_relid::TEXT);
	END IF;

	RETURN part_name;
END
$$ LANGUAGE plsql
SET sys_pathman.enable_partitionfilter = off; /* ensures that PartitionFilter is OFF */

/*
 * Attach range partition
 */
CREATE OR REPLACE internal FUNCTION @extschema@.attach_range_partition(
	parent_relid	REGCLASS,
	partition_relid	REGCLASS,
	start_value		ANYELEMENT,
	end_value		ANYELEMENT)
RETURNS TEXT AS $$
DECLARE
	part_expr			TEXT;
	part_type			INTEGER;
	rel_persistence		CHAR;
	v_init_callback		REGPROCEDURE;

BEGIN
	PERFORM @extschema@.validate_relname(parent_relid);
	PERFORM @extschema@.validate_relname(partition_relid);

	/* Acquire lock on parent's scheme */
	PERFORM @extschema@.prevent_part_modification(parent_relid);

	/* Ignore temporary tables */
	SELECT relpersistence FROM sys_catalog.sys_class
	WHERE oid = partition_relid INTO rel_persistence;

	IF rel_persistence = 't'::CHAR THEN
		RAISE EXCEPTION 'temporary table "%" cannot be used as a partition',
						partition_relid::TEXT;
	END IF;

	/* Check range overlap */
	PERFORM @extschema@.check_range_available(parent_relid, start_value, end_value);

	IF NOT @extschema@.is_tuple_convertible(parent_relid, partition_relid) THEN
		RAISE EXCEPTION 'partition must have a compatible tuple format';
	END IF;

	part_expr := @extschema@.get_partition_key(parent_relid);
	part_type := @extschema@.get_partition_type(parent_relid);

	IF part_expr IS NULL THEN
		RAISE EXCEPTION 'table "%" is not partitioned', parent_relid::TEXT;
	END IF;

	/* Check if this is a RANGE partition */
	IF part_type != 2 THEN
		RAISE EXCEPTION '"%" is not a RANGE partition', partition_relid::TEXT;
	END IF;

	/* Set inheritance */
	EXECUTE format('ALTER TABLE %s INHERIT %s', partition_relid, parent_relid);

	/* Set check constraint */
	EXECUTE format('ALTER TABLE %s ADD CONSTRAINT %s CHECK (%s)',
				   partition_relid::TEXT,
				   @extschema@.build_check_constraint_name(partition_relid),
				   @extschema@.build_range_condition(partition_relid,
													 part_expr,
													 start_value,
													 end_value));

	/* Fetch init_callback from 'params' table */
	WITH stub_callback(stub) as (values (0))
	SELECT init_callback
	FROM stub_callback
	LEFT JOIN @extschema@.pathman_config_params AS params
	ON params.partrel = parent_relid
	INTO v_init_callback;

	/* Invoke an initialization callback */
	PERFORM @extschema@.invoke_on_partition_created_callback(parent_relid,
															 partition_relid,
															 v_init_callback,
															 start_value,
															 end_value);

	RETURN partition_relid;
END
$$ LANGUAGE plsql;

/*
 * Detach range partition
 */
CREATE OR REPLACE internal FUNCTION @extschema@.detach_range_partition(
	partition_relid	REGCLASS)
RETURNS TEXT AS $$
DECLARE
	parent_relid	REGCLASS;
	part_type		INTEGER;

BEGIN
	parent_relid := @extschema@.get_parent_of_partition(partition_relid);

	PERFORM @extschema@.validate_relname(parent_relid);
	PERFORM @extschema@.validate_relname(partition_relid);

	/* Acquire lock on partition's scheme */
	PERFORM @extschema@.prevent_part_modification(partition_relid);

	/* Acquire lock on parent */
	PERFORM @extschema@.prevent_data_modification(parent_relid);

	part_type := @extschema@.get_partition_type(parent_relid);

	/* Check if this is a RANGE partition */
	IF part_type != 2 THEN
		RAISE EXCEPTION '"%" is not a RANGE partition', partition_relid::TEXT;
	END IF;

	/* Remove inheritance */
	EXECUTE format('ALTER TABLE %s NO INHERIT %s',
				   partition_relid::TEXT,
				   parent_relid::TEXT);

	/* Remove check constraint */
	EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %s',
				   partition_relid::TEXT,
				   @extschema@.build_check_constraint_name(partition_relid));

	RETURN partition_relid;
END
$$ LANGUAGE plsql;


/*
 * Create a naming sequence for partitioned table.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.create_naming_sequence(
	parent_relid	REGCLASS)
RETURNS TEXT AS $$
DECLARE
	seq_name TEXT;

BEGIN
	seq_name := @extschema@.build_sequence_name(parent_relid);

	EXECUTE format('DROP SEQUENCE IF EXISTS %s', seq_name);
	EXECUTE format('CREATE SEQUENCE %s START 1', seq_name);

	RETURN seq_name;
END
$$ LANGUAGE plsql
SET client_min_messages = WARNING; /* mute NOTICE message */

/*
 * Drop a naming sequence for partitioned table.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.drop_naming_sequence(
	parent_relid	REGCLASS)
RETURNS VOID AS $$
DECLARE
	seq_name TEXT;

BEGIN
	seq_name := @extschema@.build_sequence_name(parent_relid);

	EXECUTE format('DROP SEQUENCE IF EXISTS %s', seq_name);
END
$$ LANGUAGE plsql
SET client_min_messages = WARNING; /* mute NOTICE message */


/*
 * Split RANGE partition in two using a pivot.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.split_range_partition(
	partition_relid	REGCLASS,
	split_value		ANYELEMENT,
	partition_name	TEXT DEFAULT NULL,
	tablespace		TEXT DEFAULT NULL)
RETURNS REGCLASS AS 'sys_pathman', 'split_range_partition'
LANGUAGE C;

CREATE OR REPLACE internal FUNCTION @extschema@.split_range_partition_compat(
	partition_relid	REGCLASS,
	split_value		ANYELEMENT,
	partition_name1	TEXT DEFAULT NULL,
	tablespace1		TEXT DEFAULT NULL,
	partition_name2	TEXT DEFAULT NULL,
	tablespace2		TEXT DEFAULT NULL)
RETURNS REGCLASS AS 'sys_pathman', 'split_range_partition_compat'
LANGUAGE C;

/*
 * Split RANGE partition in two using a pivot.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.split_list_partition(
	partition_relid	REGCLASS,
	split_value		TEXT,
	partition_name1	TEXT DEFAULT NULL,
	tablespace1		TEXT DEFAULT NULL,
	partition_name2	TEXT DEFAULT NULL,
	tablespace2		TEXT DEFAULT NULL)
RETURNS REGCLASS AS 'sys_pathman', 'split_list_partition'
LANGUAGE C;

/*
 * Merge RANGE partitions.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.merge_range_partitions(
	variadic parts		REGCLASS[])
RETURNS REGCLASS AS 'sys_pathman', 'merge_range_partitions'
LANGUAGE C STRICT;

--compatible with orcle
CREATE OR REPLACE internal FUNCTION @extschema@.merge_range_partitions_compat(
	partition_name      TEXT,
	tablespace          TEXT,
	variadic parts		REGCLASS[])
RETURNS REGCLASS AS 'sys_pathman', 'merge_range_partitions_compat'
LANGUAGE C STRICT;

CREATE OR REPLACE internal FUNCTION @extschema@.merge_list_partitions_compat(
	partition_name      TEXT,
	tablespace          TEXT,
	variadic parts		REGCLASS[])
RETURNS REGCLASS AS 'sys_pathman', 'merge_list_partitions_compat'
LANGUAGE C STRICT;

/*
 * Drops partition and expands the next partition so that it cover dropped one
 *
 * This internal FUNCTION was written in order to support Oracle-like ALTER TABLE ...
 * DROP PARTITION. In Oracle partitions only have upper bound and when
 * partition is dropped the next one automatically covers freed range
 */
CREATE OR REPLACE internal FUNCTION @extschema@.drop_range_partition_expand_next(
	partition_relid		REGCLASS)
RETURNS VOID AS 'sys_pathman', 'drop_range_partition_expand_next'
LANGUAGE C STRICT;

CREATE OR REPLACE internal FUNCTION @extschema@.drop_list_partition(
	partition_relid		REGCLASS)
RETURNS VOID AS 'sys_pathman', 'drop_list_partition_internal'
LANGUAGE C STRICT;

CREATE OR REPLACE internal FUNCTION @extschema@.create_range_partitions_internal(
	parent_relid	REGCLASS,
	bounds			ANYARRAY,
	partition_names	TEXT[],
	tablespaces		TEXT[])
RETURNS REGCLASS AS 'sys_pathman', 'create_range_partitions_internal'
LANGUAGE C;

/*
 * Creates new RANGE partition. Returns partition name.
 * NOTE: This internal FUNCTION SHOULD NOT take xact_handling lock (BGWs in 9.5).
 */
CREATE OR REPLACE internal FUNCTION @extschema@.create_single_range_partition(
	parent_relid	REGCLASS,
	start_value		ANYELEMENT,
	end_value		ANYELEMENT,
	partition_name	TEXT DEFAULT NULL,
	tablespace		TEXT DEFAULT NULL)
RETURNS REGCLASS AS 'sys_pathman', 'create_single_range_partition_pl'
LANGUAGE C
SET client_min_messages = WARNING;

/*
 * Construct CHECK constraint condition for a range partition.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.build_range_condition(
	partition_relid	REGCLASS,
	expression		TEXT,
	start_value		ANYELEMENT,
	end_value		ANYELEMENT)
RETURNS TEXT AS 'sys_pathman', 'build_range_condition'
LANGUAGE C;

/*
 * Generate a name for naming sequence.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.build_sequence_name(
	parent_relid	REGCLASS)
RETURNS TEXT AS 'sys_pathman', 'build_sequence_name'
LANGUAGE C STRICT;

/*
 * Returns N-th range (as an array of two elements).
 */
CREATE OR REPLACE internal FUNCTION @extschema@.get_part_range(
	parent_relid	REGCLASS,
	partition_idx	INTEGER,
	dummy			ANYELEMENT)
RETURNS ANYARRAY AS 'sys_pathman', 'get_part_range_by_idx'
LANGUAGE C;

/*
 * Returns min and max values for specified RANGE partition.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.get_part_range(
	partition_relid	REGCLASS,
	dummy			ANYELEMENT)
RETURNS ANYARRAY AS 'sys_pathman', 'get_part_range_by_oid'
LANGUAGE C;

/*
 * Checks if range overlaps with existing partitions.
 * Returns TRUE if overlaps and FALSE otherwise.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.check_range_available(
	parent_relid	REGCLASS,
	range_min		ANYELEMENT,
	range_max		ANYELEMENT)
RETURNS VOID AS 'sys_pathman', 'check_range_available_pl'
LANGUAGE C;


CREATE OR REPLACE internal FUNCTION @extschema@.check_range_available_compat(
	parent_relid	REGCLASS,
	range_max		ANYELEMENT)
RETURNS VARCHAR AS 'sys_pathman', 'check_range_available_pl_compat'
LANGUAGE C;

/*
 * Generate range bounds starting with 'p_start' using 'p_interval'.
 */
CREATE OR REPLACE internal FUNCTION @extschema@.generate_range_bounds(
	p_start			ANYELEMENT,
	p_interval		INTERVAL,
	p_count			INTEGER)
RETURNS ANYARRAY AS 'sys_pathman', 'generate_range_bounds_pl'
LANGUAGE C STRICT;

CREATE OR REPLACE internal FUNCTION @extschema@.generate_range_bounds(
	p_start			ANYELEMENT,
	p_interval		ANYELEMENT,
	p_count			INTEGER)
RETURNS ANYARRAY AS 'sys_pathman', 'generate_range_bounds_pl'
LANGUAGE C STRICT;

CREATE OR REPLACE internal FUNCTION @extschema@.create_list_partitions_internal(
	parent_relid	REGCLASS,
	bounds			TEXT,
	partition_names	TEXT,
	tablespaces		TEXT)
RETURNS REGCLASS AS 'sys_pathman', 'create_list_partitions_internal'
LANGUAGE C;

CREATE OR REPLACE internal FUNCTION @extschema@.add_list_partition(
	parent_relid	REGCLASS,
	bounds			TEXT,
	partition_names	TEXT,
	tablespaces		TEXT)
RETURNS REGCLASS AS $$
DECLARE
	part_name		REGCLASS;

BEGIN
	PERFORM @extschema@.validate_relname(parent_relid);

	/* Acquire lock on parent's scheme */
	PERFORM @extschema@.prevent_part_modification(parent_relid);

	/* Create new partition */
	part_name := @extschema@.create_list_partitions_internal(parent_relid,
															bounds, partition_names,
															tablespaces);

	RETURN part_name;
END
$$ LANGUAGE plsql;

/*
 * Creates LIST partitions for specified relation based on bounds array
 */
CREATE OR REPLACE internal FUNCTION @extschema@.create_list_partitions(
	parent_relid	REGCLASS,
	expression		TEXT,
	bounds			TEXT,
	partition_names	TEXT DEFAULT NULL,
	tablespaces		TEXT DEFAULT NULL,
	partition_data	BOOLEAN DEFAULT TRUE)
RETURNS REGCLASS AS $$
DECLARE
	ret				REGCLASS;
	exist_part		BIGINT;

BEGIN
--	IF array_ndims(bounds) > 1 THEN
--		RAISE EXCEPTION 'Bounds array must be a one dimensional array';
--	END IF;

--	IF array_length(bounds, 1) < 2 THEN
--		RAISE EXCEPTION 'Bounds array must have at least two values';
--	END IF;

	EXECUTE format('SELECT count(*) FROM pathman_config WHERE pathman_config.PARTREL = ''%s''::REGCLASS', parent_relid)
	INTO exist_part;
	IF exist_part <= 0 THEN
		PERFORM @extschema@.prepare_for_partitioning(parent_relid,
													 expression,
													 partition_data);

		/* Check boundaries */
	/*	bounds_count = array_length(bounds, 1);
		for i in 1..bounds_count loop
		    for j in (i+1)..bounds_count loop
		        if bounds[i]=bounds[j] then
		           RAISE EXCEPTION 'List value % specified twice in partition %', bounds[i], partition_names;
		    end loop;
		end loop;
	*/
		/* Insert new entry to pathman config */
		PERFORM @extschema@.add_to_pathman_config(parent_relid, expression, NULL, NULL);

		/* Create partitions */
		ret := @extschema@.create_list_partitions_internal(parent_relid,
																   bounds,
																   partition_names,
																   tablespaces);

		/* Relocate data if asked to */
		IF partition_data = true THEN
			PERFORM @extschema@.set_enable_parent(parent_relid, false);
			PERFORM @extschema@.partition_data(parent_relid);
		ELSE
			PERFORM @extschema@.set_enable_parent(parent_relid, true);
		END IF;
	ELSE
		ret := @extschema@.add_list_partition(parent_relid,
													bounds,
													partition_names,
													tablespaces);
	END IF;

	RETURN ret;
END
$$
LANGUAGE plsql;

CREATE OR REPLACE internal FUNCTION @extschema@.drop_partition(
	parent_relid		REGCLASS,
	partition_relid		REGCLASS)
RETURNS VOID AS $$
DECLARE
	parttype			INT;

BEGIN
	EXECUTE format('SELECT PARTTYPE FROM pathman_config WHERE pathman_config.PARTREL = ''%s''::REGCLASS', parent_relid)
	INTO parttype;

	IF parttype = 1 THEN
		RAISE EXCEPTION 'deleting hash partitions is not supported';
	ELSIF parttype = 2 THEN
		PERFORM @extschema@.drop_range_partition_expand_next(partition_relid);
	ELSIF parttype = 3 THEN
		PERFORM @extschema@.drop_list_partition(partition_relid);
	END IF;
END
$$ LANGUAGE plsql;

CREATE OR REPLACE internal FUNCTION @extschema@.merge_partitions(
	parent_relid		REGCLASS,
	partition_name      TEXT,
	tablespace          TEXT,
	variadic parts		REGCLASS[])
RETURNS VOID AS $$
DECLARE
	parttype			INT;

BEGIN
	EXECUTE format('SELECT PARTTYPE FROM pathman_config WHERE pathman_config.PARTREL = ''%s''::REGCLASS', parent_relid)
	INTO parttype;

	IF parttype = 1 THEN
		RAISE EXCEPTION 'merge hash partitions is not supported';
	ELSIF parttype = 2 THEN
		PERFORM @extschema@.merge_range_partitions_compat(partition_name, tablespace, variadic parts);
	ELSIF parttype = 3 THEN
		PERFORM @extschema@.merge_list_partitions_compat(partition_name, tablespace, variadic parts);
	END IF;
END
$$ LANGUAGE plsql;

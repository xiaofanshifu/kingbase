\echo Use "CREATE EXTENSION SYSLOGICAL" to load this file. \quit

CREATE TABLE SYSLOGICAL.NODE (
    node_id oid NOT NULL PRIMARY KEY,
    NODE_NAME name NOT NULL UNIQUE
) WITH (user_catalog_table=true);

CREATE TABLE SYSLOGICAL.NODE_INTERFACE (
    if_id oid NOT NULL PRIMARY KEY,
    IF_NAME name NOT NULL, -- default same as node name
    IF_NODEID oid REFERENCES node(NODE_ID),
    if_dsn text NOT NULL,
    UNIQUE (IF_NODEID, IF_NAME)
);

CREATE TABLE SYSLOGICAL.LOCAL_NODE (
    node_id oid PRIMARY KEY REFERENCES node(node_id),
    node_local_interface oid NOT NULL REFERENCES node_interface(if_id)
);

CREATE TABLE SYSLOGICAL.SUBSCRIPTION (
    sub_id oid NOT NULL PRIMARY KEY,
    SUB_NAME name NOT NULL UNIQUE,
    sub_origin oid NOT NULL REFERENCES node(node_id),
    sub_target oid NOT NULL REFERENCES node(node_id),
    sub_origin_if oid NOT NULL REFERENCES node_interface(if_id),
    sub_target_if oid NOT NULL REFERENCES node_interface(if_id),
    sub_enabled boolean NOT NULL DEFAULT true,
    sub_slot_name name NOT NULL,
    sub_replication_sets text[],
    sub_forward_origins text[],
    sub_apply_delay interval NOT NULL DEFAULT '0'
);

CREATE TABLE SYSLOGICAL.LOCAL_SYNC_STATUS (
    sync_kind "CHAR" NOT NULL CHECK (sync_kind IN ('i', 's', 'd', 'f')),
    SYNC_SUBID oid NOT NULL REFERENCES syslogical.subscription(sub_id),
    SYNC_NSPNAME name,
    SYNC_RELNAME name,
    sync_status "CHAR" NOT NULL,
    sync_statuslsn sys_lsn NOT NULL,
    UNIQUE (SYNC_SUBID, SYNC_NSPNAME, SYNC_RELNAME)
);

CREATE TABLE SYSLOGICAL.REPLICATION_SET_SLOT(
	slot_name name NOT NULL PRIMARY KEY,
	rep_sets text[]
);

CREATE INTERNAL FUNCTION SYSLOGICAL.CREATE_NODE(node_name name, dsn text)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_create_node';
CREATE INTERNAL FUNCTION SYSLOGICAL.DROP_NODE(node_name name, ifexists boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_drop_node';

CREATE INTERNAL FUNCTION SYSLOGICAL.ALTER_NODE_ADD_INTERFACE(node_name name, interface_name name, dsn text)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_node_add_interface';
CREATE INTERNAL FUNCTION SYSLOGICAL.ALTER_NODE_DROP_INTERFACE(node_name name, interface_name name)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_node_drop_interface';

CREATE INTERNAL FUNCTION SYSLOGICAL.CREATE_SUBSCRIPTION(subscription_name name, provider_dsn text,
    replication_sets text[] = '{default,default_insert_only,ddl_sql}', synchronize_structure boolean = false,
    synchronize_data boolean = true, forward_origins text[] = '{all}', apply_delay interval DEFAULT '0', check_slot boolean = true)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_create_subscription';
CREATE INTERNAL FUNCTION SYSLOGICAL.DROP_SUBSCRIPTION(subscription_name name, ifexists boolean DEFAULT false)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_drop_subscription';

CREATE INTERNAL FUNCTION SYSLOGICAL.ALTER_SUBSCRIPTION_INTERFACE(subscription_name name, interface_name name)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_interface';

CREATE INTERNAL FUNCTION SYSLOGICAL.ALTER_SUBSCRIPTION_DISABLE(subscription_name name, immediate boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_disable';
CREATE INTERNAL FUNCTION SYSLOGICAL.ALTER_SUBSCRIPTION_ENABLE(subscription_name name, immediate boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_enable';

CREATE INTERNAL FUNCTION SYSLOGICAL.ALTER_SUBSCRIPTION_ADD_REPLICATION_SET(subscription_name name, replication_set name)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_add_replication_set';
CREATE INTERNAL FUNCTION SYSLOGICAL.ALTER_SUBSCRIPTION_REMOVE_REPLICATION_SET(subscription_name name, replication_set name)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_remove_replication_set';

CREATE INTERNAL FUNCTION SYSLOGICAL.SHOW_SUBSCRIPTION_STATUS(subscription_name name DEFAULT NULL,
    OUT subscription_name text, OUT status text, OUT provider_node text,
    OUT provider_dsn text, OUT slot_name text, OUT replication_sets text[],
    OUT forward_origins text[])
RETURNS SETOF record STABLE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_show_subscription_status';

CREATE TABLE SYSLOGICAL.REPLICATION_SET (
    set_id oid NOT NULL PRIMARY KEY,
    SET_NODEID oid NOT NULL,
    SET_NAME name NOT NULL,
    replicate_insert boolean NOT NULL DEFAULT true,
    replicate_update boolean NOT NULL DEFAULT true,
    replicate_delete boolean NOT NULL DEFAULT true,
    replicate_truncate boolean NOT NULL DEFAULT true,
    UNIQUE (SET_NODEID, SET_NAME)
) WITH (user_catalog_table=true);

CREATE TABLE SYSLOGICAL.REPLICATION_SET_TABLE (
    set_id oid NOT NULL,
    set_reloid regclass NOT NULL,
    set_att_list text[],
    set_row_filter sys_node_tree,
    set_row_filter_str text,
    PRIMARY KEY(set_id, set_reloid)
) WITH (user_catalog_table=true);

CREATE TABLE SYSLOGICAL.REPLICATION_SET_SEQ (
    set_id oid NOT NULL,
    set_seqoid regclass NOT NULL,
    PRIMARY KEY(set_id, set_seqoid)
) WITH (user_catalog_table=true);

CREATE TABLE SYSLOGICAL.SEQUENCE_STATE (
	seqoid oid NOT NULL PRIMARY KEY,
	cache_size integer NOT NULL,
	last_value bigint NOT NULL
) WITH (user_catalog_table=true);

CREATE TABLE SYSLOGICAL.DEPEND (
    classid oid NOT NULL,
    objid oid NOT NULL,
    objsubid integer NOT NULL,

    refclassid oid NOT NULL,
    refobjid oid NOT NULL,
    refobjsubid integer NOT NULL,

	deptype "CHAR" NOT NULL
) WITH (user_catalog_table=true);

CREATE VIEW SYSLOGICAL.TABLES AS
    WITH set_relations AS (
        SELECT s.set_name, r.set_reloid
          FROM syslogical.replication_set_table r,
               syslogical.replication_set s,
               syslogical.local_node n
         WHERE s.set_nodeid = n.node_id
           AND s.set_id = r.set_id
    ),
    user_tables AS (
        SELECT r.oid, n.nspname, r.relname, r.relreplident
          FROM sys_catalog.sys_class r,
               sys_catalog.sys_namespace n
         WHERE r.relkind = 'r'
           AND r.relpersistence = 'p'
           AND n.oid = r.relnamespace
           AND n.nspname !~ '^sys_'
           AND n.nspname != 'INFORMATION_SCHEMA'
           AND n.nspname != 'SYSLOGICAL'
    )
    SELECT r.oid AS relid, n.nspname, r.relname, s.set_name
      FROM sys_catalog.sys_namespace n,
           sys_catalog.sys_class r,
           set_relations s
     WHERE r.relkind = 'r'
       AND n.oid = r.relnamespace
       AND r.oid = s.set_reloid
     UNION
    SELECT t.oid AS relid, t.nspname, t.relname, NULL
      FROM user_tables t
     WHERE t.oid NOT IN (SELECT set_reloid FROM set_relations);

CREATE INTERNAL FUNCTION SYSLOGICAL.CREATE_REPLICATION_SET(set_name name,
    replicate_insert boolean = true, replicate_update boolean = true,
    replicate_delete boolean = true, replicate_truncate boolean = true)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_create_replication_set';
CREATE INTERNAL FUNCTION SYSLOGICAL.ALTER_REPLICATION_SET(set_name name,
    replicate_insert boolean DEFAULT NULL, replicate_update boolean DEFAULT NULL,
    replicate_delete boolean DEFAULT NULL, replicate_truncate boolean DEFAULT NULL)
RETURNS oid CALLED ON NULL INPUT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_replication_set';
CREATE INTERNAL FUNCTION SYSLOGICAL.DROP_REPLICATION_SET(set_name name, ifexists boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_drop_replication_set';

CREATE INTERNAL FUNCTION SYSLOGICAL.REPLICATION_SET_ADD_TABLE(set_name name, relation regclass, synchronize_data boolean DEFAULT false,
	columns text[] DEFAULT NULL, row_filter text DEFAULT NULL)
RETURNS boolean CALLED ON NULL INPUT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_add_table';
CREATE INTERNAL FUNCTION SYSLOGICAL.REPLICATION_SET_ADD_ALL_TABLES(set_name name, schema_names text[], synchronize_data boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_add_all_tables';
CREATE INTERNAL FUNCTION SYSLOGICAL.REPLICATION_SET_REMOVE_TABLE(set_name name, relation regclass)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_remove_table';

CREATE INTERNAL FUNCTION SYSLOGICAL.REPLICATION_SET_ADD_SEQUENCE(set_name name, relation regclass, synchronize_data boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_add_sequence';
CREATE INTERNAL FUNCTION SYSLOGICAL.REPLICATION_SET_ADD_ALL_SEQUENCES(set_name name, schema_names text[], synchronize_data boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_add_all_sequences';
CREATE INTERNAL FUNCTION SYSLOGICAL.REPLICATION_SET_REMOVE_SEQUENCE(set_name name, relation regclass)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_remove_sequence';

CREATE INTERNAL FUNCTION SYSLOGICAL.ALTER_SUBSCRIPTION_SYNCHRONIZE(subscription_name name, truncate boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_synchronize';

CREATE INTERNAL FUNCTION SYSLOGICAL.ALTER_SUBSCRIPTION_RESYNCHRONIZE_TABLE(subscription_name name, relation regclass,
	truncate boolean DEFAULT true)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_resynchronize_table';

CREATE INTERNAL FUNCTION SYSLOGICAL.SYNCHRONIZE_SEQUENCE(relation regclass)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_synchronize_sequence';

CREATE INTERNAL FUNCTION SYSLOGICAL.TABLE_DATA_FILTERED(reltyp anyelement, relation regclass, repsets text[])
RETURNS SETOF anyelement CALLED ON NULL INPUT STABLE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_table_data_filtered';

CREATE INTERNAL FUNCTION SYSLOGICAL.SHOW_REPSET_TABLE_INFO(relation regclass, repsets text[], OUT relid oid, OUT nspname text,
	OUT relname text, OUT att_list text[], OUT has_row_filter boolean)
RETURNS record STRICT STABLE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_show_repset_table_info';

CREATE INTERNAL FUNCTION SYSLOGICAL.SHOW_SUBSCRIPTION_TABLE(subscription_name name, relation regclass, OUT nspname text, OUT relname text, OUT status text)
RETURNS record STRICT STABLE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_show_subscription_table';

CREATE TABLE SYSLOGICAL.QUEUE (
    queued_at timestamp with time zone NOT NULL,
    role name NOT NULL,
    replication_sets text[],
    message_type "CHAR" NOT NULL,
    message json NOT NULL
);

CREATE INTERNAL FUNCTION SYSLOGICAL.REPLICATE_DDL_COMMAND(command text, replication_sets text[] DEFAULT '{ddl_sql}')
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replicate_ddl_command';

CREATE OR REPLACE INTERNAL FUNCTION SYSLOGICAL.QUEUE_TRUNCATE()
RETURNS trigger LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_queue_truncate';

CREATE OR REPLACE INTERNAL FUNCTION SYSLOGICAL.DEPENDENCY_CHECK_TRIGGER()
RETURNS event_trigger LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_dependency_check_trigger';

CREATE EVENT TRIGGER SYSLOGICAL_DEPENDENCY_CHECK_TRIGGER
ON sql_drop
EXECUTE PROCEDURE syslogical.dependency_check_trigger();
ALTER EVENT TRIGGER syslogical_dependency_check_trigger ENABLE ALWAYS;

CREATE INTERNAL FUNCTION SYSLOGICAL.SYSLOGICAL_HOOKS_SETUP(internal)
RETURNS void
STABLE LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_hooks_setup';

CREATE INTERNAL FUNCTION SYSLOGICAL.SYSLOGICAL_NODE_INFO(OUT node_id oid, OUT node_name text, OUT sysid text, OUT dbname text, OUT replication_sets text)
RETURNS record
STABLE STRICT LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_node_info';

CREATE INTERNAL FUNCTION SYSLOGICAL.SYSLOGICAL_GEN_SLOT_NAME(name, name, name, name)
RETURNS name
IMMUTABLE STRICT LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_gen_slot_name';

CREATE INTERNAL FUNCTION SYS_CATALOG.SYS_CREATE_LOGICAL_REPLICATION_SLOT(IN slot_name name, IN plugin name, IN xlog_position sys_lsn, OUT slot_name text, OUT xlog_position sys_lsn)
RETURNS record
AS 'MODULE_PATHNAME', 'sys_create_logical_replication_slot'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION SYSLOGICAL_VERSION() RETURNS text
LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_version';

CREATE INTERNAL FUNCTION SYSLOGICAL_VERSION_NUM() RETURNS integer
LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_version_num';

CREATE INTERNAL FUNCTION SYSLOGICAL_MAX_PROTO_VERSION() RETURNS integer
LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_max_proto_version';

CREATE INTERNAL FUNCTION SYSLOGICAL_MIN_PROTO_VERSION() RETURNS integer
LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_min_proto_version';

GRANT USAGE ON SCHEMA SYSLOGICAL TO public;

\echo Use "CREATE EXTENSION syslogical" to load this file. \quit

CREATE TABLE syslogical.node (
    node_id oid NOT NULL PRIMARY KEY,
    node_name name NOT NULL UNIQUE
) WITH (user_catalog_table=true);

CREATE TABLE syslogical.node_interface (
    if_id oid NOT NULL PRIMARY KEY,
    if_name name NOT NULL, -- default same as node name
    if_nodeid oid REFERENCES node(node_id),
    if_dsn text NOT NULL,
    UNIQUE (if_nodeid, if_name)
);

CREATE TABLE syslogical.local_node (
    node_id oid PRIMARY KEY REFERENCES node(node_id),
    node_local_interface oid NOT NULL REFERENCES node_interface(if_id)
);

-- Currently we allow only one node record per database
CREATE UNIQUE INDEX local_node_onlyone ON syslogical.local_node ((true));

CREATE TABLE syslogical.subscription (
    sub_id oid NOT NULL PRIMARY KEY,
    sub_name name NOT NULL UNIQUE,
    sub_origin oid NOT NULL REFERENCES node(node_id),
    sub_target oid NOT NULL REFERENCES node(node_id),
    sub_origin_if oid NOT NULL REFERENCES node_interface(if_id),
    sub_target_if oid NOT NULL REFERENCES node_interface(if_id),
    sub_enabled boolean NOT NULL DEFAULT true,
    sub_slot_name name NOT NULL,
    sub_replication_sets text[],
    sub_forward_origins text[],
    UNIQUE (sub_origin, sub_target)
);

CREATE TABLE syslogical.local_sync_status (
    sync_kind "CHAR" NOT NULL CHECK (sync_kind IN ('i', 's', 'd', 'f')),
    sync_subid oid NOT NULL REFERENCES syslogical.subscription(sub_id),
    sync_nspname name,
    sync_relname name,
    sync_status "CHAR" NOT NULL,
    UNIQUE (sync_subid, sync_nspname, sync_relname)
);


CREATE INTERNAL FUNCTION syslogical.create_node(node_name name, dsn text)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_create_node';
CREATE INTERNAL FUNCTION syslogical.drop_node(node_name name, ifexists boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_drop_node';

CREATE INTERNAL FUNCTION syslogical.create_subscription(subscription_name name, provider_dsn text,
    replication_sets text[] = '{default,default_insert_only}', synchronize_structure boolean = true,
    synchronize_data boolean = true, forward_origins text[] = '{all}', check_slot boolean = true)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_create_subscription';
CREATE INTERNAL FUNCTION syslogical.drop_subscription(subscription_name name, ifexists boolean DEFAULT false)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_drop_subscription';

CREATE INTERNAL FUNCTION syslogical.alter_subscription_disable(subscription_name name, immediate boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_disable';
CREATE INTERNAL FUNCTION syslogical.alter_subscription_enable(subscription_name name, immediate boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_enable';

CREATE INTERNAL FUNCTION syslogical.alter_subscription_add_replication_set(subscription_name name, replication_set name)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_add_replication_set';
CREATE INTERNAL FUNCTION syslogical.alter_subscription_remove_replication_set(subscription_name name, replication_set name)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_remove_replication_set';

CREATE INTERNAL FUNCTION syslogical.show_subscription_status(subscription_name name DEFAULT NULL,
    OUT subscription_name text, OUT status text, OUT provider_node text,
    OUT provider_dsn text, OUT slot_name text, OUT replication_sets text[],
    OUT forward_origins text[])
RETURNS SETOF record STABLE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_show_subscription_status';

CREATE TABLE syslogical.replication_set (
    set_id oid NOT NULL PRIMARY KEY,
    set_nodeid oid NOT NULL,
    set_name name NOT NULL,
    replicate_insert boolean NOT NULL DEFAULT true,
    replicate_update boolean NOT NULL DEFAULT true,
    replicate_delete boolean NOT NULL DEFAULT true,
    replicate_truncate boolean NOT NULL DEFAULT true,
    UNIQUE (set_nodeid, set_name)
) WITH (user_catalog_table=true);

CREATE TABLE syslogical.replication_set_table (
    set_id integer NOT NULL,
    set_reloid regclass NOT NULL,
    PRIMARY KEY(set_id, set_reloid)
) WITH (user_catalog_table=true);

CREATE VIEW syslogical.TABLES AS
    WITH set_tables AS (
        SELECT s.set_name, t.set_reloid
          FROM syslogical.replication_set_table t,
               syslogical.replication_set s,
               syslogical.local_node n
         WHERE s.set_nodeid = n.node_id
           AND s.set_id = t.set_id
    ),
    user_tables AS (
        SELECT r.oid, n.nspname, r.relname, r.relreplident
          FROM sys_catalog.sys_class r,
               sys_catalog.sys_namespace n
         WHERE r.relkind = 'r'
           AND r.relpersistence = 'p'
           AND n.oid = r.relnamespace
           AND n.nspname !~ '^sys_'
           AND n.nspname != 'information_schema'
           AND n.nspname != 'SYSLOGICAL'
    )
    SELECT n.nspname, r.relname, s.set_name
      FROM sys_catalog.sys_namespace n,
           sys_catalog.sys_class r,
           set_tables s
     WHERE r.relkind = 'r'
       AND n.oid = r.relnamespace
       AND r.oid = s.set_reloid
     UNION
    SELECT t.nspname, t.relname, NULL
      FROM user_tables t
     WHERE t.oid NOT IN (SELECT set_reloid FROM set_tables);

CREATE INTERNAL FUNCTION syslogical.create_replication_set(set_name name,
    replicate_insert boolean = true, replicate_update boolean = true,
    replicate_delete boolean = true, replicate_truncate boolean = true)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_create_replication_set';
CREATE INTERNAL FUNCTION syslogical.alter_replication_set(set_name name,
    replicate_insert boolean DEFAULT NULL, replicate_update boolean DEFAULT NULL,
    replicate_delete boolean DEFAULT NULL, replicate_truncate boolean DEFAULT NULL)
RETURNS oid CALLED ON NULL INPUT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_replication_set';
CREATE INTERNAL FUNCTION syslogical.drop_replication_set(set_name name, ifexists boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_drop_replication_set';

CREATE INTERNAL FUNCTION syslogical.replication_set_add_table(set_name name, relation regclass, synchronize boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_add_table';
CREATE INTERNAL FUNCTION syslogical.replication_set_add_all_tables(set_name name, schema_names text[], synchronize boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_add_all_tables';
CREATE INTERNAL FUNCTION syslogical.replication_set_remove_table(set_name name, relation regclass)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_remove_table';

CREATE INTERNAL FUNCTION syslogical.alter_subscription_synchronize(subscription_name name, truncate boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_synchronize';

CREATE INTERNAL FUNCTION syslogical.alter_subscription_resynchronize_table(subscription_name name, relation regclass)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_resynchronize_table';

CREATE INTERNAL FUNCTION syslogical.show_subscription_table(subscription_name name, relation regclass, OUT nspname text, OUT relname text, OUT status text)
RETURNS record STRICT STABLE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_show_subscription_table';

CREATE TABLE syslogical.queue (
    queued_at timestamp with time zone NOT NULL,
    role name NOT NULL,
    replication_sets text[],
    message_type "CHAR" NOT NULL,
    message json NOT NULL
);

CREATE INTERNAL FUNCTION syslogical.replicate_ddl_command(command text)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replicate_ddl_command';

CREATE OR REPLACE INTERNAL FUNCTION syslogical.queue_truncate()
RETURNS trigger LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_queue_truncate';

CREATE OR REPLACE INTERNAL FUNCTION syslogical.truncate_trigger_add()
RETURNS event_trigger LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_truncate_trigger_add';

CREATE EVENT TRIGGER syslogical_truncate_trigger_add
ON ddl_command_end
WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS')
EXECUTE PROCEDURE syslogical.truncate_trigger_add();

CREATE OR REPLACE INTERNAL FUNCTION syslogical.dependency_check_trigger()
RETURNS event_trigger LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_dependency_check_trigger';

CREATE EVENT TRIGGER syslogical_dependency_check_trigger
ON sql_drop
EXECUTE PROCEDURE syslogical.dependency_check_trigger();

CREATE INTERNAL FUNCTION syslogical.syslogical_hooks_setup(internal)
RETURNS void
STABLE LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_hooks_setup';

CREATE INTERNAL FUNCTION syslogical.syslogical_node_info(OUT node_id oid, OUT node_name text, OUT sysid text, OUT dbname text, OUT replication_sets text)
RETURNS record
STABLE STRICT LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_node_info';

CREATE INTERNAL FUNCTION syslogical.syslogical_gen_slot_name(name, name, name, name)
RETURNS name
IMMUTABLE STRICT LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_gen_slot_name';

CREATE INTERNAL FUNCTION syslogical_version() RETURNS text
LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_version';

CREATE INTERNAL FUNCTION syslogical_version_num() RETURNS integer
LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_version_num';

CREATE INTERNAL FUNCTION syslogical_max_proto_version() RETURNS integer
LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_max_proto_version';

CREATE INTERNAL FUNCTION syslogical_min_proto_version() RETURNS integer
LANGUAGE c AS 'MODULE_PATHNAME', 'syslogical_min_proto_version';

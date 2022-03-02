CREATE INTERNAL FUNCTION syslogical.alter_node_add_interface(node_name name, interface_name name, dsn text)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_node_add_interface';
CREATE INTERNAL FUNCTION syslogical.alter_node_drop_interface(node_name name, interface_name name)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_node_drop_interface';

CREATE INTERNAL FUNCTION syslogical.alter_subscription_interface(subscription_name name, interface_name name)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_interface';

DROP FUNCTION syslogical.replicate_ddl_command(command text);
CREATE OR REPLACE INTERNAL FUNCTION syslogical.replicate_ddl_command(command text, replication_sets text[] DEFAULT '{ddl_sql}')
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replicate_ddl_command';

DROP VIEW syslogical.TABLES;
ALTER TABLE syslogical.replication_set_table RENAME TO replication_set_relation;
ALTER TABLE syslogical.replication_set_relation ALTER COLUMN set_id TYPE oid;

CREATE TABLE syslogical.sequence_state (
	seqoid oid NOT NULL PRIMARY KEY,
	cache_size integer NOT NULL,
	last_value bigint NOT NULL
) WITH (user_catalog_table=true);

CREATE OR REPLACE VIEW syslogical.TABLES AS
    WITH set_relations AS (
        SELECT s.set_name, r.set_reloid
          FROM syslogical.replication_set_relation r,
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
           AND n.nspname != 'information_schema'
           AND n.nspname != 'SYSLOGICAL'
    )
    SELECT n.nspname, r.relname, s.set_name
      FROM sys_catalog.sys_namespace n,
           sys_catalog.sys_class r,
           set_relations s
     WHERE r.relkind = 'r'
       AND n.oid = r.relnamespace
       AND r.oid = s.set_reloid
     UNION
    SELECT t.nspname, t.relname, NULL
      FROM user_tables t
     WHERE t.oid NOT IN (SELECT set_reloid FROM set_relations);

CREATE INTERNAL FUNCTION syslogical.replication_set_add_sequence(set_name name, relation regclass, synchronize_data boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_add_sequence';
CREATE INTERNAL FUNCTION syslogical.replication_set_add_all_sequences(set_name name, schema_names text[], synchronize_data boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_add_all_sequences';
CREATE INTERNAL FUNCTION syslogical.replication_set_remove_sequence(set_name name, relation regclass)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_remove_sequence';

CREATE INTERNAL FUNCTION syslogical.synchronize_sequence(relation regclass)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_synchronize_sequence';

ALTER EVENT TRIGGER syslogical_truncate_trigger_add ENABLE ALWAYS;
ALTER EVENT TRIGGER syslogical_dependency_check_trigger ENABLE ALWAYS;

DROP FUNCTION syslogical.create_subscription(subscription_name name, provider_dsn text,
    replication_sets text[], synchronize_structure boolean, synchronize_data boolean, forward_origins text[], check_slot boolean = true);
CREATE INTERNAL FUNCTION syslogical.create_subscription(subscription_name name, provider_dsn text,
    replication_sets text[] = '{default,default_insert_only,ddl_sql}', synchronize_structure boolean = false,
    synchronize_data boolean = true, forward_origins text[] = '{all}', check_slot boolean = true)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_create_subscription';

DROP FUNCTION syslogical.replication_set_add_table(set_name name, relation regclass, synchronize boolean);
CREATE INTERNAL FUNCTION syslogical.replication_set_add_table(set_name name, relation regclass, synchronize_data boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_add_table';

DROP FUNCTION syslogical.replication_set_add_all_tables(set_name name, schema_names text[], synchronize boolean);
CREATE INTERNAL FUNCTION syslogical.replication_set_add_all_tables(set_name name, schema_names text[], synchronize_data boolean DEFAULT false)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replication_set_add_all_tables';

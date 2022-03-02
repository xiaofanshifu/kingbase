CREATE OR REPLACE INTERNAL FUNCTION syslogical.create_subscription(subscription_name name, provider_dsn text,
    replication_sets text[] = '{default,default_insert_only,ddl_sql}', synchronize_structure boolean = true,
    synchronize_data boolean = true, forward_origins text[] = '{all}', check_slot boolean = true)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_create_subscription';

DO $$
BEGIN
	IF (SELECT count(1) FROM syslogical.node) > 0 THEN
		SELECT * FROM syslogical.create_replication_set('ddl_sql', true, false, false, false);
	END IF;
END; $$;

UPDATE syslogical.subscription SET sub_replication_sets = array_append(sub_replication_sets, 'ddl_sql');

WITH applys AS (
	SELECT sub_name FROM syslogical.subscription WHERE sub_enabled
),
disable AS (
	SELECT syslogical.alter_subscription_disable(sub_name, true) FROM applys
)
SELECT syslogical.alter_subscription_enable(sub_name, true) FROM applys;

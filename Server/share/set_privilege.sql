-- Reassign the owner to proper user
-- Security
UPDATE sys_class 
	SET relowner = 
		(
			SELECT oid FROM sys_authid
        	WHERE rolname = 'SYSSSO'
		)
    WHERE relname IN ('SYS_MAC_COMPARTMENT',
					'SYS_MAC_LABEL',
					'SYS_MAC_LEVEL',
					'SYS_MAC_POLICY',
					'SYS_MAC_POLICY_ENFORCEMENT',
					'SYS_MAC_USER',
					-- View from here
					'SYS_MAC_LEVELS',
					'SYS_MAC_COMPARTMENTS',
					'SYS_MAC_LABELS',
					'SYS_MAC_POLICIES',
					'SYS_MAC_TABLE_POLICIES',
					'SYS_MAC_USER_PRIVS',
					'SYS_MAC_USER_LEVELS',
					'SYS_MAC_USER_COMPARTMENTS',
					'SYS_MAC_LABEL_LEVELS',
					'SYS_MAC_LABEL_COMPARTMENTS',
					'SYS_MAC_SESSION',
					'SYS_MAC_SESSION_LABEL_LOOKUP_INFO',
					'SYS_MAC_SESSION_LABEL_MEDIATION'
					);

-- Audit
UPDATE sys_class 
	SET relowner = 
		(
			SELECT oid FROM sys_authid
        	WHERE rolname = 'SYSSAO'
		)
    WHERE relname IN ('SYSAUDIT_RECORD',
					'SYSAUDIT_RECORDS');
-- Audit: FIXME: SYSSAO should transform 2 times.
UPDATE sys_class
		SET relacl = '{"=r/\"SYSSAO\""}'
		WHERE relkind IN ('v')
		AND relowner = (
			SELECT oid FROM sys_authid
			WHERE rolname = 'SYSSAO'
		);

-- Security
UPDATE sys_class
		SET relacl = '{"=r/\"SYSSSO\""}'
		WHERE relkind IN ('v')
		AND relowner = (
			SELECT oid FROM sys_authid
        	WHERE rolname = 'SYSSSO'
		);

-- set owner to sso for sso related function
ALTER FUNCTION create_level OWNER TO "SYSSSO";
ALTER FUNCTION create_compartment OWNER TO "SYSSSO";
ALTER FUNCTION create_label OWNER TO "SYSSSO";
ALTER FUNCTION create_policy OWNER TO "SYSSSO";
ALTER FUNCTION drop_level(text,text) OWNER TO "SYSSSO";
ALTER FUNCTION drop_level(text,int4) OWNER TO "SYSSSO";
ALTER FUNCTION drop_compartment(text,text) OWNER TO "SYSSSO";
ALTER FUNCTION drop_compartment(text,int4) OWNER TO "SYSSSO";
ALTER FUNCTION drop_label(text,text) OWNER TO "SYSSSO";
ALTER FUNCTION drop_label(text,int4) OWNER TO "SYSSSO";
ALTER FUNCTION drop_policy OWNER TO "SYSSSO";
ALTER FUNCTION disable_policy OWNER TO "SYSSSO";
ALTER FUNCTION enable_policy OWNER TO "SYSSSO";
ALTER FUNCTION alter_label(text,text,text) OWNER TO "SYSSSO";
ALTER FUNCTION alter_label(text,int4,text) OWNER TO "SYSSSO";
ALTER FUNCTION set_user_labels OWNER TO "SYSSSO";
ALTER FUNCTION drop_user_access OWNER TO "SYSSSO";
/* ALTER FUNCTION set_default_label OWNER TO "SYSSSO"; */
ALTER FUNCTION apply_table_policy OWNER TO "SYSSSO";
ALTER FUNCTION remove_table_policy OWNER TO "SYSSSO";
ALTER FUNCTION set_user_privs OWNER TO "SYSSSO";
ALTER FUNCTION read_mediation OWNER TO "SYSSSO";
ALTER FUNCTION write_mediation OWNER TO "SYSSSO";
ALTER FUNCTION label_insert OWNER TO "SYSSSO";
ALTER FUNCTION label_update OWNER TO "SYSSSO";
ALTER FUNCTION set_levels OWNER TO "SYSSSO";
ALTER FUNCTION set_compartments OWNER TO "SYSSSO";
/* ALTER FUNCTION set_def_row_label OWNER TO "SYSSSO";  */
/* ALTER FUNCTION set_row_label OWNER TO "SYSSSO";       */
ALTER FUNCTION generate_default_label_value OWNER TO "SYSSSO";
ALTER FUNCTION policy_read_max_label_id OWNER TO "SYSSSO";
ALTER FUNCTION policy_read_min_label_id OWNER TO "SYSSSO";

-- Grant the select to PUBLIC
GRANT USAGE ON SCHEMA sys_catalog TO PUBLIC;
GRANT CREATE, USAGE ON SCHEMA public TO PUBLIC;

/* BUGID: 7395: grant tablespace system's privilege TO public */
GRANT CREATE ON TABLESPACE SYS_DEFAULT TO PUBLIC;

-- revoke all privileges on security table from public
REVOKE ALL ON SYS_MAC_COMPARTMENT, SYS_MAC_LABEL, SYS_MAC_LEVEL, SYS_MAC_POLICY,
			  SYS_MAC_USER, SYS_MAC_POLICY_ENFORCEMENT FROM public;

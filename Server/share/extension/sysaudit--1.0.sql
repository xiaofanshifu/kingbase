-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION sysaudit" to load this file.\quit

CREATE FUNCTION sysaudit.sysaudit_set_rule(audit_taget smallint,
audit_type text, audit_users text, audit_schema text, audit_objs text)
RETURNS void AS
'MODULE_PATHNAME','SysAuditSetRule' LANGUAGE c  CALLED ON NULL INPUT;

CREATE FUNCTION sysaudit.set_audit_stmt(audit_type text, audit_users text,
audit_schema text, audit_objs text)
RETURNS void AS
$$ SELECT sysaudit.sysaudit_set_rule(1::smallint,$1,$2,$3,$4);$$
LANGUAGE SQL  CALLED ON NULL INPUT;

CREATE FUNCTION sysaudit.set_audit_object(audit_type text, audit_users text,
audit_schema text, audit_objs text)
RETURNS void AS
$$ SELECT sysaudit.sysaudit_set_rule(2::smallint,$1,$2,$3,$4);$$
LANGUAGE SQL  CALLED ON NULL INPUT;

CREATE FUNCTION sysaudit.remove_audit(audit_id int)
RETURNS void AS
'MODULE_PATHNAME','SysAuditRemoveRule' LANGUAGE c  CALLED ON NULL INPUT;

CREATE FUNCTION sysaudit_sql_drop()
RETURNS event_trigger
LANGUAGE C
AS 'MODULE_PATHNAME', 'sysaudit_sql_drop';

CREATE EVENT TRIGGER sysaudit_sql_drop
ON sql_drop
EXECUTE PROCEDURE sysaudit_sql_drop();

CREATE FUNCTION sysaudit_ddl_command_end()
RETURNS event_trigger
LANGUAGE C
AS 'MODULE_PATHNAME', 'sysaudit_ddl_command_end';

CREATE EVENT TRIGGER sysaudit_ddl_command_end
ON ddl_command_end
EXECUTE PROCEDURE sysaudit_ddl_command_end();

CREATE FUNCTION sysaudit.show_audit_rules(OUT audit_id int,
OUT audit_target text, OUT audit_type text,
OUT audit_users text, OUT audit_schema text, OUT audit_objname text,
OUT audit_objoid int, OUT creator_name text)
RETURNS SETOF RECORD
AS
'MODULE_PATHNAME','ShowAuditRules'
LANGUAGE c;

CREATE VIEW sysaudit.all_audit_rules
AS SELECT * FROM sysaudit.show_audit_rules() ORDER BY audit_id;

CREATE FUNCTION sys_catalog.sysaudit_fdw_handler()
RETURNS fdw_handler
AS 'MODULE_PATHNAME', 'sysaudit_fdw_handler'
LANGUAGE C STRICT;

CREATE FUNCTION sys_catalog.sysaudit_fdw_validator(text[], oid)
RETURNS void
AS 'MODULE_PATHNAME', 'sysaudit_fdw_validator'
LANGUAGE C STRICT;

CREATE FOREIGN DATA WRAPPER sysaudit_fdw
  HANDLER sys_catalog.sysaudit_fdw_handler
  VALIDATOR sys_catalog.sysaudit_fdw_validator;

CREATE SERVER sysaudit_svr FOREIGN DATA WRAPPER sysaudit_fdw;

/*
 * If you modify the table structure.
 * You must pay attention to handling the function
 *   SysAuditIterateForeignScan in sysaudit_fdw.c accordingly.
 * Make it have correct access to the record_type column.
 *   (tts_isnull [23] and tts_values [23])
 */
CREATE FOREIGN TABLE sysaudit_records_f(
session_id text,
proc_id int,
vxid text,
xid int,
user_id oid,
username text,
remote_addr text,
db_id oid,
db_name text,
rule_id bigint,
rule_type text,
opr_type text,
obj_type text,
schm_id oid,
schm_name text,
obj_id oid,
obj_name text,
sqltext text,
params text,
errcode text,
errmsg text,
audit_ts timestamp with time zone,
failed boolean,
record_type smallint
)
SERVER sysaudit_svr;

ALTER FOREIGN TABLE sysaudit_records_f SET SCHEMA sys_catalog;

CREATE VIEW sysaudit_records AS
  SELECT * FROM sysaudit_records_f WHERE record_type>0;
ALTER VIEW sysaudit_records SET SCHEMA sys_catalog;

CREATE FUNCTION sysaudit.create_ids_rule(rulename text, actionname text, username text,
schname text, objname text, when_ever text, legal_IP text, legal_time text, interval_time int,
times int)RETURNS void AS
'MODULE_PATHNAME','SysauditAddIDSRules' LANGUAGE c CALLED ON NULL INPUT;

CREATE FUNCTION sysaudit.drop_ids_rule(rulename text)
RETURNS VOID AS
'MODULE_PATHNAME','SysAuditIDSRemoveRule' LANGUAGE c CALLED ON NULL INPUT;

CREATE FUNCTION sysaudit.show_ids_rules(OUT rulename text, OUT actionname text,
OUT userOid int, OUT username text, OUT schOid int, OUT schname text,
OUT objOid int, OUT objname text, OUT whenever text,
OUT IP text, OUT start_end_time text, OUT interval_time int, OUT times int)
RETURNS SETOF RECORD
AS
'MODULE_PATHNAME','ShowIDSRules'
LANGUAGE c;

CREATE FUNCTION sysaudit.delete_ids_result(days int)
RETURNS VOID AS
'MODULE_PATHNAME','DeleteSysAuditIDSResult' LANGUAGE c CALLED ON NULL INPUT;

CREATE VIEW sysaudit.all_ids_rules
AS SELECT * FROM sysaudit.show_ids_rules();

CREATE FUNCTION sysaudit.dump_auditlog(days int)
RETURNS void AS
'MODULE_PATHNAME','sysaudit_dump_and_clean_audittrail' LANGUAGE c  CALLED ON NULL INPUT;

CREATE FUNCTION sysaudit.tp_auto_dumplog()
RETURNS void AS
'MODULE_PATHNAME','sysaudit_auto_audlog_tpdb' LANGUAGE c CALLED ON NULL INPUT;

CREATE FUNCTION sysaudit.restore_auditlog(filename text)
RETURNS void AS
'MODULE_PATHNAME','sysaudit_restore_audittrail' LANGUAGE c  CALLED ON NULL INPUT;

CREATE FUNCTION sysaudit.show_audlog_dump_file(OUT filename text,OUT filesize text)
RETURNS SETOF RECORD
AS
'MODULE_PATHNAME','sysaudit_list_logfile'
LANGUAGE c;

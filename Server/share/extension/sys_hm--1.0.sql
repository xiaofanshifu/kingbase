CREATE SCHEMA IF NOT EXISTS SYS_HM;

CREATE TABLE SYS_HM.CHECK_TYPE
(
	type_id 		oid NOT NULL PRIMARY KEY,
	type_name 		name NOT NULL,
	support_offline boolean NOT NULL
);

CREATE TABLE SYS_HM.HM_RUN_T
(
	RUN_ID 			serial,
	run_name 		name NOT NULL PRIMARY KEY,
	check_name 		name NOT NULL,
	run_mode 		int,
	timeout 		int,
	start_time 		Timestamp,
	end_time		Timestamp,
	status			int,
	error_number	int,
	param			text,
	err_msg			text
);

CREATE TABLE SYS_HM.CHECK_PARAM
(
	id				Oid,
	check_id		Oid,
	type			text,
	name			name,
	defval			text
);

insert into sys_hm.check_param values(1, 2, 'INTEGER', 'RELFILENODE', '');
insert into sys_hm.check_param values(2, 2, 'INTEGER', 'RELTABLESPACE', '');
insert into sys_hm.check_param values(3, 2, 'INTEGER', 'BLOCKNUM', '');
insert into sys_hm.check_param values(4, 4, 'INTEGER', 'RELFILENODE', '');
insert into sys_hm.check_param values(5, 4, 'INTEGER', 'RELTABLESPACE', '');
insert into sys_hm.check_param values(6, 4, 'INTEGER', 'BLOCKNUM', '');
insert into sys_hm.check_param values(7, 6, 'TEXT', 'CTL_FILE_ABS_PATH', '');
insert into sys_hm.check_param values(8, 8, 'INTEGER', 'RELFILENODE', '');
insert into sys_hm.check_param values(9, 8, 'INTEGER', 'RELTABLESPACE', '');
insert into sys_hm.check_param values(10, 10, 'TEXT', 'XLOG_FILE_ABS_PATH', '');
insert into sys_hm.check_param values(11, 11, 'TEXT', 'XLOG_FILE_ABS_PATH', '');
insert into sys_hm.check_param values(12, 12, 'TEXT', 'RELNAME', '');
insert into sys_hm.check_param values(13, 13, 'INTEGER', 'THRESHOLD', '500000000');
insert into sys_hm.check_param values(14, 14, 'INTEGER', 'TIME', '7200');


insert into sys_hm.check_type values(1, 'DB Structure Integrity Check', true);
insert into sys_hm.check_type values(2, 'Data Block Integrity Check', true);
insert into sys_hm.check_type values(3, 'Xlog Integrity Check', true);
insert into sys_hm.check_type values(4, 'Logical Block Check', false);
insert into sys_hm.check_type values(5, 'All Control Files Check', true);
insert into sys_hm.check_type values(6, 'Control File Backup Check', true);
insert into sys_hm.check_type values(7, 'All Datafiles Check', true);
insert into sys_hm.check_type values(8, 'Single Datafile Check', true);
insert into sys_hm.check_type values(9, 'All Xlog Check', true);
insert into sys_hm.check_type values(10, 'Single Xlog Check', true);
insert into sys_hm.check_type values(11, 'Archived Xlog Check', true);
insert into sys_hm.check_type values(12, 'Dictionary Integrity Check', false);
insert into sys_hm.check_type values(13, 'Autovacuum Integrity Check', false);
insert into sys_hm.check_type values(14, 'Long Time Connection Check', false);
insert into sys_hm.check_type values(15, 'Connection Percent Check', false);
insert into sys_hm.check_type values(16, 'Disk Usage Check', true);
insert into sys_hm.check_type values(17, 'IO Usage Check', true);
insert into sys_hm.check_type values(18, 'OS Load Average Check', true);
insert into sys_hm.check_type values(19, 'CPU Usage Check', true);
insert into sys_hm.check_type values(20, 'Memory Usage Check', true);
insert into sys_hm.check_type values(21, 'License Validity Check', true);
insert into sys_hm.check_type values(22, 'DB Version Check', true);
insert into sys_hm.check_type values(23, 'DB User Count Check', false);
insert into sys_hm.check_type values(24, 'Lock Wait Check', false);
insert into sys_hm.check_type values(25, 'IO Schedule Check', true);
insert into sys_hm.check_type values(26, 'Network Check', true);

CREATE OR REPLACE VIEW SYS_HM.PARAM as
select n.type_name, n.support_offline, p.type, p.name, p.defval from SYS_HM.CHECK_TYPE n left join SYS_HM.CHECK_PARAM p on n.type_id=p.check_id;

CREATE INTERNAL FUNCTION SYS_HM.RUN_CHECK(check_name name, run_name name,
	input_params text DEFAULT NULL,timeout number DEFAULT NULL)
RETURNS SETOF CString STABLE LANGUAGE c AS 'MODULE_PATHNAME', 'run_check';

CREATE INTERNAL FUNCTION SYS_HM.SHOW_RUN(run_name name)
RETURNS SETOF CString STABLE LANGUAGE c AS 'MODULE_PATHNAME', 'show_run_result';



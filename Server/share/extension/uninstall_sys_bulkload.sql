/*
 * sys_bulkload: uninstall_sys_bulkload.sql
 *
 *    Copyright (c) 2007-2016, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
 */

SET search_path = PG_CATALOG;

DROP FUNCTION SYS_BULKLOAD(TEXT[]);

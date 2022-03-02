/* contrib/orafce.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION kdb_stringfunc" to load this file. \quit
set search_path to sys_catalog;

-----------------------------------------------------------------------------------------
------------------------------mathematical functions-------------------------------------
-----------------------------------------------------------------------------------------
create internal function BITAND (NUMERIC, NUMERIC)
returns numeric
AS 'MODULE_PATHNAME','numeric_bitand'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE
STRICT;

-----------------------------------------------------------------------------------------
-----------------------------------system functions--------------------------------------
-----------------------------------------------------------------------------------------

create internal function CONNECTIONS()
returns bigint
AS 'select count(*) from sys_stat_activity'
LANGUAGE SQL
STABLE
PARALLEL SAFE
STRICT;

create internal function SESSION_ID()
returns int4
AS 'MODULE_PATHNAME','SessionId'
LANGUAGE C
STRICT
PARALLEL SAFE
STABLE;

create internal function TRANSACTION_ID()
returns int4
AS 'MODULE_PATHNAME','GetCurrentTransaction_Id'
LANGUAGE C
STRICT
PARALLEL SAFE
STABLE;

create internal function GETUSERNAME()
returns name
AS 'select current_user'
LANGUAGE SQL
STRICT
PARALLEL SAFE
STABLE;;

-----------------------------------------------------------------------------------------
----------------------------------string functions---------------------------------------
-----------------------------------------------------------------------------------------

-- contains
create internal function CONTAINS(TEXT, TEXT)
returns bool
as 'select to_tsvector($1) @@ to_tsquery($2)'
LANGUAGE SQL
IMMUTABLE
PARALLEL SAFE
STRICT;

create internal function CONTAINS(TSVECTOR, TEXT)
returns bool
as 'select $1 @@ $2::tsquery'
LANGUAGE SQL
IMMUTABLE
PARALLEL SAFE
STRICT;

create internal function CONTAINS(TEXT, TSQUERY)
returns bool
as 'select $1::tsvector @@ $2'
LANGUAGE SQL
IMMUTABLE
PARALLEL SAFE
STRICT;

create internal function CONTAINS(TSVECTOR, TSQUERY)
returns bool
as 'select $1 @@ $2'
LANGUAGE SQL
IMMUTABLE
PARALLEL SAFE
STRICT;

create internal function CONTAINS(TEXT, TEXT, REGCONFIG)
returns bool
as 'select to_tsvector($3, $1) @@ to_tsquery($3, $2)'
LANGUAGE SQL
IMMUTABLE
PARALLEL SAFE
STRICT;

-- lcase
create internal function LCASE(TEXT)
returns text
AS 'select lower($1)'
LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

-- ucase
create internal function UCASE(TEXT)
returns text
AS 'select upper($1)'
LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

-- left
create internal function LEFT(BYTEA, INT)
returns bytea
AS 'MODULE_PATHNAME','bytea_left'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function LEFT(VARBIT, INT)
returns bit
AS 'MODULE_PATHNAME','bit_left'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

-- right
create internal function RIGHT(BYTEA, INT)
returns bytea
AS 'MODULE_PATHNAME','bytea_right'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function RIGHT(VARBIT, INT)
returns bit
AS 'MODULE_PATHNAME','bit_right'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

--lengthb
create internal function LENGTHB(BYTEA)
returns int
AS 'select octet_length($1)'
LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function LENGTHB(TEXT)
returns int
AS 'select octet_length($1)'
LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function LENGTHB(BPCHAR)
returns int
AS 'select octet_length($1)'
LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function LENGTHB(BIT)
returns int
AS 'select octet_length($1)'
LANGUAGE SQL
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function REGEXP_LIKE(TEXT, TEXT)
returns bool
AS 'MODULE_PATHNAME','regexp_like_no_flags'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function REGEXP_LIKE(TEXT, TEXT, TEXT)
returns bool
AS 'MODULE_PATHNAME','regexp_like'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE;

create internal function REGEXP_SUBSTR(TEXT, TEXT)
returns text
AS 'MODULE_PATHNAME','regexp_substr'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function REGEXP_SUBSTR(TEXT, TEXT, INT8)
returns text
AS 'MODULE_PATHNAME','regexp_substr'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function REGEXP_SUBSTR(TEXT, TEXT, INT8, INT8)
returns text
AS 'MODULE_PATHNAME','regexp_substr'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function REGEXP_SUBSTR(TEXT, TEXT, INT8, INT8, TEXT)
returns text
AS 'MODULE_PATHNAME','regexp_substr'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function REGEXP_SUBSTR(TEXT, TEXT, INT8, INT8, TEXT, INT8)
returns text
AS 'MODULE_PATHNAME','regexp_substr'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

/* unicode */
create internal function UNICODE(TEXT)
returns int
AS 'MODULE_PATHNAME','unicode'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

-- upper
create internal function UPPER(VARCHAR)
returns varchar
as 'select upper($1::text)::varchar(8000)'
LANGUAGE SQL
IMMUTABLE
PARALLEL SAFE
STRICT;

-- upper
create internal function UPPER(XML)
returns xml
as 'select upper($1::text)::xml;'
LANGUAGE SQL
IMMUTABLE
PARALLEL SAFE
STRICT;

/* wm_concat_transfn */
create internal function WM_CONCAT_TRANSFN(INTERNAL, TEXT)
returns internal
AS 'MODULE_PATHNAME','wm_concat_transfn'
LANGUAGE C
PARALLEL SAFE
IMMUTABLE;

/* str_valid */
create internal function STR_VALID(TEXT, OID)
returns bool
AS 'MODULE_PATHNAME','str_validate'
LANGUAGE C
STRICT
PARALLEL SAFE
STABLE;

/* substrb */
create internal function SUBSTRB(TEXT, INT)
returns text
AS 'MODULE_PATHNAME','text_substrb_no_len'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function SUBSTRB(TEXT, INT, INT)
returns text
AS 'MODULE_PATHNAME','text_substrb'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

/* wm_concat */
CREATE AGGREGATE WM_CONCAT(TEXT)
(
	SFUNC = wm_concat_transfn,
	STYPE = internal,
	FINALFUNC = string_agg_finalfn,
	PARALLEL = SAFE
);

-- instr
create internal function INSTR(TEXT, TEXT)
returns int
AS 'MODULE_PATHNAME','instr'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function INSTR(TEXT, TEXT, INT)
returns int
AS 'MODULE_PATHNAME','instr'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function INSTR(TEXT, TEXT, INT, INT)
returns int
AS 'MODULE_PATHNAME','instr'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

-- instrb
create internal function INSTRB(TEXT, TEXT)
returns int
AS 'MODULE_PATHNAME','instrb'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function INSTRB(TEXT, TEXT, INT)
returns int
AS 'MODULE_PATHNAME','instrb'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function INSTRB(TEXT, TEXT, INT, INT)
returns int
AS 'MODULE_PATHNAME','instrb'
LANGUAGE C
STRICT
PARALLEL SAFE
IMMUTABLE;

create internal function SYS_GUID_BYTEA()
returns bytea
AS 'MODULE_PATHNAME','sys_guid_bytea'
LANGUAGE C
PARALLEL SAFE
VOLATILE;

create internal function SYS_GUID_NAME()
returns name
AS 'MODULE_PATHNAME','sys_guid_name'
LANGUAGE C
PARALLEL SAFE
VOLATILE;

create or replace internal function sys_catalog.charindex(sub_str varchar, src_str varchar, start_location int default 1)
RETURNS int
as $$
declare
  ret int;
BEGIN
	IF start_location <= 0 THEN
		start_location = 1;
	END IF;

	RETURN sys_catalog.INSTR(src_str, sub_str, start_location, 1);
END;
$$ LANGUAGE plsql
STRICT;

--set search_path to '$user',public;

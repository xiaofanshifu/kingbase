/* contrib/kdb_cast/kdb_cast--1.0.sql */

/* data type name is confilict with gram.y.
 * bit wouldn't/can't be called directly with the name in v7
 * so just rename the function with new name
 */

\echo Use "CREATE EXTENSION kdb_cast" to load this file. \quit
set search_path to sys_catalog;

-- content
---- bit cast
---- text to bytea
---- bool cast
---- number to string
---- string to number
---- time to string
---- string to time
---- time internal
---- misc
---- concat

----------------------------------bit cast--------------------------------------------------------------
/* 				text 	bit 	varbit 	bytea
	 text 		 		e 		e	  	e
	 bit 								i
	 varbit 	e 						i
	 bytea 		e 		a 		a
*/
CREATE INTERNAL FUNCTION TEXTTOBIT(text) 	RETURNS bit 	AS 'MODULE_PATHNAME', 'TextToBit' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION TEXTTOVARBIT(text)	RETURNS varbit 	AS 'MODULE_PATHNAME', 'TextToBit' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BITTOTEXT(varbit) 	RETURNS text 	AS 'MODULE_PATHNAME', 'BitToText' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE INTERNAL FUNCTION BITTOBYTEA(bit) 		RETURNS bytea 	AS 'MODULE_PATHNAME', 'BitToBytea' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION VARBITTOBYTEA(varbit) 	RETURNS bytea 	AS 'MODULE_PATHNAME', 'BitToBytea' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BYTEATOBIT(bytea) 		RETURNS bit 	AS 'MODULE_PATHNAME', 'ByteaToBit' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BYTEATOVARBIT(bytea) 	RETURNS varbit 	AS 'MODULE_PATHNAME', 'ByteaToBit' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE CAST (text as bit) 		WITH FUNCTION TextToBit(text) 		;  --explicit
CREATE CAST (text as varbit) 	WITH FUNCTION TextToVarBit(text) 	;  --explicit
CREATE CAST (varbit as text) 	WITH FUNCTION BitToText(varbit) 	;  --explicit

CREATE CAST (bit as bytea) 		WITH FUNCTION BitToBytea(bit) 		AS IMPLICIT;
CREATE CAST (varbit as bytea) 	WITH FUNCTION VarbitToBytea(varbit) AS IMPLICIT;
CREATE CAST (bytea as bit) 		WITH FUNCTION ByteaToBit(bytea) 	AS ASSIGNMENT;
CREATE CAST (bytea as varbit) 	WITH FUNCTION ByteaToVarbit(bytea) 	AS ASSIGNMENT;

----------------------------------text bytea ------------------------------------------------------------
CREATE INTERNAL FUNCTION TEXT_BYTEA(text) 	RETURNS bytea 	AS 'MODULE_PATHNAME', 'text_bytea' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BYTEA_TEXT(bytea) 	RETURNS text 	AS 'MODULE_PATHNAME', 'bytea_text' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE CAST (text as bytea) 	WITH FUNCTION text_bytea(text) 		;  --explicit
CREATE CAST (bytea as text) 	WITH FUNCTION bytea_text(bytea) 	;  --explicit

----------------------------------bool cast-----------------------------------------------------------
/* 				bool 	int2 	int8 	float4 	flloat8 	numeric		bpchar 	varchar 	text 	bit
	 bool 				a 		a 		a 		a 			a										a
	 int2 		a
	 int8 		a
	 float4 	a
	 float8 	a
	 numeric 	a
	 bpchar 	a
	 varchar 	a
	 text 		a
	 bit 		a
*/
CREATE INTERNAL FUNCTION BOOL(int2) 	RETURNS bool AS 'MODULE_PATHNAME', 'int2_bool' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BOOL(int8) 	RETURNS bool AS 'MODULE_PATHNAME', 'int8_bool' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BOOL(float4) 	RETURNS bool AS 'MODULE_PATHNAME', 'float4_bool' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BOOL(float8) 	RETURNS bool AS 'MODULE_PATHNAME', 'float8_bool' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BOOL(numeric) 	RETURNS bool AS 'MODULE_PATHNAME', 'numeric_bool' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BOOL(text) 	RETURNS bool AS 'MODULE_PATHNAME', 'text_bool' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BOOL(bpchar) 	RETURNS bool AS 'MODULE_PATHNAME', 'text_bool' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BOOL(varchar) 	RETURNS bool AS 'MODULE_PATHNAME', 'text_bool' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BOOL(bit) 		RETURNS bool AS 'MODULE_PATHNAME', 'bit_bool' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE INTERNAL FUNCTION INT2(bool) 		RETURNS int2 	AS 'MODULE_PATHNAME', 'bool_int2' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION INT8(bool) 		RETURNS int8 	AS 'MODULE_PATHNAME', 'bool_int8' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION FLOAT4(bool) 		RETURNS float4 	AS 'MODULE_PATHNAME', 'bool_float4'		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION FLOAT8(bool) 		RETURNS float8 	AS 'MODULE_PATHNAME', 'bool_float8' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BOOL_NUMERIC(bool)	RETURNS numeric AS 'MODULE_PATHNAME', 'bool_numeric'	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION BOOL_BIT(bool) 	RETURNS bit 	AS 'MODULE_PATHNAME', 'bool_bit' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;


CREATE CAST (int2 as bool) 		WITH FUNCTION bool(int2) 	AS ASSIGNMENT;
CREATE CAST (int8 as bool) 		WITH FUNCTION bool(int8) 	AS ASSIGNMENT;
CREATE CAST (float4 as bool) 	WITH FUNCTION bool(float4) 	AS ASSIGNMENT;
CREATE CAST (float8 as bool) 	WITH FUNCTION bool(float8) 	AS ASSIGNMENT;
CREATE CAST (numeric as bool) 	WITH FUNCTION bool(numeric) AS ASSIGNMENT;
CREATE CAST (varchar as bool) 	WITH FUNCTION bool(varchar) AS ASSIGNMENT;
CREATE CAST (bpchar as bool) 	WITH FUNCTION bool(bpchar) 	AS ASSIGNMENT;
CREATE CAST (text as bool) 		WITH FUNCTION bool(text) 	AS ASSIGNMENT;
CREATE CAST (bit as bool) 		WITH FUNCTION bool(bit) 	AS ASSIGNMENT;

CREATE CAST (bool as int2) 		WITH FUNCTION int2(bool)	 		AS ASSIGNMENT;
CREATE CAST (bool as int8) 		WITH FUNCTION int8(bool)	 		AS ASSIGNMENT;
CREATE CAST (bool as float4) 	WITH FUNCTION float4(bool)	 		AS ASSIGNMENT;
CREATE CAST (bool as float8) 	WITH FUNCTION float8(bool) 	 		AS ASSIGNMENT;
CREATE CAST (bool as numeric) 	WITH FUNCTION bool_numeric(bool) 	AS ASSIGNMENT;
CREATE CAST (bool as bit) 		WITH FUNCTION bool_bit(bool) 		AS ASSIGNMENT;

---------------------------------number to string------------------------------------------------------------
/* 				int2 	int8 	float4 	flloat8 	numeric		bpchar 	varchar 	text
	 int2 														a 		a 			i
	 int8 														a 		a 			i
	 float4 													a 		a 			i
	 float8 													a 		a 			i
	 numeric 													a 		a 			i
	 bpchar 	i 		i 		i 		i 			i
	 varchar 	i 		i 		i 		i 			i
	 text 		i 		i 		i 		i 			i
*/

CREATE INTERNAL FUNCTION TEXT(int2) 	RETURNS text as 'MODULE_PATHNAME', 'int2_text'		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION TEXT(int4) 	RETURNS text as 'MODULE_PATHNAME', 'int4_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION TEXT(int8) 	RETURNS text as 'MODULE_PATHNAME', 'int8_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION TEXT(float4) 	RETURNS text as 'MODULE_PATHNAME', 'float4_text' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION TEXT(float8) 	RETURNS text as 'MODULE_PATHNAME', 'float8_text' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

-- CREATE INTERNAL FUNCTION bpchar(int2) 		RETURNS bpchar as 'MODULE_PATHNAME', 'int2_text'		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION bpchar(int4) 		RETURNS bpchar as 'MODULE_PATHNAME', 'int4_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION bpchar(int8) 		RETURNS bpchar as 'MODULE_PATHNAME', 'int8_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION bpchar(float4) 		RETURNS bpchar as 'MODULE_PATHNAME', 'float4_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION bpchar(float8) 		RETURNS bpchar as 'MODULE_PATHNAME', 'float8_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION bpchar(numeric) 		RETURNS bpchar as 'MODULE_PATHNAME', 'numeric_text' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

-- CREATE INTERNAL FUNCTION varchar(int2) 		RETURNS varchar as 'MODULE_PATHNAME', 'int2_text'		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION varchar(int4) 		RETURNS varchar as 'MODULE_PATHNAME', 'int4_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION varchar(int8) 		RETURNS varchar as 'MODULE_PATHNAME', 'int8_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION varchar(float4) 		RETURNS varchar as 'MODULE_PATHNAME', 'float4_text' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION varchar(float8) 		RETURNS varchar as 'MODULE_PATHNAME', 'float8_text' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION varchar(numeric) 	RETURNS varchar as 'MODULE_PATHNAME', 'numeric_text' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE CAST (int2 as text) 		WITH FUNCTION text(int2) 	AS IMPLICIT;
CREATE CAST (int4 as text) 		WITH FUNCTION text(int4) 	AS IMPLICIT;
CREATE CAST (int8 as text) 		WITH FUNCTION text(int8) 	AS IMPLICIT;
CREATE CAST (float4 as text) 	WITH FUNCTION text(float4) 	AS IMPLICIT;
CREATE CAST (float8 as text) 	WITH FUNCTION text(float8) 	AS IMPLICIT;
-- CREATE CAST (numeric as text) 	WITH FUNCTION text(numeric) AS IMPLICIT;

-- CREATE CAST (int2 as bpchar) 	WITH FUNCTION bpchar(int2) 		AS ASSIGNMENT;
-- CREATE CAST (int4 as bpchar) 	WITH FUNCTION bpchar(int4) 		AS ASSIGNMENT;
-- CREATE CAST (int8 as bpchar) 	WITH FUNCTION bpchar(int8) 		AS ASSIGNMENT;
-- CREATE CAST (float4 as bpchar) 	WITH FUNCTION bpchar(float4) 	AS ASSIGNMENT;
-- CREATE CAST (float8 as bpchar) 	WITH FUNCTION bpchar(float8) 	AS ASSIGNMENT;
-- CREATE CAST (numeric as bpchar) 	WITH FUNCTION bpchar(numeric) 	AS ASSIGNMENT;

-- CREATE CAST (int2 as varchar) 		WITH FUNCTION varchar(int2) 	AS ASSIGNMENT;
-- CREATE CAST (int4 as varchar) 		WITH FUNCTION varchar(int4) 	AS ASSIGNMENT;
-- CREATE CAST (int8 as varchar) 		WITH FUNCTION varchar(int8) 	AS ASSIGNMENT;
-- CREATE CAST (float4 as varchar) 		WITH FUNCTION varchar(float4) 	AS ASSIGNMENT;
-- CREATE CAST (float8 as varchar) 		WITH FUNCTION varchar(float8) 	AS ASSIGNMENT;
-- CREATE CAST (numeric as varchar) 	WITH FUNCTION varchar(numeric) 	AS ASSIGNMENT;

---------------------------------string to number------------------------------------------------------------

CREATE INTERNAL FUNCTION INT2(text) 		RETURNS int2 	AS 'MODULE_PATHNAME', 'text_int2' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION INT4(text) 		RETURNS int4 	AS 'MODULE_PATHNAME', 'text_int4' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION INT8(text) 		RETURNS int8 	AS 'MODULE_PATHNAME', 'text_int8' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION FLOAT4(text) 		RETURNS float4 	AS 'MODULE_PATHNAME', 'text_float4' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION FLOAT8(text) 		RETURNS float8 	AS 'MODULE_PATHNAME', 'text_float8' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION text_numeric(text) 	RETURNS numeric AS 'MODULE_PATHNAME', 'text_numeric' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE INTERNAL FUNCTION INT2(bpchar) 			RETURNS int2 	AS 'MODULE_PATHNAME', 'text_int2' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION INT4(bpchar) 			RETURNS int4 	AS 'MODULE_PATHNAME', 'text_int4' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION INT8(bpchar) 			RETURNS int8 	AS 'MODULE_PATHNAME', 'text_int8' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION FLOAT4(bpchar) 		RETURNS float4 	AS 'MODULE_PATHNAME', 'text_float4' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION FLOAT8(bpchar) 		RETURNS float8 	AS 'MODULE_PATHNAME', 'text_float8' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION text_numeric(bpchar) 	RETURNS numeric AS 'MODULE_PATHNAME', 'text_numeric' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE INTERNAL FUNCTION INT2(varchar) 			RETURNS int2 	AS 'MODULE_PATHNAME', 'text_int2' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION INT4(varchar) 			RETURNS int4 	AS 'MODULE_PATHNAME', 'text_int4' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION INT8(varchar) 			RETURNS int8 	AS 'MODULE_PATHNAME', 'text_int8' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION FLOAT4(varchar) 		RETURNS float4 	AS 'MODULE_PATHNAME', 'text_float4' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION FLOAT8(varchar) 		RETURNS float8 	AS 'MODULE_PATHNAME', 'text_float8' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION text_numeric(varchar) 	RETURNS numeric AS 'MODULE_PATHNAME', 'text_numeric' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE CAST (text as int2) 		WITH FUNCTION int2(text) 			AS IMPLICIT;
CREATE CAST (text as int4) 		WITH FUNCTION int4(text) 			AS IMPLICIT;
CREATE CAST (text as int8) 		WITH FUNCTION int8(text) 			AS IMPLICIT;
CREATE CAST (text as float4) 	WITH FUNCTION float4(text) 			AS IMPLICIT;
CREATE CAST (text as float8) 	WITH FUNCTION float8(text) 			AS IMPLICIT;
-- CREATE CAST (text as numeric) 	WITH FUNCTION text_numeric(text) 	AS IMPLICIT;

CREATE CAST (bpchar as int2) 		WITH FUNCTION int2(bpchar) 			AS IMPLICIT;
CREATE CAST (bpchar as int4) 		WITH FUNCTION int4(bpchar) 			AS IMPLICIT;
CREATE CAST (bpchar as int8) 		WITH FUNCTION int8(bpchar) 			AS IMPLICIT;
CREATE CAST (bpchar as float4) 		WITH FUNCTION float4(bpchar) 		AS IMPLICIT;
CREATE CAST (bpchar as float8) 		WITH FUNCTION float8(bpchar) 		AS IMPLICIT;
--CREATE CAST (bpchar as numeric) 	WITH FUNCTION text_numeric(bpchar) 	AS IMPLICIT;

CREATE CAST (varchar as int2) 		WITH FUNCTION int2(varchar) 		AS IMPLICIT;
CREATE CAST (varchar as int4) 		WITH FUNCTION int4(varchar) 		AS IMPLICIT;
CREATE CAST (varchar as int8) 		WITH FUNCTION int8(varchar) 		AS IMPLICIT;
CREATE CAST (varchar as float4) 	WITH FUNCTION float4(varchar) 		AS IMPLICIT;
CREATE CAST (varchar as float8) 	WITH FUNCTION float8(varchar) 		AS IMPLICIT;
--CREATE CAST (varchar as numeric) 	WITH FUNCTION text_numeric(varchar) AS IMPLICIT;

---------------------------------time to string--------------------------------------------------------------
/* 					date 	time 	timetz 	timestamp 	timestamptz 	interval		bpchar 	varchar 	text
	 date 																				a 		a 			i
	 time 									i			i								a 		a 			i
	 timetz									i			i								a 		a 			i
	 timestamp 						i													a 		a 			i																	a 		a 			i
	 timestamptz 																		a 		a 			i
	 interval 																			a 		a 			i
	 bpchar 		i 		i 		i 		i 			i 				i
	 varchar 		i 		i 		i 		i 			i 				i
	 text 			i 		i 		i 		i 			i 				i
*/
CREATE INTERNAL FUNCTION TEXT(date) 		RETURNS text AS 'MODULE_PATHNAME', 'date_text' 			LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TEXT(time) 		RETURNS text AS 'MODULE_PATHNAME', 'time_text' 			LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION TEXT(timetz) 		RETURNS text AS 'MODULE_PATHNAME', 'timetz_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION TEXT(timestamp) 	RETURNS text AS 'MODULE_PATHNAME', 'timestamp_text' 	LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TEXT(timestamptz) 	RETURNS text AS 'MODULE_PATHNAME', 'timestamptz_text' 	LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TEXT(interval) 	RETURNS text AS 'MODULE_PATHNAME', 'interval_text' 		LANGUAGE C STRICT PARALLEL SAFE STABLE;

-- CREATE INTERNAL FUNCTION bpchar(date) 		RETURNS bpchar AS 'MODULE_PATHNAME', 'date_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION bpchar(time) 		RETURNS bpchar AS 'MODULE_PATHNAME', 'time_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION bpchar(timestamp) 	RETURNS bpchar AS 'MODULE_PATHNAME', 'timestamp_text' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION bpchar(timestamptz) 	RETURNS bpchar AS 'MODULE_PATHNAME', 'timestamptz_text' LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION bpchar(interval) 	RETURNS bpchar AS 'MODULE_PATHNAME', 'interval_text' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION bpchar(timetz) 		RETURNS bpchar AS 'MODULE_PATHNAME', 'timetz_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

-- CREATE INTERNAL FUNCTION varchar(date) 		RETURNS varchar AS 'MODULE_PATHNAME', 'date_text' 			LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION varchar(time) 		RETURNS varchar AS 'MODULE_PATHNAME', 'time_text' 			LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION varchar(timestamp) 	RETURNS varchar AS 'MODULE_PATHNAME', 'timestamp_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION varchar(timestamptz) RETURNS varchar AS 'MODULE_PATHNAME', 'timestamptz_text' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION varchar(interval) 	RETURNS varchar AS 'MODULE_PATHNAME', 'interval_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
-- CREATE INTERNAL FUNCTION varchar(timetz) 		RETURNS varchar AS 'MODULE_PATHNAME', 'timetz_text' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE CAST (date as text) 			WITH FUNCTION text(date) 		AS IMPLICIT;
CREATE CAST (time as text) 			WITH FUNCTION text(time) 		AS IMPLICIT;
CREATE CAST (timestamp as text) 	WITH FUNCTION text(timestamp) 	AS IMPLICIT;
CREATE CAST (timestamptz as text) 	WITH FUNCTION text(timestamptz) AS IMPLICIT;
CREATE CAST (interval as text) 		WITH FUNCTION text(interval) 	AS IMPLICIT;
CREATE CAST (timetz as text) 		WITH FUNCTION text(timetz) 		AS IMPLICIT;

-- CREATE CAST (date as bpchar) 		WITH FUNCTION bpchar(date) 			AS ASSIGNMENT;
-- CREATE CAST (time as bpchar) 		WITH FUNCTION bpchar(time) 			AS ASSIGNMENT;
-- CREATE CAST (timestamp as bpchar) 	WITH FUNCTION bpchar(timestamp) 	AS ASSIGNMENT;
-- CREATE CAST (timestamptz as bpchar) 	WITH FUNCTION bpchar(timestamptz) 	AS ASSIGNMENT;
-- CREATE CAST (interval as bpchar) 	WITH FUNCTION bpchar(interval) 		AS ASSIGNMENT;
-- CREATE CAST (timetz as bpchar) 		WITH FUNCTION bpchar(timetz) 		AS ASSIGNMENT;

-- CREATE CAST (date as varchar) 		WITH FUNCTION varchar(date) 		AS ASSIGNMENT;
-- CREATE CAST (time as varchar) 		WITH FUNCTION varchar(time) 		AS ASSIGNMENT;
-- CREATE CAST (timestamp as varchar) 	WITH FUNCTION varchar(timestamp) 	AS ASSIGNMENT;
-- CREATE CAST (timestamptz as varchar) WITH FUNCTION varchar(timestamptz) 	AS ASSIGNMENT;
-- CREATE CAST (interval as varchar) 	WITH FUNCTION varchar(interval) 	AS ASSIGNMENT;
-- CREATE CAST (timetz as varchar) 		WITH FUNCTION varchar(timetz) 		AS ASSIGNMENT;

---------------------------------sting to time---------------------------------------------------------------
CREATE INTERNAL FUNCTION DATE(text) 			RETURNS date 		AS 'MODULE_PATHNAME', 'text_date' 			LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TEXT_TIME(text) 		RETURNS time 		AS 'MODULE_PATHNAME', 'text_time' 			LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TEXT_TIMESTAMP(text) 	RETURNS timestamp 	AS 'MODULE_PATHNAME', 'text_timestamp' 		LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TIMESTAMPTZ(text) 		RETURNS timestamptz AS 'MODULE_PATHNAME', 'text_timestamptz' 	LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TEXT_INTERVAL(text) 	RETURNS interval 	AS 'MODULE_PATHNAME', 'text_interval' 		LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TIMETZ(text) 			RETURNS timetz 		AS 'MODULE_PATHNAME', 'text_timetz' 		LANGUAGE C STRICT PARALLEL SAFE STABLE;

CREATE INTERNAL FUNCTION DATE(bpchar) 			RETURNS date 		AS 'MODULE_PATHNAME', 'text_date' 			LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TEXT_TIME(bpchar) 		RETURNS time 		AS 'MODULE_PATHNAME', 'text_time' 			LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TEXT_TIMESTAMP(bpchar)	RETURNS timestamp 	AS 'MODULE_PATHNAME', 'text_timestamp' 		LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TIMESTAMPTZ(bpchar) 	RETURNS timestamptz AS 'MODULE_PATHNAME', 'text_timestamptz' 	LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TEXT_INTERVAL(bpchar) 	RETURNS interval 	AS 'MODULE_PATHNAME', 'text_interval' 		LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TIMETZ(bpchar) 		RETURNS timetz 		AS 'MODULE_PATHNAME', 'text_timetz' 		LANGUAGE C STRICT PARALLEL SAFE STABLE;

CREATE INTERNAL FUNCTION DATE(varchar) 				RETURNS date 		AS 'MODULE_PATHNAME', 'text_date' 			LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TEXT_TIME(varchar)			RETURNS time 		AS 'MODULE_PATHNAME', 'text_time' 			LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TEXT_TIMESTAMP(varchar) 	RETURNS timestamp 	AS 'MODULE_PATHNAME', 'text_timestamp' 		LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TIMESTAMPTZ(varchar) 		RETURNS timestamptz AS 'MODULE_PATHNAME', 'text_timestamptz' 	LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TEXT_INTERVAL(varchar) 	RETURNS interval 	AS 'MODULE_PATHNAME', 'text_interval' 		LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TIMETZ(varchar) 			RETURNS timetz 		AS 'MODULE_PATHNAME', 'text_timetz' 		LANGUAGE C STRICT PARALLEL SAFE STABLE;

CREATE CAST (text as date) 			WITH FUNCTION date(text) 			AS IMPLICIT;
CREATE CAST (text as time) 			WITH FUNCTION text_time(text) 		AS IMPLICIT;
CREATE CAST (text as timestamp) 	WITH FUNCTION text_timestamp(text) 	AS IMPLICIT;
CREATE CAST (text as timestamptz) 	WITH FUNCTION timestamptz(text) 	AS IMPLICIT;
CREATE CAST (text as interval) 		WITH FUNCTION text_interval(text) 	AS IMPLICIT;
CREATE CAST (text as timetz) 		WITH FUNCTION timetz(text) 			AS IMPLICIT;

CREATE CAST (bpchar as date) 		WITH FUNCTION date(bpchar) 				AS IMPLICIT;
CREATE CAST (bpchar as time) 		WITH FUNCTION text_time(bpchar) 		AS IMPLICIT;
CREATE CAST (bpchar as timestamp) 	WITH FUNCTION text_timestamp(bpchar) 	AS IMPLICIT;
CREATE CAST (bpchar as timestamptz) WITH FUNCTION timestamptz(bpchar) 		AS IMPLICIT;
CREATE CAST (bpchar as interval) 	WITH FUNCTION text_interval(bpchar) 	AS IMPLICIT;
CREATE CAST (bpchar as timetz) 		WITH FUNCTION timetz(bpchar) 			AS IMPLICIT;

CREATE CAST (varchar as date) 			WITH FUNCTION date(varchar) 			AS IMPLICIT;
CREATE CAST (varchar as time) 			WITH FUNCTION text_time(varchar) 		AS IMPLICIT;
CREATE CAST (varchar as timestamp) 		WITH FUNCTION text_timestamp(varchar) 	AS IMPLICIT;
CREATE CAST (varchar as timestamptz) 	WITH FUNCTION timestamptz(varchar) 		AS IMPLICIT;
CREATE CAST (varchar as interval) 		WITH FUNCTION text_interval(varchar) 	AS IMPLICIT;
CREATE CAST (varchar as timetz) 		WITH FUNCTION timetz(varchar) 		 	AS IMPLICIT;
---------------------------------time internal---------------------------------------------------------------
CREATE INTERNAL FUNCTION TIME_TIMESTAMP(time) 		RETURNS timestamp 	AS 'MODULE_PATHNAME', 'time_timestamp' 		LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION TIMETZ_TIMESTAMP(timetz) 	RETURNS timestamp 	AS 'MODULE_PATHNAME', 'timetz_timestamp' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION TIMESTAMPTZ(time) 			RETURNS timestamptz AS 'MODULE_PATHNAME', 'time_timestamptz' 	LANGUAGE C STRICT PARALLEL SAFE STABLE;
CREATE INTERNAL FUNCTION TIMESTAMPTZ(timetz) 		RETURNS timestamptz AS 'MODULE_PATHNAME', 'timetz_timestamptz' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION TIMETZ(timestamp) 			RETURNS timetz 		AS 'MODULE_PATHNAME', 'timestamp_timetz' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE CAST (time as timestamp) 	WITH FUNCTION time_timestamp(time) 		AS IMPLICIT;
CREATE CAST (timetz as timestamp) 	WITH FUNCTION timetz_timestamp(timetz) 	AS IMPLICIT;
CREATE CAST (time as timestamptz) 	WITH FUNCTION timestamptz(time) 		AS IMPLICIT;
CREATE CAST (timetz as timestamptz) WITH FUNCTION timestamptz(timetz) 		AS IMPLICIT;
CREATE CAST (timestamp as timetz) 	WITH FUNCTION timetz(timestamp) 		AS ASSIGNMENT;
-------------------------------misc -------------------------------------------------------------------------
CREATE INTERNAL FUNCTION TEXT_OID(text) 	RETURNS oid     AS 'MODULE_PATHNAME', 'text_oid' 	    LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION INET(text) 		RETURNS inet    AS 'MODULE_PATHNAME', 'text_inet' 	    LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION TEXT_CIDR(text) 	RETURNS cidr    AS 'MODULE_PATHNAME', 'text_cidr' 	    LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION TEXT_MACADDR(text) RETURNS macaddr AS 'MODULE_PATHNAME', 'text_macaddr' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE INTERNAL FUNCTION OID_TEXT(oid)			RETURNS text    AS 'MODULE_PATHNAME', 'oid_text' 	    LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;
CREATE INTERNAL FUNCTION MACADDR_TEXT(macaddr) 	RETURNS text    AS 'MODULE_PATHNAME', 'macaddr_text' 	LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE CAST (text as oid) 	    WITH FUNCTION text_oid(text) 		;  --explicit
CREATE CAST (text as inet) 	    WITH FUNCTION inet(text) 			;  --explicit
CREATE CAST (text as cidr) 	    WITH FUNCTION text_cidr(text) 		;  --explicit
CREATE CAST (text as macaddr) 	WITH FUNCTION text_macaddr(text) 	;  --explicit

CREATE CAST (oid as text) 	    WITH FUNCTION oid_text(oid)  AS IMPLICIT;
CREATE CAST (macaddr as text) 	WITH FUNCTION macaddr_text(macaddr) ;  --explicit
reset search_path;

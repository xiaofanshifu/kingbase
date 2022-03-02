--create functions

--base type to char
create internal function sys_catalog.TO_CHAR(text)
returns text
as $$ select $1;
$$ LANGUAGE SQL STABLE STRICT;

create internal function sys_catalog.TO_CHAR(text, text)
returns text
as $$ select to_char(cast($1 as NUMERIC(38, 10)), cast($2 as text));
$$ LANGUAGE SQL VOLATILE STRICT;

create internal function sys_catalog.TO_CHAR(int2)
returns text
as $$ select cast($1 as text);
$$ LANGUAGE SQL STABLE STRICT;

create internal function sys_catalog.TO_CHAR(int4)
returns text
as $$ select cast($1 as text);
$$ LANGUAGE SQL STABLE STRICT;

create internal function sys_catalog.TO_CHAR(int8)
returns text
as $$ select cast($1 as text);
$$ LANGUAGE SQL STABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TO_CHAR(float4)
RETURNS text
AS $$ select cast($1 as text);
$$ LANGUAGE SQL STABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TO_CHAR(float8)
RETURNS text
AS $$ select cast($1 as text);
$$ LANGUAGE SQL STABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TO_CHAR(num numeric)
RETURNS text
AS $$ select cast($1 as text);
$$ LANGUAGE SQL STABLE STRICT;

--datetime to char
CREATE INTERNAL FUNCTION sys_catalog.TO_CHAR(timestamp)
RETURNS text
AS $$ select to_char($1, 'NULL');
$$ LANGUAGE SQL STABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TO_CHAR(date)
RETURNS text
AS $$ select to_char($1, 'DD-MM-YYYY');
$$ LANGUAGE SQL STABLE STRICT;

--boolean to char
CREATE INTERNAL FUNCTION sys_catalog.TO_CHAR(timestamptz)
RETURNS text
AS $$ select to_char($1, 'DD-MM-YYYY HH.MI.SS.US AM TZ');
$$ LANGUAGE SQL STABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TO_CHAR(boolean)
RETURNS text
AS $$ select cast($1 as text);
$$ LANGUAGE SQL STABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TO_CHAR(boolean, text)
RETURNS text
AS $$ select text($1);
$$ LANGUAGE SQL STABLE STRICT;

--CREATE FUNCTION internal sys_catalog.TO_CHAR(interval)
--RETURNS text
--AS $$ select cast($1 as text);
--$$ LANGUAGE SQL STABLE STRICT;

--to_date
CREATE INTERNAL FUNCTION sys_catalog.TO_DATE(text)
RETURNS date
AS $$ select to_date($1, 'YYYY-MM-DD');
$$ LANGUAGE SQL STABLE STRICT;

--to_timestamp
CREATE INTERNAL FUNCTION sys_catalog.TO_TIMESTAMP(text)
RETURNS timestamp
AS $$ select cast(to_timestamp_tz($1, 'NULL') as timestamp);
$$ LANGUAGE SQL STABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TO_TIMESTAMP(text, text)
RETURNS timestamp
AS $$ select cast(to_timestamp_tz($1, $2) as timestamp);
$$ LANGUAGE SQL STABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TO_TIMESTAMP_TZ(text)
RETURNS timestamptz
AS $$ select to_timestamp_tz($1, 'YYYY-MM-DD HH:MI:SS');
$$ LANGUAGE SQL STABLE STRICT;

--to number
CREATE INTERNAL FUNCTION sys_catalog.TO_NUMBER(text)
RETURNS numeric
AS $$ select to_number($1, '99999999999999999999999999999999999999D99999999999999999999999999999999999999');
$$ LANGUAGE SQL STABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TS_STRIP(tsvector)
RETURNS tsvector AS $$
select strip($1);
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.NLSSORT(col text, method text)
RETURNS bytea
AS 'MODULE_PATHNAME','nls_sort'
LANGUAGE C STABLE STRICT;

--aggregate functions
CREATE INTERNAL FUNCTION sys_catalog.VARCHAR_LARGER(first varchar, second varchar)
RETURNS varchar
AS 'MODULE_PATHNAME', 'varchar_larger'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION sys_catalog.VARCHAR_SMALLER(first varchar, second varchar)
RETURNS varchar
AS 'MODULE_PATHNAME','varchar_smaller'
LANGUAGE C STRICT;

CREATE AGGREGATE sys_catalog.MAX(value varchar) (
  SFUNC= sys_catalog.VARCHAR_LARGER,
  STYPE= varchar,
  COMBINEFUNC = sys_catalog.VARCHAR_LARGER
);

CREATE AGGREGATE sys_catalog.MIN(value varchar) (
  SFUNC= sys_catalog.VARCHAR_SMALLER,
  STYPE= varchar,
  COMBINEFUNC = sys_catalog.VARCHAR_LARGER
);

CREATE INTERNAL FUNCTION sys_catalog.GET_LICENSE_VALUE_RETURN_ABLE(key text)
RETURNS int8
AS 'MODULE_PATHNAME','get_license_value_return_able'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION sys_catalog.GET_LICENSE_VALUE_RETURN_VALUE(key text)
RETURNS text
AS 'MODULE_PATHNAME','get_license_value_return_value'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION sys_catalog.GET_LICENSE_VALUE(in text, out able int8, out value text)
AS $$ SELECT
sys_catalog.GET_LICENSE_VALUE_RETURN_ABLE($1),
sys_catalog.GET_LICENSE_VALUE_RETURN_VALUE($1)
$$ LANGUAGE SQL;

CREATE INTERNAL FUNCTION sys_catalog.BUILD_VERSION()
RETURNS text
AS 'MODULE_PATHNAME','get_build_version'
LANGUAGE C STRICT;

--bmj
CREATE INTERNAL FUNCTION sys_catalog.get_kingbasees_version()
RETURNS text
AS $$ select text('KingBaseES V8.0. (c) 2019 Kingbase Corporation. All rights reserved.');
$$ LANGUAGE SQL STABLE STRICT;

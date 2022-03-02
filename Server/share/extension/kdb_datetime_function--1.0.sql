--CREATE ORA_DATE
--bugId#30455: adapter fanwei about date - date return number
CREATE DOMAIN "SYS_CATALOG"."ORA_DATE" AS TIMESTAMP(0);

CREATE INTERNAL FUNCTION "SYS_CATALOG"."ORACLE_DATE_MI"(ORA_DATE, ORA_DATE)
RETURNS NUMERIC LANGUAGE 'sql'
AS 'SELECT ORA_DATE_MI($1, $2)'
IMMUTABLE
STRICT
PARALLEL
SAFE;

CREATE OPERATOR - (
	LEFTARG = "SYS_CATALOG"."ORA_DATE",
	RIGHTARG = "SYS_CATALOG"."ORA_DATE",
	PROCEDURE = "SYS_CATALOG"."ORACLE_DATE_MI",
	COMMUTATOR = -
);

CREATE INTERNAL FUNCTION "SYS_CATALOG"."ORA_TO_DATE"(TEXT, TEXT)
RETURNS "SYS_CATALOG"."ORA_DATE" LANGUAGE 'sql'
AS 'select cast(to_timestamp_tz($1, $2) as "SYS_CATALOG"."ORA_DATE")'
STABLE
STRICT
PARALLEL SAFE;

/* bugId#30588: adapter fanwei--date data type compatible with oracle */
CREATE INTERNAL FUNCTION "SYS_CATALOG"."ORA_TO_DATE"(TEXT)
RETURNS "SYS_CATALOG"."ORA_DATE" LANGUAGE 'sql'
AS 'select cast(to_timestamp_tz($1, ''YYYY-MM-DD HH24:MI:SS'') as "SYS_CATALOG"."ORA_DATE")'
STABLE
STRICT
PARALLEL SAFE;

create internal function TRUNC(ORA_DATE)
returns ORA_DATE
as 'select cast(date_trunc(''day'', $1) as "SYS_CATALOG"."ORA_DATE")'
LANGUAGE SQL
IMMUTABLE
STRICT;

create internal function TRUNC(ORA_DATE, TEXT)
returns ORA_DATE
as 'select cast(date_trunc($2, $1) as "SYS_CATALOG"."ORA_DATE")'
LANGUAGE SQL
IMMUTABLE
STRICT;

--create functions
--datetime functions
CREATE INTERNAL FUNCTION sys_catalog.TIMESTAMP_ADD_MONTHS(ORA_DATE, NUMERIC)
RETURNS timestamp
AS 'MODULE_PATHNAME','timestamp_add_months'
LANGUAGE C IMMUTABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.ADD_MONTHS(ORA_DATE, NUMERIC)
RETURNS ORA_DATE
as 'select cast(TIMESTAMP_ADD_MONTHS($1, $2) as "SYS_CATALOG"."ORA_DATE")'
LANGUAGE SQL
IMMUTABLE
STRICT;

--CREATE INTERNAL FUNCTION sys_catalog.ADD_MONTHS(day timestamptz, val numeric)
--RETURNS timestamp
--AS $$ select ADD_MONTHS(cast($1 as timestamp), val);
--$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TIMESTAMP_LAST_DAY(day ORA_DATE)
RETURNS timestamp
AS 'MODULE_PATHNAME','timestamp_last_day'
LANGUAGE C IMMUTABLE STRICT;


CREATE INTERNAL FUNCTION sys_catalog.LAST_DAY(ORA_DATE)
RETURNS ORA_DATE
as 'select cast(TIMESTAMP_LAST_DAY($1) as "SYS_CATALOG"."ORA_DATE")'
LANGUAGE SQL
IMMUTABLE
STRICT;

--CREATE INTERNAL FUNCTION sys_catalog.LAST_DAY(day timestamptz)
--RETURNS timestamp
--AS $$ select LAST_DAY(cast($1 as timestamp));
--$$ LANGUAGE SQL IMMUTABLE STRICT;

/* bugId#30588: adapter fanwei--date data type compatible with oracle */
CREATE INTERNAL FUNCTION sys_catalog.TIMESTAMP_NEXT_DAY(day ORA_DATE, weekday text)
RETURNS timestamp
AS 'MODULE_PATHNAME','timestamp_next_day'
LANGUAGE C IMMUTABLE STRICT;


CREATE INTERNAL FUNCTION sys_catalog.NEXT_DAY(ORA_DATE, TEXT)
RETURNS ORA_DATE
as 'select cast(TIMESTAMP_NEXT_DAY($1, $2) as "SYS_CATALOG"."ORA_DATE")'
LANGUAGE SQL
IMMUTABLE
STRICT;

--CREATE INTERNAL FUNCTION sys_catalog.NEXT_DAY(day timestamptz, weekday text)
--RETURNS timestamp
--AS $$ select NEXT_DAY(cast($1 as timestamp), weekday);
--$$ LANGUAGE SQL IMMUTABLE STRICT;

--CREATE INTERNAL FUNCTION sys_catalog.ADD_MONTHS(day date, value numeric)
--RETURNS date
--AS 'MODULE_PATHNAME','date_add_months'
--LANGUAGE C IMMUTABLE STRICT;

--CREATE INTERNAL FUNCTION sys_catalog.NEXT_DAY(value date, weekday text)
--RETURNS date
--AS 'MODULE_PATHNAME','date_next_day'
--LANGUAGE C IMMUTABLE STRICT;

--CREATE INTERNAL FUNCTION sys_catalog.LAST_DAY(value date)
--RETURNS date
--AS 'MODULE_PATHNAME','date_last_day'
--LANGUAGE C IMMUTABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TIMESUB(head timestamptz, tail timestamptz)
RETURNS float8
AS 'MODULE_PATHNAME', 'timesub'
LANGUAGE C IMMUTABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TIMEZONE(value timestamp)
RETURNS timestamptz
AS 'MODULE_PATHNAME','timestamp_localzone'
LANGUAGE C IMMUTABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TIMEZONE(value timestamptz)
RETURNS timestamptz
AS 'MODULE_PATHNAME','timestamptz_localzone'
LANGUAGE C IMMUTABLE STRICT;

CREATE INTERNAL FUNCTION sys_catalog.TIMEZONE(value timetz)
RETURNS timetz
AS 'MODULE_PATHNAME','timetz_localzone'
LANGUAGE C IMMUTABLE STRICT;

/* bugId#30588: adapter fanwei--date data type compatible with oracle */
CREATE INTERNAL FUNCTION sys_catalog.MONTHS_BETWEEN(ORA_DATE, ORA_DATE)
 returns numeric STABLE language sql as $$
  select (extract(years from $1)::int * 12 - extract(years from $2)::int * 12)::numeric +
  (extract(month from $1)::int - extract(month from $2)::int)::numeric +
  (extract(day from $1)::int - extract(day from $2)::int)/31::numeric
$$;

CREATE INTERNAL FUNCTION ZHPRS_START(internal, int4)
RETURNS internal
AS 'MODULE_PATHNAME','zhprs_start'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION ZHPRS_GETLEXEME(internal, internal, internal)
RETURNS internal
AS 'MODULE_PATHNAME','zhprs_getlexeme'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION ZHPRS_END(internal)
RETURNS void
AS 'MODULE_PATHNAME','zhprs_end'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION ZHPRS_LEXTYPE(internal)
RETURNS internal
AS 'MODULE_PATHNAME','zhprs_lextype'
LANGUAGE C STRICT;

CREATE TEXT SEARCH PARSER ZHPARSER (
    START    = zhprs_start,
    GETTOKEN = zhprs_getlexeme,
    END      = zhprs_end,
    HEADLINE = sys_catalog.prsd_headline,
    LEXTYPES = zhprs_lextype
);

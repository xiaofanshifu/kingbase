CREATE INTERNAL FUNCTION JIEBA_START(internal, integer)
RETURNS internal
AS 'MODULE_PATHNAME','jieba_start'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION JIEBA_GETTOKEN(internal, internal, internal)
RETURNS internal
AS 'MODULE_PATHNAME','jieba_gettoken'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION JIEBA_END(internal)
RETURNS void
AS 'MODULE_PATHNAME','jieba_end'
LANGUAGE C STRICT;

CREATE INTERNAL FUNCTION JIEBA_LEXTYPE(internal)
RETURNS internal
AS 'MODULE_PATHNAME','jieba_lextype'
LANGUAGE C STRICT;

CREATE TEXT SEARCH PARSER jieba (
	START    = jieba_start,
	GETTOKEN = jieba_gettoken,
	END      = jieba_end,
	LEXTYPES = jieba_lextype,
	HEADLINE = sys_catalog.prsd_headline
);

CREATE TEXT SEARCH CONFIGURATION jiebacfg (PARSER = jieba);

COMMENT ON TEXT SEARCH CONFIGURATION jiebacfg IS 'configuration for jieba';

CREATE TEXT SEARCH DICTIONARY jieba_stem (TEMPLATE=simple, stopwords = 'jieba');

COMMENT ON TEXT SEARCH DICTIONARY jieba_stem IS 'jieba dictionary: just lower case and check for stopword';

ALTER TEXT SEARCH CONFIGURATION jiebacfg ADD MAPPING FOR n,v,a,d WITH jieba_stem;

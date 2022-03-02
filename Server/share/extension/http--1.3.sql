-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION http" to load this file. \quit

CREATE DOMAIN http_method AS text
CHECK (
    VALUE ILIKE 'get' OR
    VALUE ILIKE 'post' OR
    VALUE ILIKE 'put' OR
    VALUE ILIKE 'delete' OR
    VALUE ILIKE 'patch' OR
    VALUE ILIKE 'head'
);

CREATE DOMAIN content_type AS text
CHECK (
    VALUE ~ '^\S+\/\S+'
);

CREATE TYPE http_header AS (
    field VARCHAR,
    value VARCHAR
);

CREATE TYPE http_response AS (
    status INTEGER,
    content_type VARCHAR,
    headers http_header[],
    content VARCHAR
);

CREATE TYPE http_request AS (
    method http_method,
    uri VARCHAR,
    headers http_header[],
    content_type VARCHAR,
    content VARCHAR
);

CREATE OR REPLACE FUNCTION http_set_curlopt (curlopt VARCHAR, value VARCHAR) 
    RETURNS boolean
    AS 'MODULE_PATHNAME', 'http_set_curlopt'
    LANGUAGE 'c';

CREATE OR REPLACE FUNCTION http_reset_curlopt () 
    RETURNS boolean
    AS 'MODULE_PATHNAME', 'http_reset_curlopt'
    LANGUAGE 'c';

CREATE OR REPLACE FUNCTION http_header (field VARCHAR, value VARCHAR) 
    RETURNS http_header
    AS $$ SELECT $1, $2 $$ 
    LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION http(request http_request)
    RETURNS http_response
    AS 'MODULE_PATHNAME', 'http_request'
    LANGUAGE 'c';

CREATE OR REPLACE FUNCTION http_get(uri VARCHAR)
    RETURNS http_response
    AS $$ SELECT http(('GET', $1, NULL, NULL, NULL)::http_request) $$
    LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION http_post(uri VARCHAR, content VARCHAR, content_type VARCHAR)
    RETURNS http_response
    AS $$ SELECT http(('POST', $1, NULL, $3, $2)::http_request) $$
    LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION http_put(uri VARCHAR, content VARCHAR, content_type VARCHAR)
    RETURNS http_response
    AS $$ SELECT http(('PUT', $1, NULL, $3, $2)::http_request) $$
    LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION http_patch(uri VARCHAR, content VARCHAR, content_type VARCHAR)
    RETURNS http_response
    AS $$ SELECT http(('PATCH', $1, NULL, $3, $2)::http_request) $$
    LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION http_delete(uri VARCHAR)
    RETURNS http_response
    AS $$ SELECT http(('DELETE', $1, NULL, NULL, NULL)::http_request) $$
    LANGUAGE 'sql';
    
CREATE OR REPLACE FUNCTION http_head(uri VARCHAR)
    RETURNS http_response
    AS $$ SELECT http(('HEAD', $1, NULL, NULL, NULL)::http_request) $$
    LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION urlencode(string VARCHAR)
    RETURNS TEXT
    AS 'MODULE_PATHNAME', 'urlencode'
    LANGUAGE 'c'
    IMMUTABLE STRICT;

CREATE SCHEMA UTL_HTTP;

CREATE TYPE UTL_HTTP.req AS(
        url           VARCHAR2(32767),
        method        VARCHAR2(64),
        http_version  VARCHAR2(64));

CREATE TYPE UTL_HTTP.resp AS(
        status_code   INTEGER ,
        reason_phrase  VARCHAR2(256),
        http_version   VARCHAR2(64),
        content        TEXT);

CREATE OR REPLACE FUNCTION UTL_HTTP.BEGIN_REQUEST (
        url               IN  VARCHAR2,
        method            IN  VARCHAR2 DEFAULT 'GET',
        http_version      IN  VARCHAR2 DEFAULT NULL,
        request_context   IN  VARCHAR2 DEFAULT NULL,
        https_host        IN  VARCHAR2 DEFAULT NULL)
    RETURN UTL_HTTP.req AS
        r UTL_HTTP.req;
BEGIN
    PERFORM http_reset_curlopt();
    r.url = url;
    r.method = method;
    return r;
END;

CREATE OR REPLACE PROCEDURE UTL_HTTP.SET_HEADER (
       r       IN OUT UTL_HTTP.req,
       name    IN VARCHAR2,
       value   IN VARCHAR2) AS
BEGIN
    PERFORM http_header(name, value);
END;

CREATE OR REPLACE FUNCTION UTL_HTTP.GET_RESPONSE (
       r                       IN UTL_HTTP.req,
       return_info_response    IN BOOLEAN DEFAULT FALSE)
    RETURN UTL_HTTP.resp AS
        RESP UTL_HTTP.resp;
        sys_resp http_response;
BEGIN
    sys_resp = http_get(r.url);
    RESP.status_code = sys_resp.status;
    RESP.content = sys_resp.content;
    return RESP;
END;

CREATE OR REPLACE PROCEDURE UTL_HTTP.READ_LINE(
   r            IN OUT UTL_HTTP.resp,
   data         OUT VARCHAR2,
   remove_crlf  IN  BOOLEAN DEFAULT FALSE) AS
   sys_resp http_response;
   first_local  integer;
BEGIN
    first_local = instr(r.content, chr(10));
    if first_local <>  0 then
        data = substring(r.content, 1, first_local);
        r.content = substring(r.content, first_local + 1);
        data = substring(data, 1, first_local - 1);
    else
        first_local = instr(r.content, '>');
        data = substring(r.content, 1, first_local);
        r.content = substring(r.content, first_local + 1);
    end if;

    if first_local is NULL OR first_local = 0 then
        raise NO_DATA_FOUND;
    end if;
END;

CREATE OR REPLACE PROCEDURE UTL_HTTP.END_RESPONSE ( r  IN OUT UTL_HTTP.resp) AS
BEGIN
    r.content = NULL;
END;

CREATE OR REPLACE PROCEDURE UTL_HTTP.END_REQUEST (r  IN OUT UTL_HTTP.req) AS
BEGIN
    r.method = NULL;
    r.url = NULL;
END;
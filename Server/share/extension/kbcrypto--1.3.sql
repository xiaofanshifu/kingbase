/* contrib/kbcrypto/kbcrypto--1.3.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION kbcrypto" to load this file. \quit

CREATE INTERNAL FUNCTION digest(text, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'sys_digest'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION digest(bytea, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'sys_digest'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION hmac(text, text, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'sys_hmac'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION hmac(bytea, bytea, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'sys_hmac'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION crypt(text, text)
RETURNS text
AS 'MODULE_PATHNAME', 'sys_crypt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION gen_salt(text)
RETURNS text
AS 'MODULE_PATHNAME', 'sys_gen_salt'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION gen_salt(text, int4)
RETURNS text
AS 'MODULE_PATHNAME', 'sys_gen_salt_rounds'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION encrypt(bytea, bytea, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'sys_encrypt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- sm4
CREATE FUNCTION sm4(bytea, bytea, int4)
RETURNS bytea
AS 'MODULE_PATHNAME', 'sm4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- sm4_ex
CREATE FUNCTION sm4_ex(bytea, bytea, int4, int4)
RETURNS bytea
AS 'MODULE_PATHNAME', 'sm4_ex'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- rc4
CREATE FUNCTION rc4(bytea, bytea, int4)
RETURNS bytea
AS 'MODULE_PATHNAME', 'rc4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION decrypt(bytea, bytea, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'sys_decrypt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION encrypt_iv(bytea, bytea, bytea, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'sys_encrypt_iv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION decrypt_iv(bytea, bytea, bytea, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'sys_decrypt_iv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION gen_random_bytes(int4)
RETURNS bytea
AS 'MODULE_PATHNAME', 'sys_random_bytes'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION gen_random_uuid()
RETURNS uuid
AS 'MODULE_PATHNAME', 'sys_random_uuid'
LANGUAGE C VOLATILE PARALLEL SAFE;

--
-- pgp_sym_encrypt(data, key)
--
CREATE INTERNAL FUNCTION pgp_sym_encrypt(text, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_sym_encrypt_text'
LANGUAGE C STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION pgp_sym_encrypt_bytea(bytea, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_sym_encrypt_bytea'
LANGUAGE C STRICT PARALLEL SAFE;

--
-- pgp_sym_encrypt(data, key, args)
--
CREATE INTERNAL FUNCTION pgp_sym_encrypt(text, text, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_sym_encrypt_text'
LANGUAGE C STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION pgp_sym_encrypt_bytea(bytea, text, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_sym_encrypt_bytea'
LANGUAGE C STRICT PARALLEL SAFE;

--
-- pgp_sym_decrypt(data, key)
--
CREATE INTERNAL FUNCTION pgp_sym_decrypt(bytea, text)
RETURNS text
AS 'MODULE_PATHNAME', 'pgp_sym_decrypt_text'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION pgp_sym_decrypt_bytea(bytea, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_sym_decrypt_bytea'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

--
-- pgp_sym_decrypt(data, key, args)
--
CREATE INTERNAL FUNCTION pgp_sym_decrypt(bytea, text, text)
RETURNS text
AS 'MODULE_PATHNAME', 'pgp_sym_decrypt_text'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION pgp_sym_decrypt_bytea(bytea, text, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_sym_decrypt_bytea'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

--
-- pgp_pub_encrypt(data, key)
--
CREATE INTERNAL FUNCTION pgp_pub_encrypt(text, bytea)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_pub_encrypt_text'
LANGUAGE C STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION pgp_pub_encrypt_bytea(bytea, bytea)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_pub_encrypt_bytea'
LANGUAGE C STRICT PARALLEL SAFE;

--
-- pgp_pub_encrypt(data, key, args)
--
CREATE INTERNAL FUNCTION pgp_pub_encrypt(text, bytea, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_pub_encrypt_text'
LANGUAGE C STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_pub_encrypt_bytea'
LANGUAGE C STRICT PARALLEL SAFE;

--
-- pgp_pub_decrypt(data, key)
--
CREATE INTERNAL FUNCTION pgp_pub_decrypt(bytea, bytea)
RETURNS text
AS 'MODULE_PATHNAME', 'pgp_pub_decrypt_text'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION pgp_pub_decrypt_bytea(bytea, bytea)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_pub_decrypt_bytea'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

--
-- pgp_pub_decrypt(data, key, psw)
--
CREATE INTERNAL FUNCTION pgp_pub_decrypt(bytea, bytea, text)
RETURNS text
AS 'MODULE_PATHNAME', 'pgp_pub_decrypt_text'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_pub_decrypt_bytea'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

--
-- pgp_pub_decrypt(data, key, psw, arg)
--
CREATE INTERNAL FUNCTION pgp_pub_decrypt(bytea, bytea, text, text)
RETURNS text
AS 'MODULE_PATHNAME', 'pgp_pub_decrypt_text'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgp_pub_decrypt_bytea'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

--
-- PGP key ID
--
CREATE INTERNAL FUNCTION pgp_key_id(bytea)
RETURNS text
AS 'MODULE_PATHNAME', 'pgp_key_id_w'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

--
-- pgp armor
--
CREATE INTERNAL FUNCTION armor(bytea)
RETURNS text
AS 'MODULE_PATHNAME', 'sys_armor'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION armor(bytea, text[], text[])
RETURNS text
AS 'MODULE_PATHNAME', 'sys_armor'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION dearmor(text)
RETURNS bytea
AS 'MODULE_PATHNAME', 'sys_dearmor'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE INTERNAL FUNCTION pgp_armor_headers(text, key OUT text, value OUT text)
RETURNS SETOF record
AS 'MODULE_PATHNAME', 'pgp_armor_headers'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

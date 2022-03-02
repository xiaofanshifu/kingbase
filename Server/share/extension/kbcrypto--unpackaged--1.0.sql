/* contrib/kbcrypto/kbcrypto--unpackaged--1.0.sql */

-- complain if script is sourced in ksql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION kbcrypto FROM unpackaged" to load this file. \quit

ALTER EXTENSION kbcrypto ADD function digest(text,text);
ALTER EXTENSION kbcrypto ADD function digest(bytea,text);
ALTER EXTENSION kbcrypto ADD function hmac(text,text,text);
ALTER EXTENSION kbcrypto ADD function hmac(bytea,bytea,text);
ALTER EXTENSION kbcrypto ADD function crypt(text,text);
ALTER EXTENSION kbcrypto ADD function gen_salt(text);
ALTER EXTENSION kbcrypto ADD function gen_salt(text,integer);
ALTER EXTENSION kbcrypto ADD function encrypt(bytea,bytea,text);
-- sm4
ALTER EXTENSION kbcrypto ADD function sm4(bytea,bytea,int4);
-- sm4_ex
ALTER EXTENSION kbcrypto ADD function sm4_ex(bytea,bytea,int4,int4);
-- rc4
ALTER EXTENSION kbcrypto ADD function rc4(bytea,bytea,int4);
ALTER EXTENSION kbcrypto ADD function decrypt(bytea,bytea,text);
ALTER EXTENSION kbcrypto ADD function encrypt_iv(bytea,bytea,bytea,text);
ALTER EXTENSION kbcrypto ADD function decrypt_iv(bytea,bytea,bytea,text);
ALTER EXTENSION kbcrypto ADD function gen_random_bytes(integer);
ALTER EXTENSION kbcrypto ADD function pgp_sym_encrypt(text,text);
ALTER EXTENSION kbcrypto ADD function pgp_sym_encrypt_bytea(bytea,text);
ALTER EXTENSION kbcrypto ADD function pgp_sym_encrypt(text,text,text);
ALTER EXTENSION kbcrypto ADD function pgp_sym_encrypt_bytea(bytea,text,text);
ALTER EXTENSION kbcrypto ADD function pgp_sym_decrypt(bytea,text);
ALTER EXTENSION kbcrypto ADD function pgp_sym_decrypt_bytea(bytea,text);
ALTER EXTENSION kbcrypto ADD function pgp_sym_decrypt(bytea,text,text);
ALTER EXTENSION kbcrypto ADD function pgp_sym_decrypt_bytea(bytea,text,text);
ALTER EXTENSION kbcrypto ADD function pgp_pub_encrypt(text,bytea);
ALTER EXTENSION kbcrypto ADD function pgp_pub_encrypt_bytea(bytea,bytea);
ALTER EXTENSION kbcrypto ADD function pgp_pub_encrypt(text,bytea,text);
ALTER EXTENSION kbcrypto ADD function pgp_pub_encrypt_bytea(bytea,bytea,text);
ALTER EXTENSION kbcrypto ADD function pgp_pub_decrypt(bytea,bytea);
ALTER EXTENSION kbcrypto ADD function pgp_pub_decrypt_bytea(bytea,bytea);
ALTER EXTENSION kbcrypto ADD function pgp_pub_decrypt(bytea,bytea,text);
ALTER EXTENSION kbcrypto ADD function pgp_pub_decrypt_bytea(bytea,bytea,text);
ALTER EXTENSION kbcrypto ADD function pgp_pub_decrypt(bytea,bytea,text,text);
ALTER EXTENSION kbcrypto ADD function pgp_pub_decrypt_bytea(bytea,bytea,text,text);
ALTER EXTENSION kbcrypto ADD function pgp_key_id(bytea);
ALTER EXTENSION kbcrypto ADD function armor(bytea);
ALTER EXTENSION kbcrypto ADD function dearmor(text);

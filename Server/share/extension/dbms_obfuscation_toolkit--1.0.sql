/*contrib/dbms_obfuscation_toolkit/dbms_obfuscation_toolkit--1.0.sql */

\echo USE "CREATE EXTENSION dbms_obfuscation_toolkit" to load this file. \quit

/* CREATE SCHEMA dbms_obfuscation_toolkit; */

/* Inner Function called by package body */
CREATE OR REPLACE FUNCTION toolkit_des3encrypt_ecb(bytea, bytea, integer)
RETURNS bytea 
AS
'MODULE_PATHNAME','toolkit_des3encrypt_ecb'
LANGUAGE C CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION toolkit_des3decrypt_ecb(bytea, bytea, integer)
RETURNS bytea 
AS
'MODULE_PATHNAME','toolkit_des3decrypt_ecb'
LANGUAGE C CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION toolkit_des3encrypt_cbc(bytea, bytea, integer, bytea)
RETURNS bytea 
AS
'MODULE_PATHNAME','toolkit_des3encrypt_cbc'
LANGUAGE C CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION toolkit_des3decrypt_cbc(bytea, bytea, integer, bytea)
RETURNS bytea 
AS
'MODULE_PATHNAME','toolkit_des3decrypt_cbc'
LANGUAGE C CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION toolkit_hash_md5(bytea)
RETURNS bytea
AS
'MODULE_PATHNAME','toolkit_hash_md5'
LANGUAGE C CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION toolkit_des3encrypt_cbc_ivdefault(bytea, bytea, integer)
RETURNS bytea
AS
'MODULE_PATHNAME','toolkit_des3encrypt_cbc_ivdefault'
LANGUAGE C CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION toolkit_des3decrypt_cbc_ivdefault(bytea, bytea, integer)
RETURNS bytea
AS
'MODULE_PATHNAME','toolkit_des3decrypt_cbc_ivdefault'
LANGUAGE C CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION toolkit_desencrypt_cbc_ivdefault(bytea, bytea)
RETURNS bytea
AS
'MODULE_PATHNAME','toolkit_desencrypt_cbc_ivdefault'
LANGUAGE C CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION toolkit_desdecrypt_cbc_ivdefault(bytea, bytea)
RETURNS bytea
AS
'MODULE_PATHNAME','toolkit_desdecrypt_cbc_ivdefault'
LANGUAGE C CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION DBMS_OBFUSCATION_TOOLKIT.DES3ENCRYPT(input_string IN bytea, key_string IN bytea, which IN integer)
RETURNS bytea
AS
DECLARE encrypted_string bytea;
BEGIN
	encrypted_string := DBMS_OBFUSCATION_TOOLKIT.toolkit_des3encrypt_cbc_ivdefault(input_string, key_string, which);
	return encrypted_string;
END;


CREATE OR REPLACE FUNCTION DBMS_OBFUSCATION_TOOLKIT.DES3DECRYPT(input_string IN bytea, key_string IN bytea, which IN integer)
RETURNS bytea
AS
DECLARE decrypted_string bytea;
BEGIN
        decrypted_string := DBMS_OBFUSCATION_TOOLKIT.toolkit_des3decrypt_cbc_ivdefault(input_string, key_string, which);
        return decrypted_string;
END;


CREATE OR REPLACE FUNCTION DBMS_OBFUSCATION_TOOLKIT.DES3ENCRYPT(input_string IN bytea, key_string IN bytea, which IN integer, iv_string IN bytea)
RETURNS bytea
AS
DECLARE encrypted_string bytea;
BEGIN
        if iv_string is NULL then
        encrypted_string := DBMS_OBFUSCATION_TOOLKIT.toolkit_des3encrypt_cbc_ivdefault(input_string, key_string, which);
        else
        encrypted_string := DBMS_OBFUSCATION_TOOLKIT.toolkit_des3encrypt_cbc(input_string, key_string, which, iv_string);
        end if;
        return encrypted_string;
END;

CREATE OR REPLACE FUNCTION DBMS_OBFUSCATION_TOOLKIT.DES3DECRYPT(input_string IN bytea, key_string IN bytea, which IN integer, iv_string IN bytea)
RETURNS bytea
AS
DECLARE decrypted_string bytea;
BEGIN
        if iv_string is NULL then
        decrypted_string := DBMS_OBFUSCATION_TOOLKIT.toolkit_des3decrypt_cbc_ivdefault(input_string, key_string, which);
        else
        decrypted_string := DBMS_OBFUSCATION_TOOLKIT.toolkit_des3decrypt_cbc(input_string, key_string, which, iv_string);
        end if;
        return decrypted_string;
END;

CREATE OR REPLACE FUNCTION DBMS_OBFUSCATION_TOOLKIT.MD5(input_string IN bytea)
RETURNS bytea
AS
DECLARE md5_string bytea;
BEGIN
    	md5_string := DBMS_OBFUSCATION_TOOLKIT.toolkit_hash_md5(input_string);
        return md5_string;
END;

CREATE OR REPLACE FUNCTION DBMS_OBFUSCATION_TOOLKIT.DESENCRYPT(input_string IN bytea, key_string IN bytea)
RETURNS bytea
AS
DECLARE encrypted_string bytea;
BEGIN
        encrypted_string := DBMS_OBFUSCATION_TOOLKIT.toolkit_desencrypt_cbc_ivdefault(input_string, key_string);
        return encrypted_string;
END;

CREATE OR REPLACE FUNCTION DBMS_OBFUSCATION_TOOLKIT.DESDECRYPT(input_string IN bytea, key_string IN bytea)
RETURNS bytea
AS
DECLARE decrypted_string bytea;
BEGIN
        decrypted_string := DBMS_OBFUSCATION_TOOLKIT.toolkit_desdecrypt_cbc_ivdefault(input_string, key_string);
        return decrypted_string;
END;


CREATE OR REPLACE FUNCTION DBMS_OBFUSCATION_TOOLKIT.DESENCRYPT(input_string IN bytea, key_string IN bytea, encrypted_string INOUT bytea)
RETURNS bytea
AS $$
BEGIN
        encrypted_string := DBMS_OBFUSCATION_TOOLKIT.toolkit_desencrypt_cbc_ivdefault(input_string, key_string);
END;
$$ LANGUAGE PLSQL;

CREATE OR REPLACE FUNCTION DBMS_OBFUSCATION_TOOLKIT.DESDECRYPT(input_string IN bytea, key_string IN bytea, decrypted_string INOUT bytea)
RETURNS bytea
AS $$
BEGIN
        decrypted_string := DBMS_OBFUSCATION_TOOLKIT.toolkit_desdecrypt_cbc_ivdefault(input_string, key_string);
END;
$$ LANGUAGE PLSQL;

GRANT ALL ON SCHEMA dbms_obfuscation_toolkit TO PUBLIC;

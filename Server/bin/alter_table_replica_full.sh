#!/bin/bash

[ -f /etc/profile ] && . /etc/profile

##################################################
## Read the parameters from ../etc/logical.conf ##
##################################################

shell_folder=$(dirname $(readlink -f "$0"))

function check_params()
{
    [ "${logical_conf}"x = ""x ] && logical_conf="${shell_folder}/../etc/logical.conf"
    if [ ! -f  ${logical_conf} ]
    then
        echo "no such file \"${logical_conf}\", can not do anything"
        exit 1
    fi

    source ${logical_conf}

    [ "${db_port}"x = ""x ] && db_port=54321
    [ "${bindir}"x = ""x ] && bindir="${shell_folder}"

    if [ ${#db_list[@]} -eq 0 ]
    then
        echo "the values of \"db_list\" is null, exit with error"
        exit 1
    elif [ "${db_user}"x = ""x ]
    then
        echo "the values of \"db_user\" is null, exit with error"
        exit 1
    elif [ ${db_port} -gt 65535 -o ${db_port} -lt 1 ]
    then
        echo "the values of \"db_port\" is incurrect, exit with error"
        echo "the values of \"db_port\" can only set between 1 and 65535"
        exit 1
    elif [ ! -f ${bindir}/ksql ]
    then
        echo "the \"ksql\" is not in \"${bindir}\", exit with error"
        exit 1
    fi
}

function main()
{
    check_params

    for db in ${db_list[@]}
    do
        ## get the connection string
        local conninfo="user=${db_user} dbname=${db} port=${db_port} connect_timeout=5"
        if [ "${db_password}"x != ""x ]
        then
            conninfo="password=${db_password} ${conninfo}"
        fi
        if [ "${db_host}"x != ""x ]
        then
            conninfo="host=${db_host} ${conninfo}"
        fi

        ## execute 'select 33333;' the check the Database is running?
        echo "\"${db}\": check the database is reachable ?"
        local check_connect=`${bindir}/ksql "${conninfo}" -c "select 33333" | grep -w "33333" | wc -l`

        if [ $? -eq 0 -a "${check_connect}"x = "1"x ]
        then
            echo "\"${db}\": connect to database OK"
            ${bindir}/ksql "${conninfo}" -c "\
CREATE or REPLACE PROCEDURE set_table_no_pk_to_replica_full() AS
DECLARE
    sql VARCHAR;
    CURSOR mycur FOR SELECT nspname, relname FROM sys_class c LEFT JOIN sys_namespace n ON n.oid=c.relnamespace WHERE c.oid > 16300 AND c.relkind='r' AND c.oid NOT IN (SELECT conrelid FROM sys_constraint WHERE contype='p');
BEGIN
    FOR i IN mycur LOOP
        sql='ALTER TABLE ' || i.nspname || '.' || i.relname || ' REPLICA IDENTITY FULL';
        RAISE NOTICE '%', sql;
        EXECUTE sql;
    END LOOP;
END;

CALL set_table_no_pk_to_replica_full();

DROP PROCEDURE set_table_no_pk_to_replica_full();
"
            if [ $? -eq 0 ]
            then
                echo "\"${db}\": alter tables which have no primary key to \"REPLICA FULL\" SUCCESS"
            else
                echo "\"${db}\": alter tables which have no primary key to \"REPLICA FULL\" FAILED"
                exit 1
            fi
        else
            echo "\"${db}\": connect to database FAILED"
            exit 1
        fi
    done
}

## call main()
main
exit 0
#!/bin/bash

[ -f /etc/profile ] && . /etc/profile

##################################################
## Read the parameters from ../etc/logical.conf ##
##################################################

##service name of crontab
cron_name=""
cron_file="/etc/cron.d/KINGBASECRON"
##current path
shell_folder=$(dirname $(readlink -f "$0"))
do_command="help"

##load the logical.conf and check the parameters##
function load_config()
{
    [ "${logical_conf}"x = ""x ] && logical_conf="${shell_folder}/../etc/logical.conf"
    if [ ! -f  ${logical_conf} ]
    then
        echo "no such file \"${logical_conf}\", can not do anything"
        exit 1
    fi

    source ${logical_conf}

    [ "${bindir}"x = ""x ] && bindir="${shell_folder}"

    ## Only check the following parameters when START/RESTART
    if [ "${do_command}"x = "start"x -o "${do_command}" = "restart" ]
    then
        [ "${switch_file_interval}"x = ""x ] && switch_file_interval=0
        [ "${db_port}"x = ""x ] && db_port=54321
        [ "${log_level}"x = ""x ] && log_level="INFO"

        log_level=$(echo ${log_level} | tr [a-z] [A-Z])

        if [ "${log_level}"x != "DEBUG"x -a "${log_level}"x != "INFO"x -a "${log_level}"x != "NOLOG"x ]
        then
            echo "the values of \"log_level\" can only set as DEBUG/INFO/NOLOG, exit with error"
            exit 1
        elif [ "${db_user}"x = ""x ]
        then
            echo "the values of \"db_user\" is null, exit with error"
            exit 1
        elif [ "${db_password}"x = ""x ]
        then
            echo "`date +['%Y-%m-%d %H:%M:%S']` the values of \"db_password\" is null, exit with error"
            exit 1
        elif [ ${db_port} -gt 65535 -o ${db_port} -lt 1 ]
        then
            echo "the values of \"db_port\" is incurrect, exit with error"
            echo "the values of \"db_port\" can only set between 1 and 65535"
            exit 1
        elif [ ${switch_file_interval} -lt 0 ]
        then
            echo "the values of \"switch_file_interval\" is incurrect, exit with error"
            exit 1
        fi
    fi

    if [ ${#db_list[@]} -eq 0 ]
    then
        echo "the values of \"db_list\" is null, exit with error"
        exit 1
    elif [ "${target_dir}"x = ""x ]
    then
        echo "the values of \"target_dir\" is null, exit with error"
        exit 1
    elif [[ ${target_dir} != /* ]]
    then
        echo "the values of \"target_dir\" should be absolute path, exit with error"
        exit 1
    elif [ "${target_file}"x = ""x ]
    then
        echo "the values of \"target_file\" is null, exit with error"
        exit 1
    elif [[ ${target_file} == */* ]]
    then
        echo "the values of \"target_file\" can only content the file name, exit with error"
        exit 1
    elif [[ ${bindir} != /* ]]
    then
        echo "the values of \"bindir\" should be absolute path, exit with error"
        exit 1
    elif [ ! -f ${bindir}/sys_recvlogical ]
    then
        echo "the \"sys_recvlogical\" is not in \"${bindir}\", exit with error"
        exit 1
    fi
}

##get the user and check it before execute: only root can execute START/STOP/RESTART
function pre_execute()
{
    load_config

    if [ "${execute_user}"x = ""x ]
    then
        local file_name=$0
        file_name=${file_name##*/}
        local file_path="${shell_folder}/${file_name}"

        local file_owner=`ls -l ${file_path} | awk '{print $3}'`
        execute_user="${file_owner}"
    fi

    local current_user=`id -u`
    if [ $current_user -ne 0 ]
    then
        if [ "${do_command}"x = "status"x ]
        then
            local current_user_name=`whoami`
            if [ "${current_user_name}"x != "${execute_user}"x ]
            then
                echo "can not execute by ${current_user_name}"
                echo "execute \"$0 status\" by root or ${execute_user}"
                exit 1
            fi
        else
            echo "can only exeute by root"
            exit 1
        fi
    fi

    if [ "${cron_name}"x = ""x ]
    then
        which crond > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
            # Now ,we have used these system successfully e.g centos6.x centos7.x redhat.
            cron_name="crond"
        else
            which cron > /dev/null 2>&1
            if [ $? -eq 0 ]
            then
                ## Now ,we have used these system successfully e.g Deepin .
                cron_name="cron"
            else
                echo "Don't know the crontab service name."
            fi
        fi
    fi
}

##setup the cron: set one line for one Database
function setup_cron()
{
    for db in ${db_list[@]}
    do
        local db_cron="*/1 * * * * ${execute_user} . /etc/profile;nohup ${bindir}/sys_recvlogical -s 2 --target-dir ${target_dir}/${db} --do-logical &"
        local cronexist=`cat $cron_file 2>/dev/null| grep -wFn "${db_cron}" |wc -l`
        if [ $cronexist -eq 1 ]
        then
            local realist=`cat $cron_file | grep -wFn "${db_cron}"`
            local linenum=`echo "${realist}" |awk -F':' '{print $1}'`

            sed "${linenum}s/#*//" $cron_file > ${bindir}/crontab.bak
            cat ${bindir}/crontab.bak > $cron_file
        elif [ $cronexist -eq 0 ]
        then
            echo "${db_cron}" >> $cron_file
        else
            return 1
        fi
    done

    [ "${cron_name}"x != ""x ] && service ${cron_name} restart 2>/dev/null
}

##unsetup the cron
function unsetup_cron()
{
    for db in ${db_list[@]}
    do
        local db_cron="*/1 * * * * ${execute_user} . /etc/profile;nohup ${bindir}/sys_recvlogical -s 2 --target-dir ${target_dir}/${db} --do-logical &"
        local cronexist=`cat $cron_file 2>/dev/null| grep -wFn "${db_cron}" |wc -l`
        if [ $cronexist -eq 1 ]
        then
            local realist=`cat $cron_file | grep -wFn "${db_cron}"`
            local linenum=`echo "${realist}" |awk -F':' '{print $1}'`

            sed "${linenum}s/^/#/" $cron_file > ${bindir}/crontab.bak
            cat ${bindir}/crontab.bak > $cron_file
        fi
    done
}

##START: initial the logical.control if it's not exist, start the sys_recvlogical and call funtion setup_cron()
function start()
{
    for db in ${db_list[@]}
    do
        ## initial the logical.control if it's not exist
        if [ ! -f ${target_dir}/${db}/logical.control ]
        then
            local arguments="-d ${db} -U ${db_user} -W ${db_password} -p ${db_port} -f ${target_file} --slot logical_decoder_raw_${db} --plugin decoder_raw"
            if [ "${db_host}"x != ""x ]
            then
                arguments="-h ${db_host} ${arguments}"
            fi

            if [ ${switch_file_interval} -gt 0 ]
            then
                arguments="${arguments} --switch-file-interval ${switch_file_interval}"
            fi
            su - ${execute_user} -c "${bindir}/sys_recvlogical --target-dir ${target_dir}/${db} --log-level ${log_level} --init-control-file ${arguments}"
            if [ $? -ne 0 ]
            then
                echo "can not init control file in dir \"${target_dir}/${db}\" by Operate System User \"${execute_user}\", exit with error"
                exit 1
            fi
        fi

        su - ${execute_user} -c "nohup ${bindir}/sys_recvlogical -s 2 --target-dir ${target_dir}/${db} --do-logical &" 2>/dev/null
        if [ $? -ne 0 ]
        then
            echo "can not start process for database \"${db}\" by Operate System User \"${execute_user}\", exit with error"
            exit 1
        fi
    done

    setup_cron
}

##STOP: call funtion unsetup_cron(), and kill SIGINT for sys_recvlogical
function stop()
{
    unsetup_cron

    for db in ${db_list[@]}
    do
        local sys_pid=`cat ${target_dir}/${db}/logical.pid 2>/dev/null | head -n 1`
        if [ $? -eq 0 -a "${sys_pid}"x != ""x ]
        then
            is_started=`ps hp $sys_pid 2>/dev/null |grep -w "sys_recvlogical"|wc -l`
        else
            is_started=`ps -ef 2>/dev/null|grep -w "sys_recvlogical"|grep -w "\-\-target\-dir ${target_dir}/${db}"|grep -v grep| wc -l`
            sys_pid=""
        fi

        if [ $? -eq 0 ] && [ ${is_started} -eq 0 ]
        then
            continue
        fi

        if [ "${sys_pid}"x != ""x ]
        then
            kill -2 ${sys_pid} 2>/dev/null
        else
            ps -ef 2>/dev/null|grep -w "sys_recvlogical"| grep -w "\-\-target\-dir ${target_dir}/${db}"| grep -v grep| awk '{print $2}'| xargs kill -2
        fi
    done
}

function status()
{
    for db in ${db_list[@]}
    do
        local process_started=0
        local sys_pid=""
        ## check if the process is exist?
        if [ -f ${target_dir}/${db}/logical.pid ]
        then
            local sys_pid=`cat ${target_dir}/${db}/logical.pid 2>/dev/null | head -n 1`
            if [ $? -eq 0 -a "${sys_pid}"x != ""x ]
            then
                is_started=`ps hp $sys_pid 2>/dev/null |grep -w "sys_recvlogical"|wc -l`
                if [ $? -eq 0 -a ${is_started} -gt 0 ]
                then
                    process_started=1
                fi
            fi
        fi

        echo "Database \"${db}\": "
        if [ ${process_started} -eq 1 ]
        then
            echo "the process is still Running(PID ${sys_pid})"
            ${bindir}/sys_recvlogical --target-dir ${target_dir}/${db} --show-control-file
        else
            local is_other_process=`ps -ef 2>/dev/null|grep -w "sys_recvlogical"|grep -w "\-\-target\-dir ${target_dir}/${db}"|grep -v grep| wc -l`
            if [ ${is_other_process} -eq 0 ]
            then
                echo "there is no process Running"
            else
                local other_pid=`ps -ef 2>/dev/null|grep -w "sys_recvlogical"|grep -w "\-\-target\-dir ${target_dir}/${db}"|grep -v grep| awk '{print $2}'`
                echo "there is no process Running, but there is another process (PID ${other_pid}) Running ?"
            fi
        fi
        echo ""
    done
}

case "$1" in
    start)
        do_command="start"
        pre_execute
        start
        ;;
    stop)
        do_command="stop"
        pre_execute
        stop
        ;;
    restart)
        do_command="restart"
        pre_execute
        stop
        start
        ;;
    status)
        do_command="status"
        pre_execute
        status
        ;;
    *)
        echo $"Usage: $0 {start|stop|restart|status}"
        exit 0
esac
exit 0

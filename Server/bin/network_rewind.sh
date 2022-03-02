#!/bin/bash

AUTO_PRIMARY_RECOVERY=0
force_recovery=0
DATA_SIZE_DIFF=16
MOUNT_CHECK_MAX_RETRIES=6

SHELL_FOLDER=$(dirname $(readlink -f "$0"))
CfgFile="${SHELL_FOLDER}/../etc/HAmodule.conf"

if [ ! -f ${CfgFile} ];then
    echo "ERROR: No configuration files!"
    exit 1
fi

# if all databases are DOWN, will start a db to be primary.
# if the 'MAX_AVAILABLE_LEVEL' set to '1' or 'on', start a db and set it to be primary.
MAX_AVAILABLE_LEVEL=0

#read the configuration file HAmodule.conf
function LoadCfg()
{
    while read cfg;do
    param=${cfg%%#*}
        paramName=${param%%=*}
        paramValue=${param#*=}
    if [ -z "${paramName}" ] ; then
        continue
    elif [ -z "${paramValue}" ]; then
        continue
    fi
    eval ${paramName}=${paramValue}
    done < ${CfgFile}
}
LoadCfg

<<COMMENT
KB_GATEWAY_IP=""
KB_LOCALHOST_IP=""
NODE_NAME=""
ALL_NODE_NAME=()
SYNC_FLAG=0
KB_VIP="192.168.8.177"
DEV="eth0"
KB_POOL_VIP=""
KB_POOL_PORT=9999
# KB_POOL_PCP_PORT=9898
PCP_USER="help"
PCP_PASS=""
KB_ETC_PATH="/home/kdb/KingbaseES/V8/etc"
KB_PATH="/opt/KingbaseES/V8/bin"
CLUSTER_BIN_PATH="/opt/KingbaseES/V8/Cluster/bin"
KB_DATA_PATH="/opt/KingbaseES/V8/data"
# KB_USER="SYSTEM"
KB_PASS="123456"
KB_DATANAME="TEST"
KB_PORT="55433"
KB_EXECUTE_SYS_USER="lx"
RECOVERY_LOG_DIR="/tmp/recovery.log"
KB_CLUSTER_STATUS="/tmp/pool_nodes"
CMD_IP_PATH="/sbin"

CONNECTTIMEOUT=15
HEALTH_CHECK_MAX_RETRIES=2
HEALTH_CHECK_RETRY_DELAY=5

#the dir list of the mount point for the filesystem
MOUNT_POINT_DIR_LIST=()

# if failed in check_mount_point(), should stop the database? default is on, do stop db
USE_CHECK_DISK=1

COMMENT

KB_RECOVERY_FLAG="/dev/shm/KB_RECOVERY_FLAG"
KB_POOL_PCP_PORT=9898
PING_TIMES=3
KB_REAL_PASS=`echo $KB_PASS | base64 -d 2>/dev/null`
PCP_REAL_PASS=`echo $PCP_PASS | base64 -d 2>/dev/null`
FILE_NAME=`date '+%s'`

export PATH=$KB_PATH:$CLUSTER_BIN_PATH:$PATH

#AUTO RECOVERY
#STOPED AND PING act

# get the value of 'AUTO_PRIMARY_RECOVERY', default is '0'/'off'
if [ "${AUTO_PRIMARY_RECOVERY}"x = "1"x -o "${AUTO_PRIMARY_RECOVERY}"x = "on"x -o "${AUTO_PRIMARY_RECOVERY}"x = "true"x -o "${AUTO_PRIMARY_RECOVERY}"x = "yes"x ]
then
    AUTO_PRIMARY_RECOVERY=1
else
    AUTO_PRIMARY_RECOVERY=0
fi

# get the value of 'USE_CHECK_DISK', default is '1'/'on'
if [ "${USE_CHECK_DISK}"x = "0"x -o "${USE_CHECK_DISK}"x = "off"x -o "${USE_CHECK_DISK}"x = "false"x -o "${USE_CHECK_DISK}"x = "no"x ]
then
    USE_CHECK_DISK=0
else
    USE_CHECK_DISK=1
fi

# get the value of 'MAX_AVAILABLE_LEVEL', default is '0'/'off'
if [ "${MAX_AVAILABLE_LEVEL}"x = "1"x -o "${MAX_AVAILABLE_LEVEL}"x = "on"x -o "${MAX_AVAILABLE_LEVEL}"x = "true"x -o "${MAX_AVAILABLE_LEVEL}"x = "yes"x ]
then
    MAX_AVAILABLE_LEVEL=1
elif [ "${MAX_AVAILABLE_LEVEL}"x = "0"x -o "${MAX_AVAILABLE_LEVEL}"x = "off"x -o "${MAX_AVAILABLE_LEVEL}"x = "false"x -o "${MAX_AVAILABLE_LEVEL}"x = "no"x ]
then
    MAX_AVAILABLE_LEVEL=0
else
    MAX_AVAILABLE_LEVEL=0
    echo "WARNING: invalid values for MAX_AVAILABLE_LEVEL, set it as default 'off'" >> $RECOVERY_LOG_DIR 2>&1
fi

if [ "$1"x = "--force"x ]
then
    force_recovery=1
fi

#the function of error handing
function errorhandle()
{
    error_flag=$1
    error_cmd=$2
    if [ "${error_flag}"x = ""x ]
    then
        echo "errorhandle function's argument is null " >> $RECOVERY_LOG_DIR  2>&1
        echo 0 > ${KB_RECOVERY_FLAG}
        exit 66;
    fi
    if [ "${error_flag}"x = "exit"x ]
    then
        echo "${error_cmd}"  >> $RECOVERY_LOG_DIR 2>&1
        if [ $force_recovery -eq 1 ]
        then
            echo "${error_cmd}"
        fi
        echo 0 > ${KB_RECOVERY_FLAG}
        exit 66;
    elif [ "${error_flag}"x = "stopdbexit"x ]
    then
        echo "${error_cmd}" >> $RECOVERY_LOG_DIR 2>&1
        echo "stop db....."  >> $RECOVERY_LOG_DIR 2>&1
        if [ $force_recovery -eq 1 ]
        then
            echo "${error_cmd}"
            echo "stop db....."
        fi
        sys_ctl stop -w -t 90 -D $KB_DATA_PATH -m fast >> $RECOVERY_LOG_DIR 2>&1
        delvip
        echo 0 > ${KB_RECOVERY_FLAG}
        exit 66;
    else
        echo "${error_cmd}" >> $RECOVERY_LOG_DIR 2>&1
        if [ $force_recovery -eq 1 ]
        then
            echo "${error_cmd}"
        fi
    fi
}

#the function of delete db vip
function delvip()
{
    if [ "$KB_VIP"x != ""x ]
    then
        echo "`date +'%Y-%m-%d %H:%M:%S'` now will del vip [$KB_VIP]" >> $RECOVERY_LOG_DIR 2>&1
        vip_alive=0
        for((i=1;i<=$HEALTH_CHECK_MAX_RETRIES;i++))
        do
            vipnum=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l root -T localhost "${CMD_IP_PATH}/ip addr | grep -w \"$KB_VIP\" | wc -l;echo \";\" \\${PIPESTATUS[*]}"`

            result_of_vipnum=`echo $vipnum |awk -F ';' '{print $1}'|awk '{print $1}'`
            cmd_ip=`echo $vipnum |awk -F ';' '{print $2}'|awk '{print $1}'`
            cmd_grep=`echo $vipnum |awk -F ';' '{print $2}'|awk '{print $2}'`
            cmd_wc=`echo $vipnum |awk -F ';' '{print $2}'|awk '{print $3}'`

            if [ "${cmd_ip}"x != "0"x -o "${cmd_wc}"x != "0"x ]
            then
                echo "ip addr execute failed,will retry ,retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" >> $RECOVERY_LOG_DIR 2>&1
                errorhandle "continue" "\"ssh -o StrictHostKeyChecking=no -l root -T localhost \"${CMD_IP_PATH}/ip addr | grep -w \"$KB_VIP\" | wc -l\"\" execute failed, error num=[$cmd_ip $cmd_grep $cmd_wc ]" 
                continue
            fi

            if [ "${result_of_vipnum}"x = "1"x ]
            then
                echo "execute [${CMD_IP_PATH}/ip addr del $KB_VIP dev $DEV ]" >> $RECOVERY_LOG_DIR 2>&1
                vipdel=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l root -T localhost "${CMD_IP_PATH}/ip addr del $KB_VIP dev $DEV;echo \";\" \\${PIPESTATUS[*]}"`
                cmd_ssh=$?
                if [ "${cmd_ssh}"x != "0"x ]
                then
                    echo "ssh execute failed,will retry ,retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" >> $RECOVERY_LOG_DIR 2>&1
                    errorhandle "continue" "\"ssh -o StrictHostKeyChecking=no -l root -T localhost \"${CMD_IP_PATH}/ip addr del $KB_VIP dev $DEV\"\" execute failed, error num=[$cmd_ssh]"
                    continue
                fi
                result_of_vipdel=`echo $vipdel |awk -F ';' '{print $1}'|awk '{print $1}'`
                cmd_ip=`echo $vipdel |awk -F ';' '{print $2}'|awk '{print $1}'`
                if [ "${cmd_ip}"x != "0"x ]
                then
                    echo "ip addr del execute failed,will retry ,retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" >> $RECOVERY_LOG_DIR 2>&1
                    errorhandle "continue" "\"ssh -o StrictHostKeyChecking=no -l root -T localhost \"${CMD_IP_PATH}/ip addr del $KB_VIP dev $DEV\"\" execute failed, error num=[$cmd_ip]"
                    continue
                fi
                echo $result_of_vipdel >> $RECOVERY_LOG_DIR 2>&1

                sleep $HEALTH_CHECK_RETRY_DELAY
            else
                echo "but no $KB_VIP on my DEV, nothing to do with del" >> $RECOVERY_LOG_DIR 2>&1
                vip_alive=1
                break
            fi
        done
        if [ $vip_alive -eq 0 ]
        then
            errorhandle "exit"  "del vip failed,after retry ${HEALTH_CHECK_MAX_RETRIES} times ,cannot del vip, will exit"
        fi
    fi

}

#the function of add db vip
function addvip()
{
    if [ "$KB_VIP"x != ""x ]
    then
        echo "`date +'%Y-%m-%d %H:%M:%S'` now check vip [$KB_VIP]" >> $RECOVERY_LOG_DIR 2>&1
        vip_alive=0
        for((i=1;i<=$HEALTH_CHECK_MAX_RETRIES;i++))
        do
            vipnum=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l root -T localhost "${CMD_IP_PATH}/ip addr | grep -w \"$KB_VIP\" | wc -l;echo \";\" \\${PIPESTATUS[*]}"`

            result_of_vipnum=`echo $vipnum |awk -F ';' '{print $1}'|awk '{print $1}'`
            cmd_ip=`echo $vipnum |awk -F ';' '{print $2}'|awk '{print $1}'`
            cmd_grep=`echo $vipnum |awk -F ';' '{print $2}'|awk '{print $2}'`
            cmd_wc=`echo $vipnum |awk -F ';' '{print $2}'|awk '{print $3}'`

            if [ "${cmd_ip}"x != "0"x -o "${cmd_wc}"x != "0"x ]
            then
                echo "ip addr execute failed, will retry, retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" >> $RECOVERY_LOG_DIR 2>&1
                errorhandle "continue" "\"ssh -o StrictHostKeyChecking=no -l root -T localhost \"${CMD_IP_PATH}/ip addr | grep -w \"$KB_VIP\" | wc -l\"\" execute failed, error num=[$cmd_ip $cmd_grep $cmd_wc]"
                continue
            fi

            if [ "${result_of_vipnum}"x = "1"x ]
            then
                echo "the $KB_VIP is already on myself" >> $RECOVERY_LOG_DIR 2>&1
                vip_alive=1
                break
            else
                echo "the $KB_VIP is not exits on myself, try to add the vip" >> $RECOVERY_LOG_DIR 2>&1
                echo "execute [${CMD_IP_PATH}/ip addr add $KB_VIP dev $DEV label ${DEV}:2]" >> $RECOVERY_LOG_DIR 2>&1
                ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l root -T localhost "${CMD_IP_PATH}/ip addr add $KB_VIP dev $DEV label ${DEV}:2" >> $RECOVERY_LOG_DIR 2>&1
                cmd_ssh=$?
                if [ "${cmd_ssh}"x != "0"x ]
                then
                    echo "ssh execute [ip addr add] failed, will retry, retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" >> $RECOVERY_LOG_DIR 2>&1
                    errorhandle "continue" "\"ssh -o StrictHostKeyChecking=no -l root -T localhost \"${CMD_IP_PATH}/ip addr add $KB_VIP dev $DEV label ${DEV}:2\"\" execute failed, error num=[$cmd_ssh]"
                    continue
                fi

                echo "execute [${CMD_ARPING_PATH}/arping -U ${KB_VIP%%/*} -I $DEV -w 1 -c 1 2>/dev/null]" >> $RECOVERY_LOG_DIR 2>&1
                ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l root -T localhost "${CMD_ARPING_PATH}/arping -U ${KB_VIP%%/*} -I $DEV -w 1 -c 1 2>/dev/null" >> $RECOVERY_LOG_DIR 2>&1
                cmd_ssh=$?
                if [ "${cmd_ssh}"x != "0"x ]
                then
                    echo "ssh execute [arping] failed, try to del the vip by [${CMD_IP_PATH}/ip addr del $KB_VIP dev $DEV]" >> $RECOVERY_LOG_DIR 2>&1
                    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l root -T localhost "${CMD_IP_PATH}/ip addr del $KB_VIP dev $DEV" >> $RECOVERY_LOG_DIR 2>&1
                    echo "will retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" >> $RECOVERY_LOG_DIR 2>&1
                    errorhandle "continue" "\"ssh -o StrictHostKeyChecking=no -l root -T localhost \"${CMD_ARPING_PATH}/arping -U ${KB_VIP%%/*} -I $DEV -w 1 -c 1 2>/dev/null\"\" execute failed, error num=[$cmd_ssh]"
                    continue
                fi

                vip_alive=1
                break
            fi
        done
        if [ $vip_alive -eq 0 ]
        then
            errorhandle "continue" "add vip failed, after retry ${HEALTH_CHECK_MAX_RETRIES} times, cannot add vip"
        fi
    fi
}

#if network down ,exit
function checktrustip()
{
OLD_IFS="$IFS"
IFS=","
ip_arr=($KB_GATEWAY_IP)
IFS="$OLD_IFS"
PING_FLAG=0

for((i=1;i<=$HEALTH_CHECK_MAX_RETRIES;i++))
do
    for trust_ip in ${ip_arr[@]}
    do
        result=`ping $trust_ip -c $PING_TIMES -w 2 | grep received | awk '{print $4}'; echo ";" ${PIPESTATUS[*]}`
        result_of_ping=`echo $result |awk -F ';' '{print $1}'|awk '{print $1}'`
        cmd_ping=`echo $result |awk -F ';' '{print $2}' |awk '{print $1}'`
        cmd_grep=`echo $result |awk -F ';' '{print $2}' |awk '{print $2}'`
        cmd_awk=`echo $result |awk -F ';' '{print $2}' |awk '{print $3}'`

        if [ "${cmd_ping}"x != "0"x -a "${cmd_ping}"x != "1"x ]
        then
            echo "the ${i}th time ping trust ip failed ,will ping the next trust ip" >> $RECOVERY_LOG_DIR 2>&1
            errorhandle "continue" "\"ping $trust_ip -c $PING_TIMES -w 2 | grep received | awk '{print $4}'\" execute failed, error num=[$cmd_ping $cmd_grep $cmd_awk ]"
            continue
        fi
        if [ "${cmd_awk}"x != "0"x ]
        then
            echo "the ${i}th time ping trust ip failed ,will ping the next trust ip" >> $RECOVERY_LOG_DIR 2>&1
            errorhandle "continue" "\"ping $trust_ip -c $PING_TIMES -w 2 | grep received | awk '{print $4}'\" execute failed, error num=[$cmd_ping $cmd_grep $cmd_awk ]"
            continue
        fi
        if [ "$result_of_ping"x = ""x ]
        then
            echo "the ${i}th time ping trust ip failed ,will ping the next trust ip" >> $RECOVERY_LOG_DIR 2>&1
            errorhandle "continue" "ping execute failed please check....."
            continue
        fi
        if [ $result_of_ping -gt 0 ]
        then
            echo "ping trust ip $trust_ip success ping times :[$PING_TIMES], success times:[$result_of_ping] " >> $RECOVERY_LOG_DIR 2>&1
            PING_FLAG=1
            break
        else
            echo "ping trust ip $trust_ip failed,will ping next trust ip " >> $RECOVERY_LOG_DIR 2>&1
        fi
    done
    if [ $PING_FLAG -eq 1 ]
    then
        break
    fi
    echo "the ${i}th time ping all trust ip failed,will ping trust ip the next time, retry times: [${i}/${HEALTH_CHECK_MAX_RETRIES}] " >> $RECOVERY_LOG_DIR 2>&1
done

if [ $PING_FLAG -eq 0 ]
then
    errorhandle "stopdbexit" "ping all trust ip failed, retry times:${HEALTH_CHECK_MAX_RETRIES} times, will exit with error "
fi
}

#
# ${1} ${filefullpath}
#
function unlink_file()
{
    file_path=${1}

    if [ ! -e ${file_path} ]
    then
        return 0
    fi

    unlink ${file_path} >> $RECOVERY_LOG_DIR 2>&1
    if [ $? -ne 0 ]
    then
        echo "unlink file failed \"${1}\", please check it" >> $RECOVERY_LOG_DIR 2>&1
        return 1
    fi
    return 0
}

# write and read a status file on mount point
function check_mount_point()
{
    # if the dir list is NULL, set KB_DATA_PATH as default
    [ "${MOUNT_POINT_DIR_LIST}"x = ""x ] && MOUNT_POINT_DIR_LIST="${KB_DATA_PATH}"
    check_mount_point_resualt=0
    for((i=1;i<=$MOUNT_CHECK_MAX_RETRIES;i++))
    do
        echo "`date +'%Y-%m-%d %H:%M:%S'` check read/write on mount point ($i / $MOUNT_CHECK_MAX_RETRIES)." >> $RECOVERY_LOG_DIR 2>&1
        check_mount_point_resualt=0
        for subdir in ${MOUNT_POINT_DIR_LIST[@]}
        do
            local status_file="${subdir}/rw_status_file_`date +%N`"
            local error_output=""

            # create the subdir if it's not exist
            [ -d "${subdir}" ] || mkdir -p ${subdir}

            # check the directory
            echo "`date +'%Y-%m-%d %H:%M:%S'` stat the directory of the mount point \"${subdir}\" ..." >> $RECOVERY_LOG_DIR 2>&1
            ls ${subdir} >/dev/null 2>> $RECOVERY_LOG_DIR
            if [ $? -ne 0 ]
            then
                echo "could not stat the mount point \"${subdir}\", please check it" >> $RECOVERY_LOG_DIR 2>&1
                errorhandle "continue" "could not execute \"ls ${subdir}\"."
                check_mount_point_resualt=1
                continue
            fi
            echo "`date +'%Y-%m-%d %H:%M:%S'` stat the directory of the mount point \"${subdir}\" ... OK" >> $RECOVERY_LOG_DIR 2>&1

            # create or write the file
            echo "`date +'%Y-%m-%d %H:%M:%S'` create/write the file \"${status_file}\" ..." >> $RECOVERY_LOG_DIR 2>&1
            error_output=`echo "check read/write on ${subdir}" | timeout --signal=SIGKILL 10 dd of=${status_file} bs=8k count=1 conv=sync,fsync 2>&1`
            if [ $? -ne 0 ]
            then
                echo "could not write on mount point \"${subdir}\", please check it" >> $RECOVERY_LOG_DIR 2>&1
                echo "$error_output" >> $RECOVERY_LOG_DIR 2>&1
                errorhandle "continue" "could not create/write the file \"${status_file}\"."
                check_mount_point_resualt=1

                # if create or write file failed, delete if when it exist
                unlink_file ${status_file}
                continue
            fi
            echo "`date +'%Y-%m-%d %H:%M:%S'` create/write the file \"${status_file}\" ... OK" >> $RECOVERY_LOG_DIR 2>&1
            echo "`date +'%Y-%m-%d %H:%M:%S'` stat the file \"${status_file}\" ..." >> $RECOVERY_LOG_DIR 2>&1
            if [ ! -f ${status_file} ]
            then
                echo "could not found the file on mount point \"${subdir}\", please check it" >> $RECOVERY_LOG_DIR 2>&1
                errorhandle "continue" "could not stat the file \"${status_file}\"."
                check_mount_point_resualt=1

                # if create or write file failed, delete if when it exist
                unlink_file ${status_file}
                continue
            fi
            echo "`date +'%Y-%m-%d %H:%M:%S'` stat the file \"${status_file}\" ... OK" >> $RECOVERY_LOG_DIR 2>&1

            # read the file
            echo "`date +'%Y-%m-%d %H:%M:%S'` read the file \"${status_file}\" ..." >> $RECOVERY_LOG_DIR 2>&1
            cat ${status_file} >/dev/null 2>> $RECOVERY_LOG_DIR
            if [ $? -ne 0 ]
            then
                echo "could not read on mount point \"${subdir}\", please check it" >> $RECOVERY_LOG_DIR 2>&1
                errorhandle "continue" "could not read the file \"${status_file}\"."
                check_mount_point_resualt=1

                # if create or write file failed, delete if when it exist
                unlink_file ${status_file}
                continue
            fi
            echo "`date +'%Y-%m-%d %H:%M:%S'` read the file \"${status_file}\" ... OK" >> $RECOVERY_LOG_DIR 2>&1

            # unlink the file
            echo "`date +'%Y-%m-%d %H:%M:%S'` delete the file \"${status_file}\" ..." >> $RECOVERY_LOG_DIR 2>&1
            unlink ${status_file} >> $RECOVERY_LOG_DIR 2>&1
            if [ $? -ne 0 ]
            then
                echo "could not delete on mount point \"${subdir}\", please check it" >> $RECOVERY_LOG_DIR 2>&1
                errorhandle "continue" "could not delete the file \"${status_file}\"."
                check_mount_point_resualt=1
                continue
            fi
            echo "`date +'%Y-%m-%d %H:%M:%S'` delete the file \"${status_file}\" ... OK" >> $RECOVERY_LOG_DIR 2>&1
        done
        if [ $check_mount_point_resualt -eq 0 ]
        then
            echo "`date +'%Y-%m-%d %H:%M:%S'` success to check read/write on mount point ($i / $MOUNT_CHECK_MAX_RETRIES)." >> $RECOVERY_LOG_DIR 2>&1
            break
        else
            echo "`date +'%Y-%m-%d %H:%M:%S'` failed to check read/write on mount point ($i / $MOUNT_CHECK_MAX_RETRIES)." >> $RECOVERY_LOG_DIR 2>&1
        fi
        sleep 10
    done
    if [ $check_mount_point_resualt -eq 1 ]
    then
        echo "`date +'%Y-%m-%d %H:%M:%S'` execute check_mount_point() failed, maybe the disk is error" >> $RECOVERY_LOG_DIR 2>&1
        if [ $USE_CHECK_DISK -eq 1 ]
        then
            errorhandle "stopdbexit" "`date +'%Y-%m-%d %H:%M:%S'` USE_CHECK_DISK = on, will exit with stop db."
        else
            echo "`date +'%Y-%m-%d %H:%M:%S'` USE_CHECK_DISK = off, do nothing." >> $RECOVERY_LOG_DIR 2>&1
        fi
    fi
}

#determine the network_rewind.sh if is already execute
result_of_IMRECOVERY_FLAG=""
function isalreadyexist()
{
    if [ -s ${KB_RECOVERY_FLAG} ]
    then
        IMRECOVERY_FLAG=`cat ${KB_RECOVERY_FLAG} 2>/dev/null|head -n 1;echo ";" ${PIPESTATUS[*]}`
        result_of_IMRECOVERY_FLAG=`echo $IMRECOVERY_FLAG |awk -F ';' '{print $1}'|awk '{print $1}'`
        cmd_cat=`echo $IMRECOVERY_FLAG |awk -F ';' '{print $2}'|awk '{print $1}'`
        cmd_head=`echo $IMRECOVERY_FLAG |awk -F ';' '{print $2}'|awk '{print $2}'`

        if [ "${cmd_cat}"x != "0"x -o  "${cmd_head}"x != "0"x ]
        then
            echo "cat execute failed,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
            errorhandle "exit" "\"cat ${KB_RECOVERY_FLAG} 2>/dev/null|head -n 1\" execute failed, error num=[$cmd_cat $cmd_head]"
        fi
        if [ "$result_of_IMRECOVERY_FLAG"x = ""x ]
        then
            echo "result of IMRECOVERY_FLAG is null,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
            errorhandle "exit" "IMRECOVERY_FLAG is null please check....."
        fi
        if [ "$result_of_IMRECOVERY_FLAG"x = "1"x ]
        then
            pid_myself=`cat ${KB_RECOVERY_FLAG} 2>/dev/null|sed -n '2p';echo ";" ${PIPESTATUS[*]}`
            
            result_of_pid_myself=`echo $pid_myself |awk -F ';' '{print $1}'|awk '{print $1}'`
            cmd_cat=`echo $pid_myself |awk -F ';' '{print $2}' |awk '{print $1}'`
            cmd_sed=`echo $pid_myself |awk -F ';' '{print $2}' |awk '{print $2}'`

            if [ "${cmd_cat}"x != "0"x -o  "${cmd_sed}"x != "0"x ]
            then
                echo "cat execute failed,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
                errorhandle "exit" "\"cat ${KB_RECOVERY_FLAG} 2>/dev/null|sed -n '2p'\" execute failed, error num=[$cmd_cat $cmd_sed]"
            fi
            if [ "$result_of_pid_myself"x = ""x  ]
            then
                echo "result of myself pid is null,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
                errorhandle "exit" "result_of_pid_myself is null please check....."
            fi
            if [ "$result_of_pid_myself"x != ""x ]
            then
                abs_path=`readlink -f "$0" 2>/dev/null`
                if [ $? -ne 0 -o "$abs_path"x = ""x ]
                then
                    errorhandle "exit" "failed to execute [readlink -f \"$0\"], exit"
                fi
                Im_already_exist=`ls -l /proc/${result_of_pid_myself}/fd | grep -w "$abs_path" |wc -l; echo ";" ${PIPESTATUS[*]}`
                result_of_Im_already_exist=`echo $Im_already_exist |awk -F ';' '{print $1}'|awk '{print $1}'`
                cmd_ls=`echo $Im_already_exist |awk -F ';' '{print $2}' |awk '{print $1}'`
                cmd_grep=`echo $Im_already_exist |awk -F ';' '{print $2}' |awk '{print $2}'`
                cmd_wc=`echo $Im_already_exist |awk -F ';' '{print $2}' |awk '{print $3}'`

                if [ "${cmd_wc}"x != "0"x ]
                then
                    echo "cat execute failed,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
                    errorhandle "exit" "\"ls -l /proc/${result_of_pid_myself}/fd | grep -w \"$abs_path\" |wc -l\" execute failed, error num=[$cmd_ls $cmd_grep $cmd_wc ]"
                fi
                if [ "$result_of_Im_already_exist"x = "1"x ]
                then
                    if [ $force_recovery -eq 1 ]
                    then
                        local realist=`cat /etc/cron.d/KINGBASECRON | grep -wFn "*/1 * * * * $KB_EXECUTE_SYS_USER  ${KB_PATH}/network_rewind.sh"`
                        local linenum=`echo "$realist" |awk -F':' '{print $1}'`
                        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l root -T localhost "sed -i \"${linenum}s/^/#/\" /etc/cron.d/KINGBASECRON" 2>&1
                        errorhandle "continue" "The network_rewind.sh bebing executed, it pid is [$result_of_pid_myself], please wait 1 minute and execute [network_rewind.sh --force] again, will stop the crontab task and exit script"
                        exit 0;
                    else
                        errorhandle "continue" "I'm already recovery now pid[$result_of_pid_myself], return nothing to do,will exit script will success"
                        exit 0;
                    fi
                else
                    echo "Something interrupted the last recovery. Go on this time" >> $RECOVERY_LOG_DIR 2>&1
                fi
            fi
        fi
    fi
}

#optimized the cp cat sed command 
function MyCpCatSed()
{
    command_flag=$1
    file_from=$2
    file_to=$3
    sed_content=$4
    if [ ! -f $file_from ]
    then
        echo "$file_from does not exist"
        errorhandle "exit" "$file_from does not exist, please check,will exit with error"
    fi
    null_flag=`cat $file_from |grep "standby" |wc -l`
    if [ $null_flag -eq 0 ]
    then
        echo "$file_from is empty"
        errorhandle "exit" "$file_from is empty, please check,will exit with error"
    fi
    for((i=1;i<=$HEALTH_CHECK_MAX_RETRIES;i++))
    do
        if [ "$command_flag"x = "cp"x ]
        then
            cp $file_from $file_to
            if [ $? -ne 0 ]
            then
                echo "$cp execute failed"
                errorhandle "continue" "cp execute failed, please check,will retry"
                continue
            fi
        elif [ "$command_flag"x = "cat"x ]
        then
            cat $file_from > $file_to
            if [ $? -ne 0 ]
            then
                echo "$cat execute failed"
                errorhandle "continue" "cat execute failed, please check,will retry"
                continue
            fi
        elif [ "$command_flag"x = "sed"x ]
        then
            sed $sed_content $file_from > $file_to
            if [ $? -ne 0 ]
            then
                echo "$sed execute failed"
                errorhandle "continue" "sed execute failed, please check,will retry"
                continue
            fi
        else
            echo "function parameter error"
            errorhandle "exit" "$function parameter error, please check,will exit with error"
        fi
        if [ ! -f $file_to ]
        then
            echo "$file_to does not exist"
            errorhandle "continue" "$file_to does not exist, please check,will retry"
            continue
        fi
        null_flag=`cat $file_to |grep "standby" |wc -l`
        if [ $null_flag -eq 0 ]
        then
            echo "$file_to is empty"
            errorhandle "continue" "$file_to is empty, please check,will retry"
            continue
        fi
        break
    done
    if [ ! -f $file_to ]
    then
        echo "$file_to does not exist"
        errorhandle "exit" "$file_to does not exist, please check,will exit with error"
    fi
    null_flag=`cat $file_to |grep "standby" |wc -l`
    if [ $null_flag -eq 0 ]
    then
        echo "$file_to is empty"
        errorhandle "exit" "$file_to is empty, please check,will exit with error"
    fi
}

function attach_cluster()
{
    location_diff=`ksql -Atq "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10"  -c "select SYS_XLOG_LOCATION_DIFF(sys_current_xlog_flush_location(),write_location) from sys_stat_replication where application_name = '$NODE_NAME';"`

    if [ "$location_diff"x = ""x ]
    then
        errorhandle "exit" "can not get the replication of myself"
    fi

    if [ $location_diff -le $(($DATA_SIZE_DIFF*1024*1024)) -a $location_diff -ge 0 ]
    then
        if [ $SYNC_FLAG -eq 1 -a "${ALL_NODE_NAME}"x != ""x ]
        then
            echo "cluster is sync cluster." >> $RECOVERY_LOG_DIR 2>&1
            sync_num=`ksql -Atq "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "select sync_state from sys_stat_replication;"| grep -w sync | wc -l`
            if [ "$sync_num"x = "0"x ]
            then
                #if there is a standby`s lsn equal master`s lsn, execute sync_async.sh to change cluster from async to sync
                echo "SYNC RECOVER MODE ..." >> $RECOVERY_LOG_DIR 2>&1
                echo "`date +'%Y-%m-%d %H:%M:%S'` remote primary node change sync" >> $RECOVERY_LOG_DIR 2>&1
                sync_standby_name=""
                for sub_node in ${ALL_NODE_NAME[@]}
                do
                    if [ "${sync_standby_name}"x = ""x ]
                    then
                        sync_standby_name="synchronous_standby_names='1 ($sub_node"
                    else
                        sync_standby_name="${sync_standby_name}, $sub_node"
                    fi
                done
                sync_standby_name="${sync_standby_name})'"
                ksql "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "alter system set $sync_standby_name;" >> $RECOVERY_LOG_DIR 2>&1
                if [ $? -ne 0 ]
                then
                    errorhandle "exit" "alter system set $sync_standby_name failed,exit"
                fi

                ksql "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "select sys_reload_conf();" >> $RECOVERY_LOG_DIR 2>&1
                if [ $? -ne 0 ]
                then
                    errorhandle "exit" "reload conf file failed,exit"
                fi

                sync_num=`ksql -Atq "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "select sync_state from sys_stat_replication;"| grep -w sync | wc -l`

                if [ "$sync_num"x = "0"x ]
                then
                    errorhandle "exit" "change async to sync failed,exit"
                fi
                sleep 1
                echo "SYNC RECOVER MODE DONE" >> $RECOVERY_LOG_DIR 2>&1
            else
                echo "now,there is a synchronous standby." >> $RECOVERY_LOG_DIR 2>&1
            fi
        else
            if [ $SYNC_FLAG -eq 1 ]
            then
                echo "ALL_NODE_NAME is null, try to change sync to async ..." >> $RECOVERY_LOG_DIR 2>&1
            fi
            is_async=`ksql -Atq "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "show synchronous_standby_names;"`
            if [ $? -eq 0 -a "$is_async"x != ""x ]
            then
                echo "ASYNC RECOVER MODE ..." >> $RECOVERY_LOG_DIR 2>&1
                echo "`date +'%Y-%m-%d %H:%M:%S'` remote primary node change async" >> $RECOVERY_LOG_DIR 2>&1
                ksql "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "alter system set synchronous_standby_names to '';" >> $RECOVERY_LOG_DIR 2>&1
                if [ $? -ne 0 ]
                then
                    errorhandle "exit" "set synchronous_standby_names to '' failed,exit"
                fi

                ksql "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "select sys_reload_conf();" >> $RECOVERY_LOG_DIR 2>&1
                if [ $? -ne 0 ]
                then
                    errorhandle "exit" "reload conf file failed,exit"
                fi

                is_async=`ksql -Atq "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "show synchronous_standby_names;"`
                if [ $? -ne 0 -o "$is_async"x != ""x ]
                then
                    errorhandle "exit" "change sync to async failed,exit"
                fi
                sleep 1
                echo "ASYNC RECOVER MODE DONE" >> $RECOVERY_LOG_DIR 2>&1
            else
                echo "It's already in ASYNC MODE." >> $RECOVERY_LOG_DIR 2>&1
            fi
        fi

        if [ "$KB_POOL_VIP"x != ""x ]
        then
            #ksql -p $KB_POOL_PORT -U $KB_USER   -d $KB_DATANAME -h $KB_POOL_VIP -c "show pool_nodes;"  >> $RECOVERY_LOG_DIR 2>&1
            #sleep 1
            #IM_NODE=`ksql -p $KB_POOL_PORT -U $KB_USER  -d $KB_DATANAME -h $KB_POOL_VIP  -c "show pool_nodes;" | grep down | grep $KB_LOCALHOST_IP| grep -v grep |awk '{print $1}'`

            #write pool nodes in file again!! For standby do recovery once which only changed recovery.conf.
            ksql "host=$KB_POOL_VIP port=$KB_POOL_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "show pool_nodes;" 2>&1 > $KB_CLUSTER_STATUS
            if [ $? -ne 0 ]
            then
                echo "ksql \"host=$KB_POOL_VIP port=$KB_POOL_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10\" -c \"show pool_nodes;\" execute failed, will exit"  >> $RECOVERY_LOG_DIR 2>&1
                echo "show pool_nodes result:"
                cat $KB_CLUSTER_STATUS >> $RECOVERY_LOG_DIR 2>&1
                exit 66
            fi
            sleep 2
            IM_NODE=`cat $KB_CLUSTER_STATUS  | grep -w $KB_LOCALHOST_IP| grep -w down | grep -v grep |awk '{print $1}'; echo ";" ${PIPESTATUS[*]}`
            result_of_IM_NODE=`echo $IM_NODE |awk -F ';' '{print $1}'|awk '{print $1}'`
            cmd_cat=`echo $IM_NODE |awk -F ';' '{print $2}'|awk '{print $1}'`
            cmd_grep1=`echo $IM_NODE |awk -F ';' '{print $2}'|awk '{print $2}'`
            cmd_grep2=`echo $IM_NODE |awk -F ';' '{print $2}'|awk '{print $3}'`
            cmd_grep3=`echo $IM_NODE |awk -F ';' '{print $2}'|awk '{print $4}'`
            cmd_awk=`echo $IM_NODE |awk -F ';' '{print $2}'|awk '{print $5}'`

            if [ "${cmd_cat}"x != "0"x -o "${cmd_awk}"x != "0"x ]
            then
                echo "cat execute failed,will exit script with error and stop db"  >> $RECOVERY_LOG_DIR 2>&1
                errorhandle "stopdbexit" "\"cat $KB_CLUSTER_STATUS  | grep -w $KB_LOCALHOST_IP| grep -w down | grep -v grep |awk '{print $1}'\" execute failed, error num=[$cmd_cat $cmd_grep1 $cmd_grep2 $cmd_grep3 $cmd_awk]"
            fi

            if [ "$result_of_IM_NODE"x != ""x ]
            then
                #check db if down
                kingbase_pid=`cat ${KB_DATA_PATH}/kingbase.pid |head -n 1; echo ";" ${PIPESTATUS[*]}`
                result_of_kingbase_pid=`echo $kingbase_pid |awk -F ';' '{print $1}'|awk '{print $1}'`
                cmd_cat=`echo $kingbase_pid |awk -F ';' '{print $2}'|awk '{print $1}'`
                cmd_head=`echo $kingbase_pid |awk -F ';' '{print $2}'|awk '{print $2}'`

                if [ "${cmd_cat}"x != "0"x -o  "${cmd_head}"x != "0"x ]
                then
                    echo "cat execute failed,will exit script with error and stop db"  >> $RECOVERY_LOG_DIR 2>&1
                    errorhandle "stopdbexit" "\"cat ${KB_DATA_PATH}/kingbase.pid |head -n 1\" execute failed, error num=[$cmd_cat $cmd_head]"
                fi

                if [ "$result_of_kingbase_pid"x != ""x ]
                then
                    kingbase_exist=`ps -ef | grep -w $result_of_kingbase_pid | grep -v grep | wc -l;echo ";" ${PIPESTATUS[*]}`
                    result_of_kingbase_exist=`echo $kingbase_exist |awk -F ';' '{print $1}'|awk '{print $1}'`
                    cmd_ps=`echo $kingbase_exist |awk -F ';' '{print $2}'|awk '{print $1}'`
                    cmd_grep1=`echo $kingbase_exist |awk -F ';' '{print $2}'|awk '{print $2}'`
                    cmd_grep2=`echo $kingbase_exist |awk -F ';' '{print $2}'|awk '{print $3}'`
                    cmd_wc=`echo $kingbase_exist |awk -F ';' '{print $2}'|awk '{print $4}'`

                    if [ "${cmd_ps}"x != "0"x -o "${cmd_wc}"x != "0"x ]
                    then
                        echo "ps execute failed,will exit script with error and stop db"  >> $RECOVERY_LOG_DIR 2>&1
                        errorhandle "stopdbexit" "\"ps -ef | grep -w $result_of_kingbase_pid | grep -v grep | wc -l\" execute failed, error num=[$cmd_ps $cmd_grep1 $cmd_grep2 $cmd_wc]"
                    fi

                    if [ "$result_of_kingbase_exist" -eq 0 ]
                    then
                        echo "`date +'%Y-%m-%d %H:%M:%S'` Check the process was started or not before attach node , but no pid was foud in system, which db may have been turned off!" >> $RECOVERY_LOG_DIR 2>&1
                        errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` Set recovery flag 0, and exit recovery process."
                    fi
                else
                    echo "`date +'%Y-%m-%d %H:%M:%S'` Check the process was started or not before attach node, but no pid file was foud, which db may have been turned off!" >> $RECOVERY_LOG_DIR 2>&1    
                    errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` Set recovery flag 0, and exit recovery process."
                fi
                echo "`date +'%Y-%m-%d %H:%M:%S'` attach pool..." >> $RECOVERY_LOG_DIR 2>&1
                echo "IM Node is $result_of_IM_NODE, will try [pcp_attach_node -U $PCP_USER -W $PCP_PASS -h $KB_POOL_VIP -n $result_of_IM_NODE]" >> $RECOVERY_LOG_DIR 2>&1 
                pcp_attach_node -U $PCP_USER -W $PCP_REAL_PASS -h $KB_POOL_VIP -p $KB_POOL_PCP_PORT -c 10 -n $result_of_IM_NODE >> $RECOVERY_LOG_DIR 2>&1
                result_of_pcp=$?
                sleep 1
                ksql "host=$KB_POOL_VIP port=$KB_POOL_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "show pool_nodes;"  >> $RECOVERY_LOG_DIR 2>&1
                if [ $result_of_pcp -ne 0 ]
                then
                    errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` pcp_attach_node execute failed ,will exit script with error"
                fi
                echo "`date +'%Y-%m-%d %H:%M:%S'` attach end.. " >> $RECOVERY_LOG_DIR 2>&1
            else
                echo "`date +'%Y-%m-%d %H:%M:%S'` ALL NODES ARE UP STATUS!" >> $RECOVERY_LOG_DIR 2>&1
            fi
        fi
    else
        errorhandle "exit" "Im Node is standby,the gap between my LSN and primary LSN is too large,the data difference exceeds $DATA_SIZE_DIFF M,exit script"
    fi
}

## if that node can access by ssh
function test_access_node()
{
    local access_ip=$1
    [ "${access_ip}"x = ""x ] && return 1

    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T ${access_ip} "/bin/true >/dev/null 2>&1"
    [ $? -eq 0 ] && return 0

    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T ${access_ip} "/usr/bin/true >/dev/null 2>&1"
    [ $? -eq 0 ] && return 0

    return 1
}

function found_best_db()
{
    local db_index=0
    local db_primary_list=""
    local db_status_list=""
    local node_is_running=0

    is_db_running=0
    best_db_ip=""

    for kb_ip in ${KB_ALL_IP[@]}
    do
        echo "`date +'%Y-%m-%d %H:%M:%S'` check if it can access \"${kb_ip}\"" >> $RECOVERY_LOG_DIR 2>&1
        test_access_node ${kb_ip}
        if [ $? -ne 0 ]
        then
            if [ $MAX_AVAILABLE_LEVEL -eq 1 ]
            then
                errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` could not access \"${kb_ip}\", exit"
            fi
            echo "`date +'%Y-%m-%d %H:%M:%S'` could not access \"${kb_ip}\", skip" >> $RECOVERY_LOG_DIR 2>&1
            continue
        fi
        echo "`date +'%Y-%m-%d %H:%M:%S'` success to access \"${kb_ip}\"" >> $RECOVERY_LOG_DIR 2>&1
    done

    ## check the db status on all node
    for kb_ip in ${KB_ALL_IP[@]}
    do
        node_is_running=0

        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T ${kb_ip} "$KB_PATH/sys_ctl -D ${KB_DATA_PATH} status >/dev/null 2>&1"
        if [ $? -eq 0 ]
        then
            echo "`date +'%Y-%m-%d %H:%M:%S'` the kingbase on \"${kb_ip}\" is running ..." >> $RECOVERY_LOG_DIR 2>&1
            node_is_running=1
        fi
        ## failed to execute command or the recovery.conf is not exists, set the db is primary
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T ${kb_ip} "test -f ${KB_DATA_PATH}/recovery.conf"
        if [ $? -eq 0 ]
        then
            if [ ${node_is_running} -eq 1 -a $MAX_AVAILABLE_LEVEL -eq 1 ]
            then
                errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` the kingbase on \"${kb_ip}\" is a running standby, exit"
            fi
        else
            db_primary_list[${db_index}]="${kb_ip}"
            if [ ${node_is_running} -eq 1 ]
            then
                ## the primary is running
                db_status_list[${db_index}]=1
            else
                db_status_list[${db_index}]=0
            fi

            let db_index++
        fi
    done

    if [ ${db_index} -eq 1 ]
    then
        echo "`date +'%Y-%m-%d %H:%M:%S'` the DB on \"${db_primary_list[0]}\" is Primary before it was DOWN" >> $RECOVERY_LOG_DIR 2>&1
        echo "`date +'%Y-%m-%d %H:%M:%S'` set it(${db_primary_list[0]}) as the best candidate DB" >> $RECOVERY_LOG_DIR 2>&1
        best_db_ip="${db_primary_list[0]}"
        [ "${db_status_list[0]}"x = "1"x ] && is_db_running=1
    elif [ ${db_index} -eq 0 ]
    then
        errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` could not found any primary DB when all DBs are DOWN, exit"
    else
        if [ $MAX_AVAILABLE_LEVEL -eq 1 ]
        then
            primary_str=""
            for item in ${db_primary_list[@]}
            do
                if [ "${primary_str}"x = ""x ]
                then
                    primary_str="$item"
                else
                    primary_str="$primary_str $item"
                fi
            done
            errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` there is more than one primary DB($primary_str), do nothing and exit"
        fi
        ## TODO: find a best DB in these primary DBs
        exit 1
    fi
}

function attach_myself_into_cluster()
{
    ## check the Cluster is alive by KB_POOL_VIP
    echo "`date +'%Y-%m-%d %H:%M:%S'` try to get the info of kingbasecluster by \"${KB_POOL_VIP}\" ..." >> $RECOVERY_LOG_DIR 2>&1
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T $KB_POOL_VIP "${CLUSTER_BIN_PATH}/pcp_watchdog_info -U $PCP_USER -W $PCP_REAL_PASS -h $KB_POOL_VIP -p $KB_POOL_PCP_PORT" >> $RECOVERY_LOG_DIR 2>&1
    if [ $? -ne 0 ]
    then
        errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` failed to get the info of kingbasecluster, maybe the kingbasecluster is not alive, exit"
    fi
    echo "`date +'%Y-%m-%d %H:%M:%S'` success to get the info of kingbasecluster" >> $RECOVERY_LOG_DIR 2>&1

    ## get the node id of IP
    node_id=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T $KB_POOL_VIP "cat ${CLUSTER_BIN_PATH}/../etc/kingbasecluster.conf 2>/dev/null | grep \"^[ ]*backend_hostname\"|grep -w \"${KB_LOCALHOST_IP}\" | awk -F'=' '{print \\$1}'|tr -cd [0-9]"`
    if [ $? -ne 0 -o "${node_id}"x = ""x ]
    then
        errorhandle "exit" "could not read kingbasecluster.conf on \"$KB_POOL_VIP\", exit"
    fi

    ## attach the node into cluster
    echo "`date +'%Y-%m-%d %H:%M:%S'` try to attach the database on \"${KB_LOCALHOST_IP}\" into cluster" >> $RECOVERY_LOG_DIR 2>&1
    pcp_attach_node -U $PCP_USER -W $PCP_REAL_PASS -h $KB_POOL_VIP -p $KB_POOL_PCP_PORT -c 10 -n $node_id >> $RECOVERY_LOG_DIR 2>&1
    if [ $? -ne 0 ]
    then
        errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` pcp_attach_node execute failed, exit"
    fi
    echo "`date +'%Y-%m-%d %H:%M:%S'` success to attach the database on \"${KB_LOCALHOST_IP}\", DONE" >> $RECOVERY_LOG_DIR 2>&1
    echo 0 > ${KB_DATA_PATH}/${KB_RECOVERY_FLAG}
    exit 0
}

function start_db_or_attach_cluster()
{
    echo "`date +'%Y-%m-%d %H:%M:%S'` the MAX_AVAILABLE_LEVEL=${MAX_AVAILABLE_LEVEL}, try to check all database status, start one database and attach it into cluster" >> $RECOVERY_LOG_DIR 2>&1
    found_best_db

    if [ ${is_db_running} -eq 1 ]
    then
        if [ "${best_db_ip}"x != "${KB_LOCALHOST_IP}"x ]
        then
            errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` there is database running on other nodes, do nothing on this node, exit"
        fi
        echo "`date +'%Y-%m-%d %H:%M:%S'` the DB on localhost(${best_db_ip}) is already running" >> $RECOVERY_LOG_DIR 2>&1
    else
        if [ "${best_db_ip}"x = ""x ]
        then
            errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` could not found a database to start and be primary, exit"
        elif [ "${best_db_ip}"x != "${KB_LOCALHOST_IP}"x ]
        then
            errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` the best condidate DB on other node \"${best_db_ip}\", exit"
        fi

        ## the best condidate DB is myself, start it
        echo "`date +'%Y-%m-%d %H:%M:%S'` try to start DB on localhost(${best_db_ip}) ..." >> $RECOVERY_LOG_DIR 2>&1
        ${KB_PATH}/sys_ctl -w -t 90 -D ${KB_DATA_PATH} start >> $RECOVERY_LOG_DIR 2>&1
        if [ $? -ne 0 ]
        then
            errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` failed to start DB on localhost(${best_db_ip}), exit"
        fi

        ## attach it into kingbasecluster in next time
        echo "`date +'%Y-%m-%d %H:%M:%S'` success to start DB on localhost(${best_db_ip})" >> $RECOVERY_LOG_DIR 2>&1
        addvip

        sleep 1
        cluster_status=`ksql "host=$KB_POOL_VIP port=$KB_POOL_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "show pool_nodes;" 2>/dev/null`
        result_of_ksql=$?
        if [ "${result_of_ksql}"x = "0"x ] && [ "${cluster_status}"x != ""x ]
        then
            echo "$cluster_status" >> $RECOVERY_LOG_DIR 2>&1
            # if myself is standby, try to promote
            is_standby_in_cluster=`echo "$cluster_status" 2>/dev/null | grep -w "$KB_LOCALHOST_IP" | grep -w "standby" | grep -w "up" | wc -l`
            if [ $? -eq 0 -a "${is_standby_in_cluster}"x = "1"x ]
            then
                echo "`date +'%Y-%m-%d %H:%M:%S'` this db in cluster is standby, try to execute promote_node" >> $RECOVERY_LOG_DIR 2>&1
                ## get the node id of IP
                node_id=`echo "$cluster_status" 2>/dev/null | grep -w "$KB_LOCALHOST_IP" | awk '{print $1}'`
                if [ "${node_id}"x != ""x ]
                then
                    ## promote the node in cluster
                    pcp_promote_node -U $PCP_USER -W $PCP_REAL_PASS -h $KB_POOL_VIP -p $KB_POOL_PCP_PORT -n $node_id >> $RECOVERY_LOG_DIR 2>&1
                else
                    echo "`date +'%Y-%m-%d %H:%M:%S'` failed to get the NODE ID for localhost, could not execute promote_node" >> $RECOVERY_LOG_DIR 2>&1
                fi
            else
                echo "`date +'%Y-%m-%d %H:%M:%S'` this node is not running (up) as a standby, do nothing" >> $RECOVERY_LOG_DIR 2>&1
            fi
        else
            echo "`date +'%Y-%m-%d %H:%M:%S'` could not get the status from kingbasecluster, do nothing" >> $RECOVERY_LOG_DIR 2>&1
        fi

        echo "`date +'%Y-%m-%d %H:%M:%S'` DONE" >> $RECOVERY_LOG_DIR 2>&1
        echo 0 > ${KB_DATA_PATH}/${KB_RECOVERY_FLAG}
        exit 0
    fi

    ## attach and exit
    attach_myself_into_cluster
}

#exec 4<>/dev/shm/pd.lock
{
if flock -xn 4
then
    isalreadyexist
    echo "---------------------------------------------------------------------" >> $RECOVERY_LOG_DIR 2>&1
    echo `date +'%Y-%m-%d %H:%M:%S'` recover beging... >> $RECOVERY_LOG_DIR 2>&1
    echo 1 > ${KB_RECOVERY_FLAG}
    if [ $? -ne 0 ]
    then
        echo "`date +'%Y-%m-%d %H:%M:%S'` failed to write ${KB_RECOVERY_FLAG}, please check" >> $RECOVERY_LOG_DIR 2>&1
        exit 1;
    fi
    echo $$ >> ${KB_RECOVERY_FLAG}
    if [ $? -ne 0 ]
    then
        echo "`date +'%Y-%m-%d %H:%M:%S'` failed to write ${KB_RECOVERY_FLAG}, please check" >> $RECOVERY_LOG_DIR 2>&1
        exit 1;
    fi
else
    echo "`date +'%Y-%m-%d %H:%M:%S'` Anthoer process is on, exit this time " >> $RECOVERY_LOG_DIR 2>&1
    exit 0;
fi
} 4<>/dev/shm/kb.lock

if [ $? -ne 0 ]
then
    echo "`date +'%Y-%m-%d %H:%M:%S'` failed to lock the /dev/shm/kb.lock, please check" >> $RECOVERY_LOG_DIR 2>&1
    exit 1;
fi

if [ $force_recovery -eq 1 ]
then
    echo `date +'%Y-%m-%d %H:%M:%S'` The following log is the log of manually executing the network_rewind.sh script  >> $RECOVERY_LOG_DIR 2>&1
fi

echo "my pid is $$,officially began to perform recovery" >> $RECOVERY_LOG_DIR 2>&1
if [ $force_recovery -eq 1 ]
then
    echo "`date` my pid is $$,officially began to perform recovery, log location: $RECOVERY_LOG_DIR"
fi

echo `date +'%Y-%m-%d %H:%M:%S'` check read/write on mount point >> $RECOVERY_LOG_DIR 2>&1

check_mount_point
echo `date +'%Y-%m-%d %H:%M:%S'` check read/write on mount point ... ok >> $RECOVERY_LOG_DIR 2>&1


echo `date +'%Y-%m-%d %H:%M:%S'` check if the network is ok >> $RECOVERY_LOG_DIR 2>&1

checktrustip

#determine the master of cluster if is myself
echo "determine if i am master or standby " >> $RECOVERY_LOG_DIR 2>&1

ksql "host=$KB_POOL_VIP port=$KB_POOL_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "show pool_nodes;" > $KB_CLUSTER_STATUS 2>&1
result_of_ksql=$?
cat $KB_CLUSTER_STATUS >> $RECOVERY_LOG_DIR 2>&1
if [ "${result_of_ksql}"x != "0"x ]
then
    if [ $MAX_AVAILABLE_LEVEL -eq 1 ]
    then
        echo "ksql execute failed: $result_of_ksql" >> $RECOVERY_LOG_DIR 2>&1
        start_db_or_attach_cluster
    fi
    echo "ksql execute failed ,will exit script with error "  >> $RECOVERY_LOG_DIR 2>&1
    errorhandle "exit" "\"ksql \"host=$KB_POOL_VIP port=$KB_POOL_PORT user=$KB_USER dbname=$KB_DATANAME connect_timeout=10\" -c \"show pool_nodes;\" > $KB_CLUSTER_STATUS 2>&1 \" execute failed, error num=[$result_of_ksql]"
fi
if [ ! -f $KB_CLUSTER_STATUS ]
then
    if [ $MAX_AVAILABLE_LEVEL -eq 1 ]
    then
        echo "the file \"$KB_CLUSTER_STATUS\" is not exists" >> $RECOVERY_LOG_DIR 2>&1
        start_db_or_attach_cluster
    fi
    echo "the file that record the db status does not exist,will exit script with error"  >> $RECOVERY_LOG_DIR 2>&1
    errorhandle "exit" "file $KB_CLUSTER_STATUS donot exist please check....."
fi

if [ ! -s $KB_CLUSTER_STATUS ]
then
    if [ $MAX_AVAILABLE_LEVEL -eq 1 ]
    then
        echo "the file \"$KB_CLUSTER_STATUS\" is empty" >> $RECOVERY_LOG_DIR 2>&1
        start_db_or_attach_cluster
    fi
    echo "the file that record the db status is empty,will exit script with error"  >> $RECOVERY_LOG_DIR 2>&1
    errorhandle "exit" "file $KB_CLUSTER_STATUS is null failed please check....."
fi

#get the master db of cluster `s ip
NOWPRIMARYIP=`cat $KB_CLUSTER_STATUS | grep primary | grep -v grep |awk -F'|' '{print $2}'; echo ";" ${PIPESTATUS[*]}`
result_of_NOWPRIMARYIP=`echo $NOWPRIMARYIP |awk -F ';' '{print $1}'|awk '{print $1}'`
cmd_cat=`echo $NOWPRIMARYIP |awk -F ';' '{print $2}' |awk '{print $1}'`
cmd_grep1=`echo $NOWPRIMARYIP |awk -F ';' '{print $2}' |awk '{print $2}'`
cmd_grep2=`echo $NOWPRIMARYIP |awk -F ';' '{print $2}' |awk '{print $3}'`
cmd_awk=`echo $NOWPRIMARYIP |awk -F ';' '{print $2}' |awk '{print $4}'`

if [ "${cmd_cat}"x != "0"x -o "${cmd_awk}"x != "0"x ]
then
    echo "cat execute failed,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
    errorhandle "exit"  "\"echo $result_of_NOWPRIMARYIP | grep -w $KB_LOCALHOST_IP | wc -l\" execute failed, error num=[$cmd_cat $cmd_grep1 $cmd_grep2 $cmd_awk]"
fi
if [ "$result_of_NOWPRIMARYIP"x = ""x ]
then
    echo "result of now master ip not found,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
    errorhandle "exit"  "no primary node in kingbasecluster, nothing to do "
else
    #determine the master of cluster `s ip if is myself
    IMPRI_FLAG=`echo $result_of_NOWPRIMARYIP | grep -w $KB_LOCALHOST_IP | wc -l; echo ";" ${PIPESTATUS[*]}`
    result_of_IMPRI_FLAG=`echo $IMPRI_FLAG |awk -F ';' '{print $1}'|awk '{print $1}'`
    cmd_echo=`echo $IMPRI_FLAG |awk -F ';' '{print $2}' |awk '{print $1}'`
    cmd_grep=`echo $IMPRI_FLAG |awk -F ';' '{print $2}' |awk '{print $2}'`
    cmd_wc=`echo $IMPRI_FLAG |awk -F ';' '{print $2}' |awk '{print $3}'`

    if [ "${cmd_echo}"x != "0"x -o "${cmd_wc}"x != "0"x ]
    then
        echo "cat execute failed,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
        errorhandle "exit" "\"echo $result_of_NOWPRIMARYIP | grep -w $KB_LOCALHOST_IP | wc -l\" execute failed, error num=[$cmd_echo $cmd_grep $cmd_wc ]"
    fi
    if [ "$result_of_IMPRI_FLAG"x = ""x ]
    then
        errorhandle "exit"  "result of IMPRI_FLAG ip is null,will exit script with error"
    fi
    if [ "$result_of_IMPRI_FLAG"x = "1"x ]
    then
        #try to add vip
        addvip

        #if i am master of cluster and the cluster is sync cluster ,exit
        is_sync=`ksql -Atq "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "show synchronous_standby_names;"`
        result_of_ksql=$?
        if [ $result_of_ksql -eq 0 ]
        then
            if [ "$is_sync"x != ""x ]
            then
                standby_all=`ksql -Atq "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "select * from sys_stat_replication;"`
                if [ $? -ne 0 ]
                then
                    errorhandle "exit" "I,m node is primary, cluster is sync, execute ksql to get the number of standby failed, will exit script"
                fi
                echo "The sys_stat_replication view result is : [$standby_all]" >> $RECOVERY_LOG_DIR 2>&1
                if [ "${standby_all}"x = ""x ]
                then
                    standby_num=0
                else
                    standby_num=`echo "$standby_all" | wc -l`
                fi
                if [ $standby_num -eq 0 ]
                then
                    echo "ASYNC RECOVER MODE ..." >> $RECOVERY_LOG_DIR 2>&1
                    echo "`date +'%Y-%m-%d %H:%M:%S'` local primary node change async" >> $RECOVERY_LOG_DIR 2>&1
                    ksql "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "alter system set synchronous_standby_names to '';" >> $RECOVERY_LOG_DIR 2>&1
                    if [ $? -ne 0 ]
                    then
                        errorhandle "exit" "set synchronous_standby_names to '' failed,exit"
                    fi

                    ksql "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "select sys_reload_conf();" >> $RECOVERY_LOG_DIR 2>&1
                    if [ $? -ne 0 ]
                    then
                        errorhandle "exit" "reload conf file failed,exit"
                    fi

                    is_async=`ksql -Atq "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "show synchronous_standby_names;"`
                    if [ $? -ne 0 -o "$is_async"x != ""x ]
                    then
                        errorhandle "exit" "change sync to async failed,exit"
                    fi
                    sleep 1
                    echo "ASYNC RECOVER MODE DONE" >> $RECOVERY_LOG_DIR 2>&1
                    echo 0 > ${KB_RECOVERY_FLAG}
                    exit 0;
                else
                    echo "I,m node is primary, cluster is sync, and there is a standby db, nothing to do" >> $RECOVERY_LOG_DIR 2>&1
                    echo 0 > ${KB_RECOVERY_FLAG}
                    exit 0;
                fi
            else
                echo "I,m node is primary, and cluster is async,nothing to do" >> $RECOVERY_LOG_DIR 2>&1
                echo 0 > ${KB_RECOVERY_FLAG}
                exit 0;
            fi
        else
            echo "I,m node is primary, execute ksql to acquire cluster is sync or async failed ,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
            errorhandle "exit" "\"ksql -Atq \"host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER dbname=$KB_DATANAME connect_timeout=10\" -c \"show synchronous_standby_names;\"\" execute failed, error num=[$result_of_ksql]"
        fi
    fi

    #NEED_CHANGE=`cat ${KB_DATA_PATH}/recovery.conf | grep "host=${result_of_NOWPRIMARYIP// }" | wc -l`

    #i am standby in cluster,determine if recovery is needed
    echo "i am standby in cluster,determine if recovery is needed" >> $RECOVERY_LOG_DIR 2>&1
    #first if i have vip,del the vip
    delvip
    result_of_NEED_CHANGE=1

    if [ -f ${KB_DATA_PATH}/recovery.conf ]
    then
        #if there is recovery.conf,determine if recovery is needed by the replication stream if is ok
        for((i=1;i<=$HEALTH_CHECK_MAX_RETRIES;i++))
        do
            NEED_CHANGE=`ksql "host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10"  -Atqc "select * from sys_stat_replication where APPLICATION_NAME='$NODE_NAME' and (STATE='streaming' or STATE='catchup');"|wc -l;echo ";" ${PIPESTATUS[*]}`
            result_of_NEED_CHANGE=`echo $NEED_CHANGE |awk -F ';' '{print $1}'|awk '{print $1}'`
            cmd_ksql=`echo $NEED_CHANGE |awk -F ';' '{print $2}'|awk '{print $1}'`
            cmd_wc=`echo $NEED_CHANGE |awk -F ';' '{print $2}'|awk '{print $2}'`

            if [ "${cmd_ksql}"x != "0"x -o "${cmd_wc}"x != "0"x ]
            then
                if [ ${i} -ne ${HEALTH_CHECK_MAX_RETRIES} ]
                then
                    echo "ksql execute failed,will retry ,retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" >> $RECOVERY_LOG_DIR 2>&1
                    errorhandle "continue" "\" ksql \"host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10\"  -Atqc \"select * from sys_stat_replication where APPLICATION_NAME='$NODE_NAME' and (STATE='streaming' or STATE='catchup');\"|wc -l \" execute failed, error num=[$cmd_ksql  $cmd_wc ]"
                else
                    echo "ksql execute failed,retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}],will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
                    errorhandle "exit" "\" ksql \"host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10\"  -Atqc \"select * from sys_stat_replication where APPLICATION_NAME='$NODE_NAME' and (STATE='streaming' or STATE='catchup');\"|wc -l \" execute failed, error num=[$cmd_ksql  $cmd_wc ]"
                fi
            elif [ $result_of_NEED_CHANGE -eq 1 ]
            then
                break
            else
                echo "ksql execute success,but node:$NODE_NAME does not have correct streaming(or catchup) replication ,will retry ,retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" >> $RECOVERY_LOG_DIR 2>&1
            fi
            sleep $HEALTH_CHECK_RETRY_DELAY
        done

        #if there is recovery.conf,determine if recovery is needed by the db status
        IMSTATUS=`cat $KB_CLUSTER_STATUS | grep down | grep -w $KB_LOCALHOST_IP| grep -v grep | wc -l ; echo ";" ${PIPESTATUS[*]}`
        result_of_IMSTATUS=`echo $IMSTATUS |awk -F ';' '{print $1}'|awk '{print $1}'`
        cmd_cat=`echo $IMSTATUS |awk -F ';' '{print $2}'|awk '{print $1}'`
        cmd_grep1=`echo $IMSTATUS |awk -F ';' '{print $2}'|awk '{print $2}'`
        cmd_grep2=`echo $IMSTATUS |awk -F ';' '{print $2}'|awk '{print $3}'`
        cmd_grep3=`echo $IMSTATUS |awk -F ';' '{print $2}'|awk '{print $4}'`
        cmd_wc=`echo $IMSTATUS |awk -F ';' '{print $2}'|awk '{print $5}'`

        if [ "${cmd_cat}"x != "0"x -o "${cmd_wc}"x != "0"x ]
        then
            echo "cat execute failed,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
            errorhandle "exit" "\"cat $KB_CLUSTER_STATUS | grep down | grep -w $KB_LOCALHOST_IP| grep -v grep | wc -l \" execute failed, error num=[$cmd_cat $cmd_grep1 $cmd_grep2 $cmd_grep3 $cmd_wc]"
        fi
    else
        #if there is no recovery.conf,stop db
        sys_ctl stop -w -t 90 -D $KB_DATA_PATH -m fast >> $RECOVERY_LOG_DIR 2>&1
        result_of_IMSTATUS=2
    fi

    if [ "$result_of_NEED_CHANGE"x = "0"x -o "$result_of_IMSTATUS"x = "2"x ]
    then
        echo "primary node/Im node status is changed, primary ip[$result_of_NOWPRIMARYIP], recovery.conf NEED_CHANGE [$result_of_NEED_CHANGE] (0 is need ), I,m status is [$result_of_IMSTATUS] (1 is down), I will be in recovery. " >> $RECOVERY_LOG_DIR 2>&1
        cat $KB_CLUSTER_STATUS >> $RECOVERY_LOG_DIR 2>&1
    else
        # if result of IMRECOVERY FLAG not equels 0, last abnormal exit
        # need rewind again
        if [ "$result_of_IMRECOVERY_FLAG"x == "0"x ]
        then
            attach_cluster
            echo 0 > ${KB_RECOVERY_FLAG}
            exit 0;
        fi
        echo "rewind again, because last abnormal exit" >> $RECOVERY_LOG_DIR 2>&1
    fi
fi

#enter the real recovery process

#1, if recover node up, let it down , for rewind

echo "if recover node up, let it down , for rewind" >> $RECOVERY_LOG_DIR 2>&1
if [ -s ${KB_DATA_PATH}/kingbase.pid ]
then
    kingbase_pid=`cat ${KB_DATA_PATH}/kingbase.pid 2>/dev/null|head -n 1 ; echo ";" ${PIPESTATUS[*]}`
    result_of_kingbase_pid=`echo $kingbase_pid |awk -F ';' '{print $1}'|awk '{print $1}'`
    cmd_cat=`echo $kingbase_pid |awk -F ';' '{print $2}'|awk '{print $1}'`
    cmd_head=`echo $kingbase_pid |awk -F ';' '{print $2}'|awk '{print $2}'`

    if [ "${cmd_cat}"x != "0"x -o  "${cmd_head}"x != "0"x ]
    then
        echo "cat execute failed,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
        errorhandle "exit" "\"cat ${KB_DATA_PATH}/kingbase.pid 2>/dev/null|head -n 1 \" execute failed, error num=[$cmd_cat $cmd_head]"
    fi

    if [ "$result_of_kingbase_pid"x != ""x ]
    then
        kingbase_exist=`ps -ef | grep -w $result_of_kingbase_pid | grep -v grep | wc -l;echo ";" ${PIPESTATUS[*]}`
        result_of_kingbase_exist=`echo $kingbase_exist |awk -F ';' '{print $1}'|awk '{print $1}'`
        cmd_ps=`echo $kingbase_exist |awk -F ';' '{print $2}'|awk '{print $1}'`
        cmd_grep1=`echo $kingbase_exist |awk -F ';' '{print $2}'|awk '{print $2}'`
        cmd_grep2=`echo $kingbase_exist |awk -F ';' '{print $2}'|awk '{print $3}'`
        cmd_wc=`echo $kingbase_exist |awk -F ';' '{print $2}'|awk '{print $4}'`

        if [ "${cmd_ps}"x != "0"x -o "${cmd_wc}"x != "0"x ]
        then
            echo "ps execute failed,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
            errorhandle "exit" "\"ps -ef | grep -w $result_of_kingbase_pid | grep -v grep | wc -l\" execute failed, error num=[$cmd_ps $cmd_grep1 $cmd_grep2 $cmd_wc]"
        fi
        if [ "$result_of_kingbase_exist" -ge 1 ]
        then
            IM_NODE=`cat $KB_CLUSTER_STATUS  | grep -w $KB_LOCALHOST_IP| grep -w up | grep -v grep |awk '{print $1}'`
            if [ "$IM_NODE"x != ""x ]
            then
                echo "try detach current node from cluster" >> $RECOVERY_LOG_DIR 2>&1
                pcp_detach_node -U $PCP_USER -W $PCP_REAL_PASS -h $KB_POOL_VIP -p $KB_POOL_PCP_PORT -n $IM_NODE  >> $RECOVERY_LOG_DIR 2>&1
                ksql -p $KB_POOL_PORT -U $KB_USER -W $KB_REAL_PASS  -d $KB_DATANAME -h $KB_POOL_VIP -c "show pool_nodes;"  >> $RECOVERY_LOG_DIR 2>&1
                sleep 1
            fi
            echo "`date +'%Y-%m-%d %H:%M:%S'` stop the kingbase"
            sys_ctl stop -w -t 90 -D $KB_DATA_PATH -m fast >> $RECOVERY_LOG_DIR 2>&1

            echo "`date +'%Y-%m-%d %H:%M:%S'` set $KB_DATA_PATH down now... already down , check again" >> $RECOVERY_LOG_DIR 2>&1
            sleep 1
            echo "wait kb stop 5 sec ......." >> $RECOVERY_LOG_DIR 2>&1
            isstillalive=`ps -ef | grep -w $result_of_kingbase_pid |grep -v grep |wc -l;echo ";" ${PIPESTATUS[*]}`
            result_of_kingbase_exist=`echo $isstillalive |awk -F ';' '{print $1}'|awk '{print $1}'`
            cmd_ps=`echo $isstillalive |awk -F ';' '{print $2}'|awk '{print $1}'`
            cmd_grep1=`echo $isstillalive |awk -F ';' '{print $2}'|awk '{print $2}'`
            cmd_grep2=`echo $isstillalive |awk -F ';' '{print $2}'|awk '{print $3}'`
            cmd_wc=`echo $isstillalive |awk -F ';' '{print $2}'|awk '{print $4}'`

            if [ "${cmd_ps}"x != "0"x -o "${cmd_wc}"x != "0"x ]
            then
                echo "ps execute failed,will exit script with error" >> $RECOVERY_LOG_DIR 2>&1
                errorhandle "exit" "\"ps -ef | grep -w $result_of_kingbase_pid |grep -v grep |wc -l\" execute failed, error num=[$cmd_ps $cmd_grep1 $cmd_grep2 $cmd_wc]"
            fi

            if [ $result_of_kingbase_exist -ne 0 ]
            then
                echo "need to killed ,is alived $result_of_kingbase_exist, let [ps -ef| grep -w $result_of_kingbase_pid | grep -v grep |awk '{print $2}' |xargs kill -9]" >> $RECOVERY_LOG_DIR 2>&1
                `ps -ef| grep -w $result_of_kingbase_pid | grep -v grep |awk '{print $2}' |xargs kill -9 >>  $RECOVERY_LOG_DIR 2>&1`
                echo "kill after ...then check " >> $RECOVERY_LOG_DIR 2>&1
                ps -ef | grep -w $result_of_kingbase_pid |grep -v grep >> $RECOVERY_LOG_DIR 2>&1
            fi
        fi
    fi
fi

#if master auto recovery to standby function is closed,will check there is recovery.conf to determine am i is master before i down
if [ ${AUTO_PRIMARY_RECOVERY} -eq 0 -a $force_recovery -eq 0 ]
then
    if [ -f ${KB_DATA_PATH}/recovery.conf ]
    then
        is_standby=`cat ${KB_DATA_PATH}/recovery.conf | grep -ve "^ *#" | grep "primary_conninfo" | wc -l`

        if [ $? -eq 0 -a "${is_standby}"x = "0"x ]
        then
            echo "`date +'%Y-%m-%d %H:%M:%S'` the kingbase is not standby, can not do recovery." >> $RECOVERY_LOG_DIR 2>&1
            echo 0 > ${KB_RECOVERY_FLAG}
            exit 1
        fi
    else
        #if there is no recovery.conf,it`s mean that i am master before i down
        echo "`date +'%Y-%m-%d %H:%M:%S'` the kingbase has no file \"${KB_DATA_PATH}/recovery.conf\", maybe it's primary, can not do recovery." >> $RECOVERY_LOG_DIR 2>&1
        echo 0 > ${KB_RECOVERY_FLAG}
        exit 1
    fi
fi

#2, sys_rewind
echo "`date +'%Y-%m-%d %H:%M:%S'` sys_rewind..." >> $RECOVERY_LOG_DIR 2>&1
echo "sys_rewind  --target-data=$KB_DATA_PATH --source-server=\"host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER dbname=$KB_DATANAME\"" >> $RECOVERY_LOG_DIR 2>&1
sys_rewind  --target-data=$KB_DATA_PATH --source-server="host=$result_of_NOWPRIMARYIP port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME" >> $RECOVERY_LOG_DIR 2>&1
sleep 2

#3, sed conf change #synchronous_standby_names

echo " sed conf change #synchronous_standby_names"  >> $RECOVERY_LOG_DIR 2>&1
echo "`date +'%Y-%m-%d %H:%M:%S'` file operate" >> $RECOVERY_LOG_DIR 2>&1
MyCpCatSed cp ${KB_ETC_PATH}/kingbase.conf ${KB_DATA_PATH}/kingbase.conf >> $RECOVERY_LOG_DIR 2>&1

MyCpCatSed sed $KB_DATA_PATH/kingbase.conf $KB_ETC_PATH/$FILE_NAME.kingbase.temp 's/synchronous_standby_names/#synchronous_standby_names/'  >> $RECOVERY_LOG_DIR 2>&1

MyCpCatSed cat $KB_ETC_PATH/$FILE_NAME.kingbase.temp $KB_DATA_PATH/kingbase.conf >> $RECOVERY_LOG_DIR 2>&1

rm -f $KB_ETC_PATH/$FILE_NAME.kingbase.temp  >> $RECOVERY_LOG_DIR 2>&1

if [ ! -f $KB_DATA_PATH/kingbase.conf ]
then
    echo "$KB_DATA_PATH/kingbase.conf does not exist,will cp etc/kingbase.conf to data/kingbase.conf" >> $RECOVERY_LOG_DIR 2>&1
    MyCpCatSed cp ${KB_ETC_PATH}/kingbase.conf ${KB_DATA_PATH}/kingbase.conf >> $RECOVERY_LOG_DIR 2>&1
fi
null_flag=`cat $KB_DATA_PATH/kingbase.conf |grep "standby" |wc -l`
if [ $null_flag -eq 0 ]
then
    echo "$KB_DATA_PATH/kingbase.conf is empty,will cp etc/kingbase.conf to data/kingbase.conf" >> $RECOVERY_LOG_DIR 2>&1
    MyCpCatSed cp ${KB_ETC_PATH}/kingbase.conf ${KB_DATA_PATH}/kingbase.conf >> $RECOVERY_LOG_DIR 2>&1
fi

#4, MV recovery.conf if old primary, but also used in old standby
MyCpCatSed cp ${KB_ETC_PATH}/recovery.done ${KB_DATA_PATH}/recovery.conf  >> $RECOVERY_LOG_DIR 2>&1

echo "cp recovery.conf..." >> $RECOVERY_LOG_DIR 2>&1

#6, change recovery.conf ip -> primary.ip
echo " change recovery.conf ip -> primary.ip"  >> $RECOVERY_LOG_DIR 2>&1

NEED_CHANGE=`cat ${KB_DATA_PATH}/recovery.conf 2>/dev/null| grep -w "host=$result_of_NOWPRIMARYIP" | wc -l; echo ";" ${PIPESTATUS[*]}`
result_of_NEED_CHANGE=`echo $NEED_CHANGE |awk -F ';' '{print $1}'|awk '{print $1}'`
cmd_echo=`echo $NEED_CHANGE |awk -F ';' '{print $2}'|awk '{print $1}'`
cmd_grep=`echo $NEED_CHANGE |awk -F ';' '{print $2}'|awk '{print $2}'`
cmd_wc=`echo $NEED_CHANGE |awk -F ';' '{print $2}'|awk '{print $3}'`

if [ "${cmd_echo}"x != "0"x -o "${cmd_wc}"x != "0"x ]
then
    echo "echo execute failed,will exit script with error"  >> $RECOVERY_LOG_DIR 2>&1
    errorhandle "exit" "\"cat ${KB_DATA_PATH}/recovery.conf 2>/dev/null| grep -w \"host=$result_of_NOWPRIMARYIP\" | wc -l\" execute failed, error num=[$cmd_echo $cmd_grep $cmd_wc ]"
fi

if [ "$result_of_NEED_CHANGE"x = "0"x ]
then
    echo "`date +'%Y-%m-%d %H:%M:%S'` change recovery.conf" >> $RECOVERY_LOG_DIR 2>&1
    
    MyCpCatSed sed ${KB_DATA_PATH}/recovery.conf $KB_ETC_PATH/$FILE_NAME.recovery.temp "s#[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}#$result_of_NOWPRIMARYIP#g" >> $RECOVERY_LOG_DIR 2>&1
		
	MyCpCatSed cat $KB_ETC_PATH/$FILE_NAME.recovery.temp  ${KB_DATA_PATH}/recovery.conf >> $RECOVERY_LOG_DIR 2>&1
    
    rm -f $KB_ETC_PATH/$FILE_NAME.recovery.temp >> $RECOVERY_LOG_DIR 2>&1
else
    echo "`date +'%Y-%m-%d %H:%M:%S'` no need change recovery.conf, primary node is $result_of_NOWPRIMARYIP" >> $RECOVERY_LOG_DIR 2>&1
fi

#6.5 delete pid file if exist

echo "delete pid file if exist" >> $RECOVERY_LOG_DIR 2>&1

FILEEXIST=`ls ${KB_DATA_PATH}/kingbase.pid 2>/dev/null| wc -l; echo ";" ${PIPESTATUS[*]}`
result_of_FILEEXIST=`echo $FILEEXIST |awk -F ';' '{print $1}'|awk '{print $1}'`
cmd_ls=`echo $FILEEXIST |awk -F ';' '{print $2}'|awk '{print $1}'`
cmd_wc=`echo $FILEEXIST |awk -F ';' '{print $2}'|awk '{print $2}'`

if [ "${cmd_wc}"x != "0"x ]
then
    echo "ls execute failed,will exit script with error"  >> $RECOVERY_LOG_DIR 2>&1
    errorhandle "exit" "\"ls ${KB_DATA_PATH}/kingbase.pid 2>/dev/null| wc -l\" execute failed, error num=[$cmd_ls $cmd_wc]"
fi

if [ $result_of_FILEEXIST -eq 1 ]
then
    rm -rf ${KB_DATA_PATH}/kingbase.pid
    echo "remove file ${KB_DATA_PATH}/kingbase.pid that be safe"  >> $RECOVERY_LOG_DIR 2>&1
fi

echo "del the replication_slots if exis" >> $RECOVERY_LOG_DIR 2>&1
# del the replication_slots if exist
slots_list=()
slots_list_old=()
slots_list_new=()
slots_num=0
# if the file tmp_slot exist, read it.
if [ -f ${KB_DATA_PATH}/../tmp_slot ]
then
    slots_num=0
    all_slots=`cat ${KB_DATA_PATH}/../tmp_slot`
    for item in ${all_slots[@]}
    do
        slots_list_old[slots_num]=$item
        slots_num=$slots_num+1
    done
fi
slots_num=0
# find the slots in sys_replslot
for slot in `ls ${KB_DATA_PATH}/sys_replslot`
do
    is_dir="${KB_DATA_PATH}/sys_replslot/${slot}"
    if [ -d $is_dir ]
    then
        if [ -f ${is_dir}/state ]
        then
            is_replica=`cat -A ${is_dir}/state  | grep -E "syslogical_output|test_decoding|wal2json|ali_decoding|decoderbufs|decoder_raw" | wc -l`
            if [ "$is_replica"x = "0"x ]
            then
                slots_list_new[slots_num]=$slot
                slots_num=$slots_num+1
            fi
        fi
    fi
done
if [ ${#slots_list_old[@]} -gt ${#slots_list_new[@]} ]
then
    slots_list=(`echo ${slots_list_old[@]}`)
else
    slots_list=(`echo ${slots_list_new[@]}`)
fi
if [ ${#slots_list[@]} -gt 0 ]
then
    echo ${slots_list[@]} > ${KB_DATA_PATH}/../tmp_slot
    # delete the dir in sys_replslots
    for slot in ${slots_list_new[@]}
    do
        dest_dir="${KB_DATA_PATH}/sys_replslot/${slot}"
        echo "drop the slot [$slot]." >> $RECOVERY_LOG_DIR 2>&1
        rm -rf $dest_dir >> $RECOVERY_LOG_DIR 2>&1
    done
else
    # maybe the file tmp_slot is exist, but it's empty.
    if [ -f ${KB_DATA_PATH}/../tmp_slot ]
    then
        rm -rf ${KB_DATA_PATH}/../tmp_slot >> $RECOVERY_LOG_DIR 2>&1
    fi
fi

#7 start up
echo "`date +'%Y-%m-%d %H:%M:%S'` start up the kingbase..." >> $RECOVERY_LOG_DIR 2>&1
sys_ctl start -w -t 90 -D $KB_DATA_PATH >> $RECOVERY_LOG_DIR 2>&1
sleep 1
startup_start_time=`date +%s`
redo_start=`export LANG=en_US.UTF-8;$KB_PATH/sys_controldata -D $KB_DATA_PATH |grep "Latest checkpoint's REDO location" |awk -F ':' '{print $2}'|awk '{print $1}'` >> $RECOVERY_LOG_DIR 2>&1 
while [ 1 ]
do
    startup_current_time=`date +%s`
    startup_interval=$(($startup_current_time - $startup_start_time))
    redo_now=`export LANG=en_US.UTF-8;$KB_PATH/sys_controldata -D $KB_DATA_PATH |grep "Latest checkpoint's REDO location" |awk -F ':' '{print $2}'|awk '{print $1}'` >> $RECOVERY_LOG_DIR 2>&1
    if [ "$redo_start"x = "$redo_now"x ]
    then
        if [ $startup_interval -gt 3600 ]
        then
            errorhandle "stopdbexit" "`date +'%Y-%m-%d %H:%M:%S'` already start db 1 hour,it maybe cannot start,will exit with error."
        fi
    else
        redo_start=$redo_now
        startup_start_time=`date +%s`
    fi
    #check db if down
    kingbase_pid=`cat ${KB_DATA_PATH}/kingbase.pid |head -n 1; echo ";" ${PIPESTATUS[*]}`
    result_of_kingbase_pid=`echo $kingbase_pid |awk -F ';' '{print $1}'|awk '{print $1}'`
    cmd_cat=`echo $kingbase_pid |awk -F ';' '{print $2}'|awk '{print $1}'`
    cmd_head=`echo $kingbase_pid |awk -F ';' '{print $2}'|awk '{print $2}'`

    if [ "${cmd_cat}"x != "0"x -o  "${cmd_head}"x != "0"x ]
    then
        echo "cat execute failed,will exit script with error and stop db"  >> $RECOVERY_LOG_DIR 2>&1
        errorhandle "stopdbexit" "\"cat ${KB_DATA_PATH}/kingbase.pid |head -n 1\" execute failed, error num=[$cmd_cat $cmd_head]"
    fi

    if [ "$result_of_kingbase_pid"x != ""x ]
    then
        kingbase_exist=`ps -ef | grep -w $result_of_kingbase_pid | grep -v grep | wc -l;echo ";" ${PIPESTATUS[*]}`
        result_of_kingbase_exist=`echo $kingbase_exist |awk -F ';' '{print $1}'|awk '{print $1}'`
        cmd_ps=`echo $kingbase_exist |awk -F ';' '{print $2}'|awk '{print $1}'`
        cmd_grep1=`echo $kingbase_exist |awk -F ';' '{print $2}'|awk '{print $2}'`
        cmd_grep2=`echo $kingbase_exist |awk -F ';' '{print $2}'|awk '{print $3}'`
        cmd_wc=`echo $kingbase_exist |awk -F ';' '{print $2}'|awk '{print $4}'`

        if [ "${cmd_ps}"x != "0"x -o "${cmd_wc}"x != "0"x ]
        then
            echo "ps execute failed,will exit script with error and stop db"  >> $RECOVERY_LOG_DIR 2>&1
            errorhandle "stopdbexit" "\"ps -ef | grep -w $result_of_kingbase_pid | grep -v grep | wc -l\" execute failed, error num=[$cmd_ps $cmd_grep1 $cmd_grep2 $cmd_wc]"
        fi

        if [ "$result_of_kingbase_exist" -eq 0 ]
        then
           echo "`date +'%Y-%m-%d %H:%M:%S'` The process was started, but no pid was foud in system, which db may have been turned off!" >> $RECOVERY_LOG_DIR 2>&1
           errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` Set recovery flag 0, and exit recovery process."
        fi
    else
        echo "`date +'%Y-%m-%d %H:%M:%S'` The process was started, but no pid file was foud, which db may have been turned off!" >> $RECOVERY_LOG_DIR 2>&1
        errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` Set recovery flag 0, and exit recovery process."
    fi

    echo "ksql \"port=$KB_PORT user=$KB_USER dbname=$KB_DATANAME connect_timeout=10\"   -c \"select 33333;\"" >> $RECOVERY_LOG_DIR 2>&1
    result_of_ksql=`ksql "port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10"  -c "select 33333;"`
    rightnum=`echo $result_of_ksql | grep 33333 | wc -l;echo ";" ${PIPESTATUS[*]}`
    result_of_rightnum=`echo $rightnum |awk -F ';' '{print $1}'|awk '{print $1}'`
    cmd_ksql=`echo $rightnum |awk -F ';' '{print $2}'|awk '{print $1}'`
    cmd_grep=`echo $rightnum |awk -F ';' '{print $2}'|awk '{print $2}'`
    cmd_wc=`echo $rightnum |awk -F ';' '{print $2}'|awk '{print $3}'`

    if [ "${cmd_ksql}"x != "0"x -o "${cmd_wc}"x != "0"x ]
    then
        echo "ksql execute failed,will exit script with error and stop db"  >> $RECOVERY_LOG_DIR 2>&1
        errorhandle "stopdbexit" "\"ksql \"port=$KB_PORT user=$KB_USER dbname=$KB_DATANAME connect_timeout=10\"  -c \"select 33333;\" | grep 33333 | wc -l\" execute failed,query detail[$result_of_ksql] , error num=[$cmd_ksql $cmd_grep $cmd_wc ]"
    fi

    if [ "$result_of_rightnum"x = "1"x ]
    then
        break
    else
        echo start standby query detail[$result_of_ksql] , try again! 2>&1 >> $RECOVERY_LOG_DIR 2>&1
        sleep 3
        continue
    fi
done

# create the replication_slots
if [ ${#slots_list[@]} -gt 0 ]
then
    for slot in ${slots_list[@]}
    do
        ksql "port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10"  -c "select sys_create_physical_replication_slot('$slot');" >> $RECOVERY_LOG_DIR 2>&1
        if [ $? -eq 0 ]
        then
            echo "`date +'%Y-%m-%d %H:%M:%S'` create the slot [$slot] success." >> $RECOVERY_LOG_DIR 2>&1
        else
            errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` create the slot [$slot] failed, exit recovery process."
        fi
    done
    rm -rf ${KB_DATA_PATH}/../tmp_slot >> $RECOVERY_LOG_DIR 2>&1
fi

# check the replication has connect to primary
wal_receiver_exist=`ksql "port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10"  -c "select CONNINFO from sys_stat_wal_receiver;" | grep -w $result_of_NOWPRIMARYIP | wc -l; echo ";" ${PIPESTATUS[*]}`
result_of_wal_receiver_exist=`echo $rightnum |awk -F ';' '{print $1}'|awk '{print $1}'`
cmd_ksql=`echo $rightnum |awk -F ';' '{print $2}'|awk '{print $1}'`
cmd_grep=`echo $rightnum |awk -F ';' '{print $2}'|awk '{print $2}'`
cmd_wc=`echo $rightnum |awk -F ';' '{print $2}'|awk '{print $3}'`

if [ "${cmd_ksql}"x != "0"x -o "${cmd_wc}"x != "0"x ]
then
    echo "ksql execute failed,will exit script with error and stop db"  >> $RECOVERY_LOG_DIR 2>&1
    errorhandle "stopdbexit" "\"ksql \"port=$KB_PORT user=$KB_USER dbname=$KB_DATANAME connect_timeout=10\"  -c \"select CONNINFO from sys_stat_wal_receiver;\" | grep -w $result_of_NOWPRIMARYIP | wc -l\" execute failed, error num=[$cmd_ksql $cmd_grep $cmd_wc ]"
fi

if [ "$result_of_wal_receiver_exist"x = "0"x ]
then
    errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` The db was started, but replication to primary is failed, exit recovery process."
fi

echo "`date +'%Y-%m-%d %H:%M:%S'` start up standby successful!" >> $RECOVERY_LOG_DIR 2>&1

#7 attach pool

attach_cluster

#8 very important, set my flag is 0.
if [ $force_recovery -eq 1 ]
then
    realist=`cat /etc/cron.d/KINGBASECRON | grep -wFn "*/1 * * * * $KB_EXECUTE_SYS_USER  ${KB_PATH}/network_rewind.sh"`
    linenum=`echo "$realist" |awk -F':' '{print $1}'`
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l root -T localhost "sed -i \"${linenum}s/#//g\" /etc/cron.d/KINGBASECRON" 2>&1
    echo "recovery success,exit script with success "
fi
echo "recovery success,exit script with success "  >> $RECOVERY_LOG_DIR 2>&1
echo 0 > ${KB_RECOVERY_FLAG}

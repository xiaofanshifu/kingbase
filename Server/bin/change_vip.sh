#!/bin/bash
#del VIP

SHELL_FOLDER=$(dirname $(readlink -f "$0"))
CfgFile="${SHELL_FOLDER}/../etc/HAmodule.conf"

if [ ! -f ${CfgFile} ];then
    echo "ERROR: No change_vip files!"
	echo $CfgFile
    exit 1
fi

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
DEV=""
CMD_IP_PATH="/sbin"
CMD_ARPING_PATH="/sbin"
COMMENT

KB_VIP=$1
if [ "$DEV"x = ""x ]
then
    DEV=$2
fi
OPRATE=$3
IS_FIRST_ADD=$4
KB_DATA_PATH=$5

#the function of error handing
check_err_result()
{
    if [ $1 != 0 ];then
        echo `date +'%Y-%m-%d %H:%M:%S'` error code:$1
        #return 4;
        exit $1
    fi
}


if [ "$KB_VIP"x = ""x ]
then
    echo "no pass the dbvip,details set vip[$KB_VIP], return"
    exit 0;
fi

#determine execute add or del vip by passing parameter
if [ "$OPRATE"x = "del"x -a "$DEV"x != ""x ]
then
    echo DEL VIP NOW AT `date +'%Y-%m-%d %H:%M:%S'` ON $DEV
    ip_exist=`${CMD_IP_PATH}/ip addr | grep -w "$KB_VIP" | wc -l; echo ";" ${PIPESTATUS[*]}`
    result_of_ip_exist=`echo $ip_exist |awk -F ';' '{print $1}'|awk '{print $1}'`
    cmd_ipaddr=`echo $ip_exist |awk -F ';' '{print $2}' |awk '{print $1}'`
    cmd_grep=`echo $ip_exist |awk -F ';' '{print $2}' |awk '{print $2}'`
    cmd_wc=`echo $ip_exist |awk -F ';' '{print $2}' |awk '{print $3}'`
    check_err_result $cmd_ipaddr
    check_err_result $cmd_wc
    if [ $result_of_ip_exist -eq 0 ]
    then
        echo "No VIP on my dev, nothing to do."
        exit 0;
    fi
    echo "execute: [${CMD_IP_PATH}/ip addr $OPRATE $KB_VIP dev $DEV]"
    ${CMD_IP_PATH}/ip addr $OPRATE $KB_VIP dev $DEV 2>/dev/null
    check_err_result $?

    echo Oprate del ip cmd end.

elif [ "$OPRATE"x = "add"x -a "$DEV"x != ""x ]
then
    if [ "$IS_FIRST_ADD"x != ""x ]
    then
        master_node=`ls ${KB_DATA_PATH}/recovery.conf 2>/dev/null |wc -l; echo ";" ${PIPESTATUS[*]}`
        result_of_master_node=`echo $master_node |awk -F ';' '{print $1}'|awk '{print $1}'`
        cmd_ls=`echo $master_node |awk -F ';' '{print $2}' |awk '{print $1}'`
        cmd_wc=`echo $master_node |awk -F ';' '{print $2}' |awk '{print $2}'`
        check_err_result $cmd_wc
        if [ "$result_of_master_node" -eq 1 ]
        then
            exit 0;
        fi
    fi

    echo ADD VIP NOW AT `date +'%Y-%m-%d %H:%M:%S'` ON $DEV
    echo "execute: [${CMD_IP_PATH}/ip addr add $KB_VIP dev $DEV label ${DEV}:2]"
    ${CMD_IP_PATH}/ip addr add $KB_VIP dev $DEV label ${DEV}:2 2>&1
    check_err_result $?
    #/usr/sbin/arping -s 192.168.211.15 -c 3 -I $
    echo "execute: ${CMD_ARPING_PATH}/arping -U ${KB_VIP%%/*} -I $DEV -w 1"
    ${CMD_ARPING_PATH}/arping -U ${KB_VIP%%/*} -I $DEV -w 1 -c 1 2>/dev/null
else
    echo oprate vip failed, details vip[$KB_VIP], dev[$DEV], oprate[$OPRATE]
    exit 1
fi



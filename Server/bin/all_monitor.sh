#!/bin/bash

. /etc/profile

ACT="$2"

WHICHPRO="$3"

if [ "$WHICHPRO"x = "pool"x ]
then
CLUSTER_BIN_PATH="$1"
CLUSTER_ETC_FILE="${CLUSTER_BIN_PATH}/../etc/kingbasecluster.conf"
KB_PATH="$4"
KB_POOL_VIP="$5"
DEV="$6"
export PATH=$CLUSTER_BIN_PATH:$PATH
elif [ "$WHICHPRO"x = "dbvip"x ]
then
KB_PATH="$1"
KB_DATA_PATH="$4"
KB_VIP="$5"
DEV="$6"
export PATH=$KB_PATH:$PATH
elif [ "$WHICHPRO"x = "db"x -o "$WHICHPRO"x = "dbcrond"x ]
then
KB_PATH="$1"
KB_DATA_PATH="$4"
KB_EXECUTE_SYS_USER="$5"
export PATH=$KB_PATH:$PATH
elif [ "$WHICHPRO"x = "trustip"x ]
then
MAX_RETRIES="$1"
RETRY_DELAY="$4"
elif [ "$WHICHPRO"x = "vip"x ]
then
MAX_RETRIES="$1"
RETRY_DELAY="$4"
fi


<<COMMENT
KINGBASECLUSTERSOCKET1="/tmp/.s.KINGBASE.9999"
KINGBASECLUSTERSOCKET2="/tmp/.s.KINGBASE.9898"
KINGBASECLUSTERSOCKET3="/tmp/.s.KINGBASE.9000"
CLUSTER_STAT_FILE="/tmp/kingbasecluster_status"
CLUSTER_LOG_PATH="$CLUSTER_BIN_PATH/log"
# CONNECTTIMEOUT=15
COMMENT

SHELL_FOLDER=$(dirname $(readlink -f "$0"))
CfgFile="${SHELL_FOLDER}/../etc/HAmodule.conf"

if [ ! -f ${CfgFile} ];then
    echo "ERROR: No configuration files!"
    exit 1
fi

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

if [ "${MAX_AVAILABLE_LEVEL}"x = "1"x -o "${MAX_AVAILABLE_LEVEL}"x = "on"x -o "${MAX_AVAILABLE_LEVEL}"x = "true"x -o "${MAX_AVAILABLE_LEVEL}"x = "yes"x ]
then
    MAX_AVAILABLE_LEVEL=1
else
    MAX_AVAILABLE_LEVEL=0
fi

EXENAME="kingbasecluster"

##################
#
#BEGIN
#
##################

check_err_result()
{
        if [ $1 != 0 ];then
           echo `date +'%Y-%m-%d %H:%M:%S'` error code:$1 
           #return 4;
           exit $1
        fi
}


#create file log path

if [ "$WHICHPRO"x = "pool"x ]
then
    if [ ! -d "$CLUSTER_LOG_PATH" ]
    then
    mkdir -p $CLUSTER_LOG_PATH
    echo "File cluster log dir create now" 
    fi
fi

#determine the cron service name is cron or crond
CROND_NAME=""
#add ubuntu system judgement
    which crond > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
        # Now ,we have used these system successfully e.g centos6.x centos7.x redhat.
        CROND_NAME="crond"
    else
        which cron > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
            ## Now ,we have used these system successfully e.g Deepin .
            CROND_NAME="cron"
        else
            echo "Don't know the crontab service name."
        fi
    fi


#stop cluster
function stopcluster()
{
    local kingbasecluster_pid
    local cluster_exist
    #echo `date +'%Y-%m-%d %H:%M:%S'` let kingbasecluster down !
    #1. stop the crontab
    #service crond stop
    local crontablist="*/1 * * * * root  ${CLUSTER_BIN_PATH}/restartcluster.sh"
    #now just add #
    #sed -i "s%${crontablist}%#${crontablist}%g" /etc/cron.d/KINGBASECRON
    if [ -f /etc/cron.d/KINGBASECRON ]
    then
        local cronexist=`cat /etc/cron.d/KINGBASECRON | grep -wFn "${crontablist}" |wc -l`
        if [ $cronexist -eq 1 ]
        then
            local realist=`cat /etc/cron.d/KINGBASECRON | grep -wFn "${crontablist}"`
            #sed -i "s%${realist}%${crontablist}%g" /etc/cron.d/KINGBASECRON
            local linenum=`echo "$realist" |awk -F':' '{print $1}'`

            #echo stop crontab kingbasecluster line number : [$linenum] 2>&1
            sed -i "${linenum}s/^/#/"  /etc/cron.d/KINGBASECRON
        fi
    fi


    #2 . stop the pro
    kingbasecluster_pid=`getpoolpid`
    if [ "$kingbasecluster_pid"x != ""x ]
    then
            cluster_exist=`ps -ef | grep -w $kingbasecluster_pid | grep -v grep | wc -l`
            if [ "$cluster_exist" -ge 1 ]
            then
                cd $CLUSTER_BIN_PATH
                `./$EXENAME -m fast stop > $CLUSTER_LOG_PATH/clusterstop 2>&1 &`
                sleep 5
            else
            echo "cluster is already down.."
            fi

        isstillalive=`ps -ef | grep -w $kingbasecluster_pid | grep -v grep | wc -l`
        if [ $isstillalive -ne 0 ]
        then
            `ps -eo pid,comm  | grep -w "$EXENAME$" |awk '{print $1}' |xargs kill -9 2>&1`
            `rm -f $CLUSTER_BIN_PATH/../../log/kingbasecluster/kingbasecluster.pid  2>&1`
        fi
    fi

    zombiewatchdog="kingbasecluster: watchdog"
    isstillalive=`ps -ef | grep "$zombiewatchdog" | grep -v grep | wc -l`
    if [ $isstillalive -ne 0 ]
    then
        echo "Warning! the watchdog is zombie, check out the kingbasecluster.conf"
        `ps -ef| grep "$zombiewatchdog" | grep -v grep |awk '{print $2}' |xargs kill -9 2>&1`
        `rm -f $CLUSTER_BIN_PATH/../../log/kingbasecluster/kingbasecluster.pid  2>&1`
    fi

    FILEEXIST=`ls $KINGBASECLUSTERSOCKET1 2>/dev/null | wc -l`
    if [ $FILEEXIST -eq 1 ]
    then
        rm -rf $KINGBASECLUSTERSOCKET1
        echo "remove socket $KINGBASECLUSTERSOCKET1"
    fi

    FILEEXIST=`ls $KINGBASECLUSTERSOCKET2 2>/dev/null | wc -l`
    if [ $FILEEXIST -eq 1 ]
    then
        rm -rf $KINGBASECLUSTERSOCKET2
        echo "remove socket $KINGBASECLUSTERSOCKET2"
    fi

    FILEEXIST=`ls $KINGBASECLUSTERSOCKET3 2>/dev/null | wc -l`
    if [ $FILEEXIST -eq 1 ]
    then
        rm -rf $KINGBASECLUSTERSOCKET3
        echo "remove socket $KINGBASECLUSTERSOCKET3"
    fi

    FILEEXIST=`ls $CLUSTER_STAT_FILE 2>/dev/null | wc -l`
    if [ $FILEEXIST -eq 1 ]
    then
        rm -rf $CLUSTER_STAT_FILE
        echo "remove status file  $CLUSTER_STAT_FILE"
    fi

    #3 drop vip of cluster
    $KB_PATH/change_vip.sh $KB_POOL_VIP $DEV del 2>&1 &

}



#start cluster
function startcluster()
{
#    service crond stop 2>&1
    restartcluster.sh
    local crontablist="*/1 * * * * root  ${CLUSTER_BIN_PATH}/restartcluster.sh"
	
	if [ -f /etc/cron.d/KINGBASECRON ]
	then
		local cronexist=`cat /etc/cron.d/KINGBASECRON | grep -wFn "${crontablist}" |wc -l`
		if [ $cronexist -eq 1 ]
		then
			local realist=`cat /etc/cron.d/KINGBASECRON | grep -wFn "${crontablist}"`
			#sed -i "s%${realist}%${crontablist}%g" /etc/cron.d/KINGBASECRON
			local linenum=`echo "$realist" |awk -F':' '{print $1}'`

			echo start crontab kingbasecluster line number: [$linenum] 2>&1
			sed -i "${linenum}s/#//g" /etc/cron.d/KINGBASECRON
			check_err_result $?

			service $CROND_NAME restart 2>&1
		elif [ $cronexist -eq 0 ]
		then
			echo "$crontablist" >> /etc/cron.d/KINGBASECRON
			service $CROND_NAME restart 2>&1
		else
				echo "crond is bad ,please check!"
		fi
	else
		echo "$crontablist" >> /etc/cron.d/KINGBASECRON
		service $CROND_NAME restart 2>&1
	fi
}

#the function of set crontab of network_rewind.sj
function setcrontab()
{
    local user=$1
    local process=$2
    local crontablist="*/1 * * * * $user  ${KB_PATH}/${process}"
    #cronexist=`cat /etc/cron.d/KINGBASECRON | grep -w ${KB_PATH}/network_rewind.sh |wc -l`
	
	if [ -f /etc/cron.d/KINGBASECRON ]
	then
		local cronexist=`cat /etc/cron.d/KINGBASECRON | grep -wFn "${crontablist}" |wc -l`
		if [ $cronexist -eq 1 ]
		then
			local realist=`cat /etc/cron.d/KINGBASECRON | grep -wFn "${crontablist}"`
			#sed -i "s%${realist}%${crontablist}%g" /etc/cron.d/KINGBASECRON
			local linenum=`echo "$realist" |awk -F':' '{print $1}'`

			echo start crontab kingbase position : [$linenum] 2>&1
			sed -i "${linenum}s/#//g" /etc/cron.d/KINGBASECRON 2>&1

			service $CROND_NAME restart 2>&1
		elif [ $cronexist -eq 0 ]
		then
			echo "$crontablist" >> /etc/cron.d/KINGBASECRON
			service $CROND_NAME restart 2>&1
		else
			echo "crond is bad ,please check!"
			exit 1
		fi
	else
		echo "$crontablist" >> /etc/cron.d/KINGBASECRON
		service $CROND_NAME restart 2>&1
	fi
}

#set network_rewind.sh`s crontab
function startdbcrontab()
{
    setcrontab $1 network_rewind.sh
}

#get pid of cluster
function getpoolpid()
{
    cfg=`grep pid_file_name $CLUSTER_ETC_FILE 2>/dev/null`
    #check_err_result $?
    # Remove the configuration line comment section in the configuration file.
    param=${cfg%%#*}

    paramValue=${param##*=}

    if [ -z $paramValue ]; then
        return 
    fi
    #local paramValue1=${paramValue// /}
    local paramValue1=${paramValue//\'/}
    echo `cat ${paramValue1// /} 2>/dev/null |head -n 1`
    
    #[${paramValue// /}]
}

#check the cluster is alive
function checkpool()
{
    kingbasecluster_pid=`getpoolpid`
    if [ "$kingbasecluster_pid"x != ""x ]
    then
            cluster_exist=`ps -ef | grep -w $kingbasecluster_pid | grep -v grep | wc -l` 
            if [ "$cluster_exist" -ge 1 ]
            then
                echo $cluster_exist 2>&1
                return 
            fi
    fi
echo 0 2>&1
#return 0
}

#check the db is alive
function checkdb()
{
    kingbase_pid=`cat ${KB_DATA_PATH}/kingbase.pid 2>/dev/null|head -n 1`
    if [ "$kingbase_pid"x != ""x ]
    then
            kingbase_exist=`ps -ef | grep -w $kingbase_pid | grep -v grep | wc -l` 
            if [ "$kingbase_exist" -ge 1 ]
            then
                echo $kingbase_exist 2>&1
                return 
            fi
    fi
    echo 0 2>&1
#return 0
}

#start the db
function startdb()
{

    sys_ctl start -w -t 90 -D $KB_DATA_PATH > $CLUSTER_LOG_PATH/kbstart 2>&1 
    
    sleep 1
    local kingbase_pid=`cat ${KB_DATA_PATH}/kingbase.pid 2>/dev/null |head -n 1`
    if [ "$kingbase_pid"x != ""x ]
    then
        local kingbase_exist=`ps -ef | grep -w $kingbase_pid | grep -v grep | wc -l` 
        if [ "$kingbase_exist" -ge 1 ]
        then
            echo $kingbase_exist 2>&1
            
        else
            echo 0 2>&1
            tail -n 20 $CLUSTER_LOG_PATH/kbstart
        fi
    else
            echo 0 2>&1
            tail -n 20 $CLUSTER_LOG_PATH/kbstart
    fi
}

#stop the crontab of process
function stopcrond()
{
    local process=$1
    local crontablist="*/1 * * * * ${KB_EXECUTE_SYS_USER}  ${KB_PATH}/${process}"

    # must execute by root
    if [ -f /etc/cron.d/KINGBASECRON ]
    then
        local cronexist=`cat /etc/cron.d/KINGBASECRON | grep -wFn "${crontablist}" |wc -l`
        if [ $cronexist -eq 1 ]
        then
            local realist=`cat /etc/cron.d/KINGBASECRON | grep -wFn "${crontablist}"`
            local linenum=`echo "$realist" |awk -F':' '{print $1}'`

            sed -i "${linenum}s/^/#/"  /etc/cron.d/KINGBASECRON
            check_err_result $?
        fi
    fi
}

#stop the network_rewind.sh
function stopdbcrond()
{
    stopcrond network_rewind.sh

    if [ $MAX_AVAILABLE_LEVEL -gt 0 ]
    then
        ## try to kill network_rewind.sh process
        rewind_exists=`ps -ef | grep -w "${KB_PATH}/network_rewind.sh" | grep -v grep | wc -l`
        if [ $? -eq 0 ] && [ "${rewind_exists}"x != ""x ] && [ $rewind_exists -gt 0 ]
        then
            echo "try to kill network_rewind.sh ..." 2>&1
            ps -ef | grep -w "${KB_PATH}/network_rewind.sh" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null
        fi
    fi
}

#stop the db
function stopdb()
{
    kingbase_pid=`cat ${KB_DATA_PATH}/kingbase.pid 2>/dev/null|head -n 1`

    if [ "$kingbase_pid"x != ""x ]
    then
            kingbase_exist=`ps -ef | grep -w $kingbase_pid | grep -v grep | wc -l`
            if [ "$kingbase_exist" -ge 1 ]
            then
                sys_ctl stop -w -t 90 -D $KB_DATA_PATH -m fast > $CLUSTER_LOG_PATH/kbstop 2>&1
                echo "set $KB_DATA_PATH down now..."
                sleep 1
            fi
            kingbase_still_exist=`ps -ef | grep -w $kingbase_pid | grep -v grep | wc -l`
            if [ "$kingbase_still_exist" -ge 1 ]
            then
                ps -ef| grep -w $kingbase_pid | grep -v grep |awk '{print $2}' |xargs kill -9 2>&1
                echo "set $KB_DATA_PATH down again..." 2>&1
                sleep 1
            fi
    fi
}

#check the trust ip if is can ping through
function checktrustip()
{
    OLD_IFS="$IFS"
    IFS=","
    ip_arr=($KB_GATEWAY_IP)
    IFS="$OLD_IFS"
    PING_FLAG=0

    for((i=1;i<=$MAX_RETRIES;i++))
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
                echo "the ${i}th time ping trust ip failed, will ping the next trust ip"
                echo "\"ping $trust_ip -c $PING_TIMES -w 2 | grep received | awk '{print $4}'\" execute failed, error num=[$cmd_ping $cmd_grep $cmd_awk ]"
                continue
            fi
            if [ "${cmd_awk}"x != "0"x ]
            then
                echo "the ${i}th time ping trust ip failed, will ping the next trust ip"
                echo "\"ping $trust_ip -c $PING_TIMES -w 2 | grep received | awk '{print $4}'\" execute failed, error num=[$cmd_ping $cmd_grep $cmd_awk ]"
                continue
            fi
            if [ "$result_of_ping"x = ""x ]
            then
                echo "the ${i}th time ping trust ip failed, will ping the next trust ip"
                echo "ping execute failed please check....."
                continue
            fi
            if [ $result_of_ping -gt 0 ]
            then
                echo "ping trust ip $trust_ip success ping times :[$PING_TIMES], success times:[$result_of_ping]"
                PING_FLAG=1
                break
            else
                echo "ping trust ip $trust_ip failed, will ping next trust ip"
            fi
        done
        if [ $PING_FLAG -eq 1 ]
        then
            break
        fi
        echo "the ${i}th time ping all trust ip failed,will ping trust ip the next time, retry times: [${i}/${MAX_RETRIES}]"
        [ $i -ne $MAX_RETRIES ] && sleep $RETRY_DELAY
    done

    if [ $PING_FLAG -eq 0 ]
    then
        echo "ping all trust ip failed, retry times:${MAX_RETRIES} times, will exit with error"
        exit 1
    fi
}

#check vip if is can ping through after the primary add the vip
function checkvip()
{
    PING_FLAG=0
    vip=${KB_VIP%%/*}
    for((i=1;i<=$MAX_RETRIES;i++))
    do
        result=`ping $vip -c $PING_TIMES -w 2 | grep received | awk '{print $4}'; echo ";" ${PIPESTATUS[*]}`
        result_of_ping=`echo $result |awk -F ';' '{print $1}'|awk '{print $1}'`
        cmd_ping=`echo $result |awk -F ';' '{print $2}' |awk '{print $1}'`
        cmd_grep=`echo $result |awk -F ';' '{print $2}' |awk '{print $2}'`
        cmd_awk=`echo $result |awk -F ';' '{print $2}' |awk '{print $3}'`

        if [ $result_of_ping -gt 0 ]
        then
            echo "ping vip $vip success ping times :[$PING_TIMES], success times:[$result_of_ping]"
            PING_FLAG=1
            break
        fi
        echo "the ${i}th time ping vip failed,will ping vip the next time, retry times: [${i}/${MAX_RETRIES}]"
        [ $i -ne $MAX_RETRIES ] && sleep $RETRY_DELAY
    done

    if [ $PING_FLAG -eq 0 ]
    then
        echo "ping vip failed, retry times:${MAX_RETRIES} times, will exit with error"
        exit 1
    fi
}

#judge which functions to execute by passing paramters
main()
{
    if [ "$ACT"x = "stop"x ]
    then
         if [ "$WHICHPRO"x = "pool"x ]
         then 
            stopcluster
         elif [ "$WHICHPRO"x = "db"x ]
         then
            stopdb
         elif [ "$WHICHPRO"x = "dbcrond"x ]
         then
            stopdbcrond
         elif [ "$WHICHPRO"x = "dbvip"x ]
         then
            $KB_PATH/change_vip.sh $KB_VIP $DEV del first ${KB_DATA_PATH}
         else
            echo "wchi pro should be stop? pro is [$WHICHPRO]"
         fi
    elif [ "$ACT"x = "start"x ]
    then
         if [ "$WHICHPRO"x = "pool"x ]
         then 
            startcluster
         elif [ "$WHICHPRO"x = "db"x ]
         then
            startdb
         elif [ "$WHICHPRO"x = "dbcrond"x ]
         then
            startdbcrontab $KB_EXECUTE_SYS_USER
         elif [ "$WHICHPRO"x = "dbvip"x ]
         then
            $KB_PATH/change_vip.sh $KB_VIP $DEV add first ${KB_DATA_PATH}
         else
            echo "wchi pro should be stop? pro is [$WHICHPRO]"
         fi
    elif [ "$ACT"x = "check"x ]
    then
         if [ "$WHICHPRO"x = "pool"x ]
         then
         checkpool
         elif [ "$WHICHPRO"x = "db"x ]
         then
         checkdb
         elif [ "$WHICHPRO"x = "trustip"x ]
         then
         checktrustip
         elif [ "$WHICHPRO"x = "vip"x ]
         then
         checkvip
         fi
    else
        echo "please use start|stop"
    fi
}

main

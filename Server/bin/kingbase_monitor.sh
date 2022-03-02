#!/bin/bash

DATA_SIZE_DIFF=16

SHELL_FOLDER=$(dirname $(readlink -f "$0"))
CfgFile="${SHELL_FOLDER}/../etc/HAmodule.conf"

if [ ! -f ${CfgFile} ];then
    echo "ERROR: No configuration files!"
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
KB_ALL_IP=()
ALL_NODE_NAME=()
NODE_NAME=""
KB_LOCALHOST_IP=""
KB_POOL_IP1=""
KB_POOL_IP2=""
KB_VIP=""
KB_POOL_VIP=""
DEV=""
KB_PATH="/home/kdb/KingbaseES/V8/Server/bin"
CLUSTER_BIN_PATH=""
KB_DATA_PATH="/home/kdb/KingbaseES/V8/data"

KB_EXECUTE_SYS_USER="lx"
KB_POOL_EXECUTE_SYS_USER="root"
CONNECTTIMEOUT=15

COMMENT

# check the lsn diff between primary and standby, default is 16 MB.
DATA_SIZE_DIFF=16

# user can use '--force' to startall when standby server is not correct
# default is 0, could not start when standby has something wrong.
force_start=0

KB_REAL_PASS=`echo $KB_PASS | base64 -d 2>/dev/null`

POOL_1_STAUTS="active"
POOL_2_STAUTS="active"
export PATH=$KB_PATH:$PATH

#################################################################################
#
# main script
#
################################################################################
function usage()
{
    echo "usage: $0 start | stop | restart | set [--restart] | change_password user old_password new_password ";exit 1
}

#the function of error handing
check_err_result()
{
    if [ $1 != 0 ];then
       echo `date +'%Y-%m-%d %H:%M:%S'` error code:$1
       exit $1
    fi
}

#the function of warning handing
check_waring_result()
{
    if [ $1 != 0 ];then
       echo `date +'%Y-%m-%d %H:%M:%S'` warning code:$1
       return 1;
    fi
    return 0;
}


echo "-----------------------------------------------------------------------"
echo `date +'%Y-%m-%d %H:%M:%S'` KingbaseES automation beging...

function usgprintsucess()
{
local kbip
echo "======================================================================="

echo "|`printf %15s ip ` |`printf %30s program`|`printf %22s [status]` "
echo "[`printf %15s $KB_POOL_IP1`]|`printf %30s [kingbasecluster]`|`printf %22s [active]`"
echo "[`printf %15s $KB_POOL_IP2`]|`printf %30s [kingbasecluster]`|`printf %22s [active]`"
for kbip in ${KB_ALL_IP[@]}
do
echo "[`printf %15s $kbip`]|`printf %30s [kingbase]`|`printf %22s [active]`"
done
echo "======================================================================="
}

#check cluster if is alive
function checkpool()
{
    #new judge
    local pool_num
    local pool_up_finish=$1

    pool_num=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $KB_POOL_IP1 "$KB_PATH/all_monitor.sh $CLUSTER_BIN_PATH  check pool "`
    if [ "$pool_num"x = ""x ]
    then
        echo "We can't ssh $KB_POOL_IP1 immediately, check later.."
        POOL_1_STAUTS="unknow"
    else
        if [ $pool_num -ne 0 -a "$pool_up_finish"x = ""x ]
        then 
            echo "localhost kingbasecluster is still alive, please stop first"
            exit 0
        elif [ $pool_num -eq 0 -a "$pool_up_finish"x != ""x ]
        then
            echo "localhost kingbasecluster is not alive, please check it! (monitor log and kingbasecluster log)"
            exit 0
        fi
    fi

    pool_num=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $KB_POOL_IP2 "$KB_PATH/all_monitor.sh $CLUSTER_BIN_PATH  check pool  "`
    if [ "$pool_num"x = ""x ]
    then
        echo "We can't ssh $KB_POOL_IP2 immediately, check later.."
        POOL_2_STAUTS="unknow"
    else
        if [ $pool_num -ne 0 -a "$pool_up_finish"x = ""x ]
        then
            echo "[$KB_POOL_IP2] kingbasecluster is still alive, please stop first"
            exit 0
        elif [ $pool_num -eq 0 -a "$pool_up_finish"x != ""x ]
        then
            echo "[$KB_POOL_IP2] kingbasecluster is not alive, please check it! (monitor log and kingbasecluster log)"
            exit 0
        fi
    fi

    #1 mean all pool is start up
    return 1
}

#stop cluster
function stoppool()
{
    local pool_num
    local check_flag
    echo `date +'%Y-%m-%d %H:%M:%S'` stop kingbasecluster [$KB_POOL_IP1] ...
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $KB_POOL_IP1 "$CLUSTER_BIN_PATH/all_monitor.sh $CLUSTER_BIN_PATH  stop pool  $KB_PATH $KB_POOL_VIP $DEV"
    check_waring_result $?
    check_flag=$?
    if [ $check_flag != 0 ];then
        echo `date +'%Y-%m-%d %H:%M:%S'` Some wrong in here, ignore now. Stop next node.
    else
        pool_num=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT  -l $KB_POOL_EXECUTE_SYS_USER -T $KB_POOL_IP1 "$KB_PATH/all_monitor.sh $CLUSTER_BIN_PATH  check pool  "`
        check_waring_result $?
        check_flag=$?
        if [ $check_flag != 0 ];then
            echo `date +'%Y-%m-%d %H:%M:%S'` Some wrong were checked after shutdown, ignore now. Stop next node.
        else
            if [ $pool_num -ne 0 ]
            then
                echo "$KB_POOL_IP1 cluster is still alive, can't stop it! find error detail in log. Ignore now, Stop next node."
            else
                echo `date +'%Y-%m-%d %H:%M:%S'` Done...
            fi
        fi
    fi

    echo `date +'%Y-%m-%d %H:%M:%S'` stop kingbasecluster [$KB_POOL_IP2] ...
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT  -l $KB_POOL_EXECUTE_SYS_USER -T $KB_POOL_IP2 "$CLUSTER_BIN_PATH/all_monitor.sh $CLUSTER_BIN_PATH  stop pool  $KB_PATH $KB_POOL_VIP $DEV"

    check_waring_result $?
    check_flag=$?
    if [ $check_flag != 0 ];then
        echo `date +'%Y-%m-%d %H:%M:%S'` Some wrong in here, ignore now. Stop next node.
    else
        pool_num=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $KB_POOL_IP2 "$KB_PATH/all_monitor.sh $CLUSTER_BIN_PATH  check pool  "`
        check_waring_result $?
        check_flag=$?
        if [ $check_flag != 0 ];then
            echo `date +'%Y-%m-%d %H:%M:%S'` Some wrong were checked after shutdown, ignore now. Stop next node.
        else
            if [ $pool_num -ne 0 ]
            then 
                echo "$KB_POOL_IP2 cluster is still alive, can't stop it! find error detail in log. Ignore now. Stop next node. "
            else
                echo `date +'%Y-%m-%d %H:%M:%S'` Done...
            fi
        fi
    fi
}

#stop db
function stopdb()
{
    local db_num
    local check_flag
    for kb_ip in ${KB_ALL_IP[@]}
    do
        echo `date +'%Y-%m-%d %H:%M:%S'` stop crontab of network_rewind [$kb_ip] ... 2>&1
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $kb_ip "$KB_PATH/all_monitor.sh $KB_PATH  stop dbcrond $KB_DATA_PATH $KB_EXECUTE_SYS_USER"

        check_waring_result $?
        check_flag=$?
        if [ $check_flag != 0 ];then
            echo `date +'%Y-%m-%d %H:%M:%S'` Some wrong in here, ignore now. Continue.
        else
            echo `date +'%Y-%m-%d %H:%M:%S'` Done...
        fi

        echo `date +'%Y-%m-%d %H:%M:%S'` stop kingbase [$kb_ip] ... 2>&1
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T $kb_ip "$KB_PATH/all_monitor.sh $KB_PATH  stop db $KB_DATA_PATH $KB_EXECUTE_SYS_USER"

        check_waring_result $?
        check_flag=$?
        if [ $check_flag != 0 ];then
            echo `date +'%Y-%m-%d %H:%M:%S'` Some wrong in here, ignore now. Continue.
        else
            echo `date +'%Y-%m-%d %H:%M:%S'` Done...
        fi

        sleep 1
        echo `date +'%Y-%m-%d %H:%M:%S'` Del kingbase VIP [$KB_VIP] ... 2>&1
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $kb_ip "$KB_PATH/all_monitor.sh $KB_PATH  stop dbvip $KB_DATA_PATH $KB_VIP $DEV 2>&1" 2>&1

        check_waring_result $?
        check_flag=$?
        if [ $check_flag != 0 ];then
            echo `date +'%Y-%m-%d %H:%M:%S'` Some wrong in here, ignore now. Stop next node.
        else
            echo `date +'%Y-%m-%d %H:%M:%S'` Done...
        fi
    done
}

#check db if is alive
function checkdb()
{
    local db_num
    local db_up_finish=$1
    local primary_host=""

    for kb_ip in ${KB_ALL_IP[@]}
    do
        local is_primary=`ssh -o StrictHostKeyChecking=no -l $KB_EXECUTE_SYS_USER -T $kb_ip "cat ${KB_DATA_PATH}/recovery.conf 2>/dev/null| grep -ve \"^ *#\" | grep primary_conninfo"`
        if [ "$is_primary"x = ""x ]
        then
            if [ "$primary_host"x != ""x ]
            then
                echo "Fatal error there are two hosts in the current environment. The master ip:$primary_host and $kb_ip"
                if [ "$db_up_finish"x = ""x ]
                then
                    echo "please check the db before start it"
                    exit 1
                else
                    echo "Will stop the db and the cluster, then exit"
                    stopall
                    exit 1
                fi
            else
                primary_host=$kb_ip
            fi
        fi

        if [ "$kb_ip"x = "$KB_LOCALHOST_IP"x ]
        then
            db_num=`$KB_PATH/all_monitor.sh $KB_PATH  check db $KB_DATA_PATH`
            if [ $db_num -ne 0 -a "$db_up_finish"x = ""x ]
            then 
                echo "localhost[$KB_LOCALHOST_IP] kingbase is still alive, please stop first"
                exit 0
            elif [ $db_num -eq 0 -a "$db_up_finish"x != ""x ]
            then
                echo "localhost[$KB_LOCALHOST_IP] kingbase is not alive, please check it! (monitor log and kingbase log)"
                exit 0
            fi
            continue
        fi

        db_num=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $kb_ip "$KB_PATH/all_monitor.sh $KB_PATH  check db $KB_DATA_PATH"`
        if [ "$db_num"x = ""x ]
        then
            echo "We can't ssh $kb_ip immediately, check later.."
            continue
        fi
        if [ $db_num -ne 0 -a "$db_up_finish"x = ""x ]
        then
            echo "[$kb_ip] kingbase is still alive, please stop first"
            exit 0
        elif [ $db_num -eq 0 -a "$db_up_finish"x != ""x ]
        then
            echo "[$kb_ip] kingbase is not alive, please check it! (monitor log and kingbase log)"
            exit 0
        fi
    done

    return 1
}

#start db
function startdb()
{
    local db_num
    local primary_host=""
    local standby_count=0

    # check the trust ip on each server
    for kb_ip in ${KB_ALL_IP[@]}
    do
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $kb_ip "$KB_PATH/all_monitor.sh 3 check trustip 3 2>&1" 2>&1
        if [ $? -ne 0 ]
        then
            echo "Failed to ping trust ip on \"$kb_ip\", please check it"
            exit 1
        fi
    done

    for kb_ip in ${KB_ALL_IP[@]}
    do
        #1.stop crond all_ip
        #ssh -o StrictHostKeyChecking=no  -l $KB_POOL_EXECUTE_SYS_USER -T $kb_ip "service crond stop 2>&1"
        #2.start db
        db_num=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT  -l $KB_EXECUTE_SYS_USER -T $kb_ip "$KB_PATH/all_monitor.sh $KB_PATH start db $KB_DATA_PATH "`
        check_err_result $?
        if [ "$db_num"x = "0"x ]
        then
            echo "$kb_ip kingbase is start fail, please read log detail"
            exit 1
        fi
        #3. check if the host is other master
        local is_primary=`ssh -o StrictHostKeyChecking=no -l $KB_EXECUTE_SYS_USER -T $kb_ip "cat ${KB_DATA_PATH}/recovery.conf 2>/dev/null| grep -ve \"^ *#\" | grep primary_conninfo"`
        if [ "$is_primary"x = ""x ]
        then
            if [ "$primary_host"x != ""x ]
            then
                echo "Fatal error there are two hosts in the current environment. The master ip:$primary_host and $kb_ip"
                echo "Will stop the db started before and exit"
                stopdb
                exit 1
            else
                primary_host=$kb_ip
            fi
        fi
        #4. start crond
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $kb_ip "$KB_PATH/all_monitor.sh $KB_PATH  start dbcrond $KB_DATA_PATH $KB_EXECUTE_SYS_USER 2>&1" 2>&1
        check_err_result $?
        #5. set db vip on primary
        if [ "$primary_host"x != ""x -a "$primary_host"x = "$kb_ip"x ]
        then
            ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $kb_ip "$KB_PATH/all_monitor.sh $KB_PATH  start dbvip $KB_DATA_PATH $KB_VIP $DEV 2>&1" 2>&1
            if [ $? -ne 0 ]
            then
                echo "Failed to add vip \"$KB_VIP\" on the primary host \"$primary_host\", please check it"
                exit 1
            fi
        else
            let standby_count++
        fi
    done

    # check the vip on each server
    for kb_ip in ${KB_ALL_IP[@]}
    do
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $kb_ip "$KB_PATH/all_monitor.sh 3 check vip 3 2>&1" 2>&1
        if [ $? -ne 0 ]
        then
            echo "Failed to ping vip on \"$kb_ip\", please check it"
            exit 1
        fi
    done

    # wait standby server connect to the primary
    if [ "$force_start"x = "0"x ]
    then
        local result=""
        local failed=1
        local result_num=0
        if [ "$DATA_SIZE_DIFF"x = ""x ]
        then
            DATA_SIZE_DIFF=0
        fi
        local lsn_diff=$(($DATA_SIZE_DIFF*1024*1024))

        # check the standby count in sys_stat_replication
        for((i=0;i<10;i++))
        do
            result=`$KB_PATH/ksql "host=$primary_host port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -Aqtc "select count(*)=$standby_count from sys_stat_replication;"`
            if [ $? -eq 0 -a "$result"x = "t"x ]
            then
                failed=0
                break;
            fi
            sleep 2
        done
        if [ $failed -ne 0 -o "$result"x = "f"x ]
        then
            echo "There are no $standby_count standbys in sys_stat_replication, please check all the standby servers replica from primary"
            exit 1
        fi

        # check the standby LSN in sys_stat_replication
        result_num=`$KB_PATH/ksql "host=$primary_host port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -Aqtc "select sys_xlog_location_diff(sys_current_xlog_flush_location(), write_location)<=$lsn_diff from sys_stat_replication;" | grep -w "f" | wc -l`
        if [ $? -ne 0 -o "$result_num"x != "0"x ]
        then
            echo "The diff between the LSN of some standby server and then LSN of primary server is greater than DATA_SIZE_DIFF $DATA_SIZE_DIFF (MB)"
            echo "Some standby's data is less than primary, could not start up the whole Cluster"
            exit 1
        fi

        if [ $SYNC_FLAG -eq 1 -a "${ALL_NODE_NAME}"x != ""x ]
        then
            sync_num=`$KB_PATH/ksql -Atq "host=$primary_host port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "select * from sys_stat_replication;"| grep -w sync | wc -l`

            if [ "$sync_num"x = "0"x ]
            then
                #if there is a standby`s lsn equal master`s lsn, execute sync_async.sh to change cluster from async to sync
                echo "SYNC RECOVER MODE"
                echo "remote primary node change sync"
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
                $KB_PATH/ksql "host=$primary_host port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "alter system set $sync_standby_name;" 
                if [ $? -ne 0 ]
                then
                    echo "alter system set $sync_standby_name failed,exit"
                    exit 1;
                fi
                $KB_PATH/ksql "host=$primary_host port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "select sys_reload_conf();"
                if [ $? -ne 0 ]
                then
                    echo "reload conf file failed,exit"
                    exit 1;
                fi
                startup_start_time=`date +%s`
                while [ 1 ]
                do
                    sync_num=`$KB_PATH/ksql -Atq "host=$primary_host port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "select * from sys_stat_replication;"| grep -w sync | wc -l`
                    if [ "$sync_num"x != "0"x ]
                    then
                        break;
                    fi
                    startup_current_time=`date +%s`
                    startup_interval=$(($startup_current_time - $startup_start_time))
                    if [ $startup_interval -gt 3600 ]
                    then
                        echo "change async to sync failed,exit"
                        exit 1;
                    fi
                    sleep 1
                done
                sleep 1
                echo "SYNC RECOVER MODE DONE"
            else
                echo "now,there is a synchronous standby."
            fi
        fi
    fi
}

#start cluster
function startpool()
{
    local pool_num
    echo "wait kingbase recovery 5 sec..."
    sleep 5
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $KB_POOL_IP1 "$CLUSTER_BIN_PATH/all_monitor.sh $CLUSTER_BIN_PATH  start pool "
    check_err_result $?
    sleep 5

    pool_num=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $KB_POOL_IP1 "$KB_PATH/all_monitor.sh $CLUSTER_BIN_PATH  check pool "`
    check_err_result $?
    if [ $pool_num -eq 0 ]
    then
        echo "$KB_POOL_IP1 cluster is stop, can't up it! find error detail in log /tmp/cluster_restart.log (default , if not found, plz cat $CLUSTER_BIN_PATH/restartcluster.sh | grep POOL_RESTART= )" 2>&1
        echo "Plz wati for crontab up the [$KB_POOL_IP1] cluster"
        exit 1
    fi

    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $KB_POOL_IP2 "$CLUSTER_BIN_PATH/all_monitor.sh $CLUSTER_BIN_PATH  start pool "
    check_err_result $?
    sleep 5

    pool_num=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $KB_POOL_IP2 "$KB_PATH/all_monitor.sh $CLUSTER_BIN_PATH check pool  "`
    if [ $pool_num -eq 0 ]
    then
        echo "$KB_POOL_IP2 cluster is stop, can't up it! find error detail in log /tmp/cluster_restart.log (default , if not found, plz cat $CLUSTER_BIN_PATH/restartcluster.sh | grep POOL_RESTART= )" 2>&1
        echo "Plz wati for crontab up the [$KB_POOL_IP1] cluster"
        exit 1
    fi
}

#start db and cluster
function startall()
{
    checkpool
    checkdb
    startdb
    startpool

    echo ......................
    echo all started..
    echo ...
    echo now we check again
    checkpool finish
    checkdb finish
    usgprintsucess
}

#stop db and cluster
function stopall()
{
    stoppool
    stopdb
    echo ......................
    echo all stop..
}

# set the kingbase.conf
function setconf()
{
    checkpool finish
    checkdb finish
    local read_file="${KB_ETC_PATH}/set.conf"

    if [ ! -f $read_file ]
    then
        echo "there is no file \"$read_file\", please write it first"
        exit 1
    fi

    echo "Begin to set the kingbase.conf for the cluster ..."
    while read cfg
    do
        # del comment in cfg
        param=${cfg%%#*}
        paramName=${param%%=*}
        paramValue=${param#*=}
        if [ -z "$paramName" ] ; then
            continue
        elif [ -z "$paramValue" ]; then
            continue
        fi

        for kb_ip in ${KB_ALL_IP[@]}
        do
            ssh -n -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T $kb_ip "echo \"$cfg\" >> ${KB_ETC_PATH}/kingbase.conf" 2>&1
            if [ $? -ne 0 ]
            then
                echo "Failed to write file \"${KB_ETC_PATH}/kingbase.conf\" on \"$kb_ip\", exit"
                exit 1
            fi
            ssh -n -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T $kb_ip "echo \"$cfg\" >> ${KB_DATA_PATH}/kingbase.conf" 2>&1
            if [ $? -ne 0 ]
            then
                echo "Failed to write file \"${KB_DATA_PATH}/kingbase.conf\" on \"$kb_ip\", exit"
                exit 1
            fi
        done
    done < $read_file
    echo "End to set the kingbase.conf for the cluster ... OK"
}

# reload the database
function reload()
{
    for kb_ip in ${KB_ALL_IP[@]}
    do
        echo "Sending signale to reload the database on \"$kb_ip\""
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T $kb_ip "$KB_PATH/sys_ctl -D $KB_DATA_PATH reload" 2>&1
        if [ $? -ne 0 ]
        then
            echo "Failed to reload the database on \"$kb_ip\", exit"
            exit 1
        fi
    done
}

function change_password()
{
    checkpool finish
    checkdb finish
    CLUSTER_ETC_PATH=$CLUSTER_BIN_PATH/../etc
    if [ -f ${KB_ETC_PATH}/recovery.done ]
    then
        replica_user=`grep "^primary_conninfo" ${KB_ETC_PATH}/recovery.done | sed "s/\(.*\)\(user=[^ ']*\)\(.*$\)/\2/g" |awk -F '=' '{print $2}'`
        replica_password=`grep "^primary_conninfo" ${KB_ETC_PATH}/recovery.done | sed "s/\(.*\)\(password=[^ ']*\)\(.*$\)/\2/g" |awk -F '=' '{print $2}'`
    else
        echo "There is no recovery.done file, exit"
        exit 1
    fi

    if [ "$user"x = "$replica_user"x ]
    then
        local primary_host=""
        for kb_ip in ${KB_ALL_IP[@]}
        do
            local is_primary=`ssh -o StrictHostKeyChecking=no -l $KB_EXECUTE_SYS_USER -T $kb_ip "cat ${KB_DATA_PATH}/recovery.conf 2>/dev/null| grep -ve \"^ *#\" | grep primary_conninfo"`
            if [ "$is_primary"x = ""x ]
            then
                if [ "$primary_host"x != ""x ]
                then
                    echo "Fatal error there are two hosts in the current environment. The master ip:$primary_host and $kb_ip"
                    exit 1
                else
                    primary_host=$kb_ip
                fi
            fi
        done

        $KB_PATH/ksql "host=$primary_host port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -Aqtc "select 1111;" 2>/dev/null 1>/dev/null
        if [ $? -ne 0 ]
        then
            echo "Excute ksql failed, exit"
            exit 1
        fi

        $KB_PATH/ksql "host=$primary_host port=$KB_PORT user=$user password='$old_password' dbname=$KB_DATANAME connect_timeout=10" -Aqtc "select 1111; " 2>/dev/null 1>/dev/null
        if [ $? -ne 0 ]
        then
            echo "The old password is error, can not change password,exit"
            exit 1
        fi

        $KB_PATH/ksql "host=$primary_host port=$KB_PORT user=$KB_USER password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -Aqtc "alter user \"$user\" with password '$password'; "
        if [ $? -ne 0 ]
        then
            echo "Excute ksql to alter user password failed, exit"
            exit 1
        fi

        user_up=`echo "$user" | tr '[a-z]' '[A-Z]'`
        enp=`echo $password |base64`
        echo "Begin alter user password"
        for kb_ip in ${KB_ALL_IP[@]}
        do
            ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T $kb_ip "test -f $CLUSTER_BIN_PATH/sys_md5"
            if [ $? -eq 0 ]
            then
                user_mad5=$user:md5`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T $kb_ip "$CLUSTER_BIN_PATH/sys_md5 '${password}'${user_up}"`
                ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T $kb_ip "sed -i \"/${user}/c${user_mad5}\" ${CLUSTER_ETC_PATH}/cluster_passwd"
                if [ $? -ne 0 ]
                then
                    echo "Excute sys_md5 to change the password in cluster_passwd file failed, exit"
                    exit 1
                fi
            fi
            ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_POOL_EXECUTE_SYS_USER -T $kb_ip "test ! -f $CLUSTER_BIN_PATH/kingbasecluster || $CLUSTER_BIN_PATH/kingbasecluster -m fast stop"
            if [ $? -ne 0 ]
            then
                echo "Excute kingbasecluster restart to make cluster_passwd file take effect failed, exit"
                exit 1
            fi
            ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T $kb_ip "test ! -f ${KB_ETC_PATH}/recovery.done || (sed -i \"s/${replica_password}/${enp}/\" ${KB_ETC_PATH}/recovery.done )"
            if [ $? -ne 0 ]
            then
                echo "Excute sed command to change the password in ${KB_ETC_PATH}/recovery.done file failed, exit"
                exit 1
            fi
            ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T $kb_ip "test ! -f ${KB_DATA_PATH}/recovery.done || (sed -i \"s/${replica_password}/${enp}/\" ${KB_DATA_PATH}/recovery.done ) "
            if [ $? -ne 0 ]
            then
                echo "Excute sed command to change the password in ${KB_DATA_PATH}/recovery.done file failed, exit"
                exit 1
            fi
            ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$CONNECTTIMEOUT -l $KB_EXECUTE_SYS_USER -T $kb_ip "test ! -f ${KB_DATA_PATH}/recovery.conf || (sed -i \"s/${replica_password}/${enp}/\" ${KB_DATA_PATH}/recovery.conf )"
            if [ $? -ne 0 ]
            then
                echo "Excute sed command to change the password in ${KB_DATA_PATH}/recovery.conf file failed, exit"
                exit 1
            fi
        done
        echo "Alter user password OK"
    else
        echo "User $user is not a user used by cluster,please use sql: alter user to change the user password."
        exit 0
    fi
}

if [ "$1"x = "start"x ]
then
    if [ $# -eq 2 ]
    then
        if [ "$2"x = "--force"x ]
        then
            force_start=1
        fi
    fi
    startall
elif [ "$1"x = "stop"x ]
then
    stopall
elif [ "$1"x = "restart"x ]
then
    stopall
    startall
elif [ "$1"x = "set"x ]
then
    setconf
    if [ $# -eq 2 -a "$2"x = "--restart"x ]
    then
        stopall
        startall
    else
        reload
        echo "Some changes may not take effect by RELOAD, you can execute \"$0 restart\" to restart the cluster"
    fi
elif [ "$1"x = "change_password"x ]
then
    user=$2
    old_password=$3
    password=$4
    if [ "$user"x = ""x -o "$old_password"x = ""x -o "$password"x = ""x ]
    then
        echo "No user or old_password or new_password entered"
        exit 1
    fi
    change_password
else
    usage
fi

#!/bin/bash

function check_prm()
{
    prm=$1
    name=$2
    if [ "$prm"x = ""x ]
    then
        echo "`data`[ERROR] Parameter $name is empty,exit with error."
        exit 66
    fi
}

DB_BIN_PATH=$1
DB_BIN=`echo ${DB_BIN_PATH%*/}`
check_prm "$DB_BIN" DB_BIN
data_path=$(dirname "$DB_BIN")/data

#user_name Common OS users used for deploying clusters
user_name=$2
check_prm "$user_name" user_name
#db_port Port used by the DB instance
db_port=$3
check_prm "$db_port" db_port
#vip Virtual IP used by the db
db_vip=$4
check_prm "$db_vip" db_vip
#vip Virtual IP used by the kingbasecluster
cluster_vip=$5
check_prm "$cluster_vip" cluster_vip
#cmp_ip The path of the ip command
cmp_i=$6
cmp_ip=`echo ${cmp_i%*/}`
check_prm "$cmp_ip" cmp_ip
#cmp_arping The path of the arping command
cmp_arp=$7
cmp_arping=`echo ${cmp_arp%*/}`
check_prm "$cmp_arping" cmp_arping
#cmp_ping The path of the ping command
cmp_p=$8
cmp_ping=`echo ${cmp_p%*/}`
check_prm "$cmp_ping" cmp_ping

function check_system()
{
    file_num=`su - $user_name -c "ulimit -n 2>/dev/null"`
    if [ "$file_num"x = ""x ]
    then
        echo "[`date`] [ERROR] [ulimit.open files] is null (no less than: 65535)"
    elif [ $file_num -lt 65535 ]
    then
        echo "[`date`] [ERROR] [ulimit.open files] $file_num (no less than: 65535)"
    else
        echo "[`date`] [INFO] [ulimit.open files] $file_num"
    fi

    proc_num=`su - $user_name -c "ulimit -u 2>/dev/null"`
    if [ "$proc_num"x = ""x ]
    then
        echo "[`date`] [ERROR] [ulimit.open proc] is null (no less than: 65535)"
    elif [ $proc_num -lt 65535 ]
    then
        echo "[`date`] [ERROR] [ulimit.open proc] $proc_num (no less than: 65535)"
    else
        echo "[`date`] [INFO] [ulimit.open proc] $proc_num"
    fi

    kernel_sem_value1=`sysctl kernel.sem 2>/dev/null |awk -F '=' '{print $2}'|awk '{print $1}'`
    kernel_sem_value2=`sysctl kernel.sem 2>/dev/null |awk -F '=' '{print $2}'|awk '{print $2}'`
    kernel_sem_value3=`sysctl kernel.sem 2>/dev/null |awk -F '=' '{print $2}'|awk '{print $3}'`
    kernel_sem_value4=`sysctl kernel.sem 2>/dev/null |awk -F '=' '{print $2}'|awk '{print $4}'`
    if [ "$kernel_sem_value1"x = ""x -o "$kernel_sem_value1"x = ""x  -o "$kernel_sem_value1"x = ""x -o "$kernel_sem_value1"x = ""x ]
    then
        echo "[`date`] [ERROR] [kernel.sem] is null (no less than: 5010 641280 5010 256)"
    elif [ $kernel_sem_value1 -lt 5010 -o $kernel_sem_value2 -lt 641280 -o $kernel_sem_value3 -lt 5010 -o $kernel_sem_value4 -lt 256 ]
    then
        echo "[`date`] [ERROR] [kernel.sem] $kernel_sem_value1 $kernel_sem_value2 $kernel_sem_value3 $kernel_sem_value4 (no less than: 5010 641280 5010 256)"
    else
        echo "[`date`] [INFO] [kernel.sem] $kernel_sem_value1 $kernel_sem_value2 $kernel_sem_value3 $kernel_sem_value4"
    fi

    RemoveIPC1=`loginctl show-user 2>/dev/null |grep RemoveIPC |awk -F '=' '{print $2}'`
    if [ "$RemoveIPC1"x = "no"x  ]
    then
        echo "[`date`] [INFO] [RemoveIPC] $RemoveIPC1"
    elif [ "$RemoveIPC1"x = "yes"x ]
    then
        echo "[`date`] [ERROR] [RemoveIPC] $RemoveIPC1 (should be: no)"
    else
        RemoveIPC=`cat  /etc/systemd/logind.conf 2>/dev/null |grep ^RemoveIPC |tail -n 1`
        RemoveIPC_values=`echo $RemoveIPC | awk -F '=' '{print $2}'`
        RemoveIPC_v=${RemoveIPC_values,,}
        if [ "$RemoveIPC_v"x = "no"x ]
        then
            echo "[`date`] [INFO] [RemoveIPC] $RemoveIPC_v"
        elif [ "$RemoveIPC_v"x = ""x ]
        then
            echo "[`date`] [WARNING] [RemoveIPC] is null"
        else
            echo "[`date`] [ERROR] [RemoveIPC] $RemoveIPC_v (should be: no)"
        fi
    fi

    DefaultTasksAccounting=`systemctl show 2>/dev/null | grep DefaultTasksAccounting`
    DefaultTasksAccounting_values=`echo $DefaultTasksAccounting | awk -F '=' '{print $2}'`
    DefaultTasksAccounting_v=${DefaultTasksAccounting_values,,}

    if [ "$DefaultTasksAccounting_v"x = "no"x ]
    then
        echo "[`date`] [INFO] [DefaultTasksAccounting] $DefaultTasksAccounting_v"
    elif [ "$DefaultTasksAccounting_v"x = ""x ]
    then    
        echo "[`date`] [WARNING] [DefaultTasksAccounting] is null "
    else
        DefaultTasksMax=`systemctl show 2>/dev/null | grep DefaultTasksMax`
        DefaultTasksMax_values=`echo $DefaultTasksMax | awk -F '=' '{print $2}'`
        if [ $DefaultTasksMax_values -lt 65535 ]
        then
            echo "[`date`] [ERROR] [DefaultTasksMax] $DefaultTasksMax_values (no less than: 65535)"
        else
            echo "[`date`] [INFO] [DefaultTasksMax] $DefaultTasksMax_values "
        fi
    fi

    cron_path=`which crond 2>/dev/null`
    if [ "$cron_path"x = ""x ]
    then
        cron_path=`which cron 2>/dev/null`
        if [ "$cron_path"x = ""x ]
        then
            echo "[`date`] [ERROR] [crond service] does not exist"
        else
            cron_name=cron
        fi
    else
        cron_name=crond
    fi

    limit=`systemctl  status $cron_name 2>/dev/null|grep  "limit"`
    if [ "$limit"x != ""x ]
    then
        tasks=`systemctl  status $cron_name 2>/dev/null|grep "Tasks" |awk '{print $4}'|awk -F ')' '{print $1}'`
        if [ "$tasks"x = ""x ]
        then
            echo "[`date`] [INFO] [systemd limit] is null (no less than: 65535)"
        elif [ $tasks -lt 65535 ]
        then
            echo "[`date`] [ERROR] [systemd limit] $tasks (no less than: 65535)"
        else
            echo "[`date`] [INFO] [systemd limit] $tasks"
        fi
    fi

    SELINUX=`getenforce 2>/dev/null`
    SELINUX_values=${SELINUX,,}

    if [ "$SELINUX_values"x = "disabled"x ]
    then
        echo "[`date`] [INFO] [SELINUX] $SELINUX_values"
    elif [ "$SELINUX_values"x = ""x ]
    then
        echo "[`date`] [WARNING] [SELINUX] is null"
    else
        echo "[`date`] [ERROR] [SELINUX] $SELINUX_values (should be: disabled)"
    fi

    service iptables status 1>/dev/null 2>&1
    iptables_flag=$?

    service firewalld status 1>/dev/null 2>&1
    firewalld_flag=$?

    service ufw status 1>/dev/null 2>&1 
    ufw_flag=$?

    if [ "$iptables_flag"x = "0"x -o "$firewalld_flag"x = "0"x -o "$ufw_flag"x = "0"x ]
    then
        echo "[`date`] [WARNING] [firewall] up (should be: down or add port rules)"
    else
        echo "[`date`] [INFO] [firewall] down"
    fi

    GSSAPIAuthentication=`sshd -T 2>/dev/null|grep -i GSSAPIAuthentication`
    GSSAPIAuthentication_values=`echo $GSSAPIAuthentication |awk '{print $2}'`
    GSSAPIAuthentication_v=${GSSAPIAuthentication_values,,}
    if [ "$GSSAPIAuthentication_v"x = "no"x ]
    then
        echo "[`date`] [INFO] [GSSAPIAuthentication] $GSSAPIAuthentication_v"
    elif [ "$GSSAPIAuthentication_v"x = ""x ]
    then
        echo "[`date`] [WARNING] [GSSAPIAuthentication] is null"
    else
        echo "[`date`] [WARNING] [GSSAPIAuthentication] $GSSAPIAuthentication_v (should be: no)"
    fi

    UseDNS=`sshd -T  2>/dev/null|grep -i UseDNS`
    UseDNS_values=`echo $UseDNS |awk '{print $2}'`
    UseDNS_v=${UseDNS_values,,}
    if [ "$UseDNS_v"x = "no"x ]
    then
        echo "[`date`] [INFO] [UseDNS] $UseDNS_v "
    elif [ "$UseDNS_v"x = ""x ]
    then
        echo "[`date`] [WARNING] [UseDNS] is null"
    else
        echo "[`date`] [WARNING] [UseDNS] $UseDNS_v (should be: no)"
    fi

    port_exist=`netstat -an | grep -w $db_port |grep -w "LISTEN" |wc -l`
    if [ "$port_exist"x != "0"x ]
    then
        echo "[`date`] [ERROR] [$db_port] already occupied"
    else
        echo "[`date`] [INFO] [$db_port] OK"
    fi

    if [ -e $data_path ]
    then
        echo "[`date`] [ERROR] [Data directory] already exists"
    else
        echo "[`date`] [INFO] [Data directory] OK"
    fi

    mem=`cat /proc/meminfo |grep -w "MemFree" |awk '{print $2}'`
    if [ "$mem"x = ""x ]
    then
        echo "[`date`] [WARNING] [The memory] is null (no less than 1G)"
    elif [ $mem -lt 1048576 ]
    then
        echo "[`date`] [WARNING] [The memory] $mem kb (no less than 1G)"
    else
        echo "[`date`] [INFO] [The memory] OK"
    fi

    hard_disk=`df /home/$user_name -P 2>/dev/null |head -n 2| tail -n +2|awk '{print $4}'`
    if [ "$hard_disk"x = ""x ]
    then
        echo "[`date`] [ERROR] [The hard disk] is null (no less than 1G)"
    elif [ $hard_disk -lt 1048576 ]
    then
        echo "[`date`] [ERROR] [The hard disk] $hard_disk (no less than 1G)"
    else
        echo "[`date`] [INFO] [The hard disk] OK"
    fi

    ifconfig_exist=`which ifconfig 2>/dev/null|wc -l`
    if [ "$ifconfig_exist"x = ""x ]
    then
        echo "[`date`] [ERROR] [ifconfig command] is null"
    elif [ $ifconfig_exist -eq 0 ]
    then
        echo "[`date`] [ERROR] [ifconfig command] does not exist"
    else
        echo "[`date`] [INFO] [ifconfig command] OK"
    fi

    ping_c=`ls $cmp_ping/ping 2>/dev/null`
    ping_exist=$?
    if [ "$ping_exist"x != "0"x ]
    then
        echo "[`date`] [ERROR] [ping command path] $cmp_ping incorrect"
    else
        echo "[`date`] [INFO] [ping command path] OK"
    fi

    ip_c=`ls $cmp_ip/ip 2>/dev/null`
    ip_exist=$?
    if [ "$ip_exist"x != "0"x ]
    then
        echo "[`date`] [ERROR] [ip command path] $cmp_ip incorrect"
    else
        echo "[`date`] [INFO] [ip command path] OK"
    fi

    arping_c=`ls $cmp_arping/arping 2>/dev/null`
    arping_exist=$?
    if [ "$arping_exist"x != "0"x ]
    then
        echo "[`date`] [ERROR] [arping command path] $cmp_arping incorrect"
    else
        echo "[`date`] [INFO] [arping command path] OK"
    fi

    dev=`ls /sys/class/net|head -n 1`
    if [ "$dev"x = "lo"x ]
    then
        dev=`ls /sys/class/net|head -n 2| tail -n +2`
    fi
    arping_U=`arping --help 2>&1 |grep -wF -e "-U" |wc -l`
    if [ "$arping_U"x = "0"x ]
    then
        echo "[`date`] [ERROR] [arping -U command] incorrect"
    else
        echo "[`date`] [INFO] [arping -U command] OK"
    fi

    regex="\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\b"
    ckip=`echo $db_vip | egrep $regex | wc -l`
    if [ $ckip -eq 0 ]
    then
        echo "[`date`] [ERROR] [Virtual IP] $db_vip (should be: IP)"
    else
        vip_ping=`ping $db_vip -c 3 2>/dev/null |grep -w "received" |awk '{print $4}'`
        if [ "$vip_ping"x != "0"x ]
        then
            echo "[`date`] [ERROR] [Virtual IP] $db_vip already exists"
        else
            echo "[`date`] [INFO] [Virtual IP] $db_vip OK" 
        fi
    fi
    regex="\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\b"
    ckip=`echo $cluster_vip | egrep $regex | wc -l`
    if [ $ckip -eq 0 ]
    then
        echo "[`date`] [ERROR] [Virtual IP] $cluster_vip (should be: IP)"
    else
        vip_ping=`ping $cluster_vip -c 3 2>/dev/null |grep -w "received" |awk '{print $4}'`
        if [ "$vip_ping"x != "0"x ]
        then
            echo "[`date`] [ERROR] [Virtual IP] $cluster_vip already exists"
        else
            echo "[`date`] [INFO] [Virtual IP] $cluster_vip OK" 
        fi
    fi
}

check_system
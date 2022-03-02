#!/bin/sh

shell_folder=$(dirname $(readlink -f "$0"))
program_name=$(readlink -f "$0")

## normal configuration
on_bmj=0
cluster_path=""
all_node_ip=""
cluster_package=""
db_package=""
license_path="${shell_folder}"
license_file=()
trust_ip=""
cluster_vip=""
db_vip=""
net_device=()

cluster_user=""
super_user=""

install_conf=""

## db configuration
db_user=""
db_password=""
db_port=""

kb_data=""

## cluster configuration
wd_deadtime=""
check_retries=""
check_delay=""
connect_timeout=""

ipaddr_path=""
arping_path=""

case_sensitive=""
auto_primary_recovery=""

## the parameters do not need to be configured
crond_file="/etc/cron.d/KINGBASECRON"
usersetip=$*

kb_bin=""
kb_etc=""
kb_lib=""
kb_archive=""
cluster_etc=""
cluster_bin=""
cluster_lib=""
log_path=""
log_file=""

primary_host=""

# *************************************************
# *              General function                 *
# *************************************************

function check_and_get_user()
{
    [ "${cluster_user}"x = ""x ] && cluster_user="kingbase"
    [ "${super_user}"x = ""x ] && super_user="root"
    [ $on_bmj -eq 1 ] && cluster_user=${super_user}
}

function test_ssh()
{
    local host=$1

    execute_command ${super_user} $host "/bin/true 2>/dev/null"
    if [ $? -eq 0 ]
    then
        return 0
    fi

    execute_command ${super_user} $host "/usr/bin/true 2>/dev/null"
    if [ $? -eq 0 ]
    then
        return 0
    fi

    return 1
}

function execute_command()
{
    local user=$1
    local host=$2
    local command=$3

    if [ $on_bmj -eq 0 ]
    then
        ssh -o StrictHostKeyChecking=no -l ${user} -T $host  "${command}"
        [ $? -ne 0 ] && return 1
    else
        $kb_bin/es_client -h $host -p 8890 -U kingbase -W 123456 -o "${command}"
        [ $? -ne 0 ] && return 1
    fi

    return 0
}

# *************************************************
# *         read configuration file               *
# *************************************************

function read_conf()
{
    [ "${install_conf}"x = ""x ] && install_conf="${shell_folder}/install.conf"

    [ ! -e $install_conf ] && echo "[ERROR] $install_conf is not exits" && exit 1
    if [ -f $install_conf ]
    then
        source $install_conf
    fi

    [ "${on_bmj}"x = ""x ] && on_bmj=0
    [ $on_bmj -eq 1 ] && cluster_path="/opt/Kingbase/ES/V8"
    [ $on_bmj -eq 1 ] && license_path=(${cluster_path}/license.dat)

    if [ "${usersetip}"x != ""x ]
    then
        all_node_ip=(${usersetip})
    fi

    node_num=${#all_node_ip[@]}

    if [ "${kb_data}"x = ""x ]
    then
        [ $on_bmj -eq 1 ] && kb_data="$cluster_path/data"
        [ $on_bmj -eq 0 ] && kb_data="$cluster_path/db/data"
    fi

    if [ $on_bmj -eq 1 ]
    then
        kb_bin="$cluster_path/Server/bin"
        kb_etc="$cluster_path/Server/etc"
        kb_lib="$cluster_path/Server/lib"
        cluster_etc="$cluster_path/Cluster/etc"
        cluster_bin="$cluster_path/Cluster/bin"
        cluster_lib="$cluster_path/Cluster/lib"
    else
        kb_bin="$cluster_path/db/bin"
        kb_etc="$cluster_path/db/etc"
        kb_lib="$cluster_path/db/lib"
        cluster_etc="$cluster_path/kingbasecluster/etc"
        cluster_bin="$cluster_path/kingbasecluster/bin"
        cluster_lib="$cluster_path/kingbasecluster/lib"
    fi
    kb_archive="$cluster_path/archivedir"
    log_path="$cluster_path/log"

    return 0
}

# *************************************************
# *     check configuration file parameter        *
# *************************************************

function pre_exe()
{
    read_conf
    [ $? -ne 0 ] && exit 1

    check_and_get_user

    if [ $on_bmj -eq 0 ]
    then
        [ $UID == 0 ] && echo "[ERROR] you cannot use root user to execute this script in general machine." && exit 1
    else
        [ $UID != 0 ] && echo "[ERROR] you must use root user to execute this script in BMJ." && exit 1
    fi

    [ "${db_port}"x = ""x ] && db_port="54321"
    [ "${wd_deadtime}"x = ""x ]  && wd_deadtime="30"
    [ "${check_retries}"x = ""x ] && check_retries="6"
    [ "${check_delay}"x = ""x ] && check_delay="10"
    [ "${connect_timeout}"x = ""x ] && connect_timeout="10000"
    [ "${arping_path}"x = ""x ] && arping_path="${kb_bin}"
    [ "${auto_primary_recovery}"x = ""x ] && auto_primary_recovery="0"

    [ "${log_file}"x = ""x ] && log_file="${cluster_path}/kingbase.log"

    if [ "${all_node_ip}"x = ""x ]
    then
        echo "[ERROR] param [all_node_ip] is not set in config file \"${install_conf}\" or in myself shell script"
        exit 1
    fi

    if [ "${cluster_path}"x = ""x ]
    then
        echo "[ERROR] param [cluster_path] is not set in config file \"${install_conf}\" or in myself shell script"
        exit 1
    fi

    name_db_zip=`echo $db_package |grep -e "zip$" |wc -l`
    name_db_tar=`echo $db_package |grep -e "tar$" |wc -l`
    name_db_gz=`echo $db_package |grep -e "tar.gz$" |wc -l`

    name_cluster_zip=`echo $cluster_package |grep -e "zip$" |wc -l`
    name_cluster_tar=`echo $cluster_package |grep -e "tar$" |wc -l`
    name_cluster_gz=`echo $cluster_package |grep -e "tar.gz$" |wc -l`

    if [ "${db_package}"x = ""x ]
    then
        if [ $on_bmj -eq 1 ]
        then
            echo "[CONFIG_CHECK] BMJ does not require to set param [zip_package] .... ok"
        else
            echo "[ERROR] param [zip_package] is not set in config file \"${install_conf}\" or in myself shell script"
            exit 1
        fi
    else
        if [ $name_db_zip -eq 1 -o $name_db_tar -eq 1 -o $name_db_gz -eq 1 ]
        then
            echo "[CONFIG_CHECK] file format is correct ... OK"
        else
            echo "[ERROR] only \".zip\" \".tar\" and \".tar.gz\" could be supported."
            exit 1
        fi
    fi

    if [ "${cluster_package}"x = ""x ]
    then
        if [ $on_bmj -eq 1 ]
        then
            echo "[CONFIG_CHECK] BMJ does not require to set param [cluster_pakcage] .... ok"
        else
            echo "[ERROR] param [cluster_pakcage] is not set in config file \"${install_conf}\" or in myself shell script"
            exit 1
        fi
    else
        if [ $name_cluster_zip -eq 1 -o $name_cluster_tar -eq 1 -o $name_cluster_gz -eq 1 ]
        then
            echo "[CONFIG_CHECK] file format is correct ... OK"
        else
            echo "[ERROR] only \".zip\" \".tar\" and \".tar.gz\" could be supported."
            exit 1
        fi
    fi

    if [ $on_bmj -eq 0 ]
    then
        if [ ${kb_data} != "$cluster_path/db/data" ]
        then
            if [ ! -d `dirname ${kb_data}` ]
            then
                echo "[ERROR] the path: `dirname ${kb_data}` does not exit."
                exit 1
            else
                [ ! -w `dirname ${kb_data}` -a ! -r `dirname ${kb_data}` ] && echo "[ERROR] you have no permission for `dirname ${kb_data}`" && exit 1
            fi
        fi
    else
        if [ ${kb_data} != "$cluster_path/data" ]
        then
            if [ ! -d `dirname ${kb_data}` ]
            then
                echo "[ERROR] the path: `dirname ${kb_data}` does not exit."
                exit 1
            else
                [ ! -w `dirname ${kb_data}` -a ! -r `dirname ${kb_data}` ] && echo "[ERROR] you have no permission for `dirname ${kb_data}`" && exit 1
            fi
        fi
    fi

    if [ "${trust_ip}"x = ""x ]
    then
        echo "[ERROR] param [trust_ip] is not set in config file \"${install_conf}\" or in myself shell script"
        exit 1
    fi

    if [ "${db_user}"x = ""x ]
    then
        echo "[ERROR] the value of \"db_user\" can not be NULL, please set it install.conf or in myself shell script"
        exit 1
    fi

    if [ "${db_password}"x = ""x ]
    then
        echo "[ERROR] the value of \"db_password\" can not be NULL, please set it install.conf or in myself shell script"
        exit 1
    fi

    if [ "${db_port}"x = ""x ]
    then
        echo "[ERROR] the value of \"db_port\" can not be NULL, please set it install.conf or in myself shell script"
        exit 1
    fi

    if [ "${cluster_vip}"x != ""x ]
    then
        mask=`echo ${cluster_vip} |awk -F '/' '{print $2}'`
        if [ "$mask"x = ""x ]
        then
            cluster_vip="${cluster_vip}/24"
        elif [ $mask -ge 0 -a $mask -le 32 ]
        then
            echo "[CONFIG_CHECK] cluster_vip is right"
        else
            echo "[ERROR] the value of subnet mask for cluster_vip should be between 0 and 32"
            exit 1
        fi
        clustervip=${cluster_vip%/*}
        [ "${ipaddr_path}"x = ""x ] && ipaddr_path="/sbin"
        [ "${arping_path}"x = ""x ] && arping_path="${kb_bin}"

        if [ ! -f "${ipaddr_path}/ip" ]
        then
            echo "[ERROR] the dir \"${ipaddr_path}\" has no execute file \"ip\", please set [ipaddr_path] in install.conf or in myself shell script"
            exit 1
        fi
        if [ "${net_device}"x = ""x ]
        then
            echo "[ERROR] \"net_device\" is NULL, please set it in install.conf or in myself shell script"
            exit 1
        fi

        echo "[INFO]-Check if the cluster_vip \"${clustervip}\" is already exist ..."
        local is_vip_exist=`ping ${clustervip} -c 3 -w 3 | grep received | awk '{print $4}'`
        if [ $? -ne 0 ] || [ $is_vip_exist -gt 0 ]
        then
            echo "[ERROR] `date +'%Y-%m-%d %H:%M:%S'` The virtual ip [${clustervip}] has already exists, exit."
            exit 1
        fi
        echo "[INFO] There is no \"${clustervip}\" on any host, OK"
    else
        echo "[ERROR] the cluster_vip can not be NULL, please set it install.conf or in myself shell script"
        exit 1
    fi

    if [ "${db_vip}"x != ""x ]
    then
        mask=`echo ${db_vip} |awk -F '/' '{print $2}'`
        if [ "$mask"x = ""x ]
        then
            db_vip="${db_vip}/24"
        elif [ $mask -ge 0 -a $mask -le 32 ]
        then
            echo "[CONFIG_CHECK] db_vip is right"
        else
            echo "[ERROR] the value of subnet mask for db_vip should be between 0 and 32"
            exit 1
        fi
        dbvip=${db_vip%/*}

        echo "[INFO]-Check if the db_vip \"${dbvip}\" is already exist ..."
        local is_vip_exist=`ping ${dbvip} -c 3 -w 3 | grep received | awk '{print $4}'`
        if [ $? -ne 0 ] || [ $is_vip_exist -gt 0 ]
        then
            echo "[ERROR] The db_vip [${dbvip}] has already exists, exit."
            exit 1
        fi
        echo "[INFO] There is no \"${dbvip}\" on any host, OK"

        net_num=${#net_device[@]}
        if [ $net_num -eq ${#all_node_ip[@]} -o $net_num -eq 1 ]
        then
            echo "[CONFIG_CHECK] the number of net_device matches the length of all_node_ip or the number of net_device is 1 ... OK"
        else
            echo "[ERROR] the number of net_device is inconsistent with the number of all_node_ip or the number of net_device is not 1, please check your install.conf file, exit."
            exit 1
        fi
    else
        echo "[ERROR] the db_vip can not be NULL, please set it install.conf or in myself shell script"
        exit 1
    fi

    if [ $on_bmj -eq 0 ]
    then
        license_num=${#license_file[@]}
        if [ $license_num -eq ${#all_node_ip[@]} -o $license_num -eq 1 ]
        then
            echo "[CONFIG_CHECK] the number of license_file matches the length of all_node_ip or the number of license_file is 1 ... OK"
        else
            echo "[ERROR] the number of license_file is inconsistent with the number of all_node_ip or the number of license_file is not 1, please check your install.conf file, exit."
            exit 1
        fi
    fi

    if test ! -f ${cluster_pakcage}
    then
        if [ $on_bmj -eq 1 ]
        then
            echo "[INFO] BMJ does not require to set param [cluster_pakcage] .... ok"
        else
            echo "[ERROR] Check the zip file \"${cluster_pakcage}\" is not exist"
            exit 1
        fi
    fi
    if test ! -f ${db_package}
    then
        if [ $on_bmj -eq 1 ]
        then
            echo "[INFO] BMJ does not require to set param [db_package] .... ok"
        else
            echo "[ERROR] Check the zip file \"${db_package}\" is not exist"
            exit 1
        fi
    fi
}


# *************************************************
# *         change system configuration           *
# *************************************************
function change_system()
{
    for ip in ${all_node_ip[@]}
    do
        echo "[`date`] [INFO] change ulimit on $ip ..."
        execute_command ${super_user} ${ip} "grep '* soft nofile 655360' /etc/security/limits.conf 1>/dev/null"
        if [ $? -ne 0 ]
        then
            execute_command ${super_user} ${ip} "echo \"
            * soft nofile 655360
            root soft nofile 655360
            * hard nofile 655360
            root hard nofile 655360
            * soft nproc 655360
            root soft nproc 655360
            * hard nproc 655360
            root hard nproc 655360
            * soft core unlimited
            root soft core unlimited
            * hard core unlimited
            root hard core unlimited
            * soft memlock 50000000
            root soft memlock 50000000
            * hard memlock 50000000
            root hard memlock 50000000\" >> /etc/security/limits.conf"
        fi
        execute_command ${super_user} ${ip} "rm -rf /etc/security/limits.d/*"
        echo "[`date`] [INFO] change ulimit on $ip ... Done"

        echo "[`date`] [INFO] change kernel.sem on $ip ..."
        execute_command ${super_user} ${ip} "grep 'kernel.sem= 5010 641280 5010 256' /etc/sysctl.conf 1>/dev/null"
        if [ $? -ne 0 ]
        then
            execute_command ${super_user} ${ip} "echo \"
            kernel.sem= 5010 641280 5010 256
            fs.file-max=7672460
            fs.aio-max-nr=1048576
            net.core.rmem_default=262144
            net.core.rmem_max=4194304
            net.core.wmem_default=262144
            net.core.wmem_max=4194304
            net.ipv4.ip_local_port_range=9000 65500
            net.ipv4.tcp_wmem=8192 65536 16777216
            net.ipv4.tcp_rmem=8192 87380 16777216
            vm.min_free_kbytes=512000
            vm.vfs_cache_pressure=200
            vm.swappiness=20
            net.ipv4.tcp_max_syn_backlog=4096
            net.core.somaxconn=4096\" >> /etc/sysctl.conf"
        fi
        echo "[`date`] [INFO] change kernel.sem on $ip ... Done"

        if [ $on_bmj -eq 0 ]
        then
            echo "[`date`] [INFO] stop selinuxi on $ip ..."
            execute_command ${super_user} ${ip} "setenforce 0 > /dev/null 2>&1"
            execute_command ${super_user} ${ip} "grep 'SELINUX=disabled' /etc/selinux/config 1>/dev/null"
            if [ $? -ne 0 ]
            then
                execute_command ${super_user} ${ip} "sed -i \"s/^SELINUX[ ]*=/#SELINUX=/g\" /etc/selinux/config"
                execute_command ${super_user} ${ip} "echo \"SELINUX=disabled\" >> /etc/selinux/config"
            fi
            echo "[`date`] [INFO] stop selinux on $ip ... Done"

            echo "[`date`] [INFO] change RemoveIPC on $ip ..."
            execute_command ${super_user} ${ip} "grep 'RemoveIPC=no' /etc/systemd/logind.conf 1>/dev/null"
            if [ $? -ne 0 ]
            then
                execute_command ${super_user} ${ip} "sed -i \"s/^RemoveIPC[ ]*=/#RemoveIPC=/g\" /etc/systemd/logind.conf"
                execute_command ${super_user} ${ip} "echo \"RemoveIPC=no\" >>  /etc/systemd/logind.conf"
            fi
            echo "[`date`] [INFO] change RemoveIPC on $ip ... Done"

            echo "[`date`] [INFO] change DefaultTasksAccounting on $ip ..."
            execute_command ${super_user} ${ip} "grep 'DefaultTasksAccounting=no' /etc/systemd/system.conf 1>/dev/null"
            if [ $? -ne 0 ]
            then
                execute_command ${super_user} ${ip} "sed -i \"s/^DefaultTasksAccounting[ ]*=/#DefaultTasksAccounting=/g\" /etc/systemd/system.conf"
                execute_command ${super_user} ${ip} "echo \"DefaultTasksAccounting=no\" >> /etc/systemd/system.conf"
            fi
            echo "[`date`] [INFO] change DefaultTasksAccounting on $ip ... Done"

            echo "[`date`] [INFO] change sshd_config on $ip ..."
            execute_command ${super_user} ${ip} "grep 'GSSAPIAuthentication no' /etc/ssh/sshd_config 1>/dev/null"
            if [ $? -ne 0 ]
            then
                execute_command ${super_user} ${ip} "sed -i \"s/^GSSAPIAuthentication[ ]* /#GSSAPIAuthentication /g\" /etc/ssh/sshd_config"
                execute_command ${super_user} ${ip} "echo \"GSSAPIAuthentication no\" >>  /etc/ssh/sshd_config"
            fi
            execute_command ${super_user} ${ip} "grep 'UsePAM yes' /etc/ssh/sshd_config 1>/dev/null"
            if [ $? -ne 0 ]
            then
                execute_command ${super_user} ${ip} "sed -i \"s/^UseDNS[ ]* /#UseDNS /g\" /etc/ssh/sshd_config"
                execute_command ${super_user} ${ip} "echo \"UsePAM yes\" >>  /etc/ssh/sshd_config"
            fi
            echo "[`date`] [INFO] change sshd_config on $ip ... Done"
        else
            echo "[`date`] [INFO] change RemoveIPC on $ip ..."
            execute_command ${super_user} ${ip} "grep 'RemoveIPC=no' /etc/systemd/logind.conf 1>/dev/null"
            if [ $? -ne 0 ]
            then
                execute_command ${super_user} ${ip} "sed \"s/^RemoveIPC[ ]*=/#RemoveIPC=/g\" /etc/systemd/logind.conf > /etc/systemd/config_temp"
                execute_command ${super_user} ${ip} "cat /etc/systemd/config_temp > /etc/systemd/logind.conf"
                execute_command ${super_user} ${ip} "rm -f /etc/systemd/config_temp"
                execute_command ${super_user} ${ip} "echo \"RemoveIPC=no\" >>  /etc/systemd/logind.conf"
            fi
            echo "[`date`] [INFO] change RemoveIPC on $ip ... Done"

            echo "[`date`] [INFO] change DefaultTasksAccounting on $ip ..."
            execute_command ${super_user} ${ip} "grep 'DefaultTasksAccounting=no' /etc/systemd/system.conf 1>/dev/null"
            if [ $? -ne 0 ]
            then
                execute_command ${super_user} ${ip} "sed \"s/^DefaultTasksAccounting[ ]*=/#DefaultTasksAccounting=/g\" /etc/systemd/system.conf > /etc/systemd/config_temp"
                execute_command ${super_user} ${ip} "cat /etc/systemd/config_temp > /etc/systemd/system.conf"
                execute_command ${super_user} ${ip} "rm -f /etc/systemd/config_temp"
                execute_command ${super_user} ${ip} "echo \"DefaultTasksAccounting=no\" >> /etc/systemd/system.conf"
            fi
            echo "[`date`] [INFO] change DefaultTasksAccounting on $ip ... Done"
        fi

        echo "[`date`] [INFO] configuration to take effect on $ip ..."
        execute_command ${super_user} ${ip} "sysctl -p > /dev/null"
        if [ $on_bmj -eq 0 ]
        then
            execute_command ${super_user} ${ip} "systemctl daemon-reload 1>/dev/null 2>&1"
            execute_command ${super_user} ${ip} "systemctl restart sshd 1>/dev/null 2>&1"
            execute_command ${super_user} ${ip} "service sshd restart 1>/dev/null 2>&1"
        fi
        echo "[`date`] [INFO] configuration to take effect on $ip ... Done"
    done
}


# *************************************************
# *       change the configuration file           *
# *************************************************

function alter_HAmodule()
{
    for ((i=1;i<=$node_num;i++))
    do
        [ $i -eq 1 ] && all_node_name="(node1"
        [ $i -ne 1 ] && all_node_name="$all_node_name node$i"
    done
    all_node_name="$all_node_name)"

    local i=1
    local index=0
    for ip in ${all_node_ip[@]}
    do
        echo "[INSTALL] Alter ${kb_etc}/HAmodule.conf on $ip"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"KB_POOL_PCP_PORT=\\\"9898\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#vip is bound to the specified network card.example:DEV=\"ens33\"' > ${kb_etc}/HAmodule.conf"
        if [ $net_num -eq 1 ]
        then
            current_dev=${net_device}
        else
            current_dev=${net_device[$index]}
        fi
        execute_command ${cluster_user} ${ip} "echo -e \"DEV=\\\"${current_dev}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#the path of the ip instruction in the system.example:CMD_IP_PATH=\"/usr/sbin\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"CMD_IP_PATH=\\\"${ipaddr_path}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#the path of the arping instruction in the system.example:CMD_ARPING_PATH=\"/usr/sbin\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"CMD_ARPING_PATH=\\\"${arping_path}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#the trust server of the cluster,which can be an IP of different segmen.example:KB_GATEWAY_IP=\"192.168.29.1,192.168.28.1\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_GATEWAY_IP=\\\"$trust_ip\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#the current node ip.example:KB_LOCALHOST_IP=\"192.168.28.128\"' >> ${kb_etc}/HAmodule.conf" 
        execute_command ${cluster_user} ${ip} "echo -e \"KB_LOCALHOST_IP=\\\"$ip\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#1->synchronous cluster,0->asynchronous cluster ,default 1.example:SYNC_FLAG=1' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"SYNC_FLAG=1\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#db use vip/the subnet mask.example:KB_VIP=\"192.168.28.220/24\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_VIP=\\\"${db_vip}\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"KB_REAL_DEV=\\\"${current_dev}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#pool use vip/the subnet mask.example:KB_POOL_VIP=\"192.168.28.220/24\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_POOL_VIP=\\\"${cluster_vip%/*}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#pool use port,default 9999.example:KB_POOL_PORT=\"9999\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_POOL_PORT=\\\"9999\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#cluster user,default kingbase.example:PCP_USER=\"kingbase\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"PCP_USER=\\\"kingbase\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#cluster password,default 123456.example:PCP_PASS=\"123456\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"PCP_PASS=\\\"MTIzNDU2\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#location of the db etc directory.example:KB_ETC_PATH=\"./cluster/clusterName/db/etc\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_ETC_PATH=\\\"${kb_etc}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#location of the db bin directory.example:KB_PATH=\"./cluster/clusterName/db/bin\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_PATH=\\\"${kb_bin}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#location of the db lib directory.example:KB_LD_PATH=\"./cluster/clusterName/db/lib\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_LD_PATH=\\\"${kb_lib}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#location of the cluster bin directory.example:CLUSTER_BIN_PATH=\"./cluster/clusterName/kingbasecluster/bin\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"CLUSTER_BIN_PATH=\\\"${cluster_bin}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#location of the cluster lib directory.example:CLUSTER_LIB_PATH=\"./cluster/clusterName/kingbasecluster/lib\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"CLUSTER_LIB_PATH=\\\"${cluster_lib}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#location of the db data directory.example:KB_DATA_PATH=\"./cluster/clusterName/db/data\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_DATA_PATH=\\\"${kb_data}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_USER=\\\"SUPERMANAGER_V8ADMIN\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_PASS=\\\"S0lOR0JBU0VBRE1JTg==\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#database instance built-in database.example:KB_DATANAME=\"TEST\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_DATANAME=\\\"TEST\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#database listening port,default 54321.example:KB_PORT=\"54321\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_PORT=\\\"${db_port}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#home users of the cluster.example:KB_EXECUTE_SYS_USER=\"kingbase\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_EXECUTE_SYS_USER=\\\"${cluster_user}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#automatic recovery log path.example:RECOVERY_LOG_DIR=\"./log/recovery.log\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"RECOVERY_LOG_DIR=\\\"${log_path}/recovery.log\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#temporary files to query database status in clusster.example:KB_CLUSTER_STATUS=\"./log/pool_nodes\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_CLUSTER_STATUS=\\\"${log_path}/pool_nodes\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#IP of all nodes in the cluster.example:KB_ALL_IP=\"(192.168.28.128 192.168.28.129)\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_ALL_IP=(${all_node_ip[*]})\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#pg_pool ip.example:KB_POOL_IP1=\"192.168.28.128\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_POOL_IP1=\\\"${all_node_ip[0]}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#pg_pool ip.example:KB_POOL_IP2=\"192.168.28.129\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_POOL_IP2=\\\"${all_node_ip[1]}\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"KB_DEV=\\\"${current_dev}\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"KB_POOL_PATH=\\\"${cluster_bin}\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"KB_POOL_LD_PATH=\\\"${cluster_bin}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"POOL_EXENAME=\\\"kingbasecluster\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#kingbasecluster socket files.example:KINGBASECLUSTERSOCKET1=\"/tmp/.s.KINGBASE.54321\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KINGBASECLUSTERSOCKET1=\\\"/tmp/.s.KINGBASE.9999\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KINGBASECLUSTERSOCKET2=\\\"/tmp/.s.KINGBASE.9898\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KINGBASECLUSTERSOCKET3=\\\"/tmp/.s.KINGBASECLUSTERWD_CMD.9000\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KINGBASECLUSTERSOCKET4=\\\"/tmp/.s.KINGBASECLUSTERWD_CMD.9000.lock\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#save kingbasecluster running status file.example:CLUSTER_STAT_FILE=\".run/kingbasecluster/kingbasecluster_status\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"CLUSTER_STAT_FILE=\\\"${cluster_path}/run/kingbasecluster/kingbasecluster_status\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"CLUSTER_ETC_FILE=\\\"${cluster_etc}/kingbasecluster.conf\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#kingbasecluster log path.example:CLUSTER_LOG_PATH=\"./log\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"CLUSTER_LOG_PATH=\\\"${log_path}\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"KB_VIRTUAL_IP=\\\"${db_vip}\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"KB_VIRTUAL_DEV_NAME=\\\"${current_dev}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#kingbasecluster log file name.example:CLUSTER_LOG_NAME=\"cluster.log\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"CLUSTER_LOG_NAME=\\\"cluster.log\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"CLUSTER_GATEWAY_ROUTE=\\\"${trust_ip}\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#trust server check times.example:PING_TIMES=\"3\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"PING_TIMES=\\\"3\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"ES_PORT=\\\"8890\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"ES_USER=\\\"kingbase\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"ES_PASS=\\\"MTIzNDU2Cg==\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#kingbasecluster restart log path.example:POOL_RESTART=\"./log/cluster_restart.log\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"POOL_RESTART=\\\"${log_path}/cluster_restart.log\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#failover log path.example:FAILOVER_LOG_DIR=\"./log/failover.log\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"FAILOVER_LOG_DIR=\\\"${log_path}/failover.log\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"KB_RECOVERY_FLAG=\\\"KB_RECOVERY_FLAG\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#kingbasecluster executes as user,default root.example:KB_POOL_EXECUTE_SYS_USER=\"root\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"KB_POOL_EXECUTE_SYS_USER=\\\"${super_user}\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"POOL_1_STAUTS=\\\"active\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"POOL_2_STAUTS=\\\"active\\\"\" >> ${kb_etc}/HAmodule.conf"
        [ $on_bmj -eq 1 ] && execute_command ${cluster_user} ${ip} "echo -e \"KB_PRIMARY_FLAG=\\\"KB_PRIMARY_FLAG\\\"\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#ssh connection timeout x senonds.example:CONNECTTIMEOUT=\"10\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"CONNECTTIMEOUT=10\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#maximum number of health checks.example:HEALTH_CHECK_MAX_RETRIES=\"3\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"HEALTH_CHECK_MAX_RETRIES=${check_retries}\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#maximum health check delay.example:HEALTH_CHECK_RETRY_DELAY=\"3\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"HEALTH_CHECK_RETRY_DELAY=${check_delay}\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#whether to turn on automatic recovery,0->off,1->on.example:AUTO_PRIMARY_RECOVERY=\"1\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"AUTO_PRIMARY_RECOVERY=${auto_primary_recovery}\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#recoord the names of all nodes.example:ALL_NODE_NAME=1 (node1 node2 node3)' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"ALL_NODE_NAME=${all_node_name}\" >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e '#recoord the names of local node.example:NODE_NAME=\"node1\"' >> ${kb_etc}/HAmodule.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"NODE_NAME=\\\"node$i\\\"\" >> ${kb_etc}/HAmodule.conf"

        let i=$i+1
        let index=$index+1
        [ $? -ne 0 ] && echo "[ERROR] Failed to config HAmodule.conf on $ip"
        echo "[INSTALL] success to alter ${kb_etc}/HAmodule.conf on $ip"
    done
}

function main()
{
    pre_exe

    change_system

    local should_exit=0

    if [ "${primary_host}"x = ""x ]
    then
        primary_host="${all_node_ip[0]}"
    fi

    local cluster_ip=(${all_node_ip[0]} ${all_node_ip[1]})

    # ssh to check if every host could be reached
    echo "[RUNNING] check if the host can be reached ..."
    for ip in ${all_node_ip[@]}
    do
        test_ssh $ip
        if [ $? -ne 0 ]
        then
            should_exit=1
            echo "[RUNNING] can not connect to \"${ip}\", please check your configuration item of \"all_node_ip\"."
            break
        else
            echo "[RUNNING] success connect to the target \"${ip}\" ..... OK"
        fi
    done
    [ $should_exit -eq 1 ] && exit 1

    # check if there is kingbase running on  the host
    echo "[RUNNING] check the port is already in use or not..."
    for ip in ${all_node_ip[@]}
    do
        local db_running=`execute_command ${super_user} $ip "netstat -apn 2>/dev/null|grep -w \"${db_port}\"|wc -l"`
        if [ $? -ne 0 -o "${db_running}"x != "0"x ]
        then
            should_exit=1
            echo "[RUNNING] the port on \"${ip}:${db_port}\" is already in use, please change the port or release occupied port."
        else
            echo "[RUNNING] the port is not in use on \"${ip}:${db_port}\" ..... OK"
        fi
    done
    [ $should_exit -eq 1 ] && exit 1

    # check if data directory exists
    echo "[RUNNING] check if the cluster_path is already exist ..."
    for ip in ${all_node_ip[@]}
    do
        execute_command ${cluster_user} $ip "test ! -e ${cluster_path}"
        if [ $? -ne 0 ]
        then
            if [ $on_bmj -eq 0 ]
            then
                echo "[ERROR] the cluster_path \"${cluster_path}\" on \"${ip}\" is already exist, please remove it first."
                exit 1
            else
                echo "[RUNNING] the cluster_path \"${cluster_path}\" on \"${ip}\" of BMJ is right .... OK"
            fi
        else
            if [ $on_bmj -eq 0 ]
            then
                echo "[RUNNING] the cluster_path is not exist on \"${ip}\" ..... OK"
            else
                echo "[ERROR] there have not installed kingbase databse on \"${ip}\" of BMJ yet ..... failed"
                exit 1
            fi
        fi
    done

    # create install directory
    if [ $on_bmj -eq 0 ]
    then
        echo "[INSTALL] create the cluster_path \"${cluster_path}\" on every host ..."
        for ip in ${all_node_ip[@]}
        do
            execute_command ${cluster_user} $ip "mkdir -p ${cluster_path}"
            if [ $? -ne 0 ]
            then
                echo "[ERROR] failed to create the cluster_path \"${cluster_path}\" on \"${ip}\"."
                exit 1
            else
                echo "[INSTALL] success to create the cluster_path \"${cluster_path}\" on \"${ip}\" ..... OK"
            fi
        done

        # decompress the package to ${cluster_path}
        echo "[INSTALL] decompress the \"${db_package}\" and \"${cluster_package}\" to \"${cluster_path}\""
        if [ $name_db_zip -eq 1 ]
        then
            execute_command ${cluster_user} ${primary_host} "unzip -q -o $db_package -d $cluster_path 1>/dev/null"
            if [ $? -ne 0 ]
            then
                echo "[ERROR] failed to decompress the \"$db_package\" to \"${cluster_path}\" on \"${primary_host}\"."
                exit 1
            else
                echo "[INSTALL] success to decompress the \"${db_package}\" to \"${cluster_path}\" on \"${primary_host}\"..... OK"
            fi
        elif [ $name_db_tar -eq 1 ]
        then
            execute_command ${cluster_user} ${primary_host} "mkdir -p $cluster_path/db && tar -xvf $db_package -C $cluster_path/db 1>/dev/null"
            if [ $? -ne 0 ]
            then
                echo "[ERROR] failed to decompress the \"$db_package\" to \"${cluster_path}/db\" on \"${primary_host}\"."
                exit 1
            else
                echo "[INSTALL] success to decompress the \"${db_package}\" to \"${cluster_path}/db\" on \"${primary_host}\"..... OK"
            fi
        elif [ $name_db_gz -eq 1 ]
        then
            execute_command ${cluster_user} ${primary_host} "mkdir -p $cluster_path/db && tar -zxvf $db_package -C $cluster_path/db 1>/dev/null"
            if [ $? -ne 0 ]
            then
                echo "[ERROR] failed to decompress the \"$db_package\" to \"${cluster_path}/db\" on \"${primary_host}\"."
                exit 1
            else
                echo "[INSTALL] success to decompress the \"${db_package}\" to \"${cluster_path}/db\" on \"${primary_host}\"..... OK"
            fi
        fi
        if [ $name_cluster_zip -eq 1 ]
        then
            execute_command ${cluster_user} ${primary_host} "unzip -q -o $cluster_package -d $cluster_path 1>/dev/null"
            if [ $? -ne 0 ]
            then
                echo "[ERROR] failed to decompress the \"$cluster_package\" to \"${cluster_path}\" on \"${primary_host}\"."
                exit 1
            else
                echo "[INSTALL] success to decompress the \"$cluster_package\" to \"${cluster_path}\" on \"${primary_host}\"..... OK"
            fi
        elif [ $name_cluster_tar -eq 1 ]
        then
            execute_command ${cluster_user} ${primary_host} "mkdir -p $cluster_path/kingbasecluster && tar -xvf $cluster_package -C $cluster_path/kingbasecluster 1>/dev/null"
            if [ $? -ne 0 ]
            then
                echo "[ERROR] failed to decompress the \"$cluster_package\" to \"${cluster_path}/kingbasecluster\" on \"${primary_host}\"."
                exit 1
            else
                echo "[INSTALL] success to decompress the \"$cluster_package\" to \"${cluster_path}/kingbasecluster\" on \"${primary_host}\"..... OK"
            fi
        elif [ $name_cluster_gz -eq 1 ]
        then
            execute_command ${cluster_user} ${primary_host} "mkdir -p $cluster_path/kingbasecluster && tar -zxvf $cluster_package -C $cluster_path/kingbasecluster 1>/dev/null"
            if [ $? -ne 0 ]
            then
                echo "[ERROR] failed to decompress the \"$cluster_package\" to \"${cluster_path}/kingbasecluster\" on \"${primary_host}\"."
                exit 1
            else
                echo "[INSTALL] success to decompress the \"$cluster_package\" to \"${cluster_path}/kingbasecluster\" on \"${primary_host}\"..... OK"
            fi
        fi
    fi
    # check the directory
    execute_command ${cluster_user} ${primary_host} "test ! -d ${kb_bin}"
    if [ $? -eq 0 ]
    then
        echo "[ERROR] the target dir of unzip is not correct, there is no dir \"${kb_bin}\" on \"${primary_host}\""
        exit 1
    fi
    execute_command ${cluster_user} ${primary_host} "test ! -d ${cluster_bin}"
    if [ $? -eq 0 ]
    then
        echo "[ERROR] the target dir of unzip is not correct, there is no dir \"${cluster_bin}\" on \"${primary_host}\""
        exit 1
    fi

    # copy kingbasecluster/bin、lib to db/bin、lib
    echo "[INSTALL] copy ${cluster_bin}/pcp_* and ${cluster_lib}/libpcp.* to ${kb_bin} and ${kb_lib}"
    execute_command ${cluster_user} ${primary_host} "cp ${cluster_bin}/pcp_* ${kb_bin}"
    execute_command ${cluster_user} ${primary_host} "cp ${cluster_lib}/libpcp.* ${kb_lib}"
    if [ $? -ne 0 ]
    then
        echo "[ERROR] copy ${cluster_bin}/pcp_* and ${cluster_lib}/libpcp.* to ${kb_bin} and ${kb_lib} failed."
        exit 1
    else
        echo "[INSTALL] copy ${cluster_bin}pcp_* and ${cluster_lib}/libpcp.* to ${kb_bin} and ${kb_lib} .... OK"
    fi

    # create directory archive、etc and create file repmgr.conf
    echo "[INSTALL] create the dir \"${kb_etc}\" and  \"${cluster_etc}\" on all host"
    execute_command ${cluster_user} ${primary_host} "test ! -d ${kb_etc} && mkdir -p ${kb_etc}/"
    execute_command ${cluster_user} ${primary_host} "test ! -d ${cluster_etc} && mkdir -p ${cluster_etc}/"
    execute_command ${cluster_user} ${primary_host} "test ! -d ${kb_archive} && mkdir -p ${kb_archive}"
    execute_command ${cluster_user} ${primary_host} "test ! -d ${log_path}/kingbasecluster && mkdir -p ${log_path}/kingbasecluster"
    execute_command ${cluster_user} ${primary_host} "test ! -d ${cluster_path}/run/kingbasecluster && mkdir -p ${cluster_path}/run/kingbasecluster"

    # copy the whole install directory to other hosts
    if [ $on_bmj -eq 0 ]
    then
        echo "[INSTALL] scp the dir \"${cluster_path}\" to other host"
        for ip in ${all_node_ip[@]}
        do
            [ "${primary_host}"x != ""x -a "${primary_host}"x = "${ip}"x ] && continue

            echo "[INSTALL] try to copy the cluster_path \"${cluster_path}\" to \"${ip}\" ....."
            execute_command ${cluster_user} ${primary_host} "scp -o StrictHostKeyChecking=no -r ${cluster_path}/db ${cluster_user}@${ip}:${cluster_path} >/dev/null 2>&1"
            execute_command ${cluster_user} ${primary_host} "scp -o StrictHostKeyChecking=no -r ${kb_archive} ${cluster_user}@${ip}:${cluster_path} >/dev/null 2>&1"
            execute_command ${cluster_user} ${primary_host} "scp -o StrictHostKeyChecking=no -r ${log_path} ${cluster_user}@${ip}:${cluster_path} >/dev/null 2>&1"
            execute_command ${cluster_user} ${primary_host} "scp -o StrictHostKeyChecking=no -r ${cluster_path}/run ${cluster_user}@${ip}:${cluster_path} >/dev/null 2>&1"
            if [ $? -ne 0 ]
            then
                echo "[ERROR] failed to scp the cluster_path \"${cluster_path}\" to \"${ip}\"."
                exit 1
            else
                echo "[INSTALL] success to scp the cluster_path \"${cluster_path}\" to \"${ip}\" ..... OK"
            fi
        done

        for ip in ${cluster_ip[@]}
        do
            [ "${primary_host}"x != ""x -a "${primary_host}"x = "${ip}"x ] && continue

            echo "[INSTALL] try to copy the cluster_path \"${cluster_path}/kingbasecluster\" to \"${ip}\" ....."
            execute_command ${cluster_user} ${primary_host} "scp -o StrictHostKeyChecking=no -r ${cluster_path}/kingbasecluster ${cluster_user}@${ip}:${cluster_path} >/dev/null 2>&1"
        done
    fi
    
    # if VIP is set, change the auth of ip、arping
    if [ "${db_vip}"x != ""x -a "${cluster_vip}"x != ""x -a $on_bmj -eq 0 ]
    then
        echo "[RUNNING] chmod u+x for \"${ipaddr_path}\" and \"${arping_path}\""
        for ip in ${all_node_ip[@]}
        do
            execute_command ${super_user} $ip "chmod u+x ${ipaddr_path}/ip"
            if [ $? -ne 0 ]
            then
                should_exit=1
                echo "[RUNNING] can not execute \"chmod u+x ${ipaddr_path}/ip\" on \"${ip}\"."
                break
            else
                echo "[RUNNING] chmod u+x ${ipaddr_path}/ip on \"${ip}\" ..... OK"
            fi

            execute_command ${super_user} $ip "chown -R ${cluster_user}:${cluster_user} ${arping_path}/arping"
            execute_command ${super_user} $ip "chmod u+x ${arping_path}/arping"
            if [ $? -ne 0 ]
            then
                should_exit=1
                echo "[RUNNING] can not execute \"chmod u+x ${arping_path}/arping\" on \"${ip}\"."
                break
            else
                echo "[RUNNING] chmod u+x ${arping_path}/arping on \"${ip}\" ..... OK"
            fi
        done
        [ $should_exit -eq 1 ] && exit 1
    fi

    local i=0
    if [ $on_bmj -eq 0 ]
    then
        for ip in ${all_node_ip[@]}
        do
            if [ $license_num -eq 1 ]
            then
                #copy license.dat to cluster_path
                echo "[INSTALL] check license_file \"${license_path}/$license_file\""
                if [ -f ${license_path}/${license_file} ]
                then
                    if [ $? -ne 0 ]
                    then
                        echo "[ERROR] Cannot access license_file: ${license_path}/${license_file}"
                        exit 1
                    else
                        echo "[INSTALL] success to access license_file: ${license_path}/${license_file}"
                    fi
                fi
                echo "[INSTALL] Copy license.dat to ${cluster_path}: $license_path/$license_file"
                execute_command ${cluster_user} $primary_host "scp -o StrictHostKeyChecking=no -r ${license_path}/${license_file} ${cluster_user}@$ip:${cluster_path} >/dev/null 2>&1"
                if [ ${license_file} != "license.dat" ]
                then
                    execute_command ${cluster_user} $ip "ln -s ${cluster_path}/${license_file} ${kb_bin}/../../license.dat"
                fi
                if [ $? -ne 0 ]
                then
                    echo "[ERROR] failed to copy license.dat to $kb_bin/../../ on $ip"
                    exit 1
                else
                    echo "[INSTALL] success to copy license.dat to $kb_bin/../../ on $ip"
                fi
            else
                #copy license.dat to cluster_path
                echo "[INSTALL] check license_file \"${license_path}/${license_file[$i]}\""
                if [ -f ${license_path}/${license_file} ]
                then
                    if [ $? -ne 0 ]
                    then
                        echo "[ERROR] Cannot access license_file: ${license_path}/${license_file}"
                        exit 1
                    else
                        echo "[INSTALL] success to access license_file: ${license_path}/${license_file}"
                    fi
                fi
                echo "[INSTALL] Copy license.dat to ${cluster_path} and $cluster_bin: ${license_path[$i]} on $ip"
                execute_command ${cluster_user} $primary_host "scp -o StrictHostKeyChecking=no -r ${license_path}/${license_file[$i]} ${cluster_user}@$ip:${cluster_path} >/dev/null 2>&1"
                execute_command ${cluster_user} $ip "ln -s ${cluster_path}/${license_file[$i]} ${kb_bin}/../../license.dat"
                if [ $? -ne 0 ]
                then
                    echo "[ERROR] failed to copy ${license_path}/${license_file[$i]} to $kb_bin/../../ on $ip"
                    exit 1
                else
                    echo "[INSTALL] success to copy ${license_path}/${license_file[$i]} to $kb_bin/../../ on $ip"
                fi
            fi
            let i++
        done
    else
        for ip in ${all_node_ip[@]}
        do
            execute_command ${cluster_user} $ip "test ! -f $license_path"
            if [ $? -eq 1 ]
            then
                echo "[INSTALL] check license_path \"${license_path}\" on $ip .... ok"
            else
                echo "[ERROR] check license_path \"${license_path}\" on $ip .... failed"
                exit 1
            fi
        done
    fi

    # init the database
    echo "[INSTALL] begin to init the database on \"${primary_host}\" ..."
    if [ $on_bmj -eq 1 ]
    then
        for ip in ${all_node_ip[@]}
        do
            execute_command ${cluster_user} $ip "test ! -e ${kb_data}"
            if [ $? -ne 0 ]
            then
                echo "[RUNNING] the data dir \"${kb_data}\" on \"${ip}\" is already exist, please move it first."
            fi
        done
    fi

    execute_command ${cluster_user} ${primary_host} "${kb_bin}/initdb -D ${kb_data} -U $db_user -W '$db_password'"

    [ $? -ne 0 ] && exit 1
    echo "[INSTALL] end to init the database on \"${primary_host}\" ... OK"

    # change configuration file
    for ((i=1;i<=$node_num;i++))
    do
        [ $i -eq 1 ] && standby_name="1 (node1"
        [ $i -ne 1 ] && standby_name="$standby_name, node$i"
    done
    standby_name="$standby_name)"

    echo "[INSTALL] alter ${kb_data}/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"max_wal_senders=32\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"wal_keep_segments=256\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"hot_standby_feedback=on\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"shared_buffers=512MB\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"max_prepared_transactions=100\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"control_file_copy='${cluster_path}/template.bk'\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"port='${db_port}'\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"wal_level=replica\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"fsync=on\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"wal_log_hints=on\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"archive_mode=on\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"archive_dest='${kb_archive}'\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"max_replication_slots=`expr ${node_num} \* 2`\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"synchronous_standby_names='$standby_name'\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"hot_standby=on\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"log_destination='csvlog'\" >> $kb_data/kingbase.conf"
    execute_command ${cluster_user} ${primary_host} "echo -e \"log_directory='$kb_data/sys_log'\" >> $kb_data/kingbase.conf"
    [ $? -ne 0 ] && echo "[ERROR] Failed to config $kb_data/kingbase.conf" && exit 1
    echo "[INSTALL] Alter $kb_data/kingbase.conf ... OK"

    echo "[INSTALL] Alter ${kb_data}/sys_hba.conf"
    for ip in ${all_node_ip[@]}
    do
        mask=`echo ${ip} |awk -F '/' '{print $2}'`
        if [ "$mask"x = ""x ]
        then
            ip="$ip/24"
        elif [ $mask -ge 0 -a $mask -le 32 ]
        then
            echo "[CONFIG_CHECK] the value of subnet mask is right"
        else
            echo "[ERROR] the value of subnet mask for cluster_vip should be between 0 and 32"
            exit 1
        fi

        execute_command ${cluster_user} ${primary_host} "echo -e \"host           all                   ${db_user}            $ip                 md5\" >> ${kb_data}/sys_hba.conf"
        execute_command ${cluster_user} ${primary_host} "echo -e \"host           replication           ${db_user}            $ip                 md5\" >> ${kb_data}/sys_hba.conf"
    done
    [ $? -ne 0 ] && echo "[ERROR] Failed to config ${kb_data}/sys_hba.conf" && exit 1
    echo "[INSTALL] Alter ${kb_data}/sys_hba.conf ... OK"

    alter_HAmodule

    local i=1

    db_passwd_encpwd=`echo ${db_password} | base64`

    for ip in ${all_node_ip[@]}
    do
        echo "[INSTALL] Alter ${kb_etc}/recovery.done on $ip"
        execute_command ${cluster_user} ${ip} "echo -e \"standby_mode='on'\" >> ${kb_etc}/recovery.done"
        execute_command ${cluster_user} ${ip} "echo -e \"primary_conninfo='port=${db_port} host=${all_node_ip[0]} user=${db_user} password=${db_passwd_encpwd} application_name=node$i'\" >> ${kb_etc}/recovery.done"
        execute_command ${cluster_user} ${ip} "echo -e \"recovery_target_timeline='latest'\" >> ${kb_etc}/recovery.done"
        execute_command ${cluster_user} ${ip} "echo -e \"primary_slot_name ='slot_node$i'\" >> ${kb_etc}/recovery.done"
        [ $? -ne 0 ] && echo "[ERROR] Failed to config ${kb_etc}/recovery.done on $ip" && exit 1
        let i=$i+1
        echo "[INSTALL] Alter ${kb_etc}/recovery.done on $ip ... OK"
    done

    local i=1
    local index=0
    for ip in ${cluster_ip[@]}
    do
        echo "[INSTALL] Alter ${cluster_etc}/kingbasecluster.conf on $ip"
        execute_command ${cluster_user} ${ip} "sed \"s/ = /=/g\" ${cluster_etc}/kingbasecluster.conf.sample > ${cluster_etc}/kingbasecluster.conf.tmp"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*listen_addresses[ ]*=/clisten_addresses='*'\" ${cluster_etc}/kingbasecluster.conf.tmp > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*enable_cluster_hba[ ]*=/cenable_cluster_hba=on\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*num_init_children[ ]*=/cnum_init_children=16\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*connection_life_time[ ]*=/cconnection_life_time=3\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*pid_file_name[ ]*=/cpid_file_name='${log_path}/kingbasecluster/kingbasecluster.pid'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*logdir[ ]*=/clogdir='${cluster_path}/run/kingbasecluster'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*insert_lock[ ]*=/cinsert_lock=off\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*load_balance_mode[ ]*=/cload_balance_mode=on\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*master_slave_mode[ ]*=/cmaster_slave_mode=on\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*master_slave_sub_mode[ ]*=/cmaster_slave_sub_mode='stream'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*sr_check_user[ ]*=/csr_check_user='SUPERMANAGER_V8ADMIN'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*sr_check_password[ ]*=/csr_check_password='S0lOR0JBU0VBRE1JTg\\\\\=\\\\\='\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*sr_check_database[ ]*=/csr_check_database='TEMPLATE2'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*health_check_period[ ]*=/chealth_check_period='1'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*health_check_timeout[ ]*=/chealth_check_timeout=120\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*health_check_user[ ]*=/chealth_check_user='SUPERMANAGER_V8ADMIN'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*health_check_password[ ]*=/chealth_check_password='S0lOR0JBU0VBRE1JTg\\\\\=\\\\\='\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*health_check_database[ ]*=/chealth_check_database='TEMPLATE2'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*health_check_max_retries[ ]*=/chealth_check_max_retries=${check_retries}\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*health_check_retry_delay[ ]*=/chealth_check_retry_delay=${check_delay}\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*connect_timeout[ ]*=/cconnect_timeout='${connect_timeout}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*failover_command[ ]*=/cfailover_command='${cluster_bin}/failover_stream.sh %H %P %d %h %O %m %M %D'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*fail_over_on_backend_error[ ]*=/cfail_over_on_backend_error='off'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*search_primary_node_timeout[ ]*=/csearch_primary_node_timeout=10\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*recovery_user[ ]*=/crecovery_user='SUPERMANAGER_V8ADMIN'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*recovery_password[ ]*=/crecovery_password='S0lOR0JBU0VBRE1JTg\\\\\=\\\\\='\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*use_watchdog[ ]*=/cuse_watchdog=on\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*trusted_servers[ ]*=/ctrusted_servers='$trust_ip'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*wd_hostname[ ]*=/cwd_hostname='$ip'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*wd_priority[ ]*=/cwd_priority=3\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*wd_authkey[ ]*=/cwd_authkey='S0lOR0JBU0VBRE1JTg\\\\\=\\\\\='\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*delegate_IP[ ]*=/cdelegate_IP='${cluster_vip%/*}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*arping_path[ ]*=/carping_path='${arping_path}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*wd_interval[ ]*=/cwd_interval='1'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*wd_heartbeat_keepalive[ ]*=/cwd_heartbeat_keepalive='1'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*wd_heartbeat_deadtime[ ]*=/cwd_heartbeat_deadtime='${wd_deadtime}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*wd_lifecheck_dbname[ ]*=/cwd_lifecheck_dbname='TEMPLATE2'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*wd_lifecheck_user[ ]*=/cwd_lifecheck_user='SUPERMANAGER_V8ADMIN'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*wd_lifecheck_password[ ]*=/cwd_lifecheck_password='S0lOR0JBU0VBRE1JTg\\\\\=\\\\\='\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        execute_command ${cluster_user} ${ip} "sed \"/^[# ]*memqcache_oiddir[ ]*=/cmemqcache_oiddir='${log_path}/kingbasecluster/oiddir'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"

        if [ $net_num -eq 1 ]
        then
            execute_command ${cluster_user} ${ip} "sed \"/^[# ]*if_up_cmd[ ]*=/cif_up_cmd='ip addr add ${cluster_vip} dev ${net_device} label ${net_device}:0'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
            execute_command ${cluster_user} ${ip} "sed \"/^[# ]*if_down_cmd[ ]*=/cif_down_cmd='ip addr del ${cluster_vip} dev ${net_device}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
            execute_command ${cluster_user} ${ip} "sed \"/^[# ]*arping_cmd[ ]*=/carping_cmd='arping -U ${cluster_vip%/*} -I ${net_device} -w 1 -c 1'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        else
            execute_command ${cluster_user} ${ip} "sed \"/^[# ]*if_up_cmd[ ]*=/cif_up_cmd='ip addr add ${cluster_vip} dev ${net_device[$index]} label ${net_device[$index]}:0'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
            execute_command ${cluster_user} ${ip} "sed \"/^[# ]*if_down_cmd[ ]*=/cif_down_cmd='ip addr del ${cluster_vip} dev ${net_device[$index]}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
            execute_command ${cluster_user} ${ip} "sed \"/^[# ]*arping_cmd[ ]*=/carping_cmd='arping -U ${cluster_vip%/*} -I ${net_device[$index]} -w 1 -c 1'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
        fi

        let i=$i+1
        let index=$index+1
        [ $? -ne 0 ] && echo "[ERROR] Failed to config kingbasecluster.conf of CLUSTER on $ip"
        echo "[INSTALL] Alter $cluster_etc/kingbasecluster.conf of CLUSTER on $ip ... OK"
    done

    execute_command ${cluster_user} ${cluster_ip[0]} "sed \"/^[# ]*heartbeat_destination0[ ]*=/cheartbeat_destination0='${cluster_ip[1]}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
    if [ $net_num -eq 1 ]
    then
        execute_command ${cluster_user} ${cluster_ip[0]} "sed \"/^[# ]*heartbeat_device0[ ]*=/cheartbeat_device0='${net_device}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
    else
        execute_command ${cluster_user} ${cluster_ip[0]} "sed \"/^[# ]*heartbeat_device0[ ]*=/cheartbeat_device0='${net_device[0]}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
    fi
    execute_command ${cluster_user} ${cluster_ip[0]} "sed \"/^[# ]*other_kingbasecluster_hostname0[ ]*=/cother_kingbasecluster_hostname0='${cluster_ip[1]}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
    execute_command ${cluster_user} ${cluster_ip[0]} "sed \"/^[# ]*other_kingbasecluster_port0[ ]*=/cother_kingbasecluster_port0='9999'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
    execute_command ${cluster_user} ${cluster_ip[0]} "sed \"/^[# ]*other_wd_port0[ ]*=/cother_wd_port0=9000\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
    [ $? -ne 0 ] && echo "[ERROR] Failed to config $cluster_etc/kingbasecluster.conf on ${cluster_ip[0]}" && exit 1
    echo "[INSTALL] Alter $cluster_etc/kingbasecluster.conf on ${cluster_ip[0]} ... OK"

    execute_command ${cluster_user} ${cluster_ip[1]} "sed \"/^[# ]*heartbeat_destination0[ ]*=/cheartbeat_destination0='${cluster_ip[0]}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
    if [ $net_num -eq 1 ]
    then
        execute_command ${cluster_user} ${cluster_ip[1]} "sed \"/^[# ]*heartbeat_device0[ ]*=/cheartbeat_device0='${net_device}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
    else
        execute_command ${cluster_user} ${cluster_ip[1]} "sed \"/^[# ]*heartbeat_device0[ ]*=/cheartbeat_device0='${net_device[1]}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
    fi
    execute_command ${cluster_user} ${cluster_ip[1]} "sed \"/^[# ]*other_kingbasecluster_hostname0[ ]*=/cother_kingbasecluster_hostname0='${cluster_ip[0]}'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
    execute_command ${cluster_user} ${cluster_ip[1]} "sed \"/^[# ]*other_kingbasecluster_port0[ ]*=/cother_kingbasecluster_port0='9999'\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
    execute_command ${cluster_user} ${cluster_ip[1]} "sed \"/^[# ]*other_wd_port0[ ]*=/cother_wd_port0=9000\" ${cluster_etc}/kingbasecluster.conf > ${cluster_etc}/kingbasecluster.conf.tmp.bk && cat ${cluster_etc}/kingbasecluster.conf.tmp.bk > ${cluster_etc}/kingbasecluster.conf && rm -rf ${cluster_etc}/kingbasecluster.conf.tmp.bk"
    [ $? -ne 0 ] && echo "[ERROR] Failed to config $cluster_etc/kingbasecluster.conf on ${cluster_ip[1]}" && exit 1
    echo "[INSTALL] Alter $cluster_etc/kingbasecluster.conf on ${cluster_ip[1]} ... OK"

    for ip in ${cluster_ip[@]}
    do
        for((i=0;i<$node_num;i++))
        do
            execute_command ${cluster_user} ${ip} "echo -e \"backend_hostname${i}='${all_node_ip[${i}]}'\" >> $cluster_etc/kingbasecluster.conf"
            execute_command ${cluster_user} ${ip} "echo -e \"backend_port${i}=${db_port}\" >> $cluster_etc/kingbasecluster.conf"
            execute_command ${cluster_user} ${ip} "echo -e \"backend_weight${i}=1\" >> $cluster_etc/kingbasecluster.conf"
            execute_command ${cluster_user} ${ip} "echo -e \"backend_data_directory${i}='${kb_data}'\" >> $cluster_etc/kingbasecluster.conf"
            [ $? -ne 0 ] && echo "[ERROR] Failed to config $cluster_etc/kingbasecluster.conf of node_num on $ip" && exit 1
            echo "[INSTALL] Alter $cluster_etc/kingbasecluster.conf of node_num on $ip ... OK"
        done
    done

    local md5_user=`echo "${db_user}" |tr -t [:lower:] [:upper:]`
    local md5_passwd=`execute_command ${cluster_user} ${ip} "${cluster_bin}/sys_md5 '${db_password}'$md5_user"`
    for ip in ${cluster_ip[@]}
    do
        echo "[INSTALL] Alter ${cluster_etc}/cluster_hba.conf on $ip"
        execute_command ${cluster_user} ${ip} "echo -e \"local   all         all                               md5\" >> $cluster_etc/cluster_hba.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"host    all         all         127.0.0.1/32          md5\" >> $cluster_etc/cluster_hba.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"host    all         all         0.0.0.0/0             md5\" >> $cluster_etc/cluster_hba.conf"
        execute_command ${cluster_user} ${ip} "echo -e \"host    all         all         ::1/128               md5\" >> $cluster_etc/cluster_hba.conf"
        [ $? -ne 0 ] && echo "[ERROR] Failed to config ${cluster_etc}/cluster_hba.conf on $ip" && exit 1
        echo "[INSTALL] Alter ${cluster_etc}/cluster_hba.conf on $ip ... OK"

        echo "[INSTALL] Alter ${cluster_etc}/pcp.conf on $ip"
        execute_command ${cluster_user} ${ip} "echo \"kingbase:e10adc3949ba59abbe56e057f20f883e\" > $cluster_etc/pcp.conf"
        [ $? -ne 0 ] && echo "[ERROR] Failed to config pcp.conf on $ip" && exit 1
        echo "[INSTALL] Alter ${cluster_etc}/pcp.conf on $ip ... OK"

        echo "[INSTALL] Alter ${cluster_etc}/cluster_passwd on $ip"
        execute_command ${cluster_user} ${ip} "echo -e \"SUPERMANAGER_V8ADMIN:md5f7902af5f3f7cdcad02b5ca09320d102\" > $cluster_etc/cluster_passwd"
        execute_command ${cluster_user} ${ip} "echo -e \"${db_user}:md5${md5_passwd}\" >> $cluster_etc/cluster_passwd"
        [ $? -ne 0 ] && echo "[ERROR] Failed to config ${cluster_etc}/cluster_passwd on $ip" && exit 1
        echo "[INSTALL] config ${cluster_etc}/cluster_passwd on $ip ... OK"

        echo "[INSTALL] copy $kb_etc/HAmodule.conf to $cluster_etc on $ip"
        execute_command ${cluster_user} ${ip} "cp $kb_etc/HAmodule.conf $cluster_etc"
        [ $? -ne 0 ] && echo "[ERROR] Failed to copy HAmodule.conf from $kb_etc to $cluster_etc on $ip" && exit 1
        echo "[INSTALL] copy $kb_etc/HAmodule.conf to $cluster_etc on $ip ... OK"
    done

    echo "[INSTALL] copy $kb_data/kingbase.conf to ${kb_etc}"
    execute_command ${cluster_user} ${primary_host} "cp $kb_data/kingbase.conf $kb_etc"
    [ $? -ne 0 ] && echo "[ERROR] Failed to copy kingbase.conf from $kb_data to $kb_etc" && exit 1
    echo "[INSTALL] copy $kb_data/kingbase.conf to ${kb_etc} ... OK"

    # start up the primary database
    echo "[INSTALL] start up the database on \"${primary_host}\" ..."
    echo "[INSTALL] sys_ctl -D $kb_data start -w -t 90 -l $log_path/kingbase.log"
    execute_command ${cluster_user} ${primary_host} "${kb_bin}/sys_ctl -D $kb_data start -w -t 90 -l $log_path/kingbase.log"
    [ $? -ne 0 ] && exit 1
    echo "[INSTALL] start up the database on \"${primary_host}\" ... OK"

    # clone slave host
    echo "[INSTALL] clone and start up the slave ..."
    for ip in ${all_node_ip[@]}
    do
        [ "$ip"x = "${primary_host}"x ] && continue
        echo "[INSTALL] Basebackup the slave on \"${ip}\" ..."
        echo "[INSTALL] ${kb_bin}/sys_basebackup -h ${primary_host} -U ${db_user} -W '*****' -p ${db_port} -D $kb_data -F p -X stream"
        execute_command ${cluster_user} ${ip} "${kb_bin}/sys_basebackup -h ${primary_host} -U ${db_user} -W '${db_password}' -p ${db_port} -D $kb_data -F p -X stream"
        [ $? -ne 0 ] && echo "[ERROR] Failed to basebackup the slave on $ip" && exit 1
        echo "[INSTALL] Basebackup the slave on \"${ip}\" ... OK"

        echo "[INSTALL] Copy ${kb_etc}/recovery.done to ${kb_data}/recovery.conf on $ip"
        execute_command ${cluster_user} ${ip} "cp ${kb_etc}/recovery.done ${kb_data} && mv ${kb_data}/recovery.done ${kb_data}/recovery.conf"
        [ $? -ne 0 ] && echo "[ERROR] Failed to copy ${kb_etc}/recovery.done to ${kb_data}/recovery.conf on $ip" && exit 1
        echo "[INSTALL] Copy ${kb_etc}/recovery.done to ${kb_data}/recovery.conf on $ip ... OK"

        echo "[INSTALL] Copy $kb_data/kingbase.conf to ${kb_etc}/ on $ip"
        execute_command ${cluster_user} ${ip} "cp $kb_data/kingbase.conf ${kb_etc}"
        [ $? -ne 0 ] && echo "[ERROR] Failed to copy $kb_data/kingbase.conf to ${kb_etc} on $ip" && exit 1
        echo "[INSTALL] Copy $kb_data/kingbase.conf to ${kb_etc} on $ip ... OK"

        echo "[INSTALL] start up the slave on \"${ip}\" ..."
        echo "[INSTALL] ${kb_bin}/sys_ctl -w -t 60 -l ${cluster_path}/logfile -D ${kb_data} start"
        execute_command ${cluster_user} ${ip} "${kb_bin}/sys_ctl -w -t 60 -l ${cluster_path}/logfile -D ${kb_data} start"
        [ $? -ne 0 ] && echo "[ERROR] Failed to start up the slave on $ip" && exit 1
        echo "[INSTALL] start up the slave on \"${ip}\" ... OK"
    done

    for ip in ${all_node_ip[@]}
    do
        for((i=1;i<=$node_num;i++))
        do
            echo "[INSTALL] Create physical_replication_slot on $ip"
            local SQL="select sys_create_physical_replication_slot('slot_node${i}');"
            execute_command ${cluster_user} ${ip} "${kb_bin}/ksql -h $ip -U ${db_user} -W '${db_password}' -d TEST -p ${db_port} -c \"$SQL\""
            [ $? -ne 0 ] && echo "[ERROR] Failed to create slot \"node${i}\" on $ip" && exit 1
            echo "[INSTALL] Create physical_replication_slot on $ip ... OK"
        done
    done

    # start up the cluster
    echo "[INSTALL] start up the whole cluster ..."
    execute_command ${cluster_user} ${all_node_ip[-2]} "${kb_bin}/kingbase_monitor.sh restart"
    [ $? -ne 0 ] && exit 1
    echo "[INSTALL] start up the whole cluster ... OK"
}
main
exit 0

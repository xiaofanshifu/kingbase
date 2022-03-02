#!/bin/bash

# you should change two parameters: general_user and all_ip
# general_user is the general user which you want to config SSH password free
# all_ip is the devices that you want to config SSH password free

shell_folder=$(dirname $(readlink -f "$0"))
install_conf="${shell_folder}/install.conf"
primary_host=""

curren_user=`whoami`

if [ -f $install_conf ]
then
    source $install_conf
else
    echo "[ERROR] there is no [install.conf] found in current path"
    exit 1
fi

general_user=$cluster_user
[ "${ssh_port}"x = ""x ] && ssh_port=22
[ "${all_node_ip}"x = ""x ] && echo "[ERROR] [all_node_ip] is empty, please check your [install.conf] file" && exit 1
[ "${general_user}"x = ""x ] && general_user="kingbase"

[ "${primary_host}"x = ""x ] && primary_host="${all_node_ip[0]}"

if [ "$curren_user"x != "root"x ]
then
    echo "must use root to execute"
    exit 1;
fi

[ ! -d /home/$general_user ] && /usr/sbin/adduser $general_user
echo "$general_user:123" | chpasswd
[ ! -f /home/$general_user/.ssh ] && mkdir -p /home/$general_user/.ssh

[ ! -f ~/.ssh/id_rsa.pub ] && ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa
[ ! -f  ~/.ssh/authorized_keys ] && cat ~/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

cp /root/.ssh/* /home/$general_user/.ssh

for ips in ${all_node_ip[@]}
do
    [ "${primary_host}"x != ""x -a "${primary_host}"x = "${ips}"x ] && continue
    ssh -p ${ssh_port} root@$ips "test ! -f ~/.ssh/id_rsa.pub" && ssh -p ${ssh_port} root@$ips "ssh-keygen -t rsa -P \"\" -f /root/.ssh/id_rsa"
    scp -P ${ssh_port} -o StrictHostKeyChecking=no -r /root/.ssh/* root@$ips:/root/.ssh/
    ssh -p ${ssh_port} root@$ips "test ! -d /home/$general_user" && ssh -p ${ssh_port} root@$ips "/usr/sbin/adduser $general_user" && ssh -p ${ssh_port} root@$ips "echo \"$general_user:123\" | chpasswd"
done

for ips in ${all_node_ip[@]}
do
    ssh -p ${ssh_port} root@$ips "cp -r /root/.ssh /home/$general_user/"
    ssh -p ${ssh_port} root@$ips "chmod 700 /home/$general_user/.ssh/"
    ssh -p ${ssh_port} root@$ips "chown -R $general_user:$general_user /home/$general_user/.ssh/"
done

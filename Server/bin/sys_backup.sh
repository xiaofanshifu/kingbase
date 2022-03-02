#!/bin/bash
#file : sys_backup.sh
#set -x


# find sys_backup.conf file
script_locate_folder=$(dirname $(readlink -f "$0"))
if [ ! -f "${script_locate_folder}/sys_backup.conf" ] && [ ! -f "${script_locate_folder}/../share/sys_backup.conf" ] ; then
	echo "ERROR: sys_backup.conf does not exist"
	exit 1
fi
if [ -f "${script_locate_folder}/sys_backup.conf" ] ; then
	source "${script_locate_folder}/sys_backup.conf" 2>/dev/null
	if [ "X0" != "X$?" ] ; then
		echo "ERROR: ${script_locate_folder}/sys_backup.conf invalid."
	fi
else 
	source "${script_locate_folder}/../share/sys_backup.conf" 2>/dev/null
	if [ "X0" != "X$?" ] ; then
		echo "ERROR: ${script_locate_folder}/../share/sys_backup.conf invalid."
	fi
fi
# check some input variable firstly
ip_str_express_regex="^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])$"
echo ${_repo_ip} | ${_os_grep_cmd} -E ${ip_str_express_regex} >/dev/null
if [ "X0" == "X$?" ] ; then
	# echo "Valid IP String"
	${_os_ip_cmd} addr list | ${_os_grep_cmd} -- "${_repo_ip}/" >/dev/null 2>/dev/null
	if [ "X0" != "X$?" ] ; then
		echo "ERROR: repo_ip must located in local, and sys_backup.sh be executed at REPO host."
		exit 7
	fi
fi

# local function 
_ssh_cmd_="ssh -n -o ConnectTimeout=30 -o StrictHostKeyChecking=no -o PreferredAuthentications=publickey -- "
function _log () {
	echo "$*" >> /tmp/sys_backup.sh.log
} # end of _log
function _gene_ssh_pwd_less() {
	_ip="${1}"
	_user="${2}"
	# 1. check whether pwd-less work
	ssh -t -o ConnectTimeout=30 -o PreferredAuthentications=publickey ${_user}@${_ip} date 1>/dev/null 2>/dev/null
	_local2remote_rt=$?
	ssh -t -o ConnectTimeout=30 -o PreferredAuthentications=publickey ${_user}@${_ip} "ssh ${_user}@${_repo_ip} date>/dev/null 2>/dev/null" 2>/dev/null
	_remote2local_rt=$?
	if [ "X0" == "X${_local2remote_rt}" ] && [ "X0" == "X${_remote2local_rt}" ] ; then
		_log "local -> ${_user}@${_ip} ssh pwd-less OK."
		return 0
	fi
	# 2. if cannot, try to config pwd-less
	# if exist, does not keygen
	if [ ! -f ${HOME}/.ssh/id_rsa.pub ] ; then
		echo -e "\ny" | ssh-keygen -t rsa -N "" >/tmp/ssh-keygen.log 2>&1
		if [ "X0" != "X$?" ] ; then
			_log "ERROR: local ssh-keygen fail,please check /tmp/ssh-keygen.log"
			echo "ERROR: local ssh-keygen fail,please check /tmp/ssh-keygen.log"
			return 0
		fi
	fi
	_t_buf_pub=`cat ${HOME}/.ssh/id_rsa.pub 2>/dev/null`
	# 3. user input password only once
	echo "Please input password ..."
	# set local.pub to remote, get remote.pub to local
	_remote_pub_buf=` ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=30 -o PreferredAuthentications=password -- ${_user}@${_ip} \
		"if [ ! -f \\${HOME}/.ssh/id_rsa.pub ] ; then echo -e '\ny' | ssh-keygen -t rsa -N '' >/dev/null 2>/dev/null ; fi;echo ${_t_buf_pub} >> \\${HOME}/.ssh/authorized_keys;chmod 600 \\${HOME}/.ssh/authorized_keys;cat  \\${HOME}/.ssh/id_rsa.pub;" `
	echo "${_remote_pub_buf}" >> ${HOME}/.ssh/authorized_keys
	chmod 600 ${HOME}/.ssh/authorized_keys
	# 4. check two-way again
	${_ssh_cmd_} ${_user}@${_ip} date 1>/dev/null 2>/dev/null
	if [ "X0" == "X$?" ] ; then
		_log "local <-> ${_user}@${_ip} ssh pwd-less OK."
		echo -e "\nlocal <-> ${_user}@${_ip} ssh pwd-less OK."
	fi
} # end of _gene_ssh_pwd_less
function _make_sure_same_via_ips {
	_t_db_ip="$1"
	_t_repo_ip="$2"
	if [ "X${_t_db_ip}" == "X${_t_repo_ip}" ] ; then
		return 0
	fi

	_gene_ssh_pwd_less ${_t_db_ip} ${_os_user_name}
	_t_repo_hostid=` ${_os_ip_cmd} addr | ${_os_grep_cmd} 'ether ' | head -n 1 | awk '{print $2}' `
	_t_db_hostid=`${_ssh_cmd_} ${_os_user_name}@${_t_db_ip} "${_os_ip_cmd} addr | ${_os_grep_cmd} 'ether ' | head -n 1 | awk '{print \\$2}'" `
	_log "_make_sure_same_via_ips [${_t_db_ip}][${_t_repo_hostid}] vs [${_t_repo_ip}][${_t_db_hostid}]"	
	if [ "X${_t_repo_hostid}" == "X${_t_db_hostid}" ] ; then
		return 0
	fi
	return 1
} # end of _make_sure_same_via_ips 


#########################################################################################################
if [ "Xsingle" == "X${_target_db_style}" ] ; then
# global variable
_target_crond_file="/etc/cron.d/KINGBASECRON"		
_db_dir="${_single_data_dir}"
_etc_dir="${_single_data_dir}/../etc"
_bin_dir="${_single_bin_dir}"
_rman_bin="${_bin_dir}/sys_rman_v6"
_rman_conf_file="${_repo_path}/sys_rman_v6.conf"
_self_ip="${_one_db_ip}"
_self_user="${_single_db_user}"
_self_port="${_single_db_port}"

#########################################################################################################
# end of single
else
# init step via HAmodule.conf 
_log "sys_backup.sh begin at `date +%Y%m%d%H%M%S`"
[ "${hamodule_conf}"x = ""x ] && hamodule_conf="${script_locate_folder}/../etc/HAmodule.conf"
_make_sure_same_via_ips ${_one_db_ip} ${_repo_ip} ; _return_rt=$?
if [ "X0" == "X${_return_rt}" ] ; then
	if [ ! -f $hamodule_conf ] ;  then
		echo "ERROR: config file '${hamodule_conf}' does not exist"
		exit 1
	fi
	source ${hamodule_conf}
	if [ "X" == "X${KB_DATA_PATH}" ] ; then echo "ERROR: '${hamodule_conf}' at '${_one_db_ip}' invalid"; fi
else # end of repo-host == db-host
	# check user is KINGBASE
	if [ "X${_os_user_name}" != "X${USER}" ] ; then
		echo "ERROR: sys_backup.sh init must be executed by db-specify user '${_os_user_name}'"
		exit 5
	fi
	# ss-h pwd-less _repo_ip -> _one_db_ip
	_gene_ssh_pwd_less ${_one_db_ip} ${_os_user_name}
	# eval to remote HAmodule.conf
	empty_comment_lines_express_regex="\"^$|#\""
	eval `${_ssh_cmd_} ${_os_user_name}@${_one_db_ip} "${_os_grep_cmd} -E --invert-match ${empty_comment_lines_express_regex} ${hamodule_conf}" 2>/dev/null`
	if [ "X" == "X${KB_DATA_PATH}" ] ; then echo "ERROR: '${hamodule_conf}' at '${_one_db_ip}' invalid"; fi
fi # end of repo-host != db-host
_log "[${script_locate_folder}] -> [${hamodule_conf}]"

# global variable
_target_crond_file="/etc/cron.d/KINGBASECRON"		
_db_dir="${KB_DATA_PATH}"
_etc_dir="${KB_ETC_PATH}"
_bin_dir="${KB_PATH}"
_rman_bin="${KB_PATH}/sys_rman_v6"
_rman_conf_file="${_repo_path}/sys_rman_v6.conf"
#_self_conn_info="${conninfo}"
#set -e
# example: conninfo='host=192.168.28.37 user=esrep dbname=esrep port=54321 cQnnect_timeout=10'
#_self_ip=`   echo ${_self_conn_info} | ${_os_sed_cmd} -e 's/.*host=\([^ ]*\) .*/\1/' `
#_self_user=` echo ${_self_conn_info} | ${_os_sed_cmd} -e 's/.*user=\([^ ]*\) .*/\1/' `
#_self_port=` echo ${_self_conn_info} | ${_os_sed_cmd} -e 's/.*port=\([^ ]*\) .*/\1/' `
#########################################################################################################
fi
# end of cluster

function func_single_init() 
{
# ssh to repot root for CRONTAB
_gene_ssh_pwd_less ${_repo_ip} root
echo -n "# generate single sys_rman_v6.conf..."
echo "# Genarate by script at `date +%Y%m%d%H%M%S`, should not change manually" > ${_rman_conf_file}
echo "[${_stanza_name}]" >> ${_rman_conf_file}
echo "kb1-path=${_db_dir}" >> ${_rman_conf_file}
echo "kb1-port=${_self_port}" >> ${_rman_conf_file}
echo "kb1-user=${_self_user}" >> ${_rman_conf_file}
echo "kb1-pass=${_kb_pass}" >> ${_rman_conf_file}
_make_sure_same_via_ips ${_one_db_ip} ${_repo_ip} ; _same_host_rt=$?
if [ "X0" == "X${_same_host_rt}" ] ; then 
	_log "ignore ${_one_db_ip}"
else 
	# _list_other_ip="${_list_other_ip} ${_one_ip}"
	echo "kb1-host=${_one_db_ip}" >> ${_rman_conf_file}
	echo "kb1-host-user=${_os_user_name}" >> ${_rman_conf_file}
fi
echo "" >> ${_rman_conf_file}
echo "[global]" >> ${_rman_conf_file}
echo "repo1-path=${_repo_path}" >> ${_rman_conf_file}
echo "repo1-retention-full=${_repo_retention_full_count}" >> ${_rman_conf_file}
echo "log-path=/tmp/" >> ${_rman_conf_file}
echo "log-level-file=info" >> ${_rman_conf_file}
echo "log-level-console=info" >> ${_rman_conf_file}
echo "log-subprocess=y" >> ${_rman_conf_file}
echo "process-max=4" >> ${_rman_conf_file}
echo "#### default gz, support: gz none" >> ${_rman_conf_file}
echo "compress-type=gz" >> ${_rman_conf_file}
echo "compress-level=3" >> ${_rman_conf_file}
echo "DONE"

# if diff host, generate remote sys_rman_v6.conf on db host
if [ "X0" != "X${_same_host_rt}" ] ; then 
	# check repo_path access-able
	${_ssh_cmd_} ${_os_user_name}@${_one_db_ip} mkdir -p "${_repo_path}/"
	if [ "X0" != "X$?" ] ; then
		echo -e "\nERROR: at ${_one_db_ip}, user '${_os_user_name}' can not access the repo-path [${_repo_path}]."
		exit 1
	fi
	${_ssh_cmd_} ${_os_user_name}@${_one_db_ip} \
		"echo -e \"# Genarate by script at `date +%Y%m%d%H%M%S`, should not change manually\n[${_stanza_name}]\nkb1-path=${_db_dir}\n[global]\nrepo1-host=${_repo_ip}\nrepo1-host-user=${_os_user_name}\nrepo1-host-config=${_rman_conf_file}\nrepo1-path=${_repo_path}\" > ${_rman_conf_file}" 
fi

echo "# update single archive_command with sys_rman_v6.archive-push...DONE"
# change archive_command at local host
# if diff host, generate remote sys_rman_v6.conf on db host
if [ "X0" == "X${_same_host_rt}" ] ; then 
	${_os_sed_cmd} -i -e "s/archive_command.*/archive_command='${_rman_bin//\//\\/} --config ${_rman_conf_file//\//\\/} --stanza=${_stanza_name} archive-push %p'/" ${_db_dir}/kingbase.conf >/dev/null 2>/dev/null
	${_os_sed_cmd} -i -e "s/archive_command.*/archive_command='${_rman_bin//\//\\/} --config ${_rman_conf_file//\//\\/} --stanza=${_stanza_name} archive-push %p'/" ${_etc_dir}/kingbase.conf >/dev/null 2>/dev/null
	${_bin_dir}/sys_ctl -D ${_db_dir} reload >/dev/null 2>/dev/null
else
	${_ssh_cmd_} ${_os_user_name}@${_one_db_ip} \
		"${_os_sed_cmd} -i \"s/archive_command.*/archive_command='${_rman_bin//\//\\/} --config ${_rman_conf_file//\//\\/} --stanza=${_stanza_name} archive-push %p'/\" ${_db_dir}/kingbase.conf" >/dev/null 2>/dev/null
	${_ssh_cmd_} ${_os_user_name}@${_one_db_ip} \
		"${_os_sed_cmd} -i \"s/archive_command.*/archive_command='${_rman_bin//\//\\/} --config ${_rman_conf_file//\//\\/} --stanza=${_stanza_name} archive-push %p'/\" ${_etc_dir}/kingbase.conf" >/dev/null 2>/dev/null
	${_ssh_cmd_} ${_os_user_name}@${_one_db_ip} ${_bin_dir}/sys_ctl -D ${_db_dir} reload >/dev/null 2>/dev/null
fi

echo "# create stanza and check...(maybe 60+ seconds)"
${_os_rm_cmd} -rf "${_repo_path}/archive"
${_os_rm_cmd} -rf "${_repo_path}/backup"
${_rman_bin} --config=${_rman_conf_file} --stanza=${_stanza_name} --log-level-console=info stanza-create >>/tmp/sys_rman_v6_stanza-create.log 2>&1
if [ "X0" != "X$?" ] ; then
	echo "ERROR: create stanza failed, check log file /tmp/sys_rman_v6_stanza-create.log"
	exit 2
fi
${_rman_bin} --config=${_rman_conf_file} --stanza=${_stanza_name} --log-level-console=info check >>/tmp/sys_rman_v6_check.log 2>&1
if [ "X0" != "X$?" ] ; then
	echo "ERROR: check stanza failed, check log file /tmp/sys_rman_v6_check.log"
	exit 3
fi
echo "# create stanza and check...DONE"

echo "# initial first full backup...(maybe several minutes)"
${_rman_bin} --config=${_rman_conf_file} --stanza=${_stanza_name} --log-level-console=info --archive-copy --type=full backup >>/tmp/sys_rman_v6_backup.log 2>&1
if [ "X0" != "X$?" ] ; then
	echo "ERROR: full backup failed, check log file /tmp/sys_rman_v6_backup.log"
	exit 4
fi
echo "# initial first full backup...DONE"

echo "# Initial sys_rman_v6 OK."
echo "'sys_backup.sh start' should be executed when need back-rest feature."

} # end of function single init
function func_cluster_init() 
{
# ssh to repot root for CRONTAB
_gene_ssh_pwd_less ${_repo_ip} root

# get other node info
_list_other_ip="" # all db ip excluding the repo ip
_repo_within_db=0
for _one_kbip in ${KB_ALL_IP[@]}
do
	_make_sure_same_via_ips ${_one_kbip} ${_repo_ip} ; _return_rt=$?
	if [ "X0" == "X${_return_rt}" ] ; then
		_repo_within_db=1
	else
		_list_other_ip="${_list_other_ip} ${_one_kbip}"
	fi
done

_list_db_ip="" # all db ip and put _repo_ip first if it's in db ips
if [ ${_repo_within_db} -eq 1 ] ; then
	_list_db_ip="${_repo_ip} ${_list_other_ip}"
else
	_list_db_ip="${_list_other_ip}"
fi

# log these IPs for debug
_log "[func_cluster_init] all db ip and put _repo_ip first if it's in db ips"
for _one_ip in ${_list_db_ip} ; do _log "${_one_ip}" ; done
_log "[func_cluster_init] all db ip excluding the repo ip"
for _one_ip in ${_list_other_ip} ; do _log "${_one_ip}" ; done

_kb_index="1";

# generate local host sys_rman_v6.conf
echo -n "# generate local sys_rman_v6.conf..."
echo "# Genarate by script at `date +%Y%m%d%H%M%S`, should not change manually" > ${_rman_conf_file}
echo "[${_stanza_name}]" >> ${_rman_conf_file}

for _one_ip in ${_list_db_ip}
do
	_log "[func_cluster_init] processing ${_one_ip} for ${_rman_conf_file}" 
	_one_user=${KB_USER}
	_one_port=${KB_PORT}
	echo "kb${_kb_index}-path=${_db_dir}" >> ${_rman_conf_file}
	echo "kb${_kb_index}-port=${_one_port}" >> ${_rman_conf_file}
	echo "kb${_kb_index}-user=${_one_user}" >> ${_rman_conf_file}
        echo "kb${_kb_index}-pass=${_kb_pass}" >> ${_rman_conf_file}
	_make_sure_same_via_ips ${_one_ip} ${_repo_ip} ; _return_rt=$?
	if [ "X0" == "X${_return_rt}" ] ; then 
		_log "[func_cluster_init] ignore ${_one_ip}"
	else 
		echo "kb${_kb_index}-host=${_one_ip}" >> ${_rman_conf_file}
		echo "kb${_kb_index}-host-user=${_os_user_name}" >> ${_rman_conf_file}
	fi
	# next kb index
	_kb_index=$(( _kb_index + 1 )) 
done

echo "" >> ${_rman_conf_file}
echo "[global]" >> ${_rman_conf_file}
echo "repo1-path=${_repo_path}" >> ${_rman_conf_file}
echo "repo1-retention-full=${_repo_retention_full_count}" >> ${_rman_conf_file}
echo "log-path=/tmp/" >> ${_rman_conf_file}
echo "log-level-file=info" >> ${_rman_conf_file}
echo "log-level-console=info" >> ${_rman_conf_file}
echo "log-subprocess=y" >> ${_rman_conf_file}
echo "process-max=4" >> ${_rman_conf_file}
echo "#### default gz, support: gz none" >> ${_rman_conf_file}
echo "compress-type=gz" >> ${_rman_conf_file}
echo "compress-level=3" >> ${_rman_conf_file}
echo "DONE"

echo "# update all node: sys_rman_v6.conf and archive_command with sys_rman_v6.archive-push..."
# change archive_command at local host
${_os_sed_cmd} -i -e "s/#archive_command.*/archive_command='${_rman_bin//\//\\/} --config ${_rman_conf_file//\//\\/} --stanza=${_stanza_name} archive-push %p'/" ${_db_dir}/kingbase.conf >/dev/null 2>/dev/null
${_os_sed_cmd} -i -e "s/archive_dest=/#archive_dest=/" ${_db_dir}/kingbase.conf >/dev/null 2>/dev/null
${_os_sed_cmd} -i -e "s/#archive_command.*/archive_command='${_rman_bin//\//\\/} --config ${_rman_conf_file//\//\\/} --stanza=${_stanza_name} archive-push %p'/" ${_etc_dir}/kingbase.conf >/dev/null 2>/dev/null
${_os_sed_cmd} -i -e "s/archive_dest=/#archive_dest=/" ${_etc_dir}/kingbase.conf >/dev/null 2>/dev/null
${_bin_dir}/sys_ctl -D ${_db_dir} reload >/dev/null 2>/dev/null
# generate other node sys_rman_v6.conf
for _one_other_ip in ${_list_other_ip}
do
	# echo "one [${_one_other_ip}]"
	# generate ssh pwd-less
	_gene_ssh_pwd_less ${_one_other_ip} ${_os_user_name}
	# check repo_path access-able
	${_ssh_cmd_} ${_os_user_name}@${_one_other_ip} mkdir -p "${_repo_path}/"
	if [ "X0" != "X$?" ] ; then
		echo -e "\nERROR: at ${_one_other_ip}, user '${_os_user_name}' can not access the repo-path [${_repo_path}]."
		exit 1
	fi
	_t_tmp_file="${_repo_path}/`date +%s`"
	${_ssh_cmd_} ${_os_user_name}@${_one_other_ip} touch ${_t_tmp_file} >/dev/null 2>/dev/null
	if [ "X0" != "X$?" ] ; then
		echo -e "\nERROR: at ${_one_other_ip}, user '${_os_user_name}' can not access the repo-path [${_repo_path}]."
		${_ssh_cmd_} ${_os_user_name}@${_one_other_ip} ${_os_rm_cmd} -rf ${_t_tmp_file} >/dev/null 2>/dev/null
		exit 1
	fi
	${_ssh_cmd_} ${_os_user_name}@${_one_other_ip} ${_os_rm_cmd} -rf ${_t_tmp_file} >/dev/null 2>/dev/null

#[kbbr]
#kb1-path=/home/wim/kb_data
#[global]
#repo1-host=192.168.28.122
#repo1-host-user=wim
#repo1-host-config=/opt/kbbr_repo/sys_rman_v6.conf
#repo1-path=/opt/kbbr_repo
	# generate remote sys_rman_v6.conf
	${_ssh_cmd_} ${_os_user_name}@${_one_other_ip} \
		"echo -e \"# Genarate by script at `date +%Y%m%d%H%M%S`, should not change manually\n[${_stanza_name}]\nkb1-path=${_db_dir}\n[global]\nrepo1-host=${_repo_ip}\nrepo1-host-user=${_os_user_name}\nrepo1-host-config=${_rman_conf_file}\nrepo1-path=${_repo_path}\" > ${_rman_conf_file}" 
	# change archive_command
	${_ssh_cmd_} ${_os_user_name}@${_one_other_ip} \
		"${_os_sed_cmd} -i \"s/#archive_command.*/archive_command='${_rman_bin//\//\\/} --config ${_rman_conf_file//\//\\/} --stanza=${_stanza_name} archive-push %p'/\" ${_db_dir}/kingbase.conf" >/dev/null 2>/dev/null
	${_ssh_cmd_} ${_os_user_name}@${_one_other_ip} \
		"${_os_sed_cmd} -i \"s/archive_dest=/#archive_dest=/\" ${_db_dir}/kingbase.conf" >/dev/null 2>/dev/null
	${_ssh_cmd_} ${_os_user_name}@${_one_other_ip} \
		"${_os_sed_cmd} -i \"s/#archive_command.*/archive_command='${_rman_bin//\//\\/} --config ${_rman_conf_file//\//\\/} --stanza=${_stanza_name} archive-push %p'/\" ${_etc_dir}/kingbase.conf" >/dev/null 2>/dev/null
	${_ssh_cmd_} ${_os_user_name}@${_one_other_ip} \
		"${_os_sed_cmd} -i \"s/archive_dest=/#archive_dest=/\" ${_etc_dir}/kingbase.conf" >/dev/null 2>/dev/null
	${_ssh_cmd_} ${_os_user_name}@${_one_other_ip} ${_bin_dir}/sys_ctl -D ${_db_dir} reload >/dev/null 2>/dev/null
done

echo "# update all node: sys_rman_v6.conf and archive_command with sys_rman_v6.archive-push...DONE"

echo "# create stanza and check...(maybe 60+ seconds)"
${_os_rm_cmd} -rf "${_repo_path}/archive"
${_os_rm_cmd} -rf "${_repo_path}/backup"
${_rman_bin} --config=${_rman_conf_file} --stanza=${_stanza_name} --log-level-console=info stanza-create >>/tmp/sys_rman_v6_stanza-create.log 2>&1
if [ "X0" != "X$?" ] ; then
	echo "ERROR: create stanza failed, check log file /tmp/sys_rman_v6_stanza-create.log"
	exit 2
fi
${_rman_bin} --config=${_rman_conf_file} --stanza=${_stanza_name} --log-level-console=info check >>/tmp/sys_rman_v6_check.log 2>&1
if [ "X0" != "X$?" ] ; then
	echo "ERROR: check stanza failed, check log file /tmp/sys_rman_v6_check.log"
	exit 3
fi
echo "# create stanza and check...DONE"

echo "# initial first full backup...(maybe several minutes)"
${_rman_bin} --config=${_rman_conf_file} --stanza=${_stanza_name} --log-level-console=info --archive-copy --type=full backup >>/tmp/sys_rman_v6_backup.log 2>&1
if [ "X0" != "X$?" ] ; then
	echo "ERROR: full backup failed, check log file /tmp/sys_rman_v6_backup.log"
	exit 4
fi
echo "# initial first full backup...DONE"

echo "# Initial sys_rman_v6 OK."
echo "'sys_backup.sh start' should be executed when need back-rest feature."

} # end of function cluster init

function func_start()
{
	echo "Enable some sys_rman_v6 in crontab-daemon"

	# valid number > 0
	_cmd="${_os_sed_cmd} -i '/sys_rman_v6 --config.*--type=full backup/d' ${_target_crond_file}"
	${_ssh_cmd_} root@${_repo_ip} ${_cmd}
	if [ "${_crond_full_days}" -gt "0" ] && [ "${_crond_full_hour}" -ge "0" ] ; then
		echo "Set full-backup in ${_crond_full_days} days"
		_cmd="echo \"0 ${_crond_full_hour} */${_crond_full_days} * * ${_os_user_name} ${_rman_bin} --config=${_rman_conf_file} --stanza=${_stanza_name} --archive-copy --type=full backup >>/tmp/sys_rman_v6_backup_full.log 2>&1\"	>> ${_target_crond_file}"
		${_ssh_cmd_} root@${_repo_ip} "${_cmd}"
	fi
	_cmd="${_os_sed_cmd} -i '/sys_rman_v6 --config.*--type=diff backup/d' ${_target_crond_file}"
	${_ssh_cmd_} root@${_repo_ip} ${_cmd}
	if [ "${_crond_diff_days}" -gt "0" ] && [ "${_crond_diff_hour}" -ge "0" ] ; then
		echo "Set diff-backup in ${_crond_diff_days} days"
		_cmd="echo \"0 ${_crond_diff_hour} */${_crond_diff_days} * * ${_os_user_name} ${_rman_bin} --config=${_rman_conf_file} --stanza=${_stanza_name} --archive-copy --type=diff backup >>/tmp/sys_rman_v6_backup_diff.log 2>&1\"	>> ${_target_crond_file}"
		${_ssh_cmd_} root@${_repo_ip} "${_cmd}"
	fi
	_cmd="${_os_sed_cmd} -i '/sys_rman_v6 --config.*--type=incr backup/d' ${_target_crond_file}"
	${_ssh_cmd_} root@${_repo_ip} ${_cmd}
	if [ "${_crond_incr_days}" -gt "0" ] && [ "${_crond_incr_hour}" -ge "0" ] ; then
		echo "Set incr-backup in ${_crond_incr_days} days"
		_cmd="echo \"0 ${_crond_incr_hour} */${_crond_incr_days} * * ${_os_user_name} ${_rman_bin} --config=${_rman_conf_file} --stanza=${_stanza_name} --archive-copy --type=incr backup >>/tmp/sys_rman_v6_backup_incr.log 2>&1\"	>> ${_target_crond_file}"
		${_ssh_cmd_} root@${_repo_ip} "${_cmd}"
	fi
	${_os_grep_cmd} 'sys_rman_v6' ${_target_crond_file}

} # end of function start
function func_stop()
{
	echo "Disable all sys_rman_v6 in crontab-daemon"
	_cmd="${_os_sed_cmd} -i '/sys_rman_v6 --config.*--type=full backup/d' ${_target_crond_file}"
	${_ssh_cmd_} root@${_repo_ip} ${_cmd}
	_cmd="${_os_sed_cmd} -i '/sys_rman_v6 --config.*--type=diff backup/d' ${_target_crond_file}"
	${_ssh_cmd_} root@${_repo_ip} ${_cmd}
	_cmd="${_os_sed_cmd} -i '/sys_rman_v6 --config.*--type=incr backup/d' ${_target_crond_file}"
	${_ssh_cmd_} root@${_repo_ip} ${_cmd}
} # end of function stop
function func_pause()
{
	echo "Puase the sys_rman_v6...DONE"
	${_rman_bin} --config=${_rman_conf_file} --stanza=${_stanza_name} stop >>/tmp/sys_rman_v6_backup.log 2>&1
} # end of function pause
function func_unpause()
{
	echo "Un-Puase the sys_rman_v6...DONE"
	${_rman_bin} --config=${_rman_conf_file} --stanza=${_stanza_name} start >>/tmp/sys_rman_v6_backup.log 2>&1
} # end of function unpause
function _func_check_valid_argument()
{

	# single/cluster
	if [ "Xsingle" != "X${_target_db_style}" ] && [ "Xcluster" != "X${_target_db_style}" ] ; then
		echo "ERROR: Configured target_db_style must be single or cluster"
		exit 1
	fi
	# check _repo_path
	mkdir -p "${_repo_path}/"
	if [ "X0" != "X$?" ] ; then
		echo "ERROR: Configured repo-path [${_repo_path}] be NOT accessable by current user"
		exit 1
	fi

	_t_tmp_file="${_repo_path}/`date +%s`"
	touch ${_t_tmp_file} >/dev/null 2>/dev/null
	if [ "X0" != "X$?" ] ; then
		echo "ERROR: Configured repo-path [${_repo_path}] be NOT accessable by current user"
		${_os_rm_cmd} -rf ${_t_tmp_file} >/dev/null 2>/dev/null
		exit 1
	fi
	${_os_rm_cmd} -rf ${_t_tmp_file} >/dev/null 2>/dev/null


	# check _repo_retention_full_count
	if [ "${_repo_retention_full_count}" -ge "1" ] 2>/dev/null && [ "${_repo_retention_full_count}" -le "999999" ] ; then 
		echo "OK" >/dev/null
	else
		echo "ERROR: Configured repo-retention-full invalid."
		exit 1	
	fi

	# check crond number 
	if ! [ "${_crond_full_days}" -ge "0" ] 2>/dev/null ; then 
		echo "ERROR: Configured crond-full-days invalid."
		exit 1
	fi
	if ! [ "${_crond_diff_days}" -ge "0" ] 2>/dev/null ; then 
		echo "ERROR: Configured crond-diff-days invalid."
		exit 1
	fi
	if ! [ "${_crond_incr_days}" -ge "0" ] 2>/dev/null ; then 
		echo "ERROR: Configured crond-incr-days invalid."
		exit 1
	fi
	if ! [ "${_crond_full_hour}" -ge "0" ] 2>/dev/null ; then 
		echo "ERROR: Configured crond-full-hour invalid."
		exit 1
	fi
	if ! [ "${_crond_diff_hour}" -ge "0" ] 2>/dev/null ; then 
		echo "ERROR: Configured crond-diff-hour invalid."
		exit 1
	fi
	if ! [ "${_crond_incr_hour}" -ge "0" ] 2>/dev/null ; then 
		echo "ERROR: Configured crond-incr-hour invalid."
		exit 1
	fi
} # end of function _func_check_valid_argument

# main process of script

if [ "1" != "$#"  ] ; then
	echo "Usage: sys_backup.sh {init|start|stop|pause|unpause}"
	exit 1
fi

# check input argument valid
_func_check_valid_argument

if [ "Xinit" == "X$1" ]  ; then 
	# check user is KINGBASE
	if [ "X${_os_user_name}" != "X${USER}" ] ; then
		echo "ERROR: sys_backup.sh init must be executed by db-specify user"
		exit 5
	fi
	if [ "Xsingle" == "X${_target_db_style}" ] ; then
		func_single_init; 
	else
		func_cluster_init; 
	fi
elif [ "Xstart" == "X$1" ]  ; then 
	if [ ! -f "${_rman_conf_file}" ] ; then
		echo "ERROR: sys_backup.sh init must executed firstly"
		exit 5
	fi
	# check user is KINGBASE
	if [ "X${_os_user_name}" != "X${USER}" ] ; then
		echo "ERROR: sys_backup.sh start must be executed by db-specify user"
		exit 5
	fi
	func_start; 
elif [ "Xstop" == "X$1" ]  ; then 
	if [ ! -f "${_rman_conf_file}" ] ; then
		echo "ERROR: sys_backup.sh init must executed firstly"
		exit 5
	fi
	# check user is KINGBASE
	if [ "X${_os_user_name}" != "X${USER}" ] ; then
		echo "ERROR: sys_backup.sh stop must be executed by db-specify user"
		exit 5
	fi
	func_stop; 
elif [ "Xpause" == "X$1" ]  ; then 
	if [ ! -f "${_rman_conf_file}" ] ; then
		echo "ERROR: sys_backup.sh init must executed firstly"
		exit 5
	fi
	# check user is KINGBASE
	if [ "X${_os_user_name}" != "X${USER}" ] ; then
		echo "ERROR: sys_backup.sh pause must be executed by db-specify user"
		exit 5
	fi
	func_pause; 
elif [ "Xunpause" == "X$1" ]  ; then 
	if [ ! -f "${_rman_conf_file}" ] ; then
		echo "ERROR: sys_backup.sh init must executed firstly"
		exit 5
	fi
	# check user is KINGBASE
	if [ "X${_os_user_name}" != "X${USER}" ] ; then
		echo "ERROR: sys_backup.sh unpause must be executed by db-specify user"
		exit 5
	fi
	func_unpause; 
else 
	echo "Usage: sys_backup.sh {init|start|stop|pause|unpause}"
	echo "HINT: sys_backup.sh init must executed firstly"
	exit 1
fi

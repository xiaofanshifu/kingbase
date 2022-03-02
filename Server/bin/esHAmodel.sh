#!/bin/bash

. /etc/profile

SHELL_FOLDER=$(dirname $(readlink -f "$0"))

REAL_CRONTAB="/etc/cron.d/KINGBASECRON"


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

IS_ROOT=`whoami 2>/dev/null`
crontablist="*/1 * * * * root . /etc/profile;nohup $SHELL_FOLDER/es_server >> $SHELL_FOLDER/es_server.log 2>&1 &"
cronexist=`cat $REAL_CRONTAB 2>/dev/null| grep -wFn "${crontablist}" |wc -l`

start()
{
    if [ "$IS_ROOT"x = "root"x ]
    then
        if [ $cronexist -eq 1 ]
        then
            local realist=`cat $REAL_CRONTAB | grep -wFn "${crontablist}"`
            local linenum=`echo "$realist" |awk -F':' '{print $1}'`
            sed "${linenum}c */1 * * * * root . /etc/profile;nohup $SHELL_FOLDER/es_server >> $SHELL_FOLDER/es_server.log 2>&1 &" $REAL_CRONTAB > $SHELL_FOLDER/crontab.bak
            cat $SHELL_FOLDER/crontab.bak > $REAL_CRONTAB
        else
            echo "*/1 * * * * root . /etc/profile;nohup $SHELL_FOLDER/es_server >> $SHELL_FOLDER/es_server.log 2>&1 &" >> $REAL_CRONTAB
        fi
        service $CROND_NAME start
    fi
    local procexist=`ps -ef|grep ${SHELL_FOLDER}/es_server|grep -v grep| wc -l`
    if [ $procexist -eq 0 ]
    then
        nohup $SHELL_FOLDER/es_server >> $SHELL_FOLDER/es_server.log 2>&1 &
    fi
}

stop()
{
    if [ "$IS_ROOT"x = "root"x ]
    then
        if [ $cronexist -eq 1 ]
        then
            local realist=`cat $REAL_CRONTAB | grep -wFn "${crontablist}"`
            local linenum=`echo "$realist" |awk -F':' '{print $1}'`
            #sed -i "${linenum}c #*/1 * * * * root nohup $SHELL_FOLDER/es_server >> $SHELL_FOLDER/es_server.log 2>&1 &" $REAL_CRONTAB
            sed "${linenum}c #*/1 * * * * root . /etc/profile;nohup $SHELL_FOLDER/es_server >> $SHELL_FOLDER/es_server.log 2>&1 &" $REAL_CRONTAB > $SHELL_FOLDER/crontab.bak
            cat $SHELL_FOLDER/crontab.bak > $REAL_CRONTAB
        fi
    fi
    if [ -f "${SHELL_FOLDER}/es_server.pid" ]
    then
        local pid=`cat ${SHELL_FOLDER}/es_server.pid`
        if [ $pid -gt 0 ]
        then
            local pidexist=`readlink -f /proc/${pid}/exe | grep -w "${SHELL_FOLDER}/es_server" | wc -l`
            if [ $pidexist -eq 1 ]
            then
                kill -9 $pid
            fi
       fi
    fi
}

case "$1" in
start)
    start
    ;;
stop)
    stop
    ;;
restart)
    stop
    start
    ;;
*)
    echo "Usage: $0 start|stop|restart"
    exit 0;
esac

exit

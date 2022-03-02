#!/bin/bash
#source /home/kdb/KingbaseES/V8/kbrc
KB_PATH=$1
KB_USER=$2
KB_DATANAME=$3
KB_PORT=$4
KB_DATA_PATH=$5

KB_REAL_PASS=$6
HEALTH_CHECK_MAX_RETRIES=$7
HEALTH_CHECK_RETRY_DELAY=$8

export PATH=$KB_PATH:$PATH

#the function of error handing
function errorhandle()
{
    error_flag=$1
    error_cmd=$2
    if [ "${error_flag}"x = ""x ]
    then
        echo "errorhandle function's argument is null " 2>&1
        exit 66;
    fi
    if [ "${error_flag}"x = "exit"x ]
    then
        echo "${error_cmd}" 2>&1
        exit 66;
    else
        echo "${error_cmd}" 2>&1
    fi
}

echo "check db if is alive " 2>&1

db_alive=0
for((i=1;i<=$HEALTH_CHECK_MAX_RETRIES;i++))
do
#1. check db if down
    kingbase_pid=`cat ${KB_DATA_PATH}/kingbase.pid 2>/dev/null|head -n 1; echo ";" ${PIPESTATUS[*]}`
    result_of_kingbase_pid=`echo $kingbase_pid |awk -F ';' '{print $1}'|awk '{print $1}'`
    cmd_cat=`echo $kingbase_pid |awk -F ';' '{print $2}'|awk '{print $1}'`
    cmd_head=`echo $kingbase_pid |awk -F ';' '{print $2}'|awk '{print $2}'`

    if [ "${cmd_cat}"x != "0"x -o  "${cmd_head}"x != "0"x ]
    then
        echo "cat execute failed,will retry retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" 2>&1
        errorhandle "continue" "\"cat ${KB_DATA_PATH}/kingbase.pid 2>/dev/null|head -n 1 \" execute failed, error num=[$cmd_cat $cmd_head]"
        continue
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
            echo "ps execute failed,will retry retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" 2>&1
            errorhandle "continue" "\"ps -ef | grep -w $result_of_kingbase_pid | grep -v grep | wc -l\" execute failed, error num=[$cmd_ps $cmd_grep1 $cmd_grep2 $cmd_wc]"
            continue
        fi
        if [ "$result_of_kingbase_exist" -eq 0 ]
        then
            errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` CHECK The process was started before promote , but no pid was foud in system,, which db may have been turned off! exit"
        fi
    else
         errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` CHECK The process was started before promote , but no pid file was foud, which db may have been turned off! exit "
    fi

    echo "ksql \"port=$KB_PORT user=$KB_USER  dbname=$KB_DATANAME connect_timeout=10\"  -c \"select 33333;\" "
    result_of_ksql=`ksql "port=$KB_PORT user=$KB_USER  password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "select 33333;"`
    rightnum=`echo $result_of_ksql | grep 33333 | wc -l;echo ";" ${PIPESTATUS[*]}`
    result_of_rightnum=`echo $rightnum |awk -F ';' '{print $1}'|awk '{print $1}'`
    cmd_ksql=`echo $rightnum |awk -F ';' '{print $2}'|awk '{print $1}'`
    cmd_grep=`echo $rightnum |awk -F ';' '{print $2}'|awk '{print $2}'`
    cmd_wc=`echo $rightnum |awk -F ';' '{print $2}'|awk '{print $3}'`

    if [ "${cmd_ksql}"x != "0"x -o "${cmd_wc}"x != "0"x ]
    then
        echo "ksql execute failed,will retry retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" 2>&1
        errorhandle "continue" "\"ksql \"port=$KB_PORT user=$KB_USER dbname=$KB_DATANAME connect_timeout=10\"  -c \"select 33333;\" | grep 33333 | wc -l\" execute failed, query detail[$result_of_ksql] ,error num=[$cmd_ksql $cmd_grep $cmd_wc ]"
        continue
    fi
    if [ "$result_of_rightnum"x = "1"x ]
    then
        echo `date +'%Y-%m-%d %H:%M:%S'` kingbase is ok , to prepare execute promote 2>&1
        db_alive=1
        break
    else
        echo "kingbase is down,retry check db is if alive,retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" 2>&1
        echo before promote query detail[$result_of_ksql] , try again! 2>&1
        sleep $HEALTH_CHECK_RETRY_DELAY
    fi
done

if [ $db_alive -eq 0 ]
then
    echo "kingbase is down,after retry ${HEALTH_CHECK_MAX_RETRIES} times ,cannot do promote, will exit" 2>&1
    exit 66;
fi

#execute promote
echo "execute promote" 2>&1

sys_ctl promote -w -t 90 -D $KB_DATA_PATH 2>&1
result_of_promote=$?
if [ $result_of_promote -ne 0 ]
then
    echo "promote execute failed ,will exit " 2>&1
    exit 66
fi

echo "check db if is alive after promote " 2>&1
db_alive=0
for((i=1;i<=$HEALTH_CHECK_MAX_RETRIES;i++))
do
    #1. check db if down
    kingbase_pid=`cat ${KB_DATA_PATH}/kingbase.pid 2>/dev/null|head -n 1;echo ";" ${PIPESTATUS[*]}`
    result_of_kingbase_pid=`echo $kingbase_pid |awk -F ';' '{print $1}'|awk '{print $1}'`
    cmd_cat=`echo $kingbase_pid |awk -F ';' '{print $2}'|awk '{print $1}'`
    cmd_head=`echo $kingbase_pid |awk -F ';' '{print $2}'|awk '{print $2}'`

    if [ "${cmd_cat}"x != "0"x -o  "${cmd_head}"x != "0"x ]
    then
        echo "cat execute failed,will retry retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" 2>&1
        errorhandle "continue" "\"cat ${KB_DATA_PATH}/kingbase.pid 2>/dev/null|head -n 1 \" execute failed, error num=[$cmd_cat $cmd_head]"
        continue
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
            echo "ps execute failed,will retry retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" 2>&1
            errorhandle "continue" "\"ps -ef | grep -w $result_of_kingbase_pid | grep -v grep | wc -l\" execute failed, error num=[$cmd_ps $cmd_grep1 $cmd_grep2 $cmd_wc]"
            continue
        fi
        if [ "$result_of_kingbase_exist" -eq 0 ]
        then
            errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` CHECK The process was started after promote , but no pid was foud in system,, which db may have been turned off! exit" 
        fi
    else
        errorhandle "exit" "`date +'%Y-%m-%d %H:%M:%S'` CHECK The process was started after promote , but no pid file was foud, which db may have been turned off! exit "
    fi

    echo "ksql \"port=$KB_PORT user=$KB_USER  dbname=$KB_DATANAME connect_timeout=10\"  -c \"select 33333;\" "
    result_of_ksql=`ksql "port=$KB_PORT user=$KB_USER  password=$KB_REAL_PASS dbname=$KB_DATANAME connect_timeout=10" -c "select 33333;"`
    rightnum=`echo $result_of_ksql | grep 33333 | wc -l;echo ";" ${PIPESTATUS[*]}`
    result_of_rightnum=`echo $rightnum |awk -F ';' '{print $1}'|awk '{print $1}'`
    cmd_ksql=`echo $rightnum |awk -F ';' '{print $2}'|awk '{print $1}'`
    cmd_grep=`echo $rightnum |awk -F ';' '{print $2}'|awk '{print $2}'`
    cmd_wc=`echo $rightnum |awk -F ';' '{print $2}'|awk '{print $3}'`

    if [ "${cmd_ksql}"x != "0"x -o "${cmd_wc}"x != "0"x ]
    then
        echo "ksql execute failed,will retry retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" 2>&1
        errorhandle "continue" "\"ksql \"port=$KB_PORT user=$KB_USER dbname=$KB_DATANAME connect_timeout=10\" -c \"select 33333;\" | grep 33333 | wc -l\" execute failed,query detail[$result_of_ksql] , error num=[$cmd_ksql $cmd_grep $cmd_wc ]"
        continue
    fi

    if [ "$result_of_rightnum"x = "1"x ]
    then
        echo "`date +'%Y-%m-%d %H:%M:%S'` after execute promote , kingbase status is ok."  2>&1
        db_alive=1
        break
    else
        echo "kingbase is down,retry check db is if alive,retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}]" 2>&1
        echo "after promote query detail[$result_of_ksql] , try again!" 2>&1
        sleep $HEALTH_CHECK_RETRY_DELAY
    fi
done
if [ $db_alive -eq 0 ]
then
    echo "kingbase is down,after retry ${HEALTH_CHECK_MAX_RETRIES} times ,cannot do promote ,will exit" 2>&1
    exit 66;
else
    echo "after execute promote, kingbase is ok." 2>&1
    exit 0;
fi

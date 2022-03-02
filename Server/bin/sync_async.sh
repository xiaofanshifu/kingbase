#!/bin/bash

KB_PATH=$1
DATA_DIR=$2
SYNC_FLAG=$3
HEALTH_CHECK_MAX_RETRIES=$4
HEALTH_CHECK_RETRY_DELAY=$5

export PATH=$KB_PATH:$PATH

FILE_NAME=`date '+%s'`

#the function of error handing
function errorhandle()
{
    error_flag=$1
    error_cmd=$2
    if [ "${error_flag}"x = ""x ]
    then
        echo "errorhandle function's argument is null "
        exit 66;
    fi
    if [ "${error_flag}"x = "exit"x ]
    then
        echo "${error_cmd}"
        exit 66;
    else
        echo "${error_cmd}"
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


if [ "$SYNC_FLAG"x = ""x ]
then
    SYNC_FLAG=0
fi

#execute sync to async or async to sync by SYNC_FLAG
if [ $SYNC_FLAG -eq 1 ];then
    MyCpCatSed sed  $DATA_DIR/kingbase.conf  $DATA_DIR/$FILE_NAME.kingbase.unuse "s/[#]*synchronous_standby_names/synchronous_standby_names/g" 
    
	MyCpCatSed cat $DATA_DIR/$FILE_NAME.kingbase.unuse  $DATA_DIR/kingbase.conf

    rm -f $DATA_DIR/$FILE_NAME.kingbase.unuse 2>&1

    grep synchronous_standby_names $DATA_DIR/kingbase.conf 2>&1

    for((i=1;i<=$HEALTH_CHECK_MAX_RETRIES;i++))
    do
        sys_ctl -D $DATA_DIR reload 2>&1
        result_of_reload=$?
        if [ "${result_of_reload}"x != "0"x ]
        then
            echo "sys_ctl reload execute failed,will retry,retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}"
            errorhandle "continue" "\"sys_ctl -D $DATA_DIR reload 2>&1\" execute failed, error num=[$result_of_reload]"
            continue
        else
            break
        fi
        sleep $HEALTH_CHECK_RETRY_DELAY
    done
    if [ "${result_of_reload}"x != "0"x ]
    then
        echo "sys_ctl reload execute failed,will exit script with error"
        errorhandle "exit" "\"sys_ctl -D $DATA_DIR reload 2>&1\" execute failed, error num=[$result_of_reload]"
    fi
    echo "`date +'%Y-%m-%d %H:%M:%S'` primary async change SYNC successed!"
    exit 0;

else
    MyCpCatSed sed $DATA_DIR/kingbase.conf  $DATA_DIR/$FILE_NAME.kingbase.unuse "s/^synchronous_standby_names/#synchronous_standby_names/g"
		
	MyCpCatSed cat $DATA_DIR/$FILE_NAME.kingbase.unuse $DATA_DIR/kingbase.conf
    
    rm -f $DATA_DIR/$FILE_NAME.kingbase.unuse 2>&1
    
    grep synchronous_standby_names $DATA_DIR/kingbase.conf  2>&1

    for((i=1;i<=$HEALTH_CHECK_MAX_RETRIES;i++))
    do
        sys_ctl -D $DATA_DIR reload 2>&1
        result_of_reload=$?
        if [ "${result_of_reload}"x != "0"x ]
        then
            echo "sys_ctl reload execute failed,will retry,retry times:[${i}/${HEALTH_CHECK_MAX_RETRIES}"
            errorhandle "continue" "\"sys_ctl -D $DATA_DIR reload 2>&1\" execute failed, error num=[$result_of_reload]"
            continue
        else
            break
        fi
        sleep $HEALTH_CHECK_RETRY_DELAY
    done
    if [ "${result_of_reload}"x != "0"x ]
    then
        echo "sys_ctl reload execute failed,will exit script with error"
        errorhandle "exit" "\"sys_ctl -D $DATA_DIR reload 2>&1\" execute failed, error num=[$result_of_reload]"
    fi
    echo "`date +'%Y-%m-%d %H:%M:%S'` sync to async successed!"
    exit 0;
fi

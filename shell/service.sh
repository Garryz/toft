#!/bin/sh

abspath=$(cd "$(dirname "$0")";pwd)

source $abspath/func.sh

set_global

function check(){
    process_list=`get_process_list`
    for pname in ${process_list[@]}; do
        filter="$real_path/../hive/lua $real_path/../hive/main.lua $real_path/../etc/$pname.conf|${filter}"
    done

	ps axo pid,%cpu,%mem,rss,vsize,time,command | head -1
	ps axo pid,%cpu,%mem,rss,vsize,time,command | egrep "${filter%?}" | grep -v grep | egrep --color=auto "${process_list[@]//\ /|}"
}

function start_process(){
    last_process=`ps aux | grep lua | grep $real_path/../etc/$1.conf | grep -v grep`
    if [ -z "$last_process" ]; then
        yellow_echo "nohup $real_path/../hive/lua $real_path/../hive/main.lua $real_path/../etc/$1.conf &> /dev/null &"
        nohup $real_path/../hive/lua $real_path/../hive/main.lua $real_path/../etc/$1.conf &> /dev/null &
    else
        red_echo "进程$1已经存在, 禁止重复启动" && return
    fi
}

function start(){
    process_list=`get_process_list`
    if [[ ! -z $1 && "$1" != "all" ]]; then
        start_process $1
    else
        for pname in ${process_list[@]}; do
            start_process $pname
            sleep 1
        done
    fi
}

function kill_process(){
    yellow_echo "killing $1 ..."
    res=`ps aux | grep lua | grep $real_path/../etc/$1.conf | grep -v tail | grep -v grep | awk '{print $2}'`
    [ "$res" != "" ] && kill -9 $res
}

function fstop(){
    process_list=`get_process_list`
    if [[ ! -z $1 && "$1" != "all" ]]; then
        kill_process $1
    else
        len=0
        for pname in ${process_list[@]} ; do
            list[$len]=$pname
            let len=$len+1
        done

        let len=$len-1
        for ((i=len;i>=0;i--)); do
            kill_process ${list[i]}
            sleep 0.5
        done
    fi
}

case $1 in
    check|"")
        check;;
    start)
        start $2;;
    kill)
        fstop $2;;
    *)
        red_echo "Usage: sh $0 {start|kill|check(default)}"
esac
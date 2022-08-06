#!/bin/sh

function get_platform(){
    uname=$(uname -s)
    if [ "$uname" == "Darwin" ]; then
        platform="macosx"
    else
        platform="linux"
    fi
    echo $platform
}

function set_global(){
    get_platform
    real_path=$(cd "$(dirname "$0")";pwd)
    cd $real_path/..
    config_file="$real_path/../etc/machine.conf"
    [ ! -f $config_file ] && red_echo "配置文件 $config_file 不存在, 退出脚本" && exit
    [ "$1"!="nolog" ] && echo "本脚本文件所在目录路径是: $real_path"    
}

function red_echo(){
    if [ "$platform"=="macosx" ]; then
        echo "\033[31m `date +"%F %T"`: $1 \033[0m "
    else
        echo -e "\033[31m `date +"%F %T"`: $1 \033[0m "
    fi
}

function green_echo(){
    if [ "$platform"=="macosx" ]; then
        echo "\033[32m `date +"%F %T"`: $1 \033[0m "
    else
        echo -e "\033[32m `date +"%F %T"`: $1 \033[0m "
    fi
}

function yellow_echo(){
    if [ "$platform"=="macosx" ]; then
        echo "\033[33m `date +"%F %T"`: $1 \033[0m "
    else
        echo -e "\033[33m `date +"%F %T"`: $1 \033[0m "
    fi
}

function blue_echo(){
    if [ "$platform"=="macosx" ]; then
        echo "\033[34m `date +"%F %T"`: $1 \033[0m "
    else
        echo -e "\033[34m `date +"%F %T"`: $1 \033[0m "
    fi
}

function get_config(){
    arg1=$1
    grep -q "$arg1 = " $config_file || (red_echo "文件$config_file 中不存在$arg1 配置" && exit)
    value=`grep "$arg1 = " $config_file | head -n1 | cut -d= -f2`
    echo $value
}

function get_config_no_log(){
    arg1=$1
    if grep -q "$arg1 = " $config_file; then
        value=`grep "$arg1 = " $config_file | head -n1 | cut -d= -f2`
        echo $value
    fi
}

function get_process_list(){
    plist=`get_config process_list`
    echo $plist
}
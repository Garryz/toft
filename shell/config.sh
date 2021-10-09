#!/bin/sh

abspath=$(cd "$(dirname "$0")";pwd)

source $abspath/func.sh

echo "复制配置文件目录"

get_platform

if [[ ! -n $1 ]]; then
    green_echo "请指明源路径" && exit
fi

path=$abspath/user/$1
if [ ! -d $path ]; then
    red_echo "$path:  不存在" && exit
fi

rm -rf $abspath/../etc/*
cp -rf $abspath/etc $abspath/../
cp -rf $path/* $abspath/../etc/

blue_echo "复制配置文件完成"
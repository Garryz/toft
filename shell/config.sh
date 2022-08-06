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

set_global

process_list=`get_process_list`

for pname in ${process_list[@]}; do
    pinfo=`get_config_no_log ${pname}`
    if  [[ -n ${pinfo} ]]; then
        index=0
        zero=0
        prlist=()
        for val in ${pinfo[@]} ; do
            prlist[${index}]=${val}
            index=`expr ${index} + 1`
        done
        ori_node=${prlist[0]}
        blue_echo "new nodeName: ${pname} nodeCluster: ${ori_node}"
        if [[ ${ori_node} != ${pname} ]] ; then
            cp -rf $abspath/etc/${ori_node}.conf $abspath/../etc/${pname}.conf

            if [ "$platform" == "macosx" ] ; then
                res=`sed -i "" "s/nodeName = \"${ori_node}\"/nodeName = \"${pname}\"/g"  $abspath/../etc/${pname}.conf`
                res=`sed -i "" "s/logfile = \"${ori_node}\"/logfile = \"${pname}\"/g"  $abspath/../etc/${pname}.conf`
            else
                res=`sed -i "s/nodeName = \"${ori_node}\"/nodeName = \"${pname}\"/g"  $abspath/../etc/${pname}.conf`
                res=`sed -i "s/logfile = \"${ori_node}\"/logfile = \"${pname}\"/g"  $abspath/../etc/${pname}.conf`
            fi
        fi
    fi
done

blue_echo "复制配置文件完成"
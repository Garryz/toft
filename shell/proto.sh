#!/bin/sh

abspath=$(cd "$(dirname "$0")";pwd)

mkdir -p abspath/../pb/

for pname in `ls $abspath/../proto`; do
    pname=$(echo ${pname%.*})
    $abspath/../hive/protoc -o $abspath/../pb/$pname.pb $abspath/../proto/$pname.proto -I $abspath/../proto
done
#!/bin/sh

abspath=$(cd "$(dirname "$0")";pwd)

mkdir -p $abspath/../build

cd $abspath/../build

cmake $abspath/../hive

cmake --build . --config Release --target all --clean-first
#!/usr/bin/env bash
target=${1:?Missing folder name}
shift
cd ${target}
mvn package
mvn exec:java -Dexec.args="$@"


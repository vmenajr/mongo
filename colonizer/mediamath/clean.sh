#!/usr/bin/env bash
source $(dirname ${0})/functions.sh

function usage() {
    cat <<EOF
$@

${0}

Cleans the environment from running mongodbs and dbpaths

EOF
	exit -1
}

source $(dirname $0)/cluster_vars.sh

env="default"
[ -f ".terraform/environment" ] && env=$(cat .terraform/environment)
echo "Detected enviroment: ${env}"
inv=$(refresh_inventory ${env})

echo Cleaning mongos...
for h in $(jq '.inventory.value.mongos[].public | join(" ")' < $inv | tr -d \"); do
    ssh $h "pkill -f mongo.; rm -rvf $dbpath/*; pgrep -lfa mongo.; tree $dbpath"
    echo
done
echo

echo Cleaning shards...
for h in $(jq '.inventory.value.shards[].public | join(" ")' < $inv | tr -d \"); do
    ssh $h "pkill -f mongo.; rm -rvf $dbpath/*; pgrep -lfa mongo.; tree $dbpath"
    echo
done
echo
echo Cleaning configs...
for h in $(jq '.inventory.value.configs[].public | join(" ")' < $inv | tr -d \"); do
    ssh $h "pkill -f mongo.; rm -rvf $dbpath/*; pgrep -lfa mongo.; tree $dbpath"
    echo
done
echo


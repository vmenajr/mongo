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
cmd="/usr/local/bin/mongod --dbpath ${dbpath} --logpath ${logpath} --port 27017 --logappend --fork --shardsvr --replSet shard"
echo Starting shards...
declare -a a
readarray -t a <<< "$(jq '.inventory.value.shards[].public | join(" ")' < $inv | tr -d \")"
for h in $(jq '.inventory.value.shards[].public | join(" ")' < $inv | tr -d \"); do
    ssh $h "
    echo
done
echo

#/usr/local/bin/mongod --replSet shard${count.index / 3} --dbpath ${var.dbPath} --logpath ${var.logPath} --port 27017 --logappend --fork --shardsvr"


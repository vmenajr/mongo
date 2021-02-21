#!/usr/bin/env bash
source $(dirname ${0})/functions.sh

function usage() {
    cat <<EOF
$@

${0}

Outputs cluster details in yaml format for ansible

EOF
	exit -1
}


inv=$(refresh_inventory)
log "Detected enviroment: ${inv}"

cat <<EOF
[clients]
$(jq '.inventory.value.client[].public | join(",")' ${inv} | tr -d \" | tr \, \\n)

[mongos]
$(jq '.inventory.value.mongos[].public | join(",")' ${inv} | tr -d \" | tr \, \\n)

[configs]
$(jq '.inventory.value.configs[].public | join(",")' ${inv} | tr -d \" | tr \, \\n)

[shards]
$(jq '.inventory.value.shards[].public | join(",")' ${inv} | tr -d \" | tr \, \\n)

EOF

log "Done"


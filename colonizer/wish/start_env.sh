#!/usr/bin/env bash
exec 3>&1

function usage() {
    cat <<EOF
$@

${0} "Test name" (e.g. wish5)

EOF
	exit -1
}

function abend() {
	echo $@
	exit -1
}

# Environment is the first option
test=${1}
[ -z ${test} ] && usage "Missing name"
shift
[ -f ${test}.tfvars ] || usage "Test not found: ${test}.tfvars"

terraform env select ${test}.ap
./tf.sh plan -- -var allow_nvme=1

read -p "Press any key to continue"

./tf.sh apply -- -var allow_nvme=1
terraform output -json > servers_${test}.json

clients=$(cat servers_${test}.json | jq '.inventory.value | .client[].public[]' | tr -d \")
for host in ${clients}; do
    scp servers_${test}.json scripts/* colonizer@${host}:/home/colonizer
done

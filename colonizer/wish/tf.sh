#!/usr/bin/env bash

function usage() {
    cat <<EOF
$@

${0} cmd [-t] [-i clients] [-r region] [-o owner] [-e days] [-c configs] [-m mongos] [-s shards] [-- options]

    -t      : Test only (dry-run)
    -i      : Number of client boxes
    -r      : AWS Region (defaults to region for corresponding environment)
    -o      : Owner
    -e      : Expires days from today (default = 15)
    -c      : Number of config servers
    -m      : Number of mongos
    -s      : Number of PSS shards
    cmd     : Terraform command
    options : Additional options to terraform (e.g. -var key=value)
    -- -h   : Show this help screen

    Note: Any arguments not specified will use the values from the corresponding tfvars file or variables.tf

EOF
	exit -1
}
function abend() {
	echo $@
	exit -1
}
function refresh_inventory() {
    [ "${1}" != "apply" ] && return 0
	[ -f inventory.json ] && mv inventory.json inventory.prev
	terraform output -json &> inventory.json
}

# Command is the first argument
cmd=${1}
[ -z ${cmd} ] && usage "Missing command"
shift

args=""
var_file=""
env="default"
[ -f ".terraform/environment" ] && env=$(cat .terraform/environment)
echo -n "Detected enviroment: ${env}"
tf_env=${env}
env=${env%.*}
var_file=""
[ "${env}" != "default" ] && var_file="-var-file=${env}.tfvars"
echo " ${var_file}"
days=15

while getopts ":hc:m:s:o:e:r:i:t" opt; do
  case $opt in
    c)
      args="${args} -var config_count=${OPTARG}"
      ;;
    m)
      args="${args} -var mongos_count=${OPTARG}"
      ;;
    s)
      args="${args} -var shard_count=${OPTARG}"
      ;;
    o)
      owner=${OPTARG}
      ;;
    e)
      days=$(( OPTARG <= 1 ? 1 : OPTARG ))
      ;;
    i)
      clients=$(( OPTARG < 0 ? 0 : OPTARG ))
      args="${args} -var client_count=${clients}"
      ;;
    r)
      region=${OPTARG}
      ;;
    t)
      TEST_MODE=1
      ;;
    \?)
      INVALIDS="${INVALIDS}${OPTARG}"
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    h)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

[ ! -z ${INVALIDS} ] && INVALIDS="-${INVALIDS}"
owner="-var owner=${owner:-${USER}}"
expires="-var expire_on=$(date -v +${days}d "+%Y-%m-%d")"
if [ -z ${region} ]; then
	case ${tf_env#*.} in
		ap) region=ap-southeast-2
		;;
		ca) region=us-west-1
		;;
		*)  region=us-east-2
		;;
	esac
fi
region="-var aws_region=${region}"
args="${args} ${owner} ${expires} ${region}"

cmdline="terraform $cmd ${var_file} $args ${INVALIDS} $@"
echo Executing: ${cmdline}
echo

[ -z ${TEST_MODE} ] && ${cmdline} && refresh_inventory ${cmd}


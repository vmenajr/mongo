#!/usr/bin/env bash

function abend() {
	echo $@
	echo
	exit -1
}

ami=${1?Missing ami-id}
shift
snapshot=$(aws ec2 describe-images --image-ids $ami $@ | jq '.Images[].BlockDeviceMappings[] | select(.DeviceName=="/dev/sda1").Ebs.SnapshotId' | tr -d \")
[[ ${snapshot} =~ ^snap ]] || abend "Cannot find snapshot for ${ami}"
echo Deregister ${ami}...
aws ec2 deregister-image --image-id ${ami} $@
echo Remove  ${snapshot}...
aws ec2 delete-snapshot --snapshot-id ${snapshot} $@
echo Done


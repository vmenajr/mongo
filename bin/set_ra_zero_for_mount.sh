#!/usr/bin/env bash
mountpt=${1:?Usage: $0 mount_point}

function abend() {
	echo $@
	exit -1
}

[ -d ${mountpt} ] || abend "Mount point not found: $mountpt"

echo Before setting RA on $mountpt
blockdev --report
volume=$(df --output=source ${mountpt} | tail -1 | tr -d \  )
mappings=$(pvs --no-headings -o lv_dm_path,pv_name | grep ${volume})
while read mapper device; do
	blockdev --setra 0 $mapper $device
done <<< ${mappings}

echo Now
blockdev --report


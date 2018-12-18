#!/usr/bin/env bash
set -x
[ -z ${path} ] && path="/"
[ -z ${ra} ]   && ra=0

echo Before setting RA on $path
blockdev --report
volume=$(df --output=source ${path} | tail -1 | tr -d \  )
mappings=$(pvs --no-headings -o lv_dm_path,pv_name | grep ${volume})
while read mapper device; do
	blockdev --setra ${ra} $mapper $device
done <<< ${mappings}

echo Now
blockdev --report


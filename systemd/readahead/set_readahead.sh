#!/usr/bin/env bash
[[ -z ${paths} ]] && paths="/"
[[ -z ${ra} ]]    && ra=0

for path in ${paths}; do
	echo Before setting RA on $path
	blockdev --report
	volume=$(df --output=source ${path} | tail -1 | tr -d \  )
	mappings=$(pvs --no-headings -o lv_dm_path,pv_name | grep ${volume})
	while read mapper device; do
		echo blockdev --setra ${ra} $mapper $device
		blockdev --setra ${ra} $mapper $device
	done <<< ${mappings}

	echo Now
	blockdev --report
done


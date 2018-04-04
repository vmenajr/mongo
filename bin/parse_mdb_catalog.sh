#!/usr/bin/env bash
function abend() {
    echo ABEND: $@
    exit -1
}

function usage() {
    echo Usage: $(basename $0) dbPath
    exit -2
}

[ -z ${1} ] && usage
catalog="${1}/_mdb_catalog.wt"
echo catalog: ${catalog}
[ -f ${catalog} ] || abend "Catalog file not found at ${catalog}"

for line in $(strings -n 2 ${catalog}); do
	if [[ "$line" =~ "options" ]]; then
		echo "Namespace: ${prev}"
	fi
	if [[ "$line" =~ "index-" ]]; then
        echo "   ${line} (${prev})"
	fi
	if [[ "$line" =~ "collection-" ]]; then
		echo "   ${line}"
	fi
	prev=$line
done


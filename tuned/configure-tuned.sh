#!/usr/bin/env bash
function abend() {
    echo $@
    exit -1
}
name=${1?Missing profile name}
base=/usr/lib/tuned/${name}
url=https://raw.githubusercontent.com/vmenajr/mongo/master/tuned/${name}/tuned.conf 
mkdir ${base} || abend Unable to create ${base}
cd ${base} || abend Cannot access ${base}
curl -LO ${url} || abend Cannot download ${name} from ${url}
tuned-adm profile ${name} || abend Cannot enable ${name} profile
tuned-adm active || abend Cannot activate ${name} profile


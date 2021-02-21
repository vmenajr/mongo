#!/usr/bin/env bash

function abend() {
	>&2 echo $@
	exit -1
}

function log() {
	>&2 echo $@
}

function refresh_inventory() {
    local env="default"
    if [ -z ${1} ]; then
        [ -f ".terraform/environment" ] && env=$(cat .terraform/environment)
    fi
	[ ! -d inventory ] && mkdir inventory
	f=inventory/${env}.json
	[ -f ${f} ] && mv ${f} ${f%.*}.prev
	terraform output -json &> ${f}
    echo ${f}
}


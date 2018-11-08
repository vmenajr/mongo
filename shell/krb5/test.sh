#!/usr/bin/env bash
usr="test@MDB.ORG"

function usage() {
    echo "Usage: $0 -h host:port <-p password>"
    exit -1
}

while getopts ":h:p" opt; do
  case $opt in
    h) hostport=$OPTARG ;;
    p) pwd=$OPTARG ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

[ -z ${hostport} ] && usage

function rawurlencode () {
	local string="${1}";
	local strlen=${#string};
	local encoded="";
	local pos c o;
	for ((pos=0 ; pos<strlen ; pos++ ))
	do
		c=${string:${pos}:1};
		case "$c" in
			[-_.~a-zA-Z0-9])
				o="${c}"
				;;
			*)
				printf -v o '%%%02x' "'$c"
				;;
		esac;
		encoded+="${o}";
	done;
	echo "${encoded}";
	REPLY="${encoded}"
}

#usr=$(rawurlencode ${usr})
#pwd=$(rawurlencode ${pwd})
#usepwd=1
#uri="mongodb://${usr}:${pwd}@${hostport}/test?authMechanism=GSSAPI"
#[ -z ${usepwd} ] && uri="mongodb://${usr}@${hostport}/test?authMechanism=GSSAPI"

#echo $uri
#echo
#/c/Program\ Files/MongoDB/Server/4.0/bin/mongo $uri --eval "db.c.findOne();"
#echo

[ -z ${pwd} ] && /c/Program\ Files/MongoDB/Server/4.0/bin/mongo --host $hostport -u $usr --authenticationDatabase \$external --authenticationMechanism GSSAPI --eval "db.c.findOne();"
[ -z ${pwd} ] || /c/Program\ Files/MongoDB/Server/4.0/bin/mongo --host $hostport -u $usr -p $pwd --authenticationDatabase \$external --authenticationMechanism GSSAPI --eval "db.c.findOne();"


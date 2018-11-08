#!/usr/bin/env bash
hostport="ip-10-1-1-122.us-east-2.compute.internal:27017"
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

#usr=$(rawurlencode "vick@MDB.ORG")
#pwd=$(rawurlencode "L,4\;?GzBs3{2LjU")
usr="vick@MDB.ORG"
pwd="L,4\;?GzBs3{2LjU"
#usepwd=1
#uri="mongodb://${usr}:${pwd}@${hostport}/test?authMechanism=GSSAPI"
#[ -z ${usepwd} ] && uri="mongodb://${usr}@${hostport}/test?authMechanism=GSSAPI"

#echo $uri
#echo
#/c/Program\ Files/MongoDB/Server/4.0/bin/mongo $uri --eval "db.c.findOne();"
#echo

/c/Program\ Files/MongoDB/Server/4.0/bin/mongo --host $hostport -u $usr -p $pwd --authenticationDatabase \$external --authenticationMechanism GSSAPI --eval "db.c.findOne();"


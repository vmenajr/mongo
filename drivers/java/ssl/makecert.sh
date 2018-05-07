#!/usr/bin/env bash
state="SomeState"
city="SomeCity"
org="SomeOrganization"
unit="SomeOrganizationalUnit"
host="localhost.localdomain"
email="root@localhost.localdomain"

abend() {
    echo "Abend: $@"
    echo
    exit -1
}

usage() { 
    echo "Usage: $0 [-s state] [-c city] [-o org] [-u unit] [-h host] [-e email]"
    echo "  state: State ($state)"
    echo "  city:  City ($city)"
    echo "  org:   Organization ($org)"
    echo "  unit:  Organizational unit ($unit)"
    echo "  host:  Fully qualified domain name for the server using this cert ($host)"
    echo "  email: Email associated with the cert ($email)"
    echo
    exit 1
}

while getopts ":s:c:o:u:h:e:" o; do
    case "${o}" in
        s)
            state=${OPTARG}
            ;;
        c)
            city=${OPTARG}
            ;;
        o)
            org=${OPTARG}
            ;;
        u)
            unit=${OPTARG}
            ;;
        h)
            host=${OPTARG}
            ;;
        e)
            email=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

answers() {
	echo --
	echo $state
	echo $city
	echo $org
	echo $unit
	echo $host
	echo $email
}

answers | openssl req -new -x509 -days 365 -nodes -out mongodb.crt -keyout mongodb.key
cat *.key *.crt > mongodb.pem
openssl x509 -noout -text -in mongodb.pem


#!/usr/bin/env bash
bits=2048
days=365
country="US"
state="SomeState"
city="SomeCity"
org="SomeOrganization"
unit="SomeOrganizationalUnit"
host=$(hostname -f)
email="root@${host}"

abend() {
    echo "Abend: $@"
    echo
    exit -1
}

usage() { 
    echo "Usage: $0 [-d days] [-s state] [-c city] [-o org] [-u unit] [-h host] [-e email]"
    echo "  bits:    Number of bits ($bits)"
    echo "  days:    Number of days ($days)"
    echo "  country: Country code ($country)"
    echo "  state:   State ($state)"
    echo "  city:    City ($city)"
    echo "  org:     Organization ($org)"
    echo "  unit:    Organizational unit ($unit)"
    echo "  host:    Fully qualified domain name for the server using this cert ($host)"
    echo "  email:   Email associated with the cert ($email)"
    echo
    exit 1
}

while getopts ":b:d:k:s:c:o:u:h:e:" o; do
    case "${o}" in
        b)
            bits=${OPTARG}
            ;;
        d)
            days=${OPTARG}
            ;;
        k)
            country=${OPTARG}
            ;;
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
	echo $country
	echo $state
	echo $city
	echo $org
	echo $unit
	echo $host
	echo $email
}

[[ "Darwin" -eq "$(uname -s)" ]]  && configFile=/System/Library/OpenSSL/openssl.cnf || configFile=/etc/ssl/openssl.cnf
baseConfig=$(grep -v ^# ${configFile} | tr -s \\n)
ext="
[ EXT ]
basicConstraints=CA:TRUE
extendedKeyUsage = serverAuth,clientAuth
"
config="
$baseConfig
$ext
"

rm mongodb.crt mongodb.key mongodb.pem
answers | openssl req -extensions EXT -config <(echo "$config") -newkey rsa:${bits} -x509 -days ${days} -nodes -sha256 -out mongodb.crt -keyout mongodb.key
cat *.key *.crt > mongodb.pem
openssl x509 -noout -text -in mongodb.pem


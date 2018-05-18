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
subject_template="/C=${country}/ST=${state}/L=${city}/O=${org}/OU=${unit}/CN="

[[ "Darwin" -eq "$(uname -s)" ]]  && configFile=/System/Library/OpenSSL/openssl.cnf || configFile=/etc/ssl/openssl.cnf
baseConfig=$(grep -v ^# ${configFile} | tr -s \\n)
ext="
[ EXT ]
basicConstraints=CA:FALSE
extendedKeyUsage=serverAuth,clientAuth
"
config="
$baseConfig
$ext
"

rm *.csr *.crt *.key *.pem
#set -x
# Root Certificate Authority and private key
#openssl genrsa -out root-ca.key ${bits}
openssl req -x509 -new -newkey rsa:${bits} -nodes -keyout root-ca.key -sha256 -days 1024 -out root-ca.pem -subj "${subject_template}ROOTCA"
#openssl req -x509 -new -key root-ca.key -out root-ca.pem -subj "${subject_template}ROOTCA"

# Create a signing request with new private key for host
#csr=$(openssl req -newkey rsa:${bits} -nodes -keyout ${host}.key -subj "${subject_template}${host}")
#openssl req -new -config <(echo "$config") -extensions EXT -reqexts EXT -newkey rsa:${bits} -nodes -keyout ${host}.key -subj "${subject_template}${host}" -days ${days} -sha256 -out ${host}.csr
#openssl req -new -newkey rsa:${bits} -nodes -keyout ${host}.key -subj "${subject_template}${host}" -days ${days} -sha256 -out ${host}.csr
csr=$(openssl req -new -newkey rsa:${bits} -nodes -keyout ${host}.key -subj "${subject_template}${host}" -days ${days} -sha256)

#openssl genrsa -out ${host}.key ${bits}
#openssl req -config <(echo "$config") -newkey rsa:${bits} -nodes -keyout ${host}.key -subj "${subject_template}${host}" -days ${days} -sha256 -out ${host}.csr
#openssl req -new -key root-ca.key -extensions EXT -config <(echo "$config") -subj "${subject_template}${host}" -days ${days} -sha256 -out ${host}.csr
#openssl req -new -key root-ca.key -config <(echo "$config") -extensions usr_cert -subj "${subject_template}${host}" -days ${days} -sha256 -out ${host}.csr
openssl req -noout -text -in <(echo "$csr")

# Create certificate and sign using the private key from our RootCA
#openssl x509 -req -CA root-ca.crt -CAkey root-ca.key -CAcreateserial -days ${days} -sha256 -out ${host}.crt -in <(echo "${csr}")
#openssl x509 -req -extensions EXT -config <(echo "$config") -days ${days} -sha256 -out ${host}.crt -in ${host}.csr
#openssl x509 -req -CA root-ca.pem -CAkey root-ca.key -CAcreateserial -days ${days} -sha256 -out ${host}.crt -in ${host}.csr
#openssl ca -batch -name SigningCA -config root-ca.cfg -extensions member_ext -extfile extensions.txt -out ${host}.crt -infiles ${host}.csr
#openssl ca -cert root-ca.pem -keyfile root-ca.key -outdir . -out ${host}.crt -infiles ${host}.csr
#openssl x509 -req -extfile <(echo "$ext") -extensions EXT -CA root-ca.pem -CAkey root-ca.key -CAcreateserial -days ${days} -sha256 -out ${host}.crt -in ${host}.csr
openssl x509 -req -extfile <(echo "$ext") -extensions EXT -CA root-ca.pem -CAkey root-ca.key -CAcreateserial -days ${days} -sha256 -out ${host}.crt -in <(echo "$csr")
cat ${host}.crt ${host}.key > ${host}.pem
openssl x509 -noout -text -in ${host}.pem
exit 0

openssl x509 -req -CA root-ca.crt -CAkey root-ca.key -CAcreateserial -extensions EXT -config <(echo "$config") -newkey rsa:${bits} -days ${days} -nodes -sha256 -out mongodb.crt -keyout mongodb.key -subj "${subject_template}${host}"
cat *.key *.crt > mongodb.pem
openssl x509 -noout -text -in root-ca.crt
openssl x509 -noout -text -in mongodb.pem

#openssl x509 -noout -modulus -in server.crt| openssl md5
#openssl rsa -noout -modulus -in server.key| openssl md5
#openssl verify -verbose -CAfile cacert.pem  server.crt


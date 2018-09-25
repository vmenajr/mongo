#!/usr/bin/env bash
bits=2048
days=365
country="US"
state="SomeState"
city="SomeCity"
org="SomeOrganization"
unit="SomeOrganizationalUnit"
hosts=$(hostname -f)
name=''

abend() {
    echo "Abend: $@"
    echo
    exit -1
}

usage() { 
    echo "Usage: $0 [-n name] [-d days] [-s state] [-c city] [-o org] [-u unit] [-h hosts] [-e email] [-v]"
    echo "  bits:    Number of bits ($bits)"
    echo "  days:    Number of days ($days)"
    echo "  country: Country code ($country)"
    echo "  state:   State ($state)"
    echo "  city:    City ($city)"
    echo "  org:     Organization ($org)"
    echo "  unit:    Organizational unit ($unit)"
    echo "  hosts:   Fully qualified domain name for the server(s) using this cert ($host)."
    echo "           For multiple certs surround with quotes (e.g. -h \"host1 host2 ...\")"
    echo "  email:   Email associated with the cert ($email)"
    echo "  name :   Common name ($name)"
    echo "  -v   :   Verbose. Print certs as they are generated"
    echo
    exit 1
}

while getopts ":b:d:k:s:c:o:u:h:e:n:v" o; do
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
            hosts=${OPTARG}
            ;;
        e)
            email=${OPTARG}
            ;;
        n)
            name=${OPTARG}
            ;;
        v)
            verbose=1
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

subject_template="/C=${country}/ST=${state}/L=${city}/O=${org}/OU=${unit}/CN="

ext_template="
[ EXT ]
extendedKeyUsage=serverAuth,clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = "

# Root Certificate Authority and private key
if [[ -f root-ca.pem && -f root-ca.key ]]; then
    echo "Skipping RootCA generation in favor of current files..."
else
    openssl req -x509 -new -newkey rsa:${bits} -nodes -keyout root-ca.key -sha256 -days 1024 -out root-ca.pem -subj "${subject_template}ROOTCA"
    [[ -z ${verbose} ]] || openssl x509 -noout -text -in root-ca.pem
fi


# Process hosts
for host in $hosts; do
	# locals
    CN=${host}
	[[ -z "${name}" ]] || CN=${name}
    ext="${ext_template}${host}"

    # Create a signing request with new private key for host
    [[ -z ${email} ]] && email="root@${host}"
    csr=$(openssl req -new -newkey rsa:${bits} -nodes -keyout ${host}.key -subj "/emailAddress=${email}${subject_template}${CN}" -days ${days} -sha256)
    [[ -z ${verbose} ]] || openssl req -noout -text -in <(echo "$csr")

    # Create certificate signed with its private key and issued by our RootCA
    openssl x509 -req -extfile <(echo "$ext") -extensions EXT -CA root-ca.pem -CAkey root-ca.key -CAcreateserial -days ${days} -sha256 -out ${host}.crt -in <(echo "$csr")
    cat ${host}.crt ${host}.key > ${host}.pem
    echo
    echo ${host}
    echo
    [[ -z ${verbose} ]] || openssl x509 -noout -text -in ${host}.pem
done

echo
echo

#openssl x509 -noout -modulus -in server.crt| openssl md5
#openssl rsa -noout -modulus -in server.key| openssl md5
#openssl verify -verbose -CAfile cacert.pem  server.crt


#!/usr/bin/env bash
bin=${1:-mongod}
dbpath=$(mktemp -d /tmp/db.XXXXXXXXXX)
echo Using $dbpath
$bin --dbpath $dbpath --logpath $dbpath/log --wiredTigerCacheSizeGB 0.1 --sslMode requireSSL --sslPEMKeyFile mongodb.pem --bind_ip localhost --port 26000 --fork


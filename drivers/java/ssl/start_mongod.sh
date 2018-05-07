#!/usr/bin/env bash
bin=${1:-mongod}
dbpath=$(mktemp -d /tmp/db.XXXXXXXXXX)
$bin --dbpath $dbpath --logpath $dbpath/log --wiredTigerCacheSizeGB 0.1 --sslMode requireSSL --sslPEMKeyFile mongodb.pem --bind_ip 0.0.0.0 --port 26000 --fork


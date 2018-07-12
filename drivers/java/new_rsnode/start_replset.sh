#!/usr/bin/env bash
dbpath=$(mktemp -d /tmp/db.XXXXXXXXXX)
echo Using $dbpath
mlaunch init --dir $dbpath --replicaset --binarypath /usr/local/m/versions/3.0.15/bin --verbose --hostname localhost --bind_ip localhost --wiredTigerCacheSizeGB 1
mkdir -p $dbpath/replset/rs4/db
/usr/local/m/versions/3.0.15/bin/mongod --replSet replset --dbpath $dbpath/replset/rs4/db --logpath $dbpath/replset/rs4/mongod.log --port 27020 --fork --bind_ip localhost --wiredTigerCacheSizeGB 1
sleep 5


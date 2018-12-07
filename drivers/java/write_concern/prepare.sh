#!/usr/bin/env bash
./cleanup.sh
mlaunch init --replicaset --nodes 3 --shards 1 --config 1 --mongos 1 --binarypath /usr/local/m/versions/3.4.4-ent/bin --port 12108 --verbose --hostname localhost --bind_ip localhost --wiredTigerCacheSizeGB 0.1
/usr/local/m/versions/3.4.4-ent/bin/mongo --port 12108 --eval 'sh.enableSharding("test")'
/usr/local/m/versions/3.4.4-ent/bin/mongo --port 12108 --eval 'sh.shardCollection("test.c", {_id:1})'
/usr/local/m/versions/3.4.4-ent/bin/mongo --port 12108 --eval 'sh.status()'
for port in 12109 12110 12111; do
    /usr/local/m/versions/3.4.4-ent/bin/mongo --port $port --eval 'db.setProfilingLevel(0,0)'
done


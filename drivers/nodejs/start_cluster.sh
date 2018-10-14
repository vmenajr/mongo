#!/usr/bin/env bash
mlaunch init --replicaset --nodes 1 --config 1 --mongos 1 --shards 1 --binarypath /usr/local/m/versions/3.6.8-ent/bin --port 12108 --verbose --hostname localhost --bind_ip localhost --wiredTigerCacheSizeGB 0.1


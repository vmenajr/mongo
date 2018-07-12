#!/usr/bin/env bash
host=${1:-localhost}
mvn package
mvn exec:java -Dexec.args='-uri mongodb://localhost:27017,localhost:27018,localhost:27019/?replicaSet=replset'


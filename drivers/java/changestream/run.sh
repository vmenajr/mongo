#!/usr/bin/env bash
host=${1:-localhost}
mvn package
mvn exec:java -Dexec.args='-uri mongodb://localhost:27017/?replicaSet=replset'


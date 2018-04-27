#!/usr/bin/env bash
host=${1:-localhost}
mvn package
mvn exec:java -Dexec.args="-uri mongodb://${host}:27017/?ssl=true"


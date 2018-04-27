#!/usr/bin/env bash
mvn package
mvn exec:java -Dexec.args="-uri mongodb://hostname:27017/?ssl=true"


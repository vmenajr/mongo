#!/usr/bin/env bash
mvn package
mvn exec:java -Dexec.args='-uri mongodb://localhost:5125/ -d test -c c'


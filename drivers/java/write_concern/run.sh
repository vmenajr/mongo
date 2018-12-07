#!/usr/bin/env bash
mvn package
mvn exec:java -Dexec.args='-uri mongodb://localhost:12108/test'
find -type f -name '*.log' -exec grep -E '(insert|delete).*writeConcern' {} \;


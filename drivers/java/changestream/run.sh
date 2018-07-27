#!/usr/bin/env bash
mvn package
#mvn exec:java -Dexec.args="-uri mongodb://localhost:27017/?replicaSet=replset -fromString '{ \"_data\" : { \"\$binary\" : \"gltabtsAAAACRmRfaWQAZFtabtsXnHUIBXi/YwBaEATLPZn9BJ1MFL6bpSMcLKuyBA==\", \"\$type\" : 00 } }'"
mvn exec:java -Dexec.args='-uri mongodb://localhost:27017/?replicaSet=replset'


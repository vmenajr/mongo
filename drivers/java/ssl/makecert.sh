#!/usr/bin/env bash
openssl req -new -x509 -days 365 -nodes -out mongodb.crt -keyout mongodb.key
cat *.key *.crt > mongodb.pem
openssl x509 -noout -text -in mongodb.pem


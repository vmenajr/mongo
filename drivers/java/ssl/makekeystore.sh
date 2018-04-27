#!/usr/bin/env bash
password=${1:-mongodb}
rm keystore
keytool -import -alias "MongoDB Self-signed Cert" -file mongodb.crt -keystore keystore -storepass ${password} -noprompt


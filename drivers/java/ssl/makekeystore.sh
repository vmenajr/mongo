#!/usr/bin/env bash
password=${1:-mongodb}
rm keystore
keytool -import -alias "MongoDB RootCA" -file root-ca.pem -keystore keystore -storepass ${password} -noprompt


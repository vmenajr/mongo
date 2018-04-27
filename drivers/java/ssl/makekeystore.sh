#!/usr/bin/env bash
rm keystore
keytool -import -alias "MongoDB Self-signed Cert" -file mongodb.crt -keystore keystore -storepass mongodb -noprompt

#!/usr/bin/env bash
rm *.srl *.pem *.crt *.key
./makecert.sh
./makekeystore.sh
cp $(hostname -f).pem mongodb.pem
rm *.srl


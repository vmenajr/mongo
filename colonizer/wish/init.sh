#!/usr/bin/env bash
terraform init
echo
echo
terraform env select default
echo
terraform env list
echo
echo "Don't forget to switch to your environment from the list above"
echo


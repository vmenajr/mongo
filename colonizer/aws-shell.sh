#!/bin/bash
aws_keys=$(security -q find-generic-password -l aws_keys -w)
if [ "$?" -eq "0" ]; then
	export AWS_ACCESS_KEY_ID=${aws_keys%,*}
	export AWS_SECRET_ACCESS_KEY=${aws_keys#*,}
	export PS1="\nAWS SHELL${PS1}"
	bash -i
else
	echo "Cannot read aws_keys from keychain: ${aws_keys}"
fi

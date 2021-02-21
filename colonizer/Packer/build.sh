#!/usr/bin/env bash
#packer build -only=amazon-ebs-ubuntu-Xenial -var aws_region=ap-southeast-2 -var ubuntu_ami_id=ami-3c30215f mongodb.json 2>&1 | tee /tmp/build.log
packer build $@ --on-error=ask -only=amazon-ebs-ubuntu-Xenial mongodb.json 2>&1 | tee build.log


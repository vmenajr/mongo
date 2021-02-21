#!/usr/bin/env bash
aws ec2 describe-images --owners self --filters Name=name,Values='prod*' $@ | jq '.Images[] | { ami: .ImageId, name: (.Tags[] ? | select(.Key == "Name").Value), snapshot: (.BlockDeviceMappings[] | select(.DeviceName=="/dev/sda1").Ebs.SnapshotId), created: .CreationDate }'

#!/usr/bin/env bash
aws ec2 stop-instances --instance-ids $(terraform output -json | jq '.inventory.value | .shards[].id + .client[].id + .mongos[].id + .configs[].id | join(" ")' | tr -d \") $@

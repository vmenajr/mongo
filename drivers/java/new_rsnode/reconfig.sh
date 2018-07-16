#!/usr/bin/env bash
function print() {
	echo $(date): $@
}

print Adding localhost:27020
mongo --quiet --norc --eval 'printjson(rs.add("localhost:27020"));'
print Sleep 5 seconds...
sleep 5
print Make 27020 the new primary
mongo --quiet --norc --eval 'cfg=rs.conf(); cfg.members[3].priority=999; printjson(rs.reconfig(cfg));'
print Sleep for 15 seconds...
sleep 15
print Remove all nodes except for 27020
mongo --quiet --norc --host localhost:27020 --eval 'cfg=rs.conf(); cfg.members.splice(0,3); printjson(rs.reconfig(cfg));'
sleep 5
mongo --quiet --norc --host localhost:27020 --eval 'printjson(rs.status());'
print Done
echo


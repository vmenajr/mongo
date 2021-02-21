#!/bin/bash

set -x

exec 3>&1

test=wish4
#test=default

num_of_clients=(4 8 16 32)
#num_of_clients=(2 4)

echo "deb http://us.archive.ubuntu.com/ubuntu vivid main universe" | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y jq

echo "Cleaning up the current MongoDB cluster"
python run_test.py -t test_${test}.json -s servers_${test}.json -a get_hosts
python run_test.py -t test_${test}.json -a clean

clients=$(cat servers_${test}.json | jq '.inventory.value | .client[].private[]' | tr -d \")

echo "Set up MongoDB cluster"
python run_test.py -t test_${test}.json -a setup_mongodb -n ${test}_wt_sccc -u dba -e wiredTiger -c SCCC
#python run_test.py -t test_${test}.json -a setup_mongodb -n ${test}_mmap_sccc -u dba -e mmapv1 -c SCCC

echo "Load the data"
python run_test.py -t test_${test}.json -a load -w workload_wish

echo "Restart mongos with --noAutoSplit"
python run_test.py -t test_${test}.json -a restart_mongos_no_auto_split

echo "Run the test"
function run_test {
    local extra_args=("-t" "${1}clients_test_${test}.json" "-a" "run" "-w" "workload_wish")
    if [ $2 != 1 ]; then
        extra_args+=("-o" "true")
    fi
    #set -x
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $3 stdbuf -o 0 python "$PWD"/run_test.py "${extra_args[@]}" 1>&3
}

cmdline=""
new_clients=()
for host in ${clients}; do
    new_clients+=(${host})
done

for i in "${num_of_clients[@]}"; do
    cmdline=""
    echo $i
    for j in $(seq 1 $i); do
        k=$(($j - 1))
        cmdline+="<(run_test $i $j ${new_clients[$k]}) "
    done
    read | eval "paste $cmdline"
done

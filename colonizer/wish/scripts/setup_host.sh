#!/bin/bash -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create mongodb user
sudo mkdir -p /home/mongodb/.ssh
sudo cp $DIR/.ssh/authorized_keys /home/mongodb/.ssh/authorized_keys
sudo useradd -U mongodb -s /bin/bash
sudo chown -R mongodb:mongodb /home/mongodb

# Prepare dbpath
#sudo mkfs -t xfs /dev/nvme0n1
#echo "/dev/nvme0n1 /data xfs noatime,rw 0 0"  | sudo tee -a /etc/fstab 
#sudo mkdir /data
#sudo mount /dev/nvme0n1 /data
#sudo chown -R mongodb:mongodb /data
sudo chown -R mongodb:mongodb /mnt

# Ulimit
echo "mongodb soft nofile  64000" | sudo tee -a /etc/security/limits.conf
echo "mongodb hard nofile  64000" | sudo tee -a /etc/security/limits.conf
echo "mongodb soft nproc  64000" | sudo tee -a /etc/security/limits.conf
echo "mongodb hard nproc  64000" | sudo tee -a /etc/security/limits.conf

sudo chown mongodb:mongodb $DIR/keyFile
sudo chmod 400 $DIR/keyFile

# Automation Agent
#if [ ! -f mongodb-mms-automation-agent-manager_3.8.0.2108-1_amd64.ubuntu1604.deb ]; then
    #curl -OL https://cloud.mongodb.com/download/agent/automation/mongodb-mms-automation-agent-manager_3.8.0.2108-1_amd64.ubuntu1604.deb -o $DIR
#fi
#sudo dpkg -i /home/ubuntu/mongodb-mms-automation-agent-manager_3.8.0.2108-1_amd64.ubuntu1604.deb
#sudo sed -i -e 's/mmsGroupId=.*/mmsGroupId=59264931c0c6e3441afb202f/g' /etc/mongodb-mms/automation-agent.config
#sudo sed -i -e 's/mmsApiKey=.*/mmsApiKey=10073a430543badf04ff6a2d8b8235d2/g' /etc/mongodb-mms/automation-agent.config
#sudo systemctl restart mongodb-mms-automation-agent.service

# Monitoring Agent - will install via CM API
# curl -OL https://cloud.mongodb.com/download/agent/monitoring/mongodb-mms-monitoring-agent_5.7.0.368-1_amd64.ubuntu1604.deb -o $DIR
# sudo dpkg -i /home/ubuntu/mongodb-mms-monitoring-agent_5.7.0.368-1_amd64.ubuntu1604.deb
# sudo sed -i -e 's/mmsApiKey=/mmsApiKey=10073a430543badf04ff6a2d8b8235d2/g' /etc/mongodb-mms/monitoring-agent.config
# sudo systemctl start mongodb-mms-monitoring-agent.service

# iostat/sar
sudo apt-get -y install sysstat

# TCP keepalive
sudo sysctl -w net.ipv4.tcp_keepalive_time=120
echo "net.ipv4.tcp_keepalive_time = 120" | sudo tee -a /etc/sysctl.conf

sudo sysctl -w fs.file-max=98000
sudo sysctl -w kernel.pid_max=64000
sudo sysctl -w kernel.threads-max=64000
echo "fs.file-max=98000" | sudo tee -a /etc/sysctl.conf
echo "kernel.pid_max=64000" | sudo tee -a /etc/sysctl.conf
echo "kernel.threads-max=64000" | sudo tee -a /etc/sysctl.conf

# Readahead - MMAPv1
#sudo blockdev --setra 32 /dev/nvme0n1

# TPH
sudo cp $DIR/disable-transparent-hugepages /etc/init.d
sudo chmod 755 /etc/init.d/disable-transparent-hugepages
sudo update-rc.d disable-transparent-hugepages defaults
sudo /etc/init.d/disable-transparent-hugepages start

# Install MongoDB
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# Run mdiag
curl -OL https://raw.githubusercontent.com/mongodb/support-tools/master/mdiag/mdiag.sh -o $DIR
#sudo bash mdiag.sh

# Install python
#sudo apt-get -y install python-pip
#sudo apt-get -y install python-dev
#sudo pip install pymongo
#sudo pip install requests

#sudo apt install unzip

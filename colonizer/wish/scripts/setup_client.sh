#!/bin/bash -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


#scp ubuntu@ec2-52-23-186-25.compute-1.amazonaws.com:/home/ubuntu/ogma.tar $DIR
#tar -xvf $DIR/ogma.tar 
#scp ubuntu@ec2-52-23-186-25.compute-1.amazonaws.com:/home/ubuntu/ycsb-0.12.0.tar.gz $DIR
#tar -xzvf $DIR/ycsb-0.12.0.tar.gz 

if [ ! -f $DIR/ycsb-0.12.0.tar.gz ]; then
    curl -OL https://github.com/brianfrankcooper/YCSB/releases/download/0.12.0/ycsb-0.12.0.tar.gz $DIR
    tar -xzvf $DIR/ycsb-0.12.0.tar.gz
fi

sudo apt-get update
#sudo apt-get -y install nodejs
#sudo apt-get -y install npm
#sudo npm install json
sudo apt-get -y install default-jdk
sudo apt-get -y install python-dev
sudo apt-get -y install python-pip
sudo apt-get install -y libssl-dev
sudo pip install pymongo
sudo pip install paramiko
sudo pip install futures
sudo pip install pyyaml
#sudo pip install --upgrade --user awscli
#sudo apt install ec2-api-tools

#echo -e  'y\n'|ssh-keygen -t rsa -f $DIR/.ssh/id_rsa -N ""

#openssl rand -base64 756 > $DIR/keyFile
#chmod 400 $DIR/keyFile

#Install Monitoring Agent
if [ $# -gt 0 ]; then
    mmsGroupId=$1
    mmsApiKey=$2
    curl -OL https://cloud.mongodb.com/download/agent/monitoring/mongodb-mms-monitoring-agent_6.0.0.381-1_amd64.ubuntu1604.deb
    sudo dpkg -i mongodb-mms-monitoring-agent_6.0.0.381-1_amd64.ubuntu1604.deb
    sudo sed -i -e "s/mmsGroupId=.*/mmsGroupId=${mmsGroupId}/g" /etc/mongodb-mms/monitoring-agent.config
    sudo sed -i -e "s/mmsApiKey=/mmsApiKey=${mmsApiKey}/g" /etc/mongodb-mms/monitoring-agent.config
    sudo systemctl start mongodb-mms-monitoring-agent.service
fi

#!/bin/bash -v
yum -y install epel-release
yum -y update
yum -y groupinstall "Development Tools"
yum -y install python-matplotlib python-matplotlib-qt4 xauth tree htop git python2-pip wget python-devel
pip install --upgrade pip
/usr/local/bin/pip install mtools
wget -O /tmp/winrar.tar.gz http://www.rarlab.com/rar/rarlinux-x64-5.4.0.tar.gz
cd /tmp
tar -xzvf /tmp/winrar.tar.gz rar/unrar 
mv -v /tmp/rar/unrar /usr/local/bin/
git clone https://github.com/aheckmann/m.git
cd m
make install
mkdir -p /data/db
chown -R centos. /data
echo "set -o vi" >> ~centos/.bashrc

#!/bin/bash

check_sshd_stat=`ps -ef | grep sshd | grep -v grep | awk '{print $2}'`
while [ ! "$check_sshd_stat" ]; do
  echo -e "\033[1;36mWaiting for sshd..."
  sleep 1
done
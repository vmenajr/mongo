#!/bin/bash
yum -y install epel-release
yum -y groupinstall "Development Tools"
yum -y install \
	multitail \
    socat \
    nmap-ncat \
    yum-utils \
    tree \
    vim \
    vim-enhanced \
    git \
    psmisc \
    strace \
    man-db \
    man-pages \
    bind-utils \
    the_silver_searcher \
    htop \
    lsof \
    perf \
    python-devel \
    python2-pip \
    glibc-devel.i686 \
    libstdc++-devel.i686

pip install -U pip
pip install pwn

git clone https://github.com/longld/peda.git ~/peda
echo "source ~/peda/peda.py" >> ~/.gdbinit

EXECUTABLE=/tmp/jumpy.tsk
g++ -m32 -ggdb -o ${EXECUTABLE} /vagrant/jumpy.cpp

echo "stone function addresses"
objdump -t ${EXECUTABLE} | grep -E 'stone1|stone2|stone3'

echo "Target location in main"
gdb -batch -ex "file $EXECUTABLE" -ex "disassemble/m main" | grep -A5 'Nice work'

echo "Make sure ASLR is enabled"
sysctl -w kernel.randomize_va_space=2

echo "Exploit to win"
cd /tmp
python /vagrant/print_flag.py
echo


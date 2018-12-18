## Set readhead before MongoDB starts

Systemd service which sets the readhead to a user supplied value (default 0) on the given LVM mounted path (default /) devices.  The service script attempts to identify the LVM devices associated with the mount point.  The service runs **before** MongoDB starts and is meant to be used in the absence of tuned.

**Note:** See the following sample tuned profiles for systems running with tuned enabled: https://github.com/vmenajr/mongo/tree/master/tuned

### Tested
* Centos 7.4+

### Pre-requisites
* df
* lvm
* blockdev

### Installation

The installation consists of three files:
* set_readhead.service -> /usr/lib/systemd/system/set_readahead.service (service file)
* set_readahead.sh -> /usr/local/sbin/set_readahead.sh (service script)
* set_readahead -> /etc/sysconfig/set_readahead (default values)

To keep the service flexible the defaults can be changed by manipulating `/etc/sysconfig/set_readahead` with the user specific values
```
path=/path/to/mongodb/data
ra=0
```

Use the included easy install script to copy the files to their proper locations and to trigger the service.
```
# As root
cd /tmp
curl -LO https://raw.githubusercontent.com/vmenajr/mongo/master/systemd/install.sh
chmod +x install.sh
./install.sh
```


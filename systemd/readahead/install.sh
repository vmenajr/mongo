#!/usr/bin/env bash
function abend() {
    echo $@
    exit -1
}

set -x
base_url=https://raw.githubusercontent.com/vmenajr/mongo/master/systemd/readahead
curl -L ${base_url}/set_readahead.service -o /usr/lib/systemd/system/set_readahead.service || abend Cannot download set_readahead.service from ${base_url}
curl -L ${base_url}/set_readahead.sh -o /usr/local/sbin/set_readahead.sh || abend Cannot download set_readahead.sh from ${base_url}
curl -L ${base_url}/set_readahead -o /etc/sysconfig/set_readahead || abend Cannot download set_readahead from ${base_url}

systemctl daemon-reload
systemctl enable set_readahead
systemctl start set_readahead
systemctl status -l set_readahead


#!/bin/bash -x
(cat <<EOF
${ssh_keys}
EOF
) > ~colonizer/.ssh/authorized_keys

# Prepare /data
device=/dev/xvdg
if [ "${allow_nvme}" != "0" ] && $(sudo lsblk | grep -q nvme); then
    device=/dev/nvme0n1
fi
mkfs -t xfs -f -L mdb $device
echo "LABEL=mdb       /data   xfs	defaults,auto,noatime,noexec   0 0" | tee -a /etc/fstab
mkdir /data
mount -a
chown -R colonizer. /data


## Quick Install

The installation script pulls down the profile requested (virtual or physical) then activates it

### General
```
cd /tmp
curl -LO https://raw.githubusercontent.com/vmenajr/mongo/master/tuned/configure-tuned.sh
chmod +x /tmp/configure-tuned.sh
```

### Activate profile (Use the appropriate profile name for your system)
```
sudo /tmp/configure-tuned.sh mongodb-wt-virtual
```


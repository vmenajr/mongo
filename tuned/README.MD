## Quick Install

### Virtualized Server
```
# Execute as root
target=/usr/lib/tuned/mongodb-wt-virtual
mkdir ${target} && cd ${target} && curl -LO https://raw.githubusercontent.com/vmenajr/mongo/master/tuned/mongodb-wt-virtual/tuned.conf
tuned-adm profile mongodb-wt-virtual
tuned-adm active
```

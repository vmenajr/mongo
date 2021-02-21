port=27017
for (i=0, len=hosts.length; i<len; i+=3) {
    id=i/3
    shard_hosts=hosts.slice(i, i+3).map(function(h) {
        return h+':'+port
    })
    sh.addShard('shard'+id+'/'+shard_hosts)
}
sh.status()


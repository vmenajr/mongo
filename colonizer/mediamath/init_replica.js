rsconf={ _id: rsid, members: []}
count=0
port=27017
hosts.forEach(function(h) {
	rsconf.members.push({_id: count, host: h+':'+port})
	count++
});
rs.initiate(rsconf)
rs.status()


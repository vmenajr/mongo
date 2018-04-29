/**
 * Number.prototype.format(n, x)
 * 
 * @param integer n: length of decimal
 * @param integer x: length of sections
 */
Number.prototype.format = function(n, x) {
    var re = '\\d(?=(\\d{' + (x || 3) + '})+' + (n > 0 ? '\\.' : '$') + ')';
    return this.toFixed(Math.max(0, ~~n)).replace(new RegExp(re, 'g'), '$&,');
};

function collectionStats(coll) {
	var s=coll.stats().wiredTiger['block-manager'];
	ckps=s['checkpoint size']
	used=s['file size in bytes']
	avail=s['file bytes available for reuse']
	percent=(avail/used*100)
	print(coll.getName())
	print("     Used: "+used.format())
	print("Available: "+avail.format()+' ('+percent.format(2)+'%)')
	print()
	return [used, avail]
}

function storageStats(dbName, collName) {
	var theDB=db.getSiblingDB(dbName)
	var colls
	if (collName) {
		colls= [].concat(collName)
	}
	else {
		colls= theDB.getCollectionNames()
	}
	var used = 0
	var avail = 0
	colls.forEach(function(name){
		rc=collectionStats(theDB.getCollection(name))
		used +=rc[0]
		avail +=rc[1]
	})
	percent=(avail/used*100)
	print("Totals")
	print("     Used: "+used.format())
	print("Available: "+avail.format()+' ('+percent.format(2)+'%)')
	print()
}

function getDatabaseNames() {
    return db.adminCommand("listDatabases").databases.map(function(x){ return x.name; });
}

function fileNamesForDB(dbName) {
    var dbs = []
    if (dbName == undefined) {
        dbs=dbs.concat(getDatabaseNames())
    }
    else {
        dbs=dbs.concat(dbName)
    }

    dbs.forEach(function(name) {
        var dB=db.getSiblingDB(name)
        dB.getCollectionNames().forEach(function(colName){ 
            c=dB.getCollection(colName).stats({indexDetails:true})
            print(c.ns)
            print("    ", c.wiredTiger.uri.split(":")[2])
            Object.keys(c.indexDetails).forEach(function(idxName) {
                print("    ", c.indexDetails[idxName].uri.split(":")[2], "("+idxName+")")
            })
        })
    })
}


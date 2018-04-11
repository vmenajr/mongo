function getRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

sh.chunkDataSize = function(ns, key, kmin, kmax, est) {
    return sh._adminCommand(
        { dataSize: ns, keyPattern: key, min: kmin, max: kmax, estimate: est }
    );
}

sh.mergeChunks = function(ns, first, next) {
    return sh._adminCommand(
        { mergeChunks: ns, bounds: [ first, next ] }
    );
}

function sendtoscreen(obj) {
	printjson(obj.toArray())
}

function configDB() {
	return db.getSiblingDB("config");
}

oldhelp=sh.help
sh.help = function() {
	oldhelp()
	print("\tsh.op_count()                            Number of operations")
	print("\tsh.ops_by_hour()                         Operations by hour")
	print("\tsh.ops_by_hour_not_aborted()             Unaborted operations by hour")
	print("\tsh.ops_by_hour_not_aborted_condensed()   Condensed view")
	print("\tsh.ops_by_ns()                           Operations by namespace")
	print("\tsh.splits_and_migrations()               Operations by namespace")
	print("\tsh.errors_by_phase()                     Errors by phase")
	print("\tsh.covered_period()                      Period covered by changelog")
	print("\tsh.first_last_migration()                First and last successful migrations")
	print("\tsh.moves_by_donor()                      Shard moves sorted by donor")
	print("\tsh.rates_and_volumes()                   Successful migration rates and volumes")
}

sh.op_count = function() {
	sendtoscreen(
		configDB().changelog.aggregate([
			{ $group : { _id : { what : "$what", note : "$details.note" }, total : { $sum : 1  } } } 
		])
	)
}

sh.ops_by_hour = function() {
	sendtoscreen(
		configDB().changelog.aggregate([
			{ $project : { day : { $dayOfYear : "$time" }, time : { $hour : "$time" }, what : "$what", note : "$details.note" } }, 
			{ $group : { _id : { day : "$day", time : "$time", what : "$what", note : "$note" }, count : { $sum : 1 } } }, 
			{ $sort : { "_id.day" : 1, "_id.time" : 1 } } 
		])
	)
}

sh.ops_by_hour_not_aborted = function() {
	sendtoscreen(
		configDB().changelog.aggregate([
			{ $match : { "details.note" : { $ne : 'aborted' } } },
			{ $project : { day : { $dayOfYear : "$time" }, time : { $hour : "$time" }, what : "$what" } },
			{ $group : { _id : { day : "$day", time : "$time", what : "$what" }, count : { $sum : 1 } } },
			{ $sort : { "_id.day" : 1, "_id.time" : 1 } }
		])
	)
}

sh.ops_by_hour_not_aborted_condensed = function() {
	configDB().changelog.aggregate([
		{ $match : { "details.note" : { $ne : 'aborted' } } },
		{ $project : { day : { $dayOfYear : "$time" }, time : { $hour : "$time" }, what : "$what" } },
		{ $group : { _id : { day : "$day", time : "$time", what : "$what" }, count : { $sum : 1 } } },
		{ $sort : { "_id.day" : 1, "_id.time" : 1 } }
	]).forEach(function(cl){ printjsononeline(cl);});
}

sh.ops_by_ns = function() {
	sendtoscreen(
		configDB().changelog.aggregate([
			{ $group : { _id : { what : "$what", ns : "$ns", note : "$details.note" }, total : { $sum : 1  } } },
			{ $sort : { "_id.ns" : 1, "_id.what" : 1 } } 
		])
	)
}

sh.splits_and_migrations = function() {
	sendtoscreen(
		configDB().changelog.aggregate([
			{$group: {
				_id:{ "ns":"$ns","server":"$server"},
				multiSplits:{$sum:{$cond:[{$eq:["$what","multi-split"]},1,0]}},
				splits:{$sum:{$cond:[{$eq:["$what","split"]},1,0]}},
				migrationAttempts:{$sum:{$cond:[{$eq:["$what","moveChunk.from"]},1,0]}},
				migrationFailures:{$sum:{$cond:[ {$eq:["$details.note","aborted" ]} ,1,0]}},
				migrations:{$sum:{$cond:[{$eq:["$what","moveChunk.commit"]},1,0]}}
			} },
			{ $sort: { _id:1, multiSplits: -1, splits: -1 } }
		])
	)
}

sh.errors_by_phase = function() {
	sendtoscreen(
		configDB().changelog.aggregate([
			{ $match : { "details.note" : 'aborted' } },
			{ $group : { _id : { what : "$what", errmsg : "$details.errmsg" }, count : { $sum : 1 } } },
			{ $sort : { "_id.what" : 1, count : -1 } }
		])
	)
}

sh.covered_period = function() {
	sendtoscreen( configDB().changelog.find({},{_id:0, time:1}).limit(1) )
	sendtoscreen( configDB().changelog.find({},{_id:0, time:1}).sort({$natural:-1}).limit(1) )
}

sh.first_last_migration = function() {
	sendtoscreen( configDB().changelog.find({what:"moveChunk.commit"},{_id:0, time:1}).limit(1) )
	sendtoscreen( configDB().changelog.find({what:"moveChunk.commit"},{_id:0, time:1}).sort({$natural:-1}).limit(1) )
}

sh.moves_by_donor = function() {
	sendtoscreen(
		configDB().changelog.aggregate([
			{ $match: { "what" : "moveChunk.start" }},
			{ $group : { _id: { from: "$details.from", ns : "$ns"}, count: { $sum : 1 } } },
			{ $sort : { "count" : -1 } }
		])
	)
}

sh.rates_and_volumes = function() {
	sendtoscreen(
		configDB().changelog.aggregate([
			{ $match: { what: { "$in": [ "moveChunk.commit", "moveChunk.start" ] } } },
			{ $project: { _id: 0,
				what: "$what", time: "$time",
				uniqueDetails: {
					from: "$details.from", to: "$details.to",
					mink: "$details.min", maxk: "$details.max",
					ns: "$ns" },
				sizeInfo: {
					cloned: "$details.cloned",
					bytes: "$details.clonedBytes" }, } },
			{ $group: {
				_id: "$uniqueDetails",
				start: { "$min": "$time" },
				commit: { "$max": "$time" },
				count: { "$sum": 1 },
				cloned: { "$max": "$sizeInfo.cloned"},
				bytes: { "$max": "$sizeInfo.bytes" } } },
			{ $project: { _id: "$_id",
				whenStart: "$start", whenDone: "$commit",
				bytesMoved: "$bytes", docsMoved: "$cloned",
				moveTime_ms: { "$subtract": [ "$commit", "$start" ] } } },
			{ $match: { bytesMoved: { "$ne": null }, moveTime_ms: { "$ne": 0 } } },
			{ $project: { _id: "$_id",
				whenStart: "$whenStart", whenDone: "$whenDone",
				moveTime_ms: "$moveTime_ms",
				bytesMoved: "$bytesMoved", docsMoved: "$docsMoved",
				bytesPer_ms: { "$divide": [ "$bytesMoved", "$moveTime_ms" ] },
				docsPer_ms: { "$divide": [ "$docsMoved", "$moveTime_ms" ] } } },
			// outputs stats for each chunk moved ...
			{ $project: { _id: "$_id",
				whenStart: "$whenStart", whenDone: "$whenDone",
				moveTime_ms: "$moveTime_ms",
				bytesMoved: "$bytesMoved", docsMoved: "$docsMoved",
				docsPer_sec: { "$multiply": [ "$docsPer_ms", 1000.0 ] },
				MBper_sec: { "$divide": [ "$bytesPer_ms", 1048.576 ] } } }
			// optionally limit to date range, or etc...
			// , { $match: {
			//    whenStart: { "$gte": ISODate("2017-08-09T00:00:00.000Z") },
			//    whenDone: { "$lt": ISODate("2017-08-10T00:00:00.000Z") } } }
			// optionally get averages per shard-pair, or per sending shard or receiving shard or per collection, etc.
			// , { $group: {
			//    _id: "$_id.from",  // example: from-shard stats
			//    // _id: { "$_id.from", "$_id.to" }, // example: shard pair stats,
			//    // _id: { "$_id.ns" }, // example: collection chunk stats
			//    minMoveTime_ms: { "$min": "$moveTime_ms" },
			//    avgMoveTime_ms: { "$avg": "$moveTime_ms" },
			//    maxMoveTime_ms: { "$max": "$moveTime_ms" },
			//    stdevMoveTime_ms: { "$stdDevPop": "$moveTime_ms" },
			//    minMBper_sec: { "$min": "$MBper_sec" },
			//    avgMBper_sec: { "$avg": "$MBper_sec" },
			//    maxMBper_sec: { "$max": "$MBper_sec" },
			//    stdevMBper_sec: { "$stdDevPop": "$MBper_sec" } } }
			// optionally, sort for time charting or hot shards by long-time or large volume, etc., output to collection, etc.
			//, { $sort: { whenDone: 1 } }
			//, { $out: "__chunkMoveStats__" }
		])
	)
}

sh.hot_shard = function() {
	sendtoscreen(
		configDB().changelog.aggregate([
			{$group: {
				_id:{ "ns":"$ns","server":"$server"},
				multiSplits:{$sum:{$cond:[{$eq:["$what","multi-split"]},1,0]}},
				splits:{$sum:{$cond:[{$eq:["$what","split"]},1,0]}},
				migrationAttempts:{$sum:{$cond:[{$eq:["$what","moveChunk.from"]},1,0]}},
				migrationFailures:{$sum:{$cond:[ {$eq:["$details.note","aborted" ]} ,1,0]}},
				migrations:{$sum:{$cond:[{$eq:["$what","moveChunk.commit"]},1,0]}}
			} },
			{ $sort: { _id:1, multiSplits: -1, splits: -1 } }
		])
	)
}

//function printShardingStatus(configDB, verbose) {
    //// configDB is a DB object that contains the sharding metadata of interest.
    //// Defaults to the db named "config" on the current connection.
    //if (configDB === undefined)
        //configDB = db.getSisterDB('config');

    //var version = configDB.getCollection("version").findOne();
    //if (version == null) {
        //print(
            //"printShardingStatus: this db does not have sharding enabled. be sure you are connecting to a mongos from the shell and not to a mongod.");
        //return;
    //}

    //var raw = "";
    //var output = function(indent, s) {
        //raw += sh._shardingStatusStr(indent, s);
    //};
    //output(0, "--- Sharding Status --- ");
    //output(1, "sharding version: " + tojson(configDB.getCollection("version").findOne()));

    //output(1, "shards:");
    //configDB.shards.find().sort({_id: 1}).forEach(function(z) {
        //output(2, tojsononeline(z));
    //});

    //// (most recently) active mongoses
    //var mongosActiveThresholdMs = 60000;
    //var mostRecentMongos = configDB.mongos.find().sort({ping: -1}).limit(1);
    //var mostRecentMongosTime = null;
    //var mongosAdjective = "most recently active";
    //if (mostRecentMongos.hasNext()) {
        //mostRecentMongosTime = mostRecentMongos.next().ping;
        //// Mongoses older than the threshold are the most recent, but cannot be
        //// considered "active" mongoses. (This is more likely to be an old(er)
        //// configdb dump, or all the mongoses have been stopped.)
        //if (mostRecentMongosTime.getTime() >= Date.now() - mongosActiveThresholdMs) {
            //mongosAdjective = "active";
        //}
    //}

    //output(1, mongosAdjective + " mongoses:");
    //if (mostRecentMongosTime === null) {
        //output(2, "none");
    //} else {
        //var recentMongosQuery = {
            //ping: {
                //$gt: (function() {
                    //var d = mostRecentMongosTime;
                    //d.setTime(d.getTime() - mongosActiveThresholdMs);
                    //return d;
                //})()
            //}
        //};

        //if (verbose) {
            //configDB.mongos.find(recentMongosQuery).sort({ping: -1}).forEach(function(z) {
                //output(2, tojsononeline(z));
            //});
        //} else {
            //configDB.mongos
                //.aggregate([
                    //{$match: recentMongosQuery},
                    //{$group: {_id: "$mongoVersion", num: {$sum: 1}}},
                    //{$sort: {num: -1}}
                //])
                //.forEach(function(z) {
                    //output(2, tojson(z._id) + " : " + z.num);
                //});
        //}
    //}

    //output(1, "autosplit:");

    //// Is autosplit currently enabled
    //output(2, "Currently enabled: " + (sh.getShouldAutoSplit(configDB) ? "yes" : "no"));

    //output(1, "balancer:");

    //// Is the balancer currently enabled
    //output(2, "Currently enabled:  " + (sh.getBalancerState(configDB) ? "yes" : "no"));

    //// Is the balancer currently active
    //var balancerRunning = "unknown";
    //var balancerStatus = configDB.adminCommand({balancerStatus: 1});
    //if (balancerStatus.code != ErrorCodes.CommandNotFound) {
        //balancerRunning = balancerStatus.inBalancerRound ? "yes" : "no";
    //}
    //output(2, "Currently running:  " + balancerRunning);

    //// Output the balancer window
    //var balSettings = sh.getBalancerWindow(configDB);
    //if (balSettings) {
        //output(3,
               //"Balancer active window is set between " + balSettings.start + " and " +
                   //balSettings.stop + " server local time");
    //}

    //// Output the list of active migrations
    //var activeMigrations = sh.getActiveMigrations(configDB);
    //if (activeMigrations.length > 0) {
        //output(2, "Collections with active migrations: ");
        //activeMigrations.forEach(function(migration) {
            //output(3, migration._id + " started at " + migration.when);
        //});
    //}

    //// Actionlog and version checking only works on 2.7 and greater
    //var versionHasActionlog = false;
    //var metaDataVersion = configDB.getCollection("version").findOne().currentVersion;
    //if (metaDataVersion > 5) {
        //versionHasActionlog = true;
    //}
    //if (metaDataVersion == 5) {
        //var verArray = db.serverBuildInfo().versionArray;
        //if (verArray[0] == 2 && verArray[1] > 6) {
            //versionHasActionlog = true;
        //}
    //}

    //if (versionHasActionlog) {
        //// Review config.actionlog for errors
        //var actionReport = sh.getRecentFailedRounds(configDB);
        //// Always print the number of failed rounds
        //output(2, "Failed balancer rounds in last 5 attempts:  " + actionReport.count);

        //// Only print the errors if there are any
        //if (actionReport.count > 0) {
            //output(2, "Last reported error:  " + actionReport.lastErr);
            //output(2, "Time of Reported error:  " + actionReport.lastTime);
        //}

        //output(2, "Migration Results for the last 24 hours: ");
        //var migrations = sh.getRecentMigrations(configDB);
        //if (migrations.length > 0) {
            //migrations.forEach(function(x) {
                //if (x._id === "Success") {
                    //output(3, x.count + " : " + x._id);
                //} else {
                    //output(3,
                           //x.count + " : Failed with error '" + x._id + "', from " + x.from +
                               //" to " + x.to);
                //}
            //});
        //} else {
            //output(3, "No recent migrations");
        //}
    //}

    //output(1, "databases:");

    //var databases = configDB.databases.find().sort({name: 1}).toArray();

    //// Special case the config db, since it doesn't have a record in config.databases.
    //databases.push({"_id": "config", "primary": "config", "partitioned": true});
    //databases.sort(function(a, b) {
        //return a["_id"] > b["_id"];
    //});

    //databases.forEach(function(db) {
        //var truthy = function(value) {
            //return !!value;
        //};
        //var nonBooleanNote = function(name, value) {
            //// If the given value is not a boolean, return a string of the
            //// form " (<name>: <value>)", where <value> is converted to JSON.
            //var t = typeof(value);
            //var s = "";
            //if (t != "boolean" && t != "undefined") {
                //s = " (" + name + ": " + tojson(value) + ")";
            //}
            //return s;
        //};

        //output(2, tojsononeline(db, "", true));

        //if (db.partitioned) {
            //configDB.collections.find({_id: new RegExp("^" + RegExp.escape(db._id) + "\\.")})
                //.sort({_id: 1})
                //.forEach(function(coll) {
                    //if (!coll.dropped) {
                        //output(3, coll._id);
                        //output(4, "shard key: " + tojson(coll.key));
                        //output(4,
                               //"unique: " + truthy(coll.unique) +
                                   //nonBooleanNote("unique", coll.unique));
                        //output(4,
                               //"balancing: " + !truthy(coll.noBalance) +
                                   //nonBooleanNote("noBalance", coll.noBalance));
                        //output(4, "chunks:");

                        //res = configDB.chunks
                                  //.aggregate({$match: {ns: coll._id}},
                                             //{$group: {_id: "$shard", cnt: {$sum: 1}}},
                                             //{$project: {_id: 0, shard: "$_id", nChunks: "$cnt"}},
                                             //{$sort: {shard: 1}})
                                  //.toArray();
                        //var totalChunks = 0;
                        //res.forEach(function(z) {
                            //totalChunks += z.nChunks;
                            //output(5, z.shard + "\t" + z.nChunks);
                        //});

                        //if (totalChunks < 20 || verbose) {
                            //configDB.chunks.find({"ns": coll._id})
                                //.sort({min: 1})
                                //.forEach(function(chunk) {
                                    //output(4,
                                           //tojson(chunk.min) + " -->> " + tojson(chunk.max) +
                                               //" on : " + chunk.shard + " " +
                                               //tojson(chunk.lastmod) + " " +
                                               //(chunk.jumbo ? "jumbo " : ""));
                                //});
                        //} else {
                            //output(
                                //4,
                                //"too many chunks to print, use verbose if you want to force print");
                        //}

                        //configDB.tags.find({ns: coll._id}).sort({min: 1}).forEach(function(tag) {
                            //output(4,
                                   //" tag: " + tag.tag + "  " + tojson(tag.min) + " -->> " +
                                       //tojson(tag.max));
                        //});
                    //}
                //});
        //}
    //});

    //print(raw);
//}

    //if (config === undefined)
        //config = db.getSisterDB('config');


//sh.rebalance = function(ns) {
    //// configDB is a DB object that contains the sharding metadata of interest.
    //// Defaults to the db named "config" on the current connection.
    //if (configDB === undefined)
        //configDB = db.getSiblingDB('config');


    //var saveDB = db;
    //output(1, "databases:");
    //configDB.databases.find().sort({name: 1}).forEach(function(db) {
        //output(2, tojson(db, "", true));

    //var shard = undefined;
    //var prevChunk = undefined;
    //var coll = configDB.collections.findOne({_id: ns});
    //var runningSize = 0;

    //configDB.chunks.find({"ns": coll._id}).sort({shard:1, min: 1}).forEach(function(chunk) {
        //var ds = sh.chunkDataSize(coll._id, coll.key, chunk.min, chunk.max, true);
        //runningSize += ds


        //var mydb = shards[chunk.shard].getDB(db._id);
        //var out = mydb.runCommand({
            //dataSize: coll._id,
            //keyPattern: coll.key,
            //min: chunk.min,
            //max: chunk.max
        //});
        //delete out.millis;
        //delete out.ok;

        //output(4,
            //tojson(chunk.min) + " -->> " + tojson(chunk.max) + " on : " +
            //chunk.shard + " " + tojson(out));

    //});



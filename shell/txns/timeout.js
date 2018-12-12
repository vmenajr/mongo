let start = null
let end = null
const lifetime = 1
const sleepDelay = 60

rcrn = { };
rcrn.level = "snapshot";

wcrn = { };
wcrn.w = "majority";
wcrn.wtimeout = 10;

concerns = { };
concerns.readConcern = rcrn;
concerns.writeConcern= wcrn;
printjson(concerns);

db.getSiblingDB("test").runCommand({dropDatabase:1, writeConcern: wcrn});
db.createCollection('c', {writeConcern: wcrn});
db.c.insertOne({_id:1});
sleep(100)

db.adminCommand( { setParameter: 1, transactionLifetimeLimitSeconds: lifetime } )

session = db.getMongo().startSession( { readPreference: { mode: "primary" } } );
print("Session:", session);

try {
	start = Date.now()
	print("Starting:", start);
	session.startTransaction()
	col = session.getDatabase("test").c;
	try {
		print("Sleeping for", sleepDelay, "s")
		let cmd="sleep("+sleepDelay+"*1000)"
		col.find({$where: cmd}).toArray()
	}
    catch (error) {
		print("Operation exception, aborting txn...");
		session.abortTransaction()
		throw error;
	}
	print("Commit:", Date.now())
	session.commitTransaction()
}
catch (error) {
    print("Transaction exception");
	print(error);
}
finally {
	end = Date.now();
	print("End:", end);
	session.endSession()
}

db.adminCommand( { setParameter: 1, transactionLifetimeLimitSeconds: 60 } )
print("Runtime:" , (end - start ) / 1000)
db.c.find().sort({_id:-1}).limit(1).shellPrint()


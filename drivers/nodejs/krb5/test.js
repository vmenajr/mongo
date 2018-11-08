const { MongoClient } = require('mongodb');
const { format } = require('util');
const usr  = encodeURIComponent('vick@MDB.ORG');
const pwd  = encodeURIComponent('L,4\;?GzBs3{2LjU');
const host = 'ip-10-1-1-122.us-east-2.compute.internal:27017';
const usepwd = true;

if (usepwd) {
	uri = format('mongodb://%s:%s@%s/test?authMechanism=GSSAPI', usr, pwd, host);
}
else {
	uri = format('mongodb://%s@%s/test?authMechanism=GSSAPI', usr, host);
}
console.log(uri);

async function main() {
	const client = new MongoClient(uri, { useNewUrlParser: true, loggerLevel: 'info'});
	try {
		await client.connect();
	}
	catch (e) {
		console.log('error: '+e);
		return;
	}

	try {
		const coll = client.db('test').collection('c');
		const docs = await coll.findOne();
		console.log(`success: ${JSON.stringify(docs)}`);
	}
	catch (e) {
		console.log('error: '+e);
	}
	finally {
		await client.close();
	}

	// const result = await coll.insertOne({ a: 42 });
	//const docs = await coll.find({ _id: result.insertedId }).toArray();
}


//main().catch(console.log);
main()


const { MongoClient } = require('mongodb');
const { format } = require('util');
const assert = require('assert').strict;

assert(process.argv.length > 2, format('Usage: node %s host:port <password>', process.argv[1]));

const host = process.argv[2];
const usr  = encodeURIComponent('test@MDB.ORG');
let   uri = format('mongodb://%s@%s/test?authMechanism=GSSAPI', usr, host);
if (process.argv.length > 3) {
	const pwd  = encodeURIComponent(process.argv[3]);
	uri = format('mongodb://%s:%s@%s/test?authMechanism=GSSAPI', usr, pwd, host);
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

}

main()


const { MongoClient } = require('mongodb');
const { format } = require('util');
const assert = require('assert').strict;

assert(process.argv.length > 4, format('Usage: node %s host:port user password', process.argv[1]));

const host = process.argv[2];
const usr  = encodeURIComponent(process.argv[3]);
const pwd  = encodeURIComponent(process.argv[4]);
let   uri = format('mongodb+srv://%s:%s@%s/test?authSource=admin&retryWrites=true', usr, pwd, host)
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


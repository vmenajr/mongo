const Promise = require('promise');
const http = require("http");
const MongoClient = require('mongodb').MongoClient;
const assert = require('assert');
const url = 'mongodb://localhost:12108/test?socketTimeoutMS=15000&poolSize=1';
//const url = 'mongodb://localhost:12108/test?socketTimeoutMS=15000&poolSize=5&readPreference=secondaryPreferred';
const dbName = 'test';
const options = {
    useNewUrlParser:  true,
    loggerLevel:      "info"
};

var mdbClient = null;

const server = http.createServer(function (request, response) {
    response.writeHead(200, {'Content-Type': 'text/plain'});
    const db = mdbClient.db(dbName);
    const col = db.collection("c");
    col.findOne({}, null, function(err, doc) {
        if (err) {
            response.end("Database error");
        }
        else {
            response.end(JSON.stringify(doc)+"\n");
        }
    });
});

function startServer() {
    return new Promise(resolve => {
        server.listen({port: 8081, host: 'localhost'});
        resolve('Server running at http://127.0.0.1:8081/');
    });
}

async function main() {
    try {
        mdbClient = await MongoClient.connect(url, options);
        console.log("MDB Connected");
    }
    catch (e) {
        console.log("MDB Connection Failed:", e, "\n");
        process.exit(-1);
    }

    var msg = await startServer();
    console.log(msg);
}

main();

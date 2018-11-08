from sys import argv as args
from pymongo import MongoClient
from pprint import pprint
from urllib import quote_plus as urlquote

assert len(args) > 1, 'Usage: {} host:port <password>'.format(args[0])

hostport = args[1]
usr = urlquote('test@MDB.ORG')
uri = 'mongodb://{}@{}/test?authMechanism=GSSAPI'.format(usr, hostport)
if len(args) > 2:
    pwd = urlquote(args[2])
    uri = 'mongodb://{}:{}@{}/test?authMechanism=GSSAPI'.format(usr, pwd, hostport)

pprint(uri)

client = MongoClient(uri)
db=client['test']
col=db['c']
pprint(col.find_one())



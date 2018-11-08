from pymongo import MongoClient
from pprint import pprint
from urllib import quote_plus as encode

usr = 'vick%40MDB.ORG'
pwd = encode("L,4\;?GzBs3{2LjU")
hostport = 'ip-10-1-1-122.us-east-2.compute.internal:27017'
usepwd = False
if (usepwd):
    uri = 'mongodb://{}:{}@{}/test?authMechanism=GSSAPI'.format(usr, pwd, hostport)
else:
    uri = 'mongodb://{}@{}/test?authMechanism=GSSAPI'.format(usr, hostport)

pprint(uri)
client = MongoClient(uri)
db=client['test']
col=db['c']
pprint(col.find_one())



SETLOCAL
set usr="test@MDB.ORG"
set mdb="ip-10-1-1-122.us-east-2.compute.internal"
"C:\Program Files\MongoDB\Server\4.0\bin\mongo.exe" --host %mdb% --authenticationMechanism GSSAPI --authenticationDatabase "$external" -u %usr% --eval "db.c.findOne()"
pause


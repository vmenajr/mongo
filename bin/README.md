## Parse the MongoDB catalog

The script parses `_mdb_catalog.wt` in the dbPath of a running database to list out all of the namespaces and their corresponding filesystem names.  The operation is read-only and perfectly safe on a running database however it may miss some non-flushed changes.

### Syntax
`parse_mdb_catalog.sh dbPath`

### Tested
* MacOs
* Linux
* MongoDB version 3.0+

### Limitations

Cannot operate on the encrypted storage engine

### Pre-requisites
* strings


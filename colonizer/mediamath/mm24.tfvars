# Mongo
mongodb_version      =  "2.4.14"

# Clients
client_count         = 1
client_machine_type  = "m4.xlarge"

# Shards
shard_count          = 5
shard_machine_types  = ["r4.xlarge", "r4.xlarge", "t2.small"]

# Config Servers
config_count         =  3
config_machine_type  =  "r3.xlarge"
                     
# MongoS
mongos_count         =  5
mongos_machine_type  =  "r3.xlarge"


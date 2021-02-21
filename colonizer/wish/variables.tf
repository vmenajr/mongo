variable "vpc_cidr_block"		{ }
variable "vpc_public_subnets"   { type = "list" }
variable "mongodb_version"      { default = "3.2.15" }
variable "ami_id"               { default = "" }

variable "client_count"         { default = 0 }
variable "client_machine_type"  { default = "t2.micro" }

variable "shard_count"          { default = 0 }
variable "shard_machine_types"  { default = ["t2.micro", "t2.nano", "t2.nano"] }

variable "config_count"         { default = 0 }
variable "config_machine_type"  { default = "t2.micro" }

variable "mongos_count"         { default = 0 }
variable "mongos_machine_type"  { default = "t2.micro" }

variable "dbPath"               { default = "/data" }
variable "logPath"              { default = "/data/mongodb.log" }

variable "allow_nvme"           { default = "0" }


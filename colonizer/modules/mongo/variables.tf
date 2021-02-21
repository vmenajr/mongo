variable "name" { default = "" }
variable "ami" {}
variable "machine_count" { default = "1" }
variable "machine_type" { default = "t2.micro" }
variable "subnet_ids" { type="list" }
variable "ssh_key" {}
variable "user_data" { default = "" }
variable "tags" { type="map" }

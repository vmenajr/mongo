variable "name" {}
variable "ami" {}
variable "machine_ids" { type="map" }
variable "subnet_ids" { type="list" }
variable "ssh_key" {}
variable "user_data" { default = "" }
variable "tags" { type="map" }

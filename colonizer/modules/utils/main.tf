variable "owner" { }
variable "env" { }
variable "customer" { default = "" }
variable "case" { default = "" }
variable "ami" { default = "" }
variable "expire_on" { }
variable "max_az_subnet_count" { }

output "global_tags" {
	value = "${merge(map("expire-on", var.expire_on), map("Customer", var.customer), map("Case", var.case), map("Terraform", "true"), map("Owner", var.owner), map("Environment", var.env))}"
}
output "ami" {
	value = "${var.ami}"
}
output "env" {
	value = "${var.env}"
}
output "prefix" {
	value = "${var.customer}-${var.env}"
}
output "max_az_subnet_count" {
	value = "${var.max_az_subnet_count}"
}


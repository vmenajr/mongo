variable "ami" { default = "${lookup(var.aws_amis, var.aws_region)}" }
variable "machine_type" { default = "r4.2xlarge" }
variable "subnet" { default = "${element(aws_subnet.public.*.id, count.index)}" }
variable "vpc_sg_ids" { default = ["${aws_security_group.default.id}"] }
variable "associate_public_ip" { default = true }


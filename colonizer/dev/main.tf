variable "name" { default = "dev" }

module "vpc" {
  source = "../modules/vpc"

  name = "${format("%s-vpc", var.name)}"

  cidr = "10.0.0.0/16"
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  enable_dns_hostnames = true
  enable_dns_support = true

  azs      = ["us-east-2a", "us-east-2b", "us-east-2c"]

  tags {
    "Terraform" = "true"
    "Environment" = "${upper(var.name)}"
  }
}

# Default security group
resource "aws_security_group" "default" {
  name        = "Default Security Group (ssh public, mongo private)"
  description = "SSH from anywhere, mongodb 27000-28000 internally and outbound to everywhere"
  vpc_id      = "${module.vpc.vpc_id}"
  tags        = "${merge(var.tags, map("Name", format("%s-default-security-group", var.name)))}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MongoDB Access from within the VPC
  ingress {
    from_port   = 27000
    to_port     = 28000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "mtools" {
  ami                         = "${var.ami}"
  instance_type               = "${lookup(var.machine_ids, "mtools")}"
  subnet_id                   = "${element(module.vpc.public_subnets, count.index)}"
  vpc_security_group_ids      = ["${aws_security_group.default.id}"]
  associate_public_ip_address = true
  key_name                    = "${data.terraform_remote_state.base.terraform_key_id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  #Instance tags
  tags {
	Name      = "mtools-${count.index}"
	owner     = "vick.mena"
	expire-on = "2018-01-31"
  }

  user_data = "${file("userdata.sh")}"
}

output "instance_id" {
  value = ["${aws_instance.mtools.*.id}"]
}
output "public_ipv4" {
  value = ["${aws_instance.mtools.*.public_ip}"]
}
output "public_dns" {
  value = ["${aws_instance.mtools.*.public_dns}"]
}
output "private_ipv4" {
  value = ["${aws_instance.mtools.*.private_ip}"]
}


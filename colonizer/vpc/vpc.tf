module "vpc" {
  source = "../modules/vpc"

  name = "${module.utils.prefix}"

  cidr = "${var.vpc_cidr_block}"
  public_subnets = "${slice(var.vpc_public_subnets, 0, module.utils.max_az_subnet_count)}"
  enable_dns_hostnames = true
  enable_dns_support = true

  azs  = "${slice(data.aws_availability_zones.available.names, 0, module.utils.max_az_subnet_count)}"
  tags = "${module.utils.global_tags}"
}

# Default security group
resource "aws_default_security_group" "default" {
  vpc_id      = "${module.vpc.vpc_id}"
  tags        = "${merge(map("Name", "${module.utils.prefix}-default-security-group"), module.utils.global_tags)}"

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
    cidr_blocks = [ "${var.vpc_cidr_block}" ]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


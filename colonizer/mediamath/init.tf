terraform {
  backend "s3" {
	region  =  "us-east-2"
	bucket  =  "tse-terraform-state"
	key     =  "mediamath.tfstate"
  }
}


module "utils" {
    source = "../modules/utils"
    owner = "${var.owner}"
    env = "${terraform.env}"
    customer = "mediamath"
    case = "https://support.mongodb.com/case/00447523"
    ami = "${coalesce(var.ami_id, lookup(var.mongodb_ami, var.aws_region))}"
    expire_on = "${var.expire_on}"
    max_az_subnet_count = "${min(length(data.aws_availability_zones.available.names), length(var.vpc_public_subnets))}"
}


# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-2"
}

data "aws_availability_zones" "available" {}

variable "tf_s3_bucket"         { default = "tse-terraform-state" }
variable "master_state_file"    { default = "base.tfstate" }
variable "wish_state_file"      { default = "wish.tfstate" }
variable "tse_test_file"        { default = "tse_test.tfstate" }
variable "owner"                { }
variable "expire_on"            { }
variable "root_vol_size"        { default = 25 }
variable "data_vol_size"        { default = 100 }

variable "provisioning_key_pathname" {
  description = "Path filename for the private key used by provisioners."
  default     = "~/.ssh/id_rsa"
}

variable "mongodb_ami" {
	description = "AMI for a given region"
	default = {
		"ap-southeast-2"  =  "ami-4f203f2c"
		"us-east-2"       =  "ami-2c5d7d49"
		"us-west-1"       =  "ami-3fbe975f"
	}
}


variable "region2name" {
	description = "Region to name map"
	default = {
        "ap-southeast-2"  =  "sydney"
        "us-east-2"       =  "ohio"
        "us-west-1"       =  "california"
	}
}




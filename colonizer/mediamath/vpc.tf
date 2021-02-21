data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        region  =  "us-east-2"
        bucket  =  "tse-terraform-state"
        key     =  "env:/${lookup(var.region2name, var.aws_region)}/tse-vpc.tfstate"
    }
}


terraform {
  backend "s3" {
	region  =  "us-east-2"
	bucket  =  "tse-terraform-state"
	key     =  "base.tfstate"
  }
}



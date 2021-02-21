data "terraform_remote_state" "base" {
  backend = "s3"
  config {
    bucket = "${var.tf_s3_bucket}"
    key    = "${var.master_state_file}"
    region = "${var.aws_region}"
  }
}

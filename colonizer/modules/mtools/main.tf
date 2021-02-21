resource "aws_instance" "mtools" {
  ami           = "${var.ami}"
  instance_type = "${var.machine_type}"
  subnet_id              = "${var.subnet}"
  vpc_security_group_ids = ["${var.vpc_sg_ids}"]
  associate_public_ip_address = "${var.associate_public_ip}"
  key_name                    = "${aws_key_pair.auth.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  #Instance tags
  tags {
    Name      = "mtools"
    owner     = "vick.mena"
    expire-on = "2018-01-31"
  }

  user_data = "${file("userdata.sh")}"
}

resource "aws_instance" "mongo" {
  count                       = "${var.machine_count}"
  ami                         = "${var.ami}"
  instance_type               = "${var.machine_type}"
  subnet_id                   = "${element(var.subnet_ids, count.index)}"
  associate_public_ip_address = true
  key_name                    = "${var.ssh_key}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  tags = "${merge(var.tags, map("Name", "${var.name}-${count.index}"))}"
  user_data = "${var.user_data}"
}

output "instance_id" {
  value = ["${aws_instance.mongo.*.id}"]
}
output "public_ipv4" {
  value = ["${aws_instance.mongo.*.public_ip}"]
}
output "public_dns" {
  value = ["${aws_instance.mongo.*.public_dns}"]
}
output "private_ipv4" {
  value = ["${aws_instance.mongo.*.private_ip}"]
}


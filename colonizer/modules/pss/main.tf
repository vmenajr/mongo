resource "aws_instance" "pri" {
  count                       = 1
  ami                         = "${var.ami}"
  instance_type               = "${lookup(var.machine_ids, "primary")}"
  subnet_id                   = "${element(var.subnet_ids, count.index)}"
  associate_public_ip_address = true
  key_name                    = "${var.ssh_key}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  tags = "${merge(var.tags, map("Name", format("%s-pri", var.name)))}"

  user_data = "${var.user_data}"
}

resource "aws_instance" "sec" {
  count                       = 2
  ami                         = "${var.ami}"
  instance_type               = "${lookup(var.machine_ids, "secondary")}"
  subnet_id                   = "${element(var.subnet_ids, count.index + 1)}"
  associate_public_ip_address = true
  key_name                    = "${var.ssh_key}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  #Instance tags
  tags = "${merge(var.tags, map("Name", "${var.name}-sec-${count.index}"))}"

  user_data = "${var.user_data}"
}

output "pri_instance_id" {
  value = ["${aws_instance.pri.id}"]
}
output "sec_instance_id" {
  value = ["${aws_instance.sec.*.id}"]
}
output "pri_public_ipv4" {
  value = ["${aws_instance.pri.public_ip}"]
}
output "pri_public_dns" {
  value = ["${aws_instance.pri.public_dns}"]
}
output "pri_private_ipv4" {
  value = ["${aws_instance.pri.private_ip}"]
}
output "sec_public_ipv4" {
  value = ["${aws_instance.sec.*.public_ip}"]
}
output "sec_public_dns" {
  value = ["${aws_instance.sec.*.public_dns}"]
}
output "sec_private_ipv4" {
  value = ["${aws_instance.sec.*.private_ip}"]
}


output "mtools_public_ip" {
  value = "${aws_instance.mtools.public_ip}"
}

output "mtools_public_dns" {
  value = "${aws_instance.mtools.public_dns}"
}

output "mtools_private_ip" {
  value = "${aws_instance.mtools.private_ip}"
}


data "template_file" "init" {
  template = "${file("userdata.sh.tpl")}"

  vars {
    ssh_keys = "${file("../ssh/authorized_keys")}"
    allow_nvme = "${var.allow_nvme}"
  }
}


resource "aws_instance" "mongos" {
    count                       = "${var.mongos_count}"
    ami                         = "${module.utils.ami}"
    instance_type               = "${var.mongos_machine_type}"
    subnet_id                   = "${element(data.terraform_remote_state.vpc.public_subnets, count.index)}"
    associate_public_ip_address = true

    root_block_device {
        volume_type            =  "gp2"
        volume_size            =  "${var.root_vol_size}"
    }
    ebs_block_device {
        device_name            =  "/dev/sdg"
        volume_type            =  "gp2"
        volume_size            =  "${var.data_vol_size}"
    }
    ephemeral_block_device {
        device_name            =  "/dev/sdb"
        virtual_name           =  "ephemeral0"
        no_device              =  "true"
    }
    ephemeral_block_device {
        device_name            =  "/dev/sdc"
        virtual_name           =  "ephemeral1"
        no_device              =  "true"
    }

    tags = "${merge(map("Name", "${module.utils.prefix}-mongos-${count.index}"), module.utils.global_tags)}"
    volume_tags = "${merge(map("Name", "${module.utils.prefix}-mongos-${count.index}"), module.utils.global_tags)}"
    user_data = "${data.template_file.init.rendered}"

    connection {
        type = "ssh"
        user = "colonizer"
        agent = false
        private_key = "${file(var.provisioning_key_pathname)}"
    }
    provisioner "remote-exec" {
        inline = [
            "echo y | sudo /usr/local/bin/m ${var.mongodb_version}",
        ]
    }
}

resource "null_resource" "init_mongos" {
    depends_on = ["null_resource.init_configs"]
    #count = "${var.config_count > 0 ? var.mongos_count : 0}"
    count = 0
    connection {
        type = "ssh"
        user = "colonizer"
        agent = false
        private_key = "${file(var.provisioning_key_pathname)}"
        host = "${element(aws_instance.mongos.*.public_dns, count.index)}"
    }
    provisioner "remote-exec" {
        inline = [
            "set -x",
            "echo y | sudo /usr/local/bin/m ${var.mongodb_version}",
            "configs=${join(",", formatlist("%s:27017", aws_instance.configs.*.private_dns))}",
            "/usr/local/bin/mongos --port 27017 --logpath ${var.logPath} --logappend --configdb configRepl/$configs --fork",
        ]
    }
}


resource "aws_instance" "configs" {
	count                       = "${var.config_count}"
	ami                         = "${module.utils.ami}"
	instance_type               = "${var.config_machine_type}"
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

	tags = "${merge(map("Name", "${module.utils.prefix}-config-${count.index}"), module.utils.global_tags)}"
	volume_tags = "${merge(map("Name", "${module.utils.prefix}-config-${count.index}"), module.utils.global_tags)}"
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
			"#/usr/local/bin/mongod --replSet configRepl --dbpath ${var.dbPath} --logpath ${var.logPath} --port 27017 --logappend --fork --configsvr",
		]
	}
}

resource "null_resource" "init_configs" {
	depends_on = ["aws_instance.configs"]
	#count = "${var.config_count > 0 ? 1 : 0}"
	count = 0
	connection {
		type = "ssh"
		user = "colonizer"
		agent = false
		private_key = "${file(var.provisioning_key_pathname)}"
		host = "${element(aws_instance.configs.*.public_dns, 0)}"
	}
    provisioner "file" {
		#content = "${data.template_file.init_replica.rendered}"
		source = "init_replica.js"
        destination = "/tmp/init_replica.js"
    }
    provisioner "file" {
		content = "rsid=\"configRepl\"; hosts=${jsonencode(aws_instance.configs.*.private_dns)};",
        destination = "/tmp/params.js"
    }
	provisioner "remote-exec" {
		inline = [
            "set -x",
            "cat /tmp/params.js",
            "mongo --verbose /tmp/params.js /tmp/init_replica.js",
        ]
	}
}


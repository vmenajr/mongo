resource "aws_instance" "client" {
	count                       = "${var.client_count}"
	ami                         = "${module.utils.ami}"
	instance_type               = "${var.client_machine_type}"
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

	tags = "${merge(map("Name", "${module.utils.prefix}-client${count.index}"), module.utils.global_tags)}"
	volume_tags = "${merge(map("Name", "${module.utils.prefix}-client"), module.utils.global_tags)}"
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

resource "null_resource" "generate_client_ssh_key" {
    count = "${var.client_count != 0 ? 1 : 0}"
	triggers {
        ids = "${join(",", aws_instance.client.*.id,aws_instance.configs.*.id,aws_instance.shards.*.id,aws_instance.mongos.*.id)}"
	}
	provisioner "local-exec" {
		command = "echo y | ssh-keygen -v -P '' -C ${module.utils.env}-client-key -f /tmp/terraform-client-ssh-key"
	}
}

resource "null_resource" "copy_client_ssh_key" {
    depends_on = ["null_resource.generate_client_ssh_key"]
    count = "${var.client_count != 0 ? var.client_count + var.config_count + var.shard_count*3 + var.mongos_count: 0}"
	triggers {
        ids = "${join(",", aws_instance.client.*.id,aws_instance.configs.*.id,aws_instance.shards.*.id,aws_instance.mongos.*.id)}"
	}
	connection {
		type = "ssh"
		user = "colonizer"
		agent = false
		private_key = "${file(var.provisioning_key_pathname)}"
        host = "${element(concat(aws_instance.client.*.public_dns,aws_instance.configs.*.public_dns,aws_instance.shards.*.public_dns,aws_instance.mongos.*.public_dns), count.index)}"
	}
    provisioner "file" {
		source = "/tmp/terraform-client-ssh-key.pub"
        destination = "~/.ssh/id_rsa.pub"
    }
    provisioner "file" {
		source = "/tmp/terraform-client-ssh-key"
        destination = "~/.ssh/id_rsa"
    }
	provisioner "remote-exec" {
		inline = [
            "chown colonizer. ~/.ssh/id_rsa*",
            "chmod 0644 ~/.ssh/id_rsa.pub",
            "chmod 0600 ~/.ssh/id_rsa",
            "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys",
		]
	}
}


/*
resource "null_resource" "set_hostname" {
    depends_on = ["null_resource.copy_client_ssh_key"]
    #count = "${var.client_count + var.config_count + var.shard_count*3 + var.mongos_count}"
    count = 0
	connection {
		type = "ssh"
		user = "colonizer"
		agent = false
		private_key = "${file(var.provisioning_key_pathname)}"
        host = "${element(concat(aws_instance.client.*.public_dns,aws_instance.configs.*.public_dns,aws_instance.shards.*.public_dns,aws_instance.mongos.*.public_dns), count.index)}"
	}
    provisioner "file" {
		content = "${join("\n",concat(aws_instance.client.*.public_dns,aws_instance.configs.*.public_dns,aws_instance.shards.*.public_dns,aws_instance.mongos.*.public_dns))}"
        destination = "/tmp/hosts.txt"
    }
	provisioner "remote-exec" {
		inline = [
            "set -x",
            "cat /tmp/hosts.txt",
        ]
	}
}
*/

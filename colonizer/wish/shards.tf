resource "aws_instance" "shards" {
    count                       = "${var.shard_count * 3}"
    ami                         = "${module.utils.ami}"
    instance_type               = "${element(var.shard_machine_types, count.index)}"
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

    tags = "${merge(map("Name", "${module.utils.prefix}-shard${count.index / 3}-${count.index % 3}"), module.utils.global_tags)}"
    volume_tags = "${merge(map("Name", "${module.utils.prefix}-shard${count.index / 3}-${count.index % 3}"), module.utils.global_tags)}"
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
            "#/usr/local/bin/mongod --replSet shard${count.index / 3} --dbpath ${var.dbPath} --logpath ${var.logPath} --port 27017 --logappend --fork --shardsvr"
        ]
    }
}

resource "null_resource" "init_shards" {
    depends_on = ["aws_instance.shards"]
    #count = "${var.shard_count}"
    count = 0
    connection {
        type = "ssh"
        user = "colonizer"
        agent = false
        private_key = "${file(var.provisioning_key_pathname)}"
        host = "${element(aws_instance.shards.*.public_dns, count.index * 3)}"
    }
    provisioner "file" {
        #content = "${data.template_file.init_replica.rendered}"
        source = "init_replica.js"
        destination = "/tmp/init_replica.js"
    }
    provisioner "file" {
        content = "rsid=\"shard${count.index}\"; hosts=${jsonencode(slice(aws_instance.shards.*.private_dns, count.index * 3, count.index * 3 + 3))};",
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

resource "null_resource" "add_shards" {
    depends_on = ["null_resource.init_shards", "null_resource.init_mongos"]
    #count = "${var.mongos_count > 0 && var.shard_count > 0 ? 1 : 0}"
    count = 0
    connection {
        type = "ssh"
        user = "colonizer"
        agent = false
        private_key = "${file(var.provisioning_key_pathname)}"
        host = "${element(aws_instance.mongos.*.public_dns, 0)}"
    }
    provisioner "file" {
        source = "add_shards.js"
        destination = "/tmp/add_shards.js"
    }
    provisioner "file" {
        content = "hosts=${jsonencode(aws_instance.shards.*.private_dns)};",
        destination = "/tmp/params.js"
    }
    provisioner "remote-exec" {
        inline = [
            "set -x",
            "cat /tmp/params.js",
            "mongo --verbose /tmp/params.js /tmp/add_shards.js",
        ]
    }
}


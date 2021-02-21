output "inventory" {
	value = {
		vpc = {
			id= "${data.terraform_remote_state.vpc.id}",
			private= "${data.terraform_remote_state.vpc.private_subnets}",
			public= "${data.terraform_remote_state.vpc.public_subnets}",
		},
		client = {
			id= "${aws_instance.client.*.id}",
			public= "${aws_instance.client.*.public_dns}",
			private= "${aws_instance.client.*.private_dns}"
		},
		mongos = {
			id= "${aws_instance.mongos.*.id}",
			public= "${aws_instance.mongos.*.public_dns}",
			private= "${aws_instance.mongos.*.private_dns}"
		},
		configs = {
			id= "${aws_instance.configs.*.id}",
			public= "${aws_instance.configs.*.public_dns}",
			private= "${aws_instance.configs.*.private_dns}"
		},
		shards = {
			id= "${aws_instance.shards.*.id}",
			public= "${aws_instance.shards.*.public_dns}",
			private= "${aws_instance.shards.*.private_dns}"
		}
	}
}

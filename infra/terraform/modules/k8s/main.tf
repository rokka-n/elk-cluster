variable vpc_id           { }
variable vpc_cidr         { }
variable public_subnets   { type = "list" }
variable k8stoken         { }
variable k8s-ssh-key      { }

# Key pair for the instances
resource "aws_key_pair" "ssh-key" {
  key_name = "k8s"
  public_key = "${var.k8s-ssh-key}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow ssh"
  vpc_id = "${var.vpc_id}"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  // allow access inside vpc
  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["${var.vpc_cidr}"]
  }


  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_ssh"
  }
}

data "template_file" "master-userdata" {
    template = "${file("${path.module}/master.sh")}"

    vars {
        k8stoken = "${var.k8stoken}"
    }
}

data "template_file" "worker-userdata" {
    template = "${file("${path.module}/worker.sh")}"

    vars {
        k8stoken  = "${var.k8stoken}"
        MASTER_IP = "${aws_instance.k8s-master.private_ip}"
    }
}

resource "aws_instance" "k8s-master" {
  ami           = "ami-2ef48339"
  instance_type = "t2.medium"
  subnet_id = "${var.public_subnets[1]}"
  user_data = "${data.template_file.master-userdata.rendered}"
  key_name = "${aws_key_pair.ssh-key.key_name}"
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]

  tags {
      Name = "k8s-master"
  }
}

resource "aws_instance" "k8s-worker1" {
  ami           = "ami-2ef48339"
  instance_type = "t2.medium"
  subnet_id = "${var.public_subnets[1]}"
  user_data = "${data.template_file.worker-userdata.rendered}"
  key_name = "${aws_key_pair.ssh-key.key_name}"
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]

  tags {
      Name = "k8s-worker1"
  }
}

output "public_dns" {
  value = "${aws_instance.k8s-master.public_dns}"
}

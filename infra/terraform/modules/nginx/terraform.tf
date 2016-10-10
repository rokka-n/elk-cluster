variable azs         { type = "list" }
variable public_subnets { type = "list" }
variable min_size    { }
variable max_size    { }
variable asg_desired { }
variable vpc_id      { }
variable instance_type { }
variable k8s-ssh-key { }
variable aws_region  { default = "us-east-1" }

# ubuntu-trusty-14.04 (x64)
variable "aws_amis" {
  default = {
    "us-east-1" = "ami-2d39803a"
  }

}

# Key pair for the instances
resource "aws_key_pair" "ssh-key" {
  key_name = "nginx"
  public_key = "${var.k8s-ssh-key}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "web-elb" {
  name = "terraform-nginx-elb"

  # The same availability zone as our instances
  subnets = ["${var.public_subnets}"]
  security_groups = ["${aws_security_group.elb.id}"]
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

}

resource "aws_autoscaling_group" "web-asg" {
  #availability_zones = ["${var.availability_zones}"]
  name = "${aws_launch_configuration.web-lc.name}-asg"
  max_size = "${var.max_size}"
  min_size = "${var.min_size}"
  desired_capacity = "${var.asg_desired}"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.web-lc.name}"
  load_balancers = ["${aws_elb.web-elb.name}"]
  vpc_zone_identifier = ["${var.public_subnets}"]

  tag {
    key = "Name"
    value = "web-asg"
    propagate_at_launch = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "web-lc" {
  name_prefix = "nginx-lc-"
  image_id = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "${var.instance_type}"
  # Security group
  security_groups = ["${aws_security_group.ec2.id}"]
  user_data = "${file("${path.module}/userdata.sh")}"
  key_name = "${aws_key_pair.ssh-key.key_name}"

  lifecycle {
    create_before_destroy = true
  }

}

# SG for ELB
resource "aws_security_group" "elb" {
  name = "elb_sg"
  description = "SG for ELB"
  vpc_id  = "${var.vpc_id}"

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG to access the instances over SSH and HTTP
resource "aws_security_group" "ec2" {
  name = "ec2_sg"
  description = "SG for ec2 instances"
  vpc_id  = "${var.vpc_id}"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  # outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "elb_dns" { value = "${aws_elb.web-elb.dns_name}" }

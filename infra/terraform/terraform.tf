# Amazon resources 

variable region { default = "us-east-1" }

provider "aws" {
  region     = "${var.region}"
}

# K8S vars
variable k8stoken    { }
variable k8s-ssh-key { }

module "vpc" {
  source = "github.com/terraform-community-modules/tf_aws_vpc"

  name = "elk-vpc"

  cidr = "10.200.0.0/16"
  public_subnets  = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]
  enable_dns_hostnames = "true"
  enable_dns_support = "true"

  azs      = ["us-east-1b", "us-east-1c", "us-east-1e"]
}

module "private_subnet" {
  source             = "github.com/terraform-community-modules/tf_aws_private_subnet_nat_gateway"

  name               = "private-subnets"
  vpc_id             = "${module.vpc.vpc_id}"
  cidrs              = ["10.200.11.0/24", "10.200.12.0/24", "10.200.13.0/24"]
  azs                = ["us-east-1b", "us-east-1c", "us-east-1e"]
  public_subnet_ids  = "${module.vpc.public_subnets}"
  nat_gateways_count = 1
}

# Create k8s cluster
module "k8s" {
  source             = "modules/k8s"
  k8stoken           = "${var.k8stoken}"
  vpc_id             = "${module.vpc.vpc_id}"
  k8s-ssh-key        = "${var.k8s-ssh-key}"
  public_subnets     = "${module.vpc.public_subnets}"
}

# Create ELB with nginx instances
module "elb-nginx" {
  source             = "modules/nginx"

  azs                = ["us-east-1b", "us-east-1c", "us-east-1e"]
  public_subnets     = "${module.vpc.public_subnets}" 
  min_size           = 1
  max_size           = 2
  asg_desired        = 2 
  vpc_id             = "${module.vpc.vpc_id}"
  instance_type      = "t2.small"
  k8s-ssh-key        = "${var.k8s-ssh-key}"
}

output "master_dns" {
  value = "${module.k8s.public_dns}"
}

output "elb_dns" {
  value = "${module.elb-nginx.elb_dns}"
}

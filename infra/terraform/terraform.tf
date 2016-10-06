# Amazon resources 

variable region { default = "us-east-1" }

provider "aws" {
  region     = "${var.region}"
}

module "vpc" {
  source = "github.com/terraform-community-modules/tf_aws_vpc"

  name = "elk-vpc"

  cidr = "10.200.0.0/16"
  private_subnets = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]

  azs      = ["us-east-1b", "us-east-1c", "us-east-1e"]
}

module "private_subnet" {
  source             = "github.com/terraform-community-modules/tf_aws_private_subnet_nat_gateway"

  name               = "private-subnets"
  vpc_id             = "${module.vpc.vpc_id}"
  cidrs              = ["10.200.11.0/24", "10.200.12.0/24", "10.200.13.0/24"]
  azs                = ["us-east-1b", "us-east-1c", "us-east-1e"]
  public_subnet_ids  = "${module.vpc.private_subnets}"
  nat_gateways_count = 1
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.64.0"

  cidr            = var.vpc_cidr_block
  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  # Need nat gateway if ec2 instances are in private subnet
  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    project     = "bobbins",
    environment = "dev"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}


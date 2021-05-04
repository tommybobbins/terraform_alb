terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

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

module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"
  version = "3.17.0"

  name        = "web-sg-bobbins-dev"
  description = "Security group for web-servers with HTTP ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  #ingress_cidr_blocks = module.vpc.public_subnets_cidr_blocks
  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Add 80/22 rules
  ingress_rules = ["http-80-tcp", "ssh-tcp"]
  # Allow all rules for all protocols
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  tags = {
    project     = "bobbins",
    environment = "dev"
  }
}

module "lb_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"
  version = "3.17.0"

  name        = "lb-sg-bobbins-dev"
  description = "Security group for load balancer with HTTP ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Add 80 rules
  ingress_rules = ["http-80-tcp"]
  # Allow all rules for all protocols
  egress_rules = ["all-all"]

  tags = {
    project     = "bobbins",
    environment = "dev"
  }
}

resource "random_string" "lb_id" {
  length  = 3
  special = false
}

###################

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "bobbins-alb"

  load_balancer_type = "application"

  vpc_id      = module.vpc.vpc_id
  security_groups = [module.lb_security_group.this_security_group_id]
  subnets         = module.vpc.public_subnets

  target_groups = [
    {
      count = var.instance_count
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = [
        {
          #target_id           = module.ec2_instances[0].id
          target_id           = module.ec2_instances.instance_ids[0]
          port = 80
        }
#        {
#          target_id           = module.ec2_instances[1].id
#          port = 80
#        }
      ]
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    project     = "bobbins",
    environment = "dev"
  }
}

#resource "aws_lb_target_group_attachment" "node" {
#
#  count = var.instance_count
#  target_group_arn = module.alb.target_group.arn
#  target_id           = module.ec2_instances[count.index].id
#  port             = 80
#  tags = {
#    project     = "bobbins",
#    environment = "dev"
#  }
#
#}


####################


#module "elb_http" {
#  source  = "terraform-aws-modules/elb/aws"
#  version = "2.4.0"
#
#  # Ensure load balancer name is unique
#  name = "lb-${random_string.lb_id.result}-bobbins-dev"
#
#  internal = false
#
#  security_groups = [module.lb_security_group.this_security_group_id]
#  subnets         = module.vpc.public_subnets
#
#  number_of_instances = length(module.ec2_instances.instance_ids)
#  instances           = module.ec2_instances.instance_ids
#
#  listener = [{
#    instance_port     = "80"
#    instance_protocol = "HTTP"
#    lb_port           = "80"
#    lb_protocol       = "HTTP"
#  }]
#
#  health_check = {
#    target              = "HTTP:80/index.html"
#    interval            = 10
#    healthy_threshold   = 3
#    unhealthy_threshold = 10
#    timeout             = 5
#  }
#
#  tags = {
#    project     = "bobbins",
#    environment = "dev"
#  }
#}

module "ec2_instances" {
  source = "./modules/aws-instance"

  instance_count = var.instance_count
  instance_type  = "t2.micro"
  # Need NAT gateway enabling if private
  subnet_ids = module.vpc.private_subnets[*]
  #subnet_ids         = module.vpc.public_subnets[*]
  security_group_ids = [module.app_security_group.this_security_group_id]

  tags = {
    project     = "bobbins",
    environment = "dev"
  }
}

#resource "aws_instance" "node" {
# 
#  count = var.instance_count
#  
#  ami                    = data.aws_ami.ubuntu.id
#  subnet_id              = var.subnet_id
#  key_name               = var.key_pair
#  instance_type          = var.instance_type
#  vpc_security_group_ids = [var.security_group_id]
#  
#  tags          = {
#    Name        = "${var.app_name}"
#    #Environment = "production"
#  }
#  
#  root_block_device {
#        volume_type     = "gp2"
#        volume_size     = 8
#        delete_on_termination   = true
#  }
#
#  user_data = file("install_apache.sh")
#}
#
#resource "aws_lb_target_group_attachment" "node" {
#
#  count = var.instance_count
#
#  target_group_arn = var.target_group_arn
##  target_id        = aws_instance.node[count.index].id
#  target_id           = module.ec2_instances[count.index].id
#  port             = 80
#}

# some outputs skipped 

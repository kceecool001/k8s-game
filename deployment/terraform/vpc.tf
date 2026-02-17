module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster}" = "shared"
    "kubernetes.io/role/elb"                 = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster}" = "shared"
    "kubernetes.io/role/internal-elb"        = 1
  }

  tags = local.tags

}



### VPC Endpoints Configuration

# VPC Endpoints Resource Block

# resource "aws_security_group" "vpc_endpoints" {
#   name        = "${local.name}-vpce"
#   description = "Interface endpoint access"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "HTTPS from VPC"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [module.vpc.vpc_cidr_block]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = local.tags
# }

# VPC Endpoints Module Block

# module "vpc_endpoints" {
#   source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
#   version = "~> 5.0"

#   vpc_id             = module.vpc.vpc_id
#   security_group_ids = [aws_security_group.vpc_endpoints.id]

#   endpoints = {
#     s3 = {
#       service         = "s3"
#       service_type    = "Gateway"
#       route_table_ids = module.vpc.private_route_table_ids
#       tags            = local.tags
#     }
#     ecr_api = {
#       service             = "ecr.api"
#       private_dns_enabled = true
#       subnet_ids          = module.vpc.private_subnets
#       tags                = local.tags
#     }
#     ecr_dkr = {
#       service             = "ecr.dkr"
#       private_dns_enabled = true
#       subnet_ids          = module.vpc.private_subnets
#       tags                = local.tags
#     }
#     sts = {
#       service             = "sts"
#       private_dns_enabled = true
#       subnet_ids          = module.vpc.private_subnets
#       tags                = local.tags
#     }
#     logs = {
#       service             = "logs"
#       private_dns_enabled = true
#       subnet_ids          = module.vpc.private_subnets
#       tags                = local.tags
#     }
#   }

#   tags = local.tags
# }
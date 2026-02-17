module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster
  cluster_version = "1.32"

  # KMS managed externally
  create_kms_key = false
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # Updated: addons → cluster_addons
  cluster_addons = {
    coredns = {
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {
      before_compute = true
    }
    vpc-cni = {
      before_compute              = true
      resolve_conflicts_on_create = "OVERWRITE"
    }
  }

  # Updated endpoint settings
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["46.232.159.83/32"]
  cluster_endpoint_private_access      = true

  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # Node groups (unchanged)
  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      disk_size = 50

      update_config = {
        max_unavailable_percentage = 33
      }
    }
  }

  depends_on = [
    aws_kms_key.eks,
    aws_kms_alias.eks
  ]

  tags = local.tags
}

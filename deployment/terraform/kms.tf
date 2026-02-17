# kms.tf
resource "aws_kms_key" "eks" {
  description             = "${local.cluster} cluster encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = local.tags
}

resource "aws_kms_alias" "eks" {
  name          = "alias/eks/${local.cluster}"
  target_key_id = aws_kms_key.eks.key_id
}
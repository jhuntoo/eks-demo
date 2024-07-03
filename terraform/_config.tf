locals {
  name              = "eks-demo"
  region            = "ap-southeast-2"
  azs               = slice(data.aws_availability_zones.available.names, 0, 3)
  cluster_version   = "1.30"
  karpenter_version = "0.37.0"
  tags = {
    stack_name = local.name
  }
}
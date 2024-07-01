locals {
  name = "eks-demo"
  region = "ap-southeast-2"
  vpc_cidr = "10.0.0.0/16"
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  cluster_version = "1.30"
  tags = {
    stack_name = local.name
  }
}
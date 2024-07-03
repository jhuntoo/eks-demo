# module "ebs_csi_driver_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "5.39.1"
#
#   role_name_prefix = "${module.eks.cluster_name}-ebs-csi-driver-"
#
#   attach_ebs_csi_policy = true
#
#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#     }
#   }
#
#   tags = local.tags
# }

# module "eks_blueprints_addons" {
#   source  = "aws-ia/eks-blueprints-addons/aws"
#   version = "1.16.3"
#
#   cluster_name      = module.eks.cluster_name
#   cluster_endpoint  = module.eks.cluster_endpoint
#   cluster_version   = module.eks.cluster_version
#   oidc_provider_arn = module.eks.oidc_provider_arn
#
#   create_delay_dependencies = [for prof in module.eks.eks_managed_node_groups : prof.node_group_arn]
#
#   enable_aws_load_balancer_controller = true
#   enable_metrics_server               = true
#
#   eks_addons = {
#     aws-ebs-csi-driver = {
#       service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
#     }
#   }
#
#   enable_aws_for_fluentbit = true
#   aws_for_fluentbit = {
#     set = [
#       {
#         name  = "cloudWatchLogs.region"
#         value = local.region
#       }
#     ]
#   }
#   tags       = local.tags
#   depends_on = [helm_release.karpenter]
# }
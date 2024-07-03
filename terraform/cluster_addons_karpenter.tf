module "karpenter" {
  source                          = "terraform-aws-modules/eks/aws//modules/karpenter"
  version                         = "20.16.0"
  cluster_name                    = module.eks.cluster_name
  enable_pod_identity             = true
  create_pod_identity_association = true
  enable_irsa                     = true
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "helm_release" "karpenter" {
  namespace           = helm_release.karpenter-crd.namespace
  create_namespace    = false
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = local.karpenter_version
  wait                = false

  values = [
    <<-EOT
    serviceAccount:
      name: ${module.karpenter.service_account}
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    EOT
  ]
}


resource "helm_release" "karpenter-crd" {
  namespace        = "karpenter"
  create_namespace = true
  name             = "karpenter-crd"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter-crd"
  version          = local.karpenter_version
  wait             = true
  values           = []
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<YAML
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  role: "${module.karpenter.node_iam_role_name}"
  amiFamily: AL2
  securityGroupSelectorTerms:
  - tags:
      karpenter.sh/discovery: ${local.name}
  subnetSelectorTerms:
  - tags:
      karpenter.sh/discovery: ${local.name}
  tags:
    IntentLabel: apps
    KarpenterNodePoolName: default
    NodeType: default
    intent: apps
    karpenter.sh/discovery: ${local.name}
    project: karpenter-blueprints
YAML
  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<YAML
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    metadata:
      labels:
        intent: apps
    spec:
      requirements:
        - key: node.kubernetes.io/instance-type
          operator: In
          values:
          - t3a.medium
        - key: kubernetes.io/os
          operator: In
          values:
          - linux
        - key: kubernetes.io/arch
          operator: In
          values:
          - amd64
        - key: karpenter.sh/capacity-type
          operator: In
          values:
          - on-demand
      nodeClassRef:
        name: default
      kubelet:
        containerRuntime: containerd
        systemReserved:
          cpu: 100m
          memory: 100Mi
  disruption:
    consolidationPolicy: WhenUnderutilized

YAML
  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}
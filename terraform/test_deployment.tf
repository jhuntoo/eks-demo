# Test deployment by using the [pause image](https://www.ianlewis.org/en/almighty-pause-container)
# If you want to inflate - use kubectl scale --replicas=20 deployment/inflate
resource "kubernetes_namespace" "inflate" {
  metadata {
    name = "inflate"
  }
}

resource "kubernetes_manifest" "inflate" {
  manifest = yamldecode(<<-EOF
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      namespace: ${kubernetes_namespace.inflate.metadata[0].name}
      name: inflate
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: inflate
      template:
        metadata:
          labels:
            app: inflate
        spec:
          terminationGracePeriodSeconds: 0
          containers:
            - name: inflate
              image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
              resources:
                requests:
                  cpu: 500m
  EOF
  )

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}
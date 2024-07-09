# EKS Demo

This repo contains a basic configuration of an EKS cluster with Karpenter installed. It utilises terraform and helm for IaC

```shell
# 1. run terraform and wait for completion
terraform apply
# 2. update kube config, see TF output configure_kubectl
aws eks --region ap-southeast-2 update-kubeconfig --name eks-demo
# 3. scale replicas to force karpenter to create new nodes
kubectl scale -n inflate --replicas=10 deployment/inflate
# 4. scale down to see karpenter shrinks number of nodes
kubectl scale -n inflate --replicas=1 deployment/inflate
# 5. tidy up
terraform destroy

```


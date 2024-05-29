# --------------------------------- providers --------------------------

provider "aws" {
  region = "us-east-1"
}

terraform {

  required_version = ">= 1.3.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
    
  }

  backend "s3" {
    bucket = "agricola-tf-state"
    key    = "tf/state/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "agricola-tf-state"
    encrypt = "true"
  }


}

data "aws_eks_cluster" "eks-cluster" {
  name = "prueba-eks-eks-cluster-${var.environment}"
}

provider "helm" { 
  kubernetes {
    host                   = data.aws_eks_cluster.eks-cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.eks-cluster.id]
      command     = "aws"
    }
  }
}

# creates a file with what is needed to use kubernetes in our cluster

data "aws_eks_cluster_auth" "cluster_kube_config" {
  name = data.aws_eks_cluster.eks-cluster.id // this one needs to change for multi env since it uses cluster as ref
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks-cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster_kube_config.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-cluster.certificate_authority.0.data)
}

data "tls_certificate" "eks" {
  url = data.aws_eks_cluster.eks-cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.eks-cluster.identity[0].oidc[0].issuer
}
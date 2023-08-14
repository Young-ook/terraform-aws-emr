[[English](README.md)] [[한국어](README.ko.md)]

# Amazon EMR Virtual Cluster
[Amazon EMR](https://aws.amazon.com/emr/) is the industry-leading cloud big data solution for petabyte-scale data processing, interactive analytics, and machine learning using open-source frameworks such as Apache Spark, Apache Hive, and Presto.

A [virtual cluster](https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/virtual-cluster.html) is a Kubernetes namespace that Amazon EMR is registered with. You can create, describe, list, and delete virtual clusters. They do not consume any additional resource in your system. A single virtual cluster maps to a single Kubernetes namespace. Given this relationship, you can model virtual clusters the same way you model Kubernetes namespaces to meet your requirements. See possible use cases in the [Kubernetes Concepts Overview](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) documentation.

## Setup
### Prerequisites
This module requires *eksctl* which is an open-source cli tool for EKS cluster management. In this example, we will use *eksctl* to create kubernetes access control objects for EMR integration. Follow the [instructions](https://github.com/weaveworks/eksctl#installation) for eksctl installation. And if you don't have the terraform and kubernetes tools in your environment, go to the main [page](https://github.com/Young-ook/terraform-aws-emr) of this repository and follow the installation instructions.

:warning: **This example requires the eksctl version 0.135.0 or higher**

### Quickstart
```
module "vpc" {
  source  = "Young-ook/vpc/aws"
}

module "eks" {
  source  = "Young-ook/eks/aws"
  subnets = values(module.vpc.subnets["public"])
}

module "emr-containers" {
  source  = "Young-ook/emr/aws//modules/emr-containers"
  container_providers = {
    id = module.eks.cluster.name
  }
}
```
Run terraform:
```
terraform init
terraform apply
```

# Additional Resources
## Amazon EMR on Amazon EKS
- [Amazon EMR on Amazon EKS Developer Guide](https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/emr-eks.html)
- [Best practices for running Spark on Amazon EKS](https://aws.amazon.com/blogs/containers/best-practices-for-running-spark-on-amazon-eks/)
- [Run Apache Spark with Amazon EMR on EKS backed by Amazon FSx for Lustre storage](https://aws.amazon.com/blogs/big-data/run-apache-spark-with-amazon-emr-on-eks-backed-by-amazon-fsx-for-lustre-storage/)
- [Troubleshooting Amazon EMR on EKS identity and access](https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/security_iam_troubleshoot.html)

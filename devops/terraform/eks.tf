# main.tf

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

locals {
  name = "incode-demo-eks"

  tags = {
    Project     = "incode-sre-assessment"
    Environment = "demo"
    ManagedBy   = "terraform"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "eks" {
  source = "git::https://github.com/victor405/terraform-module-eks.git?ref=main"

  cluster_name       = local.name
  aws_region         = var.aws_region
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  kubernetes_version = var.kubernetes_version

  # Easier for local kubectl during take-home.
  endpoint_public_access  = true
  endpoint_private_access = true
  public_access_cidrs     = [var.admin_cidr]

  # Keep useful SRE logs, but not too crazy.
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator"
  ]

  encryption_config_enabled = true

  node_groups = {
    default = {
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3.medium"]

      desired_size = 1
      min_size     = 1
      max_size     = 1

      disk_size = 20

      labels = {
        workload = "demo"
      }

      tags = local.tags
    }
  }

  # Required because your module variable has no default.
  fargate_profiles = {}

  # Turn off extras for the assessment unless you intentionally need them.
  aws_load_balancer_controller_enabled = false
  keda_enabled                         = false
  kubernetes_dashboard_enabled         = false
  argocd_enabled                       = false

  cloudwatch_observability_enabled = false
  datadog_observability_enabled    = false

  addons                     = {}
  identity_providers         = {}
  access_policy_associations = {}
  eks_access_entries         = {}
  pod_identity_associations  = {}
  prometheus_workspaces      = {}

  eks_cluster_tags = local.tags
}
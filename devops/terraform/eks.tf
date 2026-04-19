# EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.app_name}-eks"
  cluster_version = var.kubernetes_version

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      desired_size = 1
      min_size     = 1
      max_size     = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = {
    Environment = "dev"
  }
}

# prompt-gemini (FastAPI)
resource "aws_ecr_repository" "prompt_gemini" {
  name = "prompt-gemini"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# prompt-generator (Go/Rust)
resource "aws_ecr_repository" "prompt_generator" {
  name = "prompt-generator"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# prompt-history (read API)
resource "aws_ecr_repository" "prompt_history" {
  name = "prompt-history"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# db-migration (job / flyway / init)
resource "aws_ecr_repository" "db_migration" {
  name = "db-migration"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "default" {
  for_each = {
    prompt_gemini   = aws_ecr_repository.prompt_gemini.name
    prompt_generator = aws_ecr_repository.prompt_generator.name
    prompt_history  = aws_ecr_repository.prompt_history.name
    db_migration    = aws_ecr_repository.db_migration.name
  }

  repository = each.value

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 2
      }
      action = {
        type = "expire"
      }
    }]
  })
}
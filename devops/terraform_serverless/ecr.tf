# prompt-gemini (FastAPI)
resource "aws_ecr_repository" "prompt_gemini" {
  name = "prompt-gemini"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "prompt_gemini" {
  repository = aws_ecr_repository.prompt_gemini.name

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
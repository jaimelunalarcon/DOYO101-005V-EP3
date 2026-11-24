# ECR acelera build/push → deploy. No crea roles IAM (usa LabRole de la CLI).

locals {
  services = ["frontend", "backend", "reporting-service", "db"]
}

resource "aws_ecr_repository" "services" {
  for_each = toset(local.services)

  name                 = "${var.project}/${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Project = var.project
    Purpose = "ep3"
  }
}

resource "aws_ecr_lifecycle_policy" "keep_last_5" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

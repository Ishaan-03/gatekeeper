resource "aws_ecr_repository" "gatekeeper" {
  #checkov:skip=CKV_AWS_136:Repository is encrypted with AES256 at rest; a customer-managed KMS key adds about 1 EUR/month and key-policy upkeep, not justified for a lab
  name                 = "gatekeeper"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "gatekeeper" {
  repository = aws_ecr_repository.gatekeeper.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

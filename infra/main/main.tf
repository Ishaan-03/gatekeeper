terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "gatekeeper-tfstate-843109108746"
    key          = "gatekeeper/main.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-west-3"
  default_tags {
    tags = {
      Project     = "gatekeeper"
      Owner       = "ishaan"
      Environment = "lab"
    }
  }
}

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

output "ecr_repository_url" {
  value = aws_ecr_repository.gatekeeper.repository_url
}

variable "github_repo" {
  description = "GitHub repo allowed to push images, as owner/name"
  type        = string
  default     = "Ishaan-03/gatekeeper"
}

data "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "gha_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "pipeline" {
  name               = "gatekeeper-pipeline"
  assume_role_policy = data.aws_iam_policy_document.gha_trust.json
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid = "PushToGatekeeperRepoOnly"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [aws_ecr_repository.gatekeeper.arn]
  }
  statement {
    sid       = "GetLoginToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "pipeline_ecr_push" {
  name   = "ecr-push-only"
  role   = aws_iam_role.pipeline.id
  policy = data.aws_iam_policy_document.ecr_push.json
}

output "pipeline_role_arn" {
  value = aws_iam_role.pipeline.arn
}

# The account already has the GitHub OIDC provider (only one is allowed per account),
# so it is looked up here instead of created.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# GitHub writes the sub claim with the numeric owner and repo IDs, for example
# repo:Ishaan-03@166810647/gatekeeper@1414191999:ref:refs/heads/main
# IDs are never reused, so a deleted and recreated repo with the same name
# cannot assume this role.
locals {
  github_subject = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}:ref:refs/heads/main"
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
      values   = [local.github_subject]
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

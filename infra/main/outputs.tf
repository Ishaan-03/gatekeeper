output "ecr_repository_url" {
  value = aws_ecr_repository.gatekeeper.repository_url
}

output "pipeline_role_arn" {
  value = aws_iam_role.pipeline.arn
}

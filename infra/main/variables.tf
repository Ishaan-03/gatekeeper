variable "github_owner" {
  description = "GitHub account that owns the repository"
  type        = string
  default     = "Ishaan-03"
}

variable "github_owner_id" {
  description = "Numeric ID of the GitHub account. GitHub puts it in the OIDC sub claim."
  type        = string
  default     = "166810647"
}

variable "github_repo" {
  description = "Repository allowed to push images"
  type        = string
  default     = "gatekeeper"
}

variable "github_repo_id" {
  description = "Numeric ID of the repository. GitHub puts it in the OIDC sub claim."
  type        = string
  default     = "1414191999"
}

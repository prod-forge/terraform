variable "github_owner" {
  description = "GitHub organization or user"
  type        = string
}

variable "github_repos" {
  description = "List of GitHub repository names"
  type        = list(string)
}


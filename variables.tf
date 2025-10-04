variable "environment" {
  type = string
}

variable "account_id" {
  type = string
}

variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "github-runner"
}

variable "github_app_secret" {
  description = "GitHub App Secret name"
  type        = string
}

variable "runner_instance_type" {
  description = "EC2 instance type for GitHub runners"
  type        = string
  default     = "t3.medium"
}

variable "runner_min_size" {
  description = "Minimum number of runners"
  type        = number
  default     = 1
}

variable "runner_max_size" {
  description = "Maximum number of runners"
  type        = number
  default     = 3
}

variable "runner_desired_capacity" {
  description = "Desired number of runners"
  type        = number
  default     = 2
}

variable "github_organization" {
  description = "GitHub organization name"
  type        = string
}

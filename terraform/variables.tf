variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_log_level" {
  type    = string
  default = "Error"
}

variable "environment" {
  type    = string
  default = "dev"
}

locals {
  aws_tags = {
    "environment" = var.environment
    "source"      = "terraform",
    "project"     = "tiny-url"
  }
}

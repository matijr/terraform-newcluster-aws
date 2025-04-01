variable "region" {
  description = "The AWS region"
  type        = string
}

variable "availability_zone" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "name" {
    description = "Base name for the resources"
    type        = string
}

variable "aws_access_key" {
    description = "AWS Access Key"
    type        = string
}

variable "aws_secret_key" {
    description = "AWS Secret Key"
    type        = string
}

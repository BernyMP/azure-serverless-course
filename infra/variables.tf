variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "westus3"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "order-system"
}

variable "environment" {
  description = "Application environment"
  type        = string
  default     = "dev"
}
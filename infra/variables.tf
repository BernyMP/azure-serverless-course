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
variable "monthly_budget_amount" {
  description = "Monthly spend, in the subscription's billing currency, that the cost alerts in budget.tf are measured against. Not a spending limit -- see the comments in budget.tf."
  type        = number
  default     = 5

  // Set low on purpose: this stack should sit near zero, so anything unexpected trips it early.
  validation {
    condition     = var.monthly_budget_amount >= 1
    error_message = "Azure requires a budget amount of at least 1."
  }
}

variable "budget_start_date" {
  description = "First day of the month the budget begins tracking, RFC 3339. Must be the 1st, and no more than three months in the past. Changing it recreates the budget."
  type        = string
  default     = "2026-08-01T00:00:00Z"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-01T00:00:00Z$", var.budget_start_date))
    error_message = "budget_start_date must be the first of a month, e.g. 2026-08-01T00:00:00Z."
  }
}

variable "budget_end_date" {
  description = "When the budget stops tracking, RFC 3339. Far in the future so the alerts simply keep running for the life of the course."
  type        = string
  default     = "2030-01-01T00:00:00Z"
}

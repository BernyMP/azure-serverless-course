// Reads the subscription the provider is authenticated against (what `az account show`
// reports), keeping the subscription GUID out of source control.
data "azurerm_subscription" "current" {}

// An Azure budget is an ALERT, not a spending limit: crossing a threshold sends
// mail but never stops or throttles anything -- it buys time to run `terraform destroy`.
resource "azurerm_consumption_budget_subscription" "monthly_guardrail" {
  name            = "${var.project_name}-${var.environment}-budget"
  subscription_id = data.azurerm_subscription.current.id

  amount     = var.monthly_budget_amount
  time_grain = "Monthly"

  time_period {
    // start_date forces a new resource when it changes, so it's a fixed variable
    // (not timestamp()) to avoid recreating the budget every month. Must be the 1st of a month.
    start_date = var.budget_start_date
    end_date   = var.budget_end_date
  }

  notification {
    enabled        = true
    threshold      = 100.0
    threshold_type = "Forecasted"
    operator       = "GreaterThan"
    contact_roles  = ["Owner"]
    # contact_emails = ["you@example.com"]
  }

  notification {
    enabled        = true
    threshold      = 50.0
    threshold_type = "Actual"
    operator       = "GreaterThan"
    contact_roles  = ["Owner"]
    # contact_emails = ["you@example.com"]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    threshold_type = "Actual"
    operator       = "GreaterThan"
    contact_roles  = ["Owner"]
    # contact_emails = ["you@example.com"]
  }
}

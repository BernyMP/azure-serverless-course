// Every other guardrail in this configuration caps TELEMETRY: daily_quota_gb on
// the workspace, daily_data_cap_in_gb on Application Insights, app_scale_limit
// on the function app. None of them caps money. Compute, storage, bandwidth and
// any resource you create by hand while experimenting can all bill without a
// single log line being written.
//
// A budget is the subscription-wide backstop for that. Read the next paragraph
// carefully, because the name is misleading:
//
//   An Azure budget is an ALERT, not a spending limit. Crossing a threshold
//   sends mail. It never stops a resource, throttles an API, or shuts anything
//   down. Pay-as-you-go subscriptions have no hard spend cap at all -- only the
//   free trial does, and it stops the whole subscription when it trips. So
//   treat this as a smoke detector, not a sprinkler: it buys you the chance to
//   run `terraform -chdir=infra destroy` before a surprise becomes a bill.
//
// Budgets themselves are free, and they live in Cost Management rather than in
// the resource group, so they cost nothing to leave switched on.

// Reads whichever subscription the provider is currently authenticated against
// -- the one `az account show` reports. Using the data source instead of
// hardcoding a GUID keeps the subscription id out of source control and lets
// the same configuration work if you switch subscriptions with `az account set`.
data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_subscription" "monthly_guardrail" {
  name = "${var.project_name}-${var.environment}-budget"

  // Expects the full resource id ("/subscriptions/<guid>"), not the bare guid,
  // which is exactly what the data source's .id attribute returns.
  subscription_id = data.azurerm_subscription.current.id

  amount = var.monthly_budget_amount

  // The window the amount applies to, after which the running total resets to
  // zero. "Monthly" lines up with how Azure bills and how the free grants on
  // Functions and Log Analytics reset. "Quarterly" and "Annually" also exist.
  time_grain = "Monthly"

  time_period {
    // Azure requires a budget period to begin on the first day of a month and
    // refuses a start date more than three months in the past.
    //
    // This is a variable rather than something computed from timestamp() on
    // purpose: start_date forces a new resource when it changes, so a computed
    // value would silently destroy and recreate the budget every month, on a
    // plan where nothing else changed. Fixed input, stable plan.
    start_date = var.budget_start_date
    end_date   = var.budget_end_date
  }

  // Deliberately NOT narrowed with a `filter` block. Filtering on
  // ResourceGroupName would watch only order-system-dev-rg and stay quiet about
  // everything else -- including the tfstate storage account in serverless-rg,
  // which was created by hand and which `terraform destroy` therefore never
  // removes, and including anything you click together in the portal while
  // following along. Watching the entire subscription is the point of a
  // backstop; a filtered budget is the one that misses the bill you did not
  // expect.

  // Azure allows up to five notifications per budget. Two flavours matter:
  //
  //   Actual     - fires after the money has genuinely been spent. Accurate,
  //                but by definition it only ever tells you about the past.
  //   Forecasted - fires when Azure's projection for the rest of the period
  //                crosses the threshold. This is the one that warns you while
  //                something is still ramping up and there is time to react.
  //
  // Each notification also picks who hears about it. contact_roles = ["Owner"]
  // mails whoever holds Owner on the subscription -- you, on a personal
  // learning subscription -- so no address has to be committed to git. To add
  // specific addresses instead, uncomment contact_emails below.

  // Early warning: spend is on track to blow through the budget this month.
  notification {
    enabled        = true
    threshold      = 100.0
    threshold_type = "Forecasted"
    operator       = "GreaterThan"
    contact_roles  = ["Owner"]
    # contact_emails = ["you@example.com"]
  }

  // Something is actually running up a tab. At the default budget this is a
  // couple of dollars: still cheap, but it means the "everything is free tier"
  // assumption no longer holds and it is worth looking at Cost Analysis.
  notification {
    enabled        = true
    threshold      = 50.0
    threshold_type = "Actual"
    operator       = "GreaterThan"
    contact_roles  = ["Owner"]
    # contact_emails = ["you@example.com"]
  }

  // The budget has been spent. Nothing stops here -- see the warning at the top
  // of this file -- so treat this mail as a prompt to go destroy the stack.
  notification {
    enabled        = true
    threshold      = 100.0
    threshold_type = "Actual"
    operator       = "GreaterThan"
    contact_roles  = ["Owner"]
    # contact_emails = ["you@example.com"]
  }
}

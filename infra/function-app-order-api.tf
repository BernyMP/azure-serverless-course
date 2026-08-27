resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  // PerGB2018 bills per GB ingested with no ceiling by default (the API
  // reports dailyQuotaGb = -1, meaning unlimited). A runaway loop or a public
  // endpoint being hammered would bill straight through. 1 GB/day is far more
  // than a course workload needs; ingestion stops for the day once it is hit.
  daily_quota_gb = 1

  tags = {
    "course" = "serverless"
  }
}

resource "azurerm_application_insights" "app1_insights" {
  name                = "${var.project_name}-api-${var.environment}-ai"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "other"

  workspace_id = azurerm_log_analytics_workspace.main.id

  // Defaults to 100 GB/day. At PerGB2018 rates that is a multi-hundred-dollar
  // day if telemetry ever runs away. Cap it low for a learning project.
  daily_data_cap_in_gb = 1

  // Keeps the "daily cap reached" email notification switched on. (Older
  // provider versions only exposed the negative form of this switch,
  // daily_data_cap_notifications_disabled; 4.x deprecated it.)
  daily_data_cap_notifications_enabled = true

  tags = {
    "course" = "serverless"
    "func"   = "${var.project_name}-api-${var.environment}"
  }
}

// Flex Consumption uses its own resource type, not azurerm_linux_function_app.
// Switching plans is therefore a replacement, not an in-place update: Terraform
// destroys the Y1 app and creates this one, and the code must be redeployed
// afterwards because the deployed package does not survive the swap.
resource "azurerm_function_app_flex_consumption" "order-api-func" {
  name                = "${var.project_name}-api-${var.environment}-func2"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.my_plan.id

  // Flex's "one deploy" model: CI uploads the published zip to this blob
  // container and the platform runs the app from it. These four arguments
  // replace the Y1-era storage_account_name / storage_account_access_key
  // pair and the WEBSITE_CONTENT* app settings.
  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.deployments.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.main.primary_access_key

  // Replaces site_config.application_stack. The version must match the
  // <TargetFramework> in order-api-function.csproj, or the host starts a
  // runtime the published assemblies cannot load. Azure reports flex
  // runtime versions without the minor part ("10", not "10.0") -- see
  // `az functionapp list-flexconsumption-runtimes`. runtime_name also
  // replaces the FUNCTIONS_WORKER_RUNTIME app setting, which must NOT be
  // set manually on flex (it breaks deployments). The isolated worker
  // model is the only one flex supports, so there is no in-process toggle.
  runtime_name    = "dotnet-isolated"
  runtime_version = "10"

  // The cost guardrail, replacing app_scale_limit (its underlying setting,
  // WEBSITE_MAX_DYNAMIC_APPLICATION_SCALE_OUT, is not honoured on flex).
  // 40 is the minimum Azure accepts, which sounds like a lot next to the
  // old limit of 5 -- but unlike Y1's default burst to 200 instances, an
  // instance here is a fixed 2 GB billed only while executing, and the
  // plan scales to zero when idle. Runaway-cost risk is bounded by
  // instance count times memory, and the subscription budget alerts
  // remain the real safety net.
  maximum_instance_count = 40
  instance_memory_in_mb  = 2048

  // Defaults to false, which leaves the app answering on plain HTTP as well as
  // HTTPS. Order payloads carry a customer name and email, so the cleartext
  // listener should be closed. This redirects http:// to https://.
  https_only = true

  site_config {}

  app_settings = {
    // Host runtime state (timers, leases, function keys) still lives in the
    // storage account, separate from the deployment container above.
    AzureWebJobsStorage = azurerm_storage_account.main.primary_connection_string

    // Program.cs only wires up the Azure Monitor OpenTelemetry exporter when
    // this variable is present, and host.json sets "telemetryMode":
    // "OpenTelemetry". The older APPINSIGHTS_INSTRUMENTATION_KEY is deprecated
    // and is not read by the OpenTelemetry exporter at all.
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.app1_insights.connection_string
  }

  tags = {
    "course" = "serverless"
  }
}


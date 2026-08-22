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

  // The provider only exposes the negative form: setting this to false leaves
  // the "daily cap reached" email notification switched on.
  daily_data_cap_notifications_disabled = false

  tags = {
    "course" = "serverless"
    "func"   = "${var.project_name}-api-${var.environment}"
  }
}

resource "azurerm_linux_function_app" "order-api-func" {
  name                = "${var.project_name}-api-${var.environment}-func2"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.my_plan.id

  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  // Defaults to false, which leaves the app answering on plain HTTP as well as
  // HTTPS. Order payloads carry a customer name and email, so the cleartext
  // listener should be closed. This redirects http:// to https://.
  https_only = true

  site_config {
    // A Consumption plan bursts to 200 instances by default (that is what
    // Azure reports for this app today), and each instance can run several
    // executions at once. That elasticity is the whole point of serverless in
    // production, but on a learning subscription it is also the blast radius:
    // a function that loops, retries forever, or gets hit by a tight test loop
    // can fan out to hundreds of billed workers before you notice.
    //
    // 5 is far more concurrency than a course exercise needs, and it turns a
    // runaway function into a slow queue instead of a large invoice. Requests
    // beyond that capacity are not dropped -- they wait.
    //
    // Under the hood this sets WEBSITE_MAX_DYNAMIC_APPLICATION_SCALE_OUT. Only
    // Consumption and Premium plans honour it; a Dedicated plan ignores it.
    // Raise or remove it before any real load test, or you will be measuring
    // this ceiling rather than the code.
    app_scale_limit = 5

    application_stack {
      // The worker runs the .NET version named here. It must match the
      // <TargetFramework> in order-api-function.csproj, or the host starts a
      // runtime the published assemblies cannot load.
      dotnet_version = "8.0"

      // The isolated worker model runs our code in its own process, separate
      // from the Functions host, which is what Program.cs builds with
      // FunctionsApplication.CreateBuilder. The alternative (in-process) is
      // retired, so this is always true for new apps.
      use_dotnet_isolated_runtime = true
    }
  }

  app_settings = {
    // Tells the Functions host which language worker to launch. "dotnet" would
    // mean the retired in-process model; the isolated model needs this value.
    FUNCTIONS_WORKER_RUNTIME = "dotnet-isolated"

    AzureWebJobsStorage = azurerm_storage_account.main.primary_connection_string

    // Program.cs only wires up the Azure Monitor OpenTelemetry exporter when
    // this variable is present, and host.json sets "telemetryMode":
    // "OpenTelemetry". The older APPINSIGHTS_INSTRUMENTATION_KEY is deprecated
    // and is not read by the OpenTelemetry exporter at all.
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.app1_insights.connection_string
  }
}


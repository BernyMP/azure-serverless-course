resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  // PerGB2018 has no ingestion ceiling by default
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

  // Default cap is 100 GB/day,
  daily_data_cap_in_gb                 = 1
  daily_data_cap_notifications_enabled = true

  tags = {
    "course" = "serverless"
    "func"   = "${var.project_name}-api-${var.environment}"
  }
}

// Flex uses its own resource type; switching plans is a destroy/create replacement
// and the code must be redeployed afterwards.
resource "azurerm_function_app_flex_consumption" "order-api-func" {
  name                = "${var.project_name}-api-${var.environment}-func2"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.my_plan.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.deployments.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.main.primary_access_key

  runtime_name    = "dotnet-isolated"
  runtime_version = "10.0"

  maximum_instance_count = 40 // 40 is the minimum Azure accepts
  instance_memory_in_mb  = 2048

  https_only = true

  site_config {}

  app_settings = {
    AzureWebJobsStorage                   = azurerm_storage_account.main.primary_connection_string
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.app1_insights.connection_string
  }

  tags = {
    "course" = "serverless"
  }
}

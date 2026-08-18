resource "azurerm_log_analytics_workspace" "main" {
  name = "${var.project_name}-${var.environment}-law"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku = "PerGB2018"
  retention_in_days = "30"
  
  tags = {
    "course" = "serverless"
  }
}

resource "azurerm_application_insights" "app1_insights" {
  name = "${var.project_name}-api-${var.environment}-ai"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type = "other"
  
  workspace_id = azurerm_log_analytics_workspace.main.id
  
  tags = {
    "course" = "serverless"
    "func" = "${var.project_name}-api-${var.environment}"
  }
}

resource "azurerm_linux_function_app" "order-api-func" {
  name = "${var.project_name}-api-${var.environment}-func2"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  service_plan_id = azurerm_service_plan.my_plan.id
  
  storage_account_name = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  
  site_config {
    application_stack {
      python_version = "3.11"
    }
  }
  
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    AzureWebJobsStorage = azurerm_storage_account.main.primary_connection_string
    APPINSIGHTS_INSTRUMENTATION_KEY = azurerm_application_insights.app1_insights.instrumentation_key
  }
}
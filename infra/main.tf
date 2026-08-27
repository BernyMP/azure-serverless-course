resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_service_plan" "my_plan" {
  name                = "${var.project_name}-${var.environment}-asp"
  location            = var.location
  os_type             = "Linux"
  resource_group_name = azurerm_resource_group.main.name

  // FC1 is the Flex Consumption plan (the successor to Y1 Classic
  // Consumption). Like Y1 it bills per execution and scales to zero when
  // idle, but it adds per-app instance-count/memory controls and a faster
  // cold start. One structural difference from Y1: a Flex plan hosts
  // exactly ONE function app, so a second function app needs its own plan
  // rather than reusing this one.
  sku_name = "FC1"
}

// storage account name must be lowercase letters and numbers
// for the back-end we initialized manually the storage account for the tfstate blob container 
resource "azurerm_storage_account" "main" {
  name                     = "${replace(var.project_name, "-", "")}${var.environment}sa2"
  location                 = var.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  resource_group_name      = azurerm_resource_group.main.name

  // The azurerm provider defaults this to true, which leaves the account-level
  // switch open for any container here to be made anonymously readable. This
  // account stores the function app's runtime state, including the
  // azure-webjobs-secrets container that holds the function access keys, so
  // nothing in it should ever be public. Functions never needs public blobs.
  allow_nested_items_to_be_public = false

  // Reject anything older than TLS 1.2 on the wire.
  min_tls_version = "TLS1_2"
}

// Flex Consumption apps deploy from a blob container (the "one deploy"
// model): the CI pipeline uploads the published zip here and the platform
// runs the app from it. This replaces the Y1-era zip-push into the app's
// own file share, so each function app gets a container like this one.
resource "azurerm_storage_container" "deployments" {
  name                  = "app-deployments"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

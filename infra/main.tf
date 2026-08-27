resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_service_plan" "my_plan" {
  name                = "${var.project_name}-${var.environment}-asp"
  location            = var.location
  os_type             = "Linux"
  resource_group_name = azurerm_resource_group.main.name

  // FC1 = Flex Consumption (successor to Y1): per-execution billing, scales to
  // zero, but a Flex plan hosts exactly ONE function app, a second app needs its own plan.
  sku_name = "FC1"
}

// Name must be lowercase alphanumerics; the tfstate backend account is separate and manually created.
resource "azurerm_storage_account" "main" {
  name                     = "${replace(var.project_name, "-", "")}${var.environment}sa2"
  location                 = var.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  resource_group_name      = azurerm_resource_group.main.name

  // Lock down: no public blobs (this account holds function keys) and TLS 1.2 minimum.
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
}

// Flex's "one deploy" model: CI uploads the published zip here and the platform
// runs the app from it. Each function app gets its own container like this one.
resource "azurerm_storage_container" "deployments" {
  name                  = "app-deployments"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

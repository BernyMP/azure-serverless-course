resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_service_plan" "my_plan" {
  name                = "${var.project_name}-${var.environment}-asp"
  location            = var.location
  os_type             = "Linux"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Y1"
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

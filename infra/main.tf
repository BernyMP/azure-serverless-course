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
  name = "${replace(var.project_name, "-", "")}${var.environment}sa"
  location = var.location
  account_replication_type = "LRS"
  account_tier = "Standard"
  resource_group_name = azurerm_resource_group.main.name
}
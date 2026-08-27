output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "order_api_function_url" {
  value = azurerm_function_app_flex_consumption.order-api-func.default_hostname
}

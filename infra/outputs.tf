output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "order_api_function_url" {
  value = azurerm_linux_function_app.order-api-func.default_hostname
}

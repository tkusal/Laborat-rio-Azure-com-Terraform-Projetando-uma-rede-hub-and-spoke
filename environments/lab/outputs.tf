output "resource_group_names" {
  description = "Nomes dos grupos de recursos por papel de rede."
  value       = { for key, group in azurerm_resource_group.network : key => group.name }
}

output "virtual_network_ids" {
  description = "IDs das redes virtuais criadas pelo laboratorio."
  value       = { for key, network in module.virtual_network : key => network.id }
}

output "subnet_ids" {
  description = "IDs das subnets, agrupados por rede virtual."
  value       = { for key, network in module.virtual_network : key => network.subnet_ids }
}

output "peering_ids" {
  description = "IDs dos quatro links direcionais de peering."
  value = {
    hub_to_app  = azurerm_virtual_network_peering.hub_to_app.id
    app_to_hub  = azurerm_virtual_network_peering.app_to_hub.id
    hub_to_data = azurerm_virtual_network_peering.hub_to_data.id
    data_to_hub = azurerm_virtual_network_peering.data_to_hub.id
  }
}

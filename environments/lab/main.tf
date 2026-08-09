locals {
  common_tags = merge(
    {
      environment = var.environment
      owner       = var.owner
      cost-center = var.cost_center
      managed-by  = "terraform"
      project     = "azure-hub-spoke-lab"
    },
    var.extra_tags
  )

  networks = {
    hub = {
      resource_group_name = "rg-network-hub-${var.environment}-${var.location_code}-001"
      vnet_name           = "vnet-hub-${var.environment}-${var.location_code}-001"
      role                = "hub"
      address_space       = ["10.64.0.0/16"]
      subnets = {
        shared = {
          name             = "snet-shared-${var.environment}-${var.location_code}-001"
          address_prefixes = ["10.64.10.0/24"]
        }
      }
    }
    spoke_app = {
      resource_group_name = "rg-network-app-${var.environment}-${var.location_code}-001"
      vnet_name           = "vnet-app-${var.environment}-${var.location_code}-001"
      role                = "spoke"
      address_space       = ["10.65.0.0/16"]
      subnets = {
        web = {
          name             = "snet-web-${var.environment}-${var.location_code}-001"
          address_prefixes = ["10.65.10.0/24"]
        }
        app = {
          name             = "snet-app-${var.environment}-${var.location_code}-001"
          address_prefixes = ["10.65.20.0/24"]
        }
      }
    }
    spoke_data = {
      resource_group_name = "rg-network-data-${var.environment}-${var.location_code}-001"
      vnet_name           = "vnet-data-${var.environment}-${var.location_code}-001"
      role                = "spoke"
      address_space       = ["10.66.0.0/16"]
      subnets = {
        data = {
          name             = "snet-data-${var.environment}-${var.location_code}-001"
          address_prefixes = ["10.66.10.0/24"]
        }
        integration = {
          name             = "snet-integration-${var.environment}-${var.location_code}-001"
          address_prefixes = ["10.66.20.0/24"]
        }
      }
    }
  }
}

resource "azurerm_resource_group" "network" {
  for_each = local.networks

  name     = each.value.resource_group_name
  location = var.location
  tags     = merge(local.common_tags, { network-role = each.value.role })
}

module "virtual_network" {
  source   = "../../modules/virtual-network"
  for_each = local.networks

  name                = each.value.vnet_name
  resource_group_name = azurerm_resource_group.network[each.key].name
  location            = azurerm_resource_group.network[each.key].location
  address_space       = each.value.address_space
  subnets             = each.value.subnets
  tags                = merge(local.common_tags, { network-role = each.value.role })
}

resource "azurerm_virtual_network_peering" "hub_to_app" {
  name                      = "peer-hub-to-app-${var.environment}-${var.location_code}-001"
  resource_group_name       = module.virtual_network["hub"].resource_group_name
  virtual_network_name      = module.virtual_network["hub"].name
  remote_virtual_network_id = module.virtual_network["spoke_app"].id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "app_to_hub" {
  name                      = "peer-app-to-hub-${var.environment}-${var.location_code}-001"
  resource_group_name       = module.virtual_network["spoke_app"].resource_group_name
  virtual_network_name      = module.virtual_network["spoke_app"].name
  remote_virtual_network_id = module.virtual_network["hub"].id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [azurerm_virtual_network_peering.hub_to_app]
}

resource "azurerm_virtual_network_peering" "hub_to_data" {
  name                      = "peer-hub-to-data-${var.environment}-${var.location_code}-001"
  resource_group_name       = module.virtual_network["hub"].resource_group_name
  virtual_network_name      = module.virtual_network["hub"].name
  remote_virtual_network_id = module.virtual_network["spoke_data"].id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [azurerm_virtual_network_peering.hub_to_app]
}

resource "azurerm_virtual_network_peering" "data_to_hub" {
  name                      = "peer-data-to-hub-${var.environment}-${var.location_code}-001"
  resource_group_name       = module.virtual_network["spoke_data"].resource_group_name
  virtual_network_name      = module.virtual_network["spoke_data"].name
  remote_virtual_network_id = module.virtual_network["hub"].id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [azurerm_virtual_network_peering.hub_to_data]
}

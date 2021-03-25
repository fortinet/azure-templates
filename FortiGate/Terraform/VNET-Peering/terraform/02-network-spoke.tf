###############################################################################################################
#
# Cloud Security Services Hub
# using VNET peering and FortiGate Active/Passive High Availability with Azure Standard Load Balancer - External and Internal
# Fortinet FortiGate Terraform deployment template
#
##############################################################################################################
#
# Deployment of the spoke networks and VNET peering
#
# Known issue during deployment: https://github.com/terraform-providers/terraform-provider-azurerm/issues/2605
#
##############################################################################################################

##############################################################################################################
# SPOKE 1
##############################################################################################################
resource "azurerm_virtual_network" "vnetspoke1" {
  name                = "${var.PREFIX}-VNET-SPOKE1"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  address_space       = [var.vnetspoke1]
}

resource "azurerm_subnet" "subnet1spoke1" {
  name                 = "${var.PREFIX}-SPOKE1-SUBNET1"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetspoke1.name
  address_prefixes     = [var.subnetspoke1["1"]]
}

resource "azurerm_virtual_network_peering" "hub2spoke1" {
  name                         = "hub2spoke1"
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.vnetspoke1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  depends_on = [
    azurerm_virtual_network.vnet,
    azurerm_virtual_network.vnetspoke1,
    azurerm_virtual_network.vnetspoke2,
    azurerm_subnet.subnet1,
    azurerm_subnet.subnet2,
    azurerm_subnet.subnet3,
    azurerm_subnet.subnet4,
    azurerm_subnet.subnet5,
    azurerm_subnet.subnet6,
    azurerm_subnet.subnet1spoke1,
    azurerm_subnet.subnet1spoke2,
    azurerm_subnet_route_table_association.spoke1rt,
  ]
}

resource "azurerm_virtual_network_peering" "spoke12hub" {
  name                         = "spoke12hub"
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  virtual_network_name         = azurerm_virtual_network.vnetspoke1.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  depends_on = [
    azurerm_virtual_network.vnet,
    azurerm_virtual_network.vnetspoke1,
    azurerm_virtual_network.vnetspoke2,
    azurerm_subnet.subnet1,
    azurerm_subnet.subnet2,
    azurerm_subnet.subnet3,
    azurerm_subnet.subnet4,
    azurerm_subnet.subnet5,
    azurerm_subnet.subnet6,
    azurerm_subnet.subnet1spoke1,
    azurerm_subnet.subnet1spoke2,
    azurerm_virtual_network_peering.hub2spoke1,
  ]
}

resource "azurerm_subnet_route_table_association" "spoke1rt" {
  subnet_id      = azurerm_subnet.subnet1spoke1.id
  route_table_id = azurerm_route_table.spoke1route.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}

resource "azurerm_route_table" "spoke1route" {
  name                = "${var.PREFIX}-RT-SPOKE1"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "VirtualNetwork"
    address_prefix         = var.vnetspoke1
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.lb_internal_ipaddress
  }
  route {
    name           = "Subnet"
    address_prefix = var.subnetspoke1["1"]
    next_hop_type  = "VnetLocal"
  }
  route {
    name                   = "Default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.lb_internal_ipaddress
  }
}

##############################################################################################################
# SPOKE 2
##############################################################################################################
resource "azurerm_virtual_network" "vnetspoke2" {
  name                = "${var.PREFIX}-VNET-SPOKE2"
  address_space       = [var.vnetspoke2]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_virtual_network_peering" "hub2spoke2" {
  name                         = "hub2spoke2"
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.vnetspoke2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  depends_on = [
    azurerm_virtual_network.vnet,
    azurerm_virtual_network.vnetspoke1,
    azurerm_virtual_network.vnetspoke2,
    azurerm_subnet.subnet1,
    azurerm_subnet.subnet2,
    azurerm_subnet.subnet3,
    azurerm_subnet.subnet4,
    azurerm_subnet.subnet5,
    azurerm_subnet.subnet6,
    azurerm_subnet.subnet1spoke1,
    azurerm_subnet.subnet1spoke2,
    azurerm_virtual_network_peering.spoke12hub,
  ]
}

resource "azurerm_virtual_network_peering" "spoke22hub" {
  name                         = "spoke22hub"
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  virtual_network_name         = azurerm_virtual_network.vnetspoke2.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  depends_on = [
    azurerm_virtual_network.vnet,
    azurerm_virtual_network.vnetspoke1,
    azurerm_virtual_network.vnetspoke2,
    azurerm_subnet.subnet1,
    azurerm_subnet.subnet2,
    azurerm_subnet.subnet3,
    azurerm_subnet.subnet4,
    azurerm_subnet.subnet5,
    azurerm_subnet.subnet6,
    azurerm_subnet.subnet1spoke1,
    azurerm_subnet.subnet1spoke2,
    azurerm_virtual_network_peering.hub2spoke2,
  ]
}

resource "azurerm_subnet" "subnet1spoke2" {
  name                 = "${var.PREFIX}-SPOKE2-SUBNET1"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnetspoke2.name
  address_prefixes     = [var.subnetspoke2["1"]]
}

resource "azurerm_subnet_route_table_association" "spoke2rt" {
  subnet_id      = azurerm_subnet.subnet1spoke2.id
  route_table_id = azurerm_route_table.spoke2route.id

  lifecycle {
    ignore_changes = [route_table_id]
  }
}

resource "azurerm_route_table" "spoke2route" {
  name                = "${var.PREFIX}-RT-SPOKE2"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name

  route {
    name                   = "VirtualNetwork"
    address_prefix         = var.vnetspoke2
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.lb_internal_ipaddress
  }
  route {
    name           = "Subnet"
    address_prefix = var.subnetspoke2["1"]
    next_hop_type  = "VnetLocal"
  }
  route {
    name                   = "Default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.lb_internal_ipaddress
  }
}

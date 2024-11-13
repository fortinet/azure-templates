##############################################################################################################
#
# FortiManager VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "azurerm_network_security_group" "fmgnsg" {
  name                = "${var.PREFIX}-FMG-NSG"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_rule" "fmgnsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 105
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowsshin" {
  name                        = "AllowSSHInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowhttpin" {
  name                        = "AllowHTTPInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowhttpsin" {
  name                        = "AllowHTTPSInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fmgnsgallowdevregin" {
  name                        = "AllowDevRegInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fmgnsg.name
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "541"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "fmgpip" {
  name                = "${var.PREFIX}-FMG-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "lb-pip")
}


resource "azurerm_network_interface" "fmgifc" {
  name                 = "${var.PREFIX}-FMG-IFC"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "static"
    private_ip_address            = var.fmg_ipaddress_a["1"]
    public_ip_address_id          = azurerm_public_ip.fmgpip.id
  }
}

resource "azurerm_network_interface_security_group_association" "fmgnsg" {
  network_interface_id      = azurerm_network_interface.fmgifc.id
  network_security_group_id = azurerm_network_security_group.fmgnsg.id
}

resource "azurerm_virtual_machine" "fmgvm" {
  name                         = "${var.PREFIX}-FMG-VM"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  network_interface_ids        = [azurerm_network_interface.fmgifc.id]
  primary_network_interface_id = azurerm_network_interface.fmgifc.id
  vm_size                      = var.fmg_vmsize

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "fortinet"
    offer     = "fortinet-fortimanager"
    sku       = var.FMG_IMAGE_SKU
    version   = var.FMG_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet-fortimanager"
    name      = var.FMG_IMAGE_SKU
  }

  storage_os_disk {
    name              = "${var.PREFIX}-FMG-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-FMG-A"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.fmg_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    publisher = "Fortinet",
    template  = "FortiManager-Terraform",
    provider  = "6EB3B02F-50E5-4A3E-8CB8-2E1292583FMG"
  }
}

data "template_file" "fmg_custom_data" {
  template = file("${path.module}/customdata.tpl")

  vars = {
    fmg_vm_name        = "${var.PREFIX}-FMG-A"
    fmg_license_file   = var.FMG_BYOL_LICENSE_FILE
    fmg_username       = var.USERNAME
    fmg_ssh_public_key = var.FMG_SSH_PUBLIC_KEY_FILE
    fmg_ipaddr         = var.fmg_ipaddress_a["1"]
    fmg_mask           = var.subnetmask["1"]
    fmg_gw             = var.gateway_ipaddress["1"]
    vnet_network       = var.vnet
  }
}

data "azurerm_public_ip" "fmgpip" {
  name                = azurerm_public_ip.fmgpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "fmg_public_ip_address" {
  value = data.azurerm_public_ip.fmgpip.ip_address
}

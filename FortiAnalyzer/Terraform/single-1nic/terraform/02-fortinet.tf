##############################################################################################################
#
# FortiAnalyzer VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "azurerm_network_security_group" "faznsg" {
  name                = "${var.PREFIX}-FAZ-NSG"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_rule" "faznsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 105
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowsshin" {
  name                        = "AllowSSHInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowhttpin" {
  name                        = "AllowHTTPInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowhttpsin" {
  name                        = "AllowHTTPSInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "faznsgallowdevregin" {
  name                        = "AllowDevRegInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.faznsg.name
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "514"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "fazpip" {
  name                = "${var.PREFIX}-FAZ-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "lb-pip")
}


resource "azurerm_network_interface" "fazifc" {
  name                 = "${var.PREFIX}-FAZ-IFC"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "static"
    private_ip_address            = var.faz_ipaddress_a["1"]
    public_ip_address_id          = azurerm_public_ip.fazpip.id
  }
}

resource "azurerm_network_interface_security_group_association" "faznsg" {
  network_interface_id      = azurerm_network_interface.fazifc.id
  network_security_group_id = azurerm_network_security_group.faznsg.id
}

resource "azurerm_virtual_machine" "fazvm" {
  name                         = "${var.PREFIX}-FAZ-VM"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  network_interface_ids        = [azurerm_network_interface.fazifc.id]
  primary_network_interface_id = azurerm_network_interface.fazifc.id
  vm_size                      = var.faz_vmsize

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "fortinet"
    offer     = "fortinet-fortianalyzer"
    sku       = var.FAZ_IMAGE_SKU
    version   = var.FAZ_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet-fortianalyzer"
    name      = var.FAZ_IMAGE_SKU
  }

  storage_os_disk {
    name              = "${var.PREFIX}-FAZ-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-FAZ-A"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.faz_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    publisher = "Fortinet",
    template  = "FortiAnalyzer-Terraform",
    provider  = "6EB3B02F-50E5-4A3E-8CB8-2E1292583FAZ"
  }
}

data "template_file" "faz_custom_data" {
  template = file("${path.module}/customdata.tpl")

  vars = {
    faz_vm_name        = "${var.PREFIX}-FAZ-A"
    faz_license_file   = var.FAZ_BYOL_LICENSE_FILE
    faz_username       = var.USERNAME
    faz_ssh_public_key = var.FAZ_SSH_PUBLIC_KEY_FILE
    faz_ipaddr         = var.faz_ipaddress_a["1"]
    faz_mask           = var.subnetmask["1"]
    faz_gw             = var.gateway_ipaddress["1"]
    vnet_network       = var.vnet
  }
}

data "azurerm_public_ip" "fazpip" {
  name                = azurerm_public_ip.fazpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

output "faz_public_ip_address" {
  value = data.azurerm_public_ip.fazpip.ip_address
}

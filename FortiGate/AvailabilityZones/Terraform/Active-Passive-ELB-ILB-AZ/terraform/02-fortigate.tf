##############################################################################################################
#
# FortiGate Active/Passive High Availability with Azure Standard Load Balancer - External and Internal
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "azurerm_network_security_group" "fgtnsg" {
  name                = "${var.PREFIX}-FGT-NSG"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_rule" "fgtnsgallowallout" {
  name                        = "AllowAllOutbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fgtnsg.name
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "fgtnsgallowallin" {
  name                        = "AllowAllInbound"
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.fgtnsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "elbpip" {
  name                = "${var.PREFIX}-ELB-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "lb-pip")
}

resource "azurerm_lb" "elb" {
  name                = "${var.PREFIX}-ExternalLoadBalancer"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.PREFIX}-ELB-PIP"
    public_ip_address_id = azurerm_public_ip.elbpip.id
  }
}

resource "azurerm_lb_backend_address_pool" "elbbackend" {
  resource_group_name = azurerm_resource_group.resourcegroup.name
  loadbalancer_id     = azurerm_lb.elb.id
  name                = "BackEndPool"
}

resource "azurerm_lb_probe" "elbprobe" {
  resource_group_name = azurerm_resource_group.resourcegroup.name
  loadbalancer_id     = azurerm_lb.elb.id
  name                = "lbprobe"
  port                = 8008
}

resource "azurerm_lb_rule" "lbruletcp" {
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "PublicLBRule-FE1-http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.PREFIX}-ELB-PIP"
  probe_id                       = azurerm_lb_probe.elbprobe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.elbbackend.id
}

resource "azurerm_lb_rule" "lbruleudp" {
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "PublicLBRule-FE1-udp10551"
  protocol                       = "Udp"
  frontend_port                  = 10551
  backend_port                   = 10551
  frontend_ip_configuration_name = "${var.PREFIX}-ELB-PIP"
  probe_id                       = azurerm_lb_probe.elbprobe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.elbbackend.id
}

resource "azurerm_lb" "ilb" {
  name                = "${var.PREFIX}-InternalLoadBalancer"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "${var.PREFIX}-ILB-PIP"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address            = var.lb_internal_ipaddress
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "ilbbackend" {
  resource_group_name = azurerm_resource_group.resourcegroup.name
  loadbalancer_id     = azurerm_lb.ilb.id
  name                = "BackEndPool"
}

resource "azurerm_lb_probe" "ilbprobe" {
  resource_group_name = azurerm_resource_group.resourcegroup.name
  loadbalancer_id     = azurerm_lb.ilb.id
  name                = "lbprobe"
  port                = 8008
}

resource "azurerm_lb_rule" "lb_haports_rule" {
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = azurerm_lb.ilb.id
  name                           = "lb_haports_rule"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "${var.PREFIX}-ILB-PIP"
  probe_id                       = azurerm_lb_probe.ilbprobe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.ilbbackend.id
}

resource "azurerm_network_interface" "fgtaifcext" {
  name                          = "${var.PREFIX}-A-VM-FGT-IFC-EXT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.FGT_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress_a["1"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtaifcextnsg" {
  network_interface_id      = azurerm_network_interface.fgtaifcext.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "fgtaifcext2elbbackendpool" {
  network_interface_id    = azurerm_network_interface.fgtaifcext.id
  ip_configuration_name   = "interface1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.elbbackend.id
}

resource "azurerm_network_interface" "fgtaifcint" {
  name                 = "${var.PREFIX}-A-VM-FGT-IFC-INT"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress_a["2"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtaifcintnsg" {
  network_interface_id      = azurerm_network_interface.fgtaifcint.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "fgtaifcint2ilbbackendpool" {
  network_interface_id    = azurerm_network_interface.fgtaifcint.id
  ip_configuration_name   = "interface1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ilbbackend.id
}

resource "azurerm_network_interface" "fgtaifchasync" {
  name                 = "${var.PREFIX}-A-VM-FGT-IFC-HASYNC"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet3.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress_a["3"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtaifchasyncnsg" {
  network_interface_id      = azurerm_network_interface.fgtaifchasync.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_public_ip" "fgtamgmtpip" {
  name                = "${var.PREFIX}-A-FGT-MGMT-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "fgt-a-mgmt-pip")
}

resource "azurerm_network_interface" "fgtaifcmgmt" {
  name                          = "${var.PREFIX}-A-VM-FGT-IFC-MGMT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.FGT_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet4.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress_a["4"]
    public_ip_address_id          = azurerm_public_ip.fgtamgmtpip.id
  }
}

resource "azurerm_network_interface_security_group_association" "fgtaifcmgmtnsg" {
  network_interface_id      = azurerm_network_interface.fgtaifcmgmt.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_virtual_machine" "fgtavm" {
  name                         = "${var.PREFIX}-A-VM-FGT"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  network_interface_ids        = [azurerm_network_interface.fgtaifcext.id, azurerm_network_interface.fgtaifcint.id, azurerm_network_interface.fgtaifchasync.id, azurerm_network_interface.fgtaifcmgmt.id]
  primary_network_interface_id = azurerm_network_interface.fgtaifcext.id
  vm_size                      = var.fgt_vmsize
  zones                        = [1]
  tags                         = var.fortinet_tags

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = var.FGT_IMAGE_SKU
    version   = var.FGT_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet_fortigate-vm_v5"
    name      = var.FGT_IMAGE_SKU
  }

  storage_os_disk {
    name              = "${var.PREFIX}-A-VM-FGT-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "${var.PREFIX}-A-FGT-VM-DATADISK"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "10"
  }


  os_profile {
    computer_name  = "${var.PREFIX}-A-VM-FGT"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.fgt_a_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

data "template_file" "fgt_a_custom_data" {
  template = file("${path.module}/customdata.tpl")

  vars = {
    fgt_vm_name         = "${var.PREFIX}-A-VM-FGT"
    fgt_license_file    = var.FGT_BYOL_LICENSE_FILE_A
    fgt_username        = var.USERNAME
    fgt_ssh_public_key  = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_config_ha       = var.FGT_CONFIG_HA
    fgt_external_ipaddr = var.fgt_ipaddress_a["1"]
    fgt_external_mask   = var.subnetmask["1"]
    fgt_external_gw     = var.gateway_ipaddress["1"]
    fgt_internal_ipaddr = var.fgt_ipaddress_a["2"]
    fgt_internal_mask   = var.subnetmask["2"]
    fgt_internal_gw     = var.gateway_ipaddress["2"]
    fgt_hasync_ipaddr   = var.fgt_ipaddress_a["3"]
    fgt_hasync_mask     = var.subnetmask["3"]
    fgt_hasync_gw       = var.gateway_ipaddress["3"]
    fgt_mgmt_ipaddr     = var.fgt_ipaddress_a["4"]
    fgt_mgmt_mask       = var.subnetmask["4"]
    fgt_mgmt_gw         = var.gateway_ipaddress["4"]
    fgt_ha_peerip       = var.fgt_ipaddress_b["3"]
    fgt_ha_priority     = "255"
    fgt_protected_net   = var.subnet["5"]
    vnet_network        = var.vnet
  }
}

resource "azurerm_network_interface" "fgtbifcext" {
  name                          = "${var.PREFIX}-B-VM-FGT-IFC-EXT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.FGT_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress_b["1"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtbifcextnsg" {
  network_interface_id      = azurerm_network_interface.fgtbifcext.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "fgtbifcext2elbbackendpool" {
  network_interface_id    = azurerm_network_interface.fgtbifcext.id
  ip_configuration_name   = "interface1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.elbbackend.id
}

resource "azurerm_network_interface" "fgtbifcint" {
  name                          = "${var.PREFIX}-B-VM-FGT-IFC-INT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.FGT_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress_b["2"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtbifcintnsg" {
  network_interface_id      = azurerm_network_interface.fgtbifcint.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "fgtbifcint2ilbbackendpool" {
  network_interface_id    = azurerm_network_interface.fgtbifcint.id
  ip_configuration_name   = "interface1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ilbbackend.id
}

resource "azurerm_network_interface" "fgtbifchasync" {
  name                          = "${var.PREFIX}-B-VM-FGT-IFC-HASYNC"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.FGT_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet3.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress_b["3"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtbifchasyncnsg" {
  network_interface_id      = azurerm_network_interface.fgtbifchasync.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_public_ip" "fgtbmgmtpip" {
  name                = "${var.PREFIX}-B-FGT-MGMT-PIP"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "fgt-b-mgmt-pip")
}

resource "azurerm_network_interface" "fgtbifcmgmt" {
  name                          = "${var.PREFIX}-B-VM-FGT-IFC-MGMT"
  location                      = azurerm_resource_group.resourcegroup.location
  resource_group_name           = azurerm_resource_group.resourcegroup.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = var.FGT_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet4.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress_b["4"]
    public_ip_address_id          = azurerm_public_ip.fgtbmgmtpip.id
  }
}

resource "azurerm_network_interface_security_group_association" "fgtbifcmgmtnsg" {
  network_interface_id      = azurerm_network_interface.fgtbifcmgmt.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_virtual_machine" "fgtbvm" {
  name                         = "${var.PREFIX}-B-VM-FGT"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  network_interface_ids        = [azurerm_network_interface.fgtbifcext.id, azurerm_network_interface.fgtbifcint.id, azurerm_network_interface.fgtbifchasync.id, azurerm_network_interface.fgtbifcmgmt.id]
  primary_network_interface_id = azurerm_network_interface.fgtbifcext.id
  vm_size                      = var.fgt_vmsize
  zones                        = [2]
  tags                         = var.fortinet_tags

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = var.FGT_IMAGE_SKU
    version   = var.FGT_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet_fortigate-vm_v5"
    name      = var.FGT_IMAGE_SKU
  }

  storage_os_disk {
    name              = "${var.PREFIX}-B-VM-FGT-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "${var.PREFIX}-B-FGT-VM-DATADISK"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "10"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-B-VM-FGT"
    admin_username = var.USERNAME
    admin_password = var.PASSWORD
    custom_data    = data.template_file.fgt_b_custom_data.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

data "template_file" "fgt_b_custom_data" {
  template = file("${path.module}/customdata.tpl")

  vars = {
    fgt_vm_name         = "${var.PREFIX}-B-VM-FGT"
    fgt_license_file    = var.FGT_BYOL_LICENSE_FILE_B
    fgt_username        = var.USERNAME
    fgt_ssh_public_key  = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_config_ha       = var.FGT_CONFIG_HA
    fgt_external_ipaddr = var.fgt_ipaddress_b["1"]
    fgt_external_mask   = var.subnetmask["1"]
    fgt_external_gw     = var.gateway_ipaddress["1"]
    fgt_internal_ipaddr = var.fgt_ipaddress_b["2"]
    fgt_internal_mask   = var.subnetmask["2"]
    fgt_internal_gw     = var.gateway_ipaddress["2"]
    fgt_hasync_ipaddr   = var.fgt_ipaddress_b["3"]
    fgt_hasync_mask     = var.subnetmask["3"]
    fgt_hasync_gw       = var.gateway_ipaddress["3"]
    fgt_mgmt_ipaddr     = var.fgt_ipaddress_b["4"]
    fgt_mgmt_mask       = var.subnetmask["4"]
    fgt_mgmt_gw         = var.gateway_ipaddress["4"]
    fgt_ha_peerip       = var.fgt_ipaddress_a["3"]
    fgt_ha_priority     = "255"
    fgt_protected_net   = var.subnet["5"]
    vnet_network        = var.vnet
  }
}

data "azurerm_public_ip" "fgtamgmtpip" {
  name                = azurerm_public_ip.fgtamgmtpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  depends_on          = [azurerm_virtual_machine.fgtavm]
}

data "azurerm_public_ip" "fgtbmgmtpip" {
  name                = azurerm_public_ip.fgtbmgmtpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  depends_on          = [azurerm_virtual_machine.fgtbvm]
}

output "fgt_a_public_ip_address" {
  value = data.azurerm_public_ip.fgtamgmtpip.ip_address
}

output "fgt_b_public_ip_address" {
  value = data.azurerm_public_ip.fgtbmgmtpip.ip_address
}

data "azurerm_public_ip" "elbpip" {
  name                = azurerm_public_ip.elbpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  depends_on          = [azurerm_lb.elb]
}

output "elb_public_ip_address" {
  value = data.azurerm_public_ip.elbpip.ip_address
}


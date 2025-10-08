##############################################################################################################
#
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################

resource "azurerm_availability_set" "fgtavset" {
  name                = "${var.prefix}-fgt-availabilityset"
  location            = var.location
  managed             = true
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_network_security_group" "fgtnsg" {
  name                = "${var.prefix}-fgt-nsg"
  location            = var.location
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
  name                = "${var.prefix}-elb-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.prefix), "lb-pip")
}

resource "azurerm_lb" "elb" {
  name                = "${var.prefix}-externalloadbalancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.prefix}-elb-pip"
    public_ip_address_id = azurerm_public_ip.elbpip.id
  }
}

resource "azurerm_lb_backend_address_pool" "elbbackend" {
  loadbalancer_id = azurerm_lb.elb.id
  name            = "BackEndPool"
}

resource "azurerm_lb_probe" "elbprobe" {
  loadbalancer_id     = azurerm_lb.elb.id
  name                = "lbprobe"
  port                = 8008
  interval_in_seconds = 5
  number_of_probes    = 2
  protocol            = "Tcp"
}

resource "azurerm_lb_rule" "lbruletcp" {
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "PublicLBRule-FE1-http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.prefix}-ELB-PIP"
  probe_id                       = azurerm_lb_probe.elbprobe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.elbbackend.id]
  enable_floating_ip             = true
}

resource "azurerm_lb_rule" "lbruleudp" {
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "PublicLBRule-FE1-udp10551"
  protocol                       = "Udp"
  frontend_port                  = 10551
  backend_port                   = 10551
  frontend_ip_configuration_name = "${var.prefix}-ELB-PIP"
  probe_id                       = azurerm_lb_probe.elbprobe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.elbbackend.id]
  enable_floating_ip             = true
}

resource "azurerm_lb_nat_rule" "fgtamgmthttps" {
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "${var.prefix}-fgt-a-https"
  protocol                       = "Tcp"
  frontend_port                  = 40030
  backend_port                   = 443
  frontend_ip_configuration_name = "${var.prefix}-ELB-PIP"
}

resource "azurerm_lb_nat_rule" "fgtbmgmthttps" {
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "${var.prefix}-FGT-B-HTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 40031
  backend_port                   = 443
  frontend_ip_configuration_name = "${var.prefix}-ELB-PIP"
}

resource "azurerm_lb_nat_rule" "fgtamgmtssh" {
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "${var.prefix}-FGT-A-SSH"
  protocol                       = "Tcp"
  frontend_port                  = 50030
  backend_port                   = 22
  frontend_ip_configuration_name = "${var.prefix}-ELB-PIP"
}

resource "azurerm_lb_nat_rule" "fgtbmgmtssh" {
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  loadbalancer_id                = azurerm_lb.elb.id
  name                           = "${var.prefix}-FGT-B-SSH"
  protocol                       = "Tcp"
  frontend_port                  = 50031
  backend_port                   = 22
  frontend_ip_configuration_name = "${var.prefix}-ELB-PIP"
}

resource "azurerm_lb" "ilb" {
  name                = "${var.prefix}-InternalLoadBalancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "${var.prefix}-ILB-PIP"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "ilbbackend" {
  loadbalancer_id = azurerm_lb.ilb.id
  name            = "BackEndPool"
}

resource "azurerm_lb_probe" "ilbprobe" {
  loadbalancer_id     = azurerm_lb.ilb.id
  name                = "lbprobe"
  port                = 8008
  interval_in_seconds = 5
  number_of_probes    = 2
  protocol            = "Tcp"
}

resource "azurerm_lb_rule" "lb_haports_rule" {
  loadbalancer_id                = azurerm_lb.ilb.id
  name                           = "lb_haports_rule"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "${var.prefix}-ILB-PIP"
  probe_id                       = azurerm_lb_probe.ilbprobe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ilbbackend.id]
}

resource "azurerm_network_interface" "fgtifc1" {
  count                          = var.FGT_COUNT
  name                           = "${var.prefix}-fgt-${count.index}-nic1"
  location                       = azurerm_resource_group.resourcegroup.location
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = var.FGT_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    #    private_ip_address_allocation = "Static"
    #    private_ip_address            = var.fgt_ipaddress_a["1"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtifc1" {
  count                     = var.FGT_COUNT
  network_interface_id      = element(azurerm_network_interface.fgtifc1.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "fgtifc1elbbackendpool" {
  count                   = var.FGT_COUNT
  network_interface_id    = element(azurerm_network_interface.fgtifc1.*.id, count.index)
  ip_configuration_name   = "interface1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.elbbackend.id
}

resource "azurerm_network_interface" "fgtifc2" {
  count                 = var.FGT_COUNT
  name                  = "${var.prefix}-fgt-${count.index}-nic2"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
    #    private_ip_address_allocation = "Static"
    #    private_ip_address            = var.fgt_ipaddress_a["2"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtifc2" {
  count                     = var.FGT_COUNT
  network_interface_id      = element(azurerm_network_interface.fgtifc2.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "fgtifc2elbbackendpool" {
  count                   = var.FGT_COUNT
  network_interface_id    = element(azurerm_network_interface.fgtifc2.*.id, count.index)
  ip_configuration_name   = "interface1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.elbbackend.id
}

resource "azurerm_linux_virtual_machine" "fgtvm" {
  count                 = var.FGT_COUNT
  name                  = "${var.prefix}-fgt-${count.index}"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = ["${element(azurerm_network_interface.fgtifc1.*.id, count.index)}", "${element(azurerm_network_interface.fgtifc2.*.id, count.index)}"]
  size                  = var.fgt_vmsize
  availability_set_id   = azurerm_availability_set.fgtavset.id

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
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

  os_disk {
    name                 = "${var.prefix}-fgt-${count.index}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata.tpl", {
    fgt_vm_name           = "${var.prefix}-fgt-${count.index}"
    fgt_license_file      = "${var.FGT_BYOL_LICENSE_FILE[tostring(count.index)]}"
    fgt_license_fortiflex = "${var.FGT_BYOL_FORTIFLEX_LICENSE_TOKEN[tostring(count.index)]}"
    fgt_username          = var.username
    fgt_ssh_public_key    = var.FGT_SSH_PUBLIC_KEY_FILE
    fgt_external_ipaddr   = element(azurerm_network_interface.fgtifc1, count.index)
    fgt_external_mask     = cidrnetmask(var.subnet["0"])
    fgt_external_gw       = cidrhost(var.subnet["0"], 1)
    fgt_internal_ipaddr   = element(azurerm_network_interface.fgtifc2, count.index)
    fgt_internal_mask     = cidrnetmask(var.subnet["1"])
    fgt_internal_gw       = cidrhost(var.subnet["0"], 1)
    fgt_ha_peerip         = azurerm_network_interface.fgtifc2
    fgt_protected_net     = var.subnet["3"]
    vnet_network          = var.vnet
  }))

  boot_diagnostics {
  }

  tags = var.fortinet_tags
}

resource "azurerm_managed_disk" "fgtvm-datadisk" {
  count                = var.FGT_COUNT
  name                 = "${var.prefix}-fgt-${count.index}-datadisk"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50
}

resource "azurerm_virtual_machine_data_disk_attachment" "fgtvm-datadisk-attach" {
  count              = var.FGT_COUNT
  managed_disk_id    = element(azurerm_managed_disk.fgtvm-datadisk.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.fgtvm.*.id, count.index)
  lun                = 0
  caching            = "ReadWrite"
}

data "azurerm_public_ip" "elbpip" {
  name                = azurerm_public_ip.elbpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  depends_on          = [azurerm_lb.elb]
}

output "elb_public_ip_address" {
  value = data.azurerm_public_ip.elbpip.ip_address
}

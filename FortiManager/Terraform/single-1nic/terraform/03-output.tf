##############################################################################################################
#
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Output summary of deployment
#
##############################################################################################################

data "template_file" "summary" {
  template = file("${path.module}/summary.tpl")

  vars = {
    location               = var.LOCATION
    fmg_username           = var.USERNAME
    fmg_public_ip_address  = data.azurerm_public_ip.fmgpip.ip_address
    fmg_private_ip_address = azurerm_network_interface.fmgifc.private_ip_address
  }
}

output "deployment_summary" {
  value = data.template_file.summary.rendered
}
output "VNET ID" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet1 id" {
  value = azurerm_subnet.subnet1.id
}

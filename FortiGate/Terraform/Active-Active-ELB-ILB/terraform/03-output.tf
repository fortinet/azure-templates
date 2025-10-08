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

output "deployment_summary" {
  value = templatefile("${path.module}/summary.tpl", {
    username                     = var.username
    location                     = var.location
    elb_ipaddress                = data.azurerm_public_ip.elbpip.ip_address
    fgt_a_private_ip_address_ext = azurerm_network_interface.fgtifc.private_ip_address
    fgt_a_private_ip_address_int = azurerm_network_interface.fgtaifcint.private_ip_address
    fgt_b_private_ip_address_ext = azurerm_network_interface.fgtbifcext.private_ip_address
    fgt_b_private_ip_address_int = azurerm_network_interface.fgtbifcint.private_ip_address
  })
}


##############################################################################################################
#
# FortiGate a standalone FortiGate VM
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
#
# Output summary of deployment
#
##############################################################################################################

output "deployment_summary" {
  value = templatefile("${path.module}/summary.tpl", {
    username                   = var.username
    location                   = var.location
    fgt_ipaddress              = data.azurerm_public_ip.fgtpip.ip_address
    fgt_private_ip_address_ext = azurerm_network_interface.fgtifcext.private_ip_address
    fgt_private_ip_address_int = azurerm_network_interface.fgtifcint.private_ip_address
  })
}

##############################################################################################################
#
# FortiAnalyzer VM
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
    faz_username           = var.USERNAME
    faz_public_ip_address  = data.azurerm_public_ip.fazpip.ip_address
    faz_private_ip_address = azurerm_network_interface.fazifc.private_ip_address
  }
}

output "deployment_summary" {
  value = data.template_file.summary.rendered
}

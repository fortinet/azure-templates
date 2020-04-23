##############################################################################################################
#
# Cloud Security Services Hub
# using VNET peering and FortiGate Active/Passive High Availability with Azure Standard Load Balancer - External and Internal
# Fortinet FortiGate Terraform deployment template
#
# Configuration management example usig the FortiGate Terraform provider
#
##############################################################################################################

provider "fortios" {
    hostname = "ipaddress:port"
    token = "password"
}

resource "fortios_firewall_object_address" "s1" {
    name = "s1"
    type = "iprange"
    start_ip = "1.0.0.0"
    end_ip = "2.0.0.0"
    comment = "dd"
}

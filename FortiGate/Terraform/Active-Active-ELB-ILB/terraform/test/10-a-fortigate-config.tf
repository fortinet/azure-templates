##############################################################################################################
#
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Microsoft Azure
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

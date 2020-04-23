##############################################################################################################
#
# Cloud Security Services Hub
# using VNET peering and FortiGate Active/Passive High Availability with Azure Standard Load Balancer - External and Internal
# Fortinet FortiGate Terraform deployment template
#
# Deployment location: ${location}
#
##############################################################################################################

elb_ipaddress = ${elb_ipaddress}
fgt_a_private_ip_address_ext = ${fgt_a_private_ip_address_ext}
fgt_a_private_ip_address_int = ${fgt_a_private_ip_address_int}
fgt_a_private_ip_address_hasync = ${fgt_a_private_ip_address_hasync}
fgt_a_private_ip_address_mgmt = ${fgt_a_private_ip_address_mgmt}
fgt_a_public_ip_address = ${fgt_a_public_ip_address}
fgt_b_private_ip_address_ext = ${fgt_a_private_ip_address_ext}
fgt_b_private_ip_address_int = ${fgt_a_private_ip_address_int}
fgt_b_private_ip_address_hasync = ${fgt_a_private_ip_address_hasync}
fgt_b_private_ip_address_mgmt = ${fgt_a_private_ip_address_mgmt}
fgt_b_public_ip_address = ${fgt_b_public_ip_address}
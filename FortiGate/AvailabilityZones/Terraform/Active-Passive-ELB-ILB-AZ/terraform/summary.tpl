##############################################################################################################
#
# Active/Passive High Available FortiGate pair with external and internal Azure Standard Load Balancer
# Terraform deployment template for Microsoft Azure with Availability Zones
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
fgt_b_private_ip_address_ext = ${fgt_b_private_ip_address_ext}
fgt_b_private_ip_address_int = ${fgt_b_private_ip_address_int}
fgt_b_private_ip_address_hasync = ${fgt_b_private_ip_address_hasync}
fgt_b_private_ip_address_mgmt = ${fgt_b_private_ip_address_mgmt}
fgt_b_public_ip_address = ${fgt_b_public_ip_address}
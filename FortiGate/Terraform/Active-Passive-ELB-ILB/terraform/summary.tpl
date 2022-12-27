##############################################################################################################
#
# FortiGate Active/Passive High Availability with Azure Standard Load Balancer - External and Internal
# Terraform deployment template for Microsoft Azure
#
# The FortiGate VMs are reachable on their HA management public IP on port HTTPS/443 and SSH/22.
#
# BEWARE: The state files contain sensitive data like passwords and others. After the demo clean up your
#         clouddrive directory.
#
# Deployment location: ${location}
# Username: ${username}
#
# Management FortiGate A: https://${fgt_a_public_ip_address}/
# Management FortiGate B: https://${fgt_b_public_ip_address}/
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

##############################################################################################################
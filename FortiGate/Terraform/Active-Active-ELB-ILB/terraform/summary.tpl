##############################################################################################################
#
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Microsoft Azure
#
# Deployment location: ${location}
#
##############################################################################################################

elb_ipaddress = ${elb_ipaddress}
fgt_a_private_ip_address_ext = ${fgt_a_private_ip_address_ext}
fgt_a_private_ip_address_int = ${fgt_a_private_ip_address_int}
fgt_b_private_ip_address_ext = ${fgt_b_private_ip_address_ext}
fgt_b_private_ip_address_int = ${fgt_b_private_ip_address_int}

Management of the both active FortiGate VMs is available via the external load balancer IP address.
Port 40030 and 40031 for HTTPS console and port 50030 and 50031 for SSH.

##############################################################################################################
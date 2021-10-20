##############################################################################################################
#
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Microsoft Azure
#
# The FortiGate VMs are reachable via the public IP address of the load balancer.
# Management GUI HTTPS on port 40030, 40031 and for SSH on port 50030 and 50031.
#
# BEWARE: The state files contain sensitive data like passwords and others. After the demo clean up your
#         clouddrive directory.
#
# Deployment location: ${location}
# Username: ${username}
#
# Management FortiGate A: https://${elb_ipaddress}:40030/
# Management FortiGate B: https://${elb_ipaddress}:40031/
#
##############################################################################################################

elb_ipaddress = ${elb_ipaddress}
fgt_a_private_ip_address_ext = ${fgt_a_private_ip_address_ext}
fgt_a_private_ip_address_int = ${fgt_a_private_ip_address_int}
fgt_b_private_ip_address_ext = ${fgt_b_private_ip_address_ext}
fgt_b_private_ip_address_int = ${fgt_b_private_ip_address_int}

##############################################################################################################
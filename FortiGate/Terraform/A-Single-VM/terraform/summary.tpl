##############################################################################################################
#
# FortiGate a standalone FortiGate VM
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
# Management FortiGate: https://${fgt_ipaddress}/
#
##############################################################################################################

fgt_ipaddress = ${fgt_ipaddress}
fgt_private_ip_address_ext = ${fgt_private_ip_address_ext}
fgt_private_ip_address_int = ${fgt_private_ip_address_int}

##############################################################################################################
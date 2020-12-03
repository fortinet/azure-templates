##############################################################################################################
#
# FortiManager VM
# Terraform deployment template for Microsoft Azure
#
# The FortiManager VM is reachable via the public or private IP address
# Management GUI HTTPS on port 443 and for SSH on port 22
#
# BEWARE: The state files contain sensitive data like passwords and others. After the demo clean up your
#         clouddrive directory
#
# Deployment location: ${location}
#
##############################################################################################################

username = ${fmg_username}
fmg_public_ip_address = ${fmg_public_ip_address}
fmg_private_ip_address = ${fmg_private_ip_address}

##############################################################################################################

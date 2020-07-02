#!/bin/bash
echo "
##############################################################################################################
#
# FortiGate Azure deployment using ARM Template
# Fortigate Active/Passive cluster with External + Internal Load Balancer
#
##############################################################################################################

"

# Stop on error
set +e

if [ -z "$DEPLOY_LOCATION" ]
then
    # Input location
    echo -n "Enter location (e.g. eastus2): "
    stty_orig=`stty -g` # save original terminal setting.
    read location         # read the location
    stty $stty_orig     # restore terminal setting.
    if [ -z "$location" ]
    then
        location="eastus2"
    fi
else
    location="$DEPLOY_LOCATION"
fi
echo ""
echo "--> Deployment in '$location' location ..."
echo ""

if [ -z "$DEPLOY_PREFIX" ]
then
    # Input prefix
    echo -n "Enter prefix: "
    stty_orig=`stty -g` # save original terminal setting.
    read prefix         # read the prefix
    stty $stty_orig     # restore terminal setting.
    if [ -z "$prefix" ]
    then
        prefix="FORTI"
    fi
else
    prefix="$DEPLOY_PREFIX"
fi
echo ""
echo "--> Using prefix '$prefix' for all resources ..."
echo ""
rg="$prefix-RG"

if [ -z "$DEPLOY_USERNAME" ]
then
    # Input username
    echo -n "Enter username: "
    stty_orig=`stty -g` # save original terminal setting.
    read USERNAME         # read the prefix
    stty $stty_orig     # restore terminal setting.
    if [ -z "$USERNAME" ]
    then
        USERNAME="azureuser"
    fi
else
    USERNAME="$DEPLOY_USERNAME"
fi
echo ""
echo "--> Using username '$USERNAME' ..."
echo ""

if [ -z "$DEPLOY_PASSWORD" ]
then
    # Input password
    echo -n "Enter password: "
    stty_orig=`stty -g` # save original terminal setting.
    stty -echo          # turn-off echoing.
    read PASSWORD         # read the password
    stty $stty_orig     # restore terminal setting.
else
    PASSWORD="$DEPLOY_PASSWORD"
    echo ""
    echo "--> Using password found in env variable DEPLOY_PASSWORD ..."
    echo ""
fi

# Create resource group
echo ""
echo "--> Creating $rg resource group ..."
az group create --location "$location" --name "$rg"

# Validate template
echo "--> Validation deployment in $rg resource group ..."
az deployment group validate --resource-group "$rg" \
                           --template-file azuredeploy.json \
                           --parameters adminUsername="$USERNAME" adminPassword=$PASSWORD fortigateNamePrefix=$prefix
result=$?
if [ $result != 0 ];
then
    echo "--> Validation failed ..."
    exit $rc;
fi

# Deploy resources
echo "--> Deployment of $rg resources ..."
az deployment group create --resource-group "$rg" \
                           --template-file azuredeploy.json \
                           --parameters adminUsername="$USERNAME" adminPassword=$PASSWORD fortigateNamePrefix=$prefix
result=$?
if [[ $result != 0 ]];
then
    echo "--> Deployment failed ..."
    exit $rc;
else
echo "
##############################################################################################################
#
# FortiGate Azure deployment using ARM Template
# Fortigate Active/Passive cluster with External + Internal Load Balancer
#
# The FortiGate systems is reachable via the management public IP addresses of the firewall
# on HTTPS/443 and SSH/22.
#
##############################################################################################################

Deployment information:

Username: $USERNAME

FortiGate IP addesses
"
query="[?virtualMachine.name.starts_with(@, '$prefix')].{virtualMachine:virtualMachine.name, publicIP:virtualMachine.network.publicIpAddresses[0].ipAddress,privateIP:virtualMachine.network.privateIpAddresses[0]}"
az vm list-ip-addresses --query "$query" --output tsv
echo "

##############################################################################################################
"
fi

exit 0

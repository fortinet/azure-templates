#!/bin/bash
echo "
##############################################################################################################
#
# Deployment of a different Azure Virtual WAN Scenario's
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

if [ -z "$DEPLOY_VPNSITEPREFIX" ]
then
    # Input prefix
    echo -n "Enter on-premise prefix: "
    stty_orig=`stty -g`                 # save original terminal setting.
    read vpnsiteprefix         # read the public ip
    stty $stty_orig                     # restore terminal setting.
    if [ -z "$vpnprefix" ]
    then
        vpnsiteprefix="ONPREM"
    fi
else
    vpnsiteprefix="$DEPLOY_VPNSITEPREFIX"
fi
echo ""
echo "--> Using on-premise prefix '$vpnsiteprefix' ..."
echo ""

if [ -z "$DEPLOY_VPNSITEPUBLICIPADDRESS" ]
then
    # Input prefix
    echo -n "Enter on-premise public ip for VPN tunnel: "
    stty_orig=`stty -g`                 # save original terminal setting.
    read vpnsitepublicipaddress         # read the public ip
    stty $stty_orig                     # restore terminal setting.
    if [ -z "$vpnsitepublicipaddress" ]
    then
        vpnsitepublicipaddress=""
    fi
else
    vpnsitepublicipaddress="$DEPLOY_VPNSITEPUBLICIPADDRESS"
fi
echo ""
echo "--> Using on-premise public ip '$vpnsitepublicipaddress' for all resources ..."
echo ""

if [ -z "$DEPLOY_PASSWORD" ]
then
    # Input password
    echo -n "Enter password: "
    stty_orig=`stty -g` # save original terminal setting.
    stty -echo          # turn-off echoing.
    read passwd         # read the password
    stty $stty_orig     # restore terminal setting.
else
    passwd="$DEPLOY_PASSWORD"
    echo ""
    echo "--> Using password found in env variable DEPLOY_PASSWORD ..."
    echo ""
fi

if [ -z "$DEPLOY_USERNAME" ]
then
    username="azureuser"
else
    username="$DEPLOY_USERNAME"
fi
echo ""
echo "--> Using username '$username' ..."
echo ""

# Create resource group
echo ""
echo "--> Creating $rg resource group ..."
az group create --location "$location" --name "$rg"

# Validate template
echo "--> Validation deployment in $rg resource group ..."
az deployment group validate --resource-group "$rg" \
                           --template-file scenario2.json \
                           --parameters adminUsername="$username" adminPassword=$passwd prefix=$prefix vpnsitePrefix=$vpnsiteprefix vpnsitePublicIPAddress=$vpnsitepublicipaddress
result=$?
if [ $result != 0 ];
then
    echo "--> Validation failed ..."
    exit $result;
fi

# Deploy resources
echo "--> Deployment of $rg resources ..."
az deployment group create --resource-group "$rg" \
                           --template-file scenario2.json \
                           --parameters adminUsername="$username" adminPassword=$passwd prefix=$prefix vpnsitePrefix=$vpnsiteprefix vpnsitePublicIPAddress=$vpnsitepublicipaddress
result=$?
if [[ $result != 0 ]];
then
    echo "--> Deployment failed ..."
    exit $result;
else

# Display connection information
az extension show --name virtual-wan
result=$?
if [[ $result != 0 ]];
then
    echo "--> Installing Azure CLI extension for Virtual WAN ..."
    az extension install --name virtual-wan
    result=$?
    if [[ $result != 0 ]];
    then
        echo "--> Unable to add Azure CLI extension for Virtual WAN ..."
        exit $result;
    fi
fi
if [[ $result == 0 ]];
then
    az network vhub connection create --name "$prefix-VNET" --remote-vnet "$prefix-VNET" --resource-group $rg --vhub-name "$prefix-VHUB-$location"
    az network vhub connection create --name "$prefix-VNET-SPOKE1" --remote-vnet "$prefix-VNET-SPOKE1" --resource-group $rg --vhub-name "$prefix-VHUB-$location"
    az network vhub connection create --name "$prefix-VNET-SPOKE2" --remote-vnet "$prefix-VNET-SPOKE2" --resource-group $rg --vhub-name "$prefix-VHUB-$location"
fi

echo "
##############################################################################################################
#
# Deployment of Microsoft Azure Virtual WAN can time some time (> 30min). Verify in the Azure Portal the
# status of the deployment and retrieve the VPN configuration to finish the configuration on the FortiGate
# branch side.
#
##############################################################################################################
"
exit 0
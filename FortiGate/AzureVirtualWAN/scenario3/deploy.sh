#!/bin/bash
echo "
##############################################################################################################
#
# FortiGate and Microsoft Azure Virtual WAN
# Scenario 3
#
##############################################################################################################

"

# Stop on error
set +e

if [ -z "$DEPLOY_LOCATION" ]
then
    # Input location
    echo -n "Region A: Enter location (e.g. eastus2): "
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
echo "--> Region A: Deployment in '$location' location ..."
echo ""

if [ -z "$DEPLOY_LOCATION2" ]
then
    # Input location
    echo -n "Region B: Enter location (e.g. westeurope): "
    stty_orig=`stty -g` # save original terminal setting.
    read location2         # read the location
    stty $stty_orig     # restore terminal setting.
    if [ -z "$location2" ]
    then
        location2="westeurope"
    fi
else
    location2="$DEPLOY_LOCATION2"
fi
echo ""
echo "--> Region B: Deployment in '$location2' location ..."
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

if [ -z "$DEPLOY_VPNSITE1PREFIX" ]
then
    # Input prefix
    echo -n "Region A: Enter on-premise prefix: "
    stty_orig=`stty -g`                 # save original terminal setting.
    read vpnsite1prefix         # read the public ip
    stty $stty_orig                     # restore terminal setting.
    if [ -z "$vpnsite1prefix" ]
    then
        vpnsite1prefix="ONPREM"
    fi
else
    vpnsite1prefix="$DEPLOY_VPNSITE1PREFIX"
fi
echo ""
echo "--> Region A: Using on-premise prefix '$vpnsite1prefix' ..."
echo ""

if [ -z "$DEPLOY_VPNSITE1PUBLICIPADDRESS" ]
then
    # Input prefix
    echo -n "Region A: Enter on-premise public ip for VPN tunnel: "
    stty_orig=`stty -g`                 # save original terminal setting.
    read vpnsite1publicipaddress         # read the public ip
    stty $stty_orig                     # restore terminal setting.
    if [ -z "$vpnsite1publicipaddress" ]
    then
        vpnsite1publicipaddress=""
    fi
else
    vpnsite1publicipaddress="$DEPLOY_VPNSITE1PUBLICIPADDRESS"
fi
echo ""
echo "--> Region A: Using on-premise public ip '$vpnsite1publicipaddress' ..."
echo ""

if [ -z "$DEPLOY_VPNSITE2PREFIX" ]
then
    # Input prefix
    echo -n "Region B: Enter on-premise prefix: "
    stty_orig=`stty -g`                 # save original terminal setting.
    read vpnsite2prefix         # read the public ip
    stty $stty_orig                     # restore terminal setting.
    if [ -z "$vpnsite2prefix" ]
    then
        vpnsite2prefix="ONPREM2"
    fi
else
    vpnsite2prefix="$DEPLOY_VPNSITE2PREFIX"
fi
echo ""
echo "--> Region B: Using on-premise prefix '$vpnsite2prefix' ..."
echo ""

if [ -z "$DEPLOY_VPNSITE2PUBLICIPADDRESS" ]
then
    # Input prefix
    echo -n "Region B: Enter on-premise public ip for VPN tunnel: "
    stty_orig=`stty -g`                 # save original terminal setting.
    read vpnsite2publicipaddress         # read the public ip
    stty $stty_orig                     # restore terminal setting.
    if [ -z "$vpnsite2publicipaddress" ]
    then
        vpnsite2publicipaddress=""
    fi
else
    vpnsite2publicipaddress="$DEPLOY_VPNSITE2PUBLICIPADDRESS"
fi
echo ""
echo "--> Region B: Using on-premise public ip '$vpnsite2publicipaddress' ..."
echo ""

# Create resource group
echo ""
echo "--> Creating $rg resource group ..."
az group create --location "$location" --name "$rg"

# Validate template
echo "--> Validation deployment in $rg resource group ..."
az deployment group validate --resource-group "$rg" \
                           --template-file scenario3.json \
                           --parameters prefix=$prefix vpnsite1Prefix=$vpnsite1prefix vpnsite1PublicIPAddress=$vpnsite1publicipaddress \
                                        vpnsite2Prefix=$vpnsite2prefix vpnsite2PublicIPAddress=$vpnsite2publicipaddress hub2Location=$location2
result=$?
if [ $result != 0 ];
then
    echo "--> Validation failed ..."
    exit $result;
fi

# Deploy resources
echo "--> Deployment of $rg resources ..."
az deployment group create --resource-group "$rg" \
                           --template-file scenario3.json \
                           --parameters prefix=$prefix vpnsite1Prefix=$vpnsite1prefix vpnsite1PublicIPAddress=$vpnsite1publicipaddress \
                                        vpnsite2Prefix=$vpnsite2prefix vpnsite2PublicIPAddress=$vpnsite2publicipaddress hub2Location=$location2
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
az network vhub connection create --name "$prefix-VNET" --remote-vnet "$prefix-VNET" --remote-group $rg --vhub-name "$prefix-VHUB-$location"
az network vhub connection create --name "$prefix-VNET-SPOKE1" --remote-vnet "$prefix-VNET-SPOKE1" --remote-group $rg --vhub-name "$prefix-VHUB-$location"
az network vhub connection create --name "$prefix-VNET-SPOKE2" --remote-vnet "$prefix-VNET-SPOKE2" --remote-group $rg --vhub-name "$prefix-VHUB-$location"

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
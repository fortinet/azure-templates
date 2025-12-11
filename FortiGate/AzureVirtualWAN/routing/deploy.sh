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
#vwancheck=`az extension list-available --output table --query "[].{installed:installed, name:name}" | grep virtual-wan`
#if [[ $vwancheck == "False"* ]]
#then
#    echo "Azure CLI: Add Azure Virtual WAN extension"
#    az extension add --name virtual-wan
#elif [[ $vwancheck == *"upgrade available"* ]]
#then
#    echo "Azure CLI: Upgrade Azure Virtual WAN extension"
#    az extension update --name virtual-wan
#fi

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
    echo -n "Enter username (default: azureuser): "
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
echo "--> Using USERNAME '$USERNAME' ..."
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

#if [ -z "$DEPLOY_VPNSITEPREFIX" ]
#then
#    # Input prefix
#    echo -n "Enter on-premise prefix: "
#    stty_orig=`stty -g`                 # save original terminal setting.
#    read vpnsiteprefix         # read the public ip
#    stty $stty_orig                     # restore terminal setting.
#    if [ -z "$vpnprefix" ]
#    then
#        vpnsiteprefix="ONPREM"
#    fi
#else
#    vpnsiteprefix="$DEPLOY_VPNSITEPREFIX"
#fi
#echo ""
#echo "--> Using on-premise prefix '$VPNSITEPREFIX' ..."
#echo ""

#if [ -z "$DEPLOY_VPNSITEPUBLICIPADDRESS" ]
#then
#    # Input prefix
#    echo -n "Enter on-premise public ip for VPN tunnel: "
#    stty_orig=`stty -g`                 # save original terminal setting.
#    read vpnsitepublicipaddress         # read the public ip
#    stty $stty_orig                     # restore terminal setting.
#    if [ -z "$vpnsitepublicipaddress" ]
#    then
#        vpnsitepublicipaddress=""
#    fi
#else
#    vpnsitepublicipaddress="$DEPLOY_VPNSITEPUBLICIPADDRESS"
#fi
#echo ""
#echo "--> Using on-premise public ip '$vpnsitepublicipaddress' for all resources ..."
#echo ""

vwanName="$prefix-VWAN"
vhubName="$prefix-HUB-$location"
vhubAddressPrefix="172.16.160.0/24"
vnetSpoke1Name="$prefix-$location-VNET-Spoke1"
vnetSpoke1Prefix="172.16.161.0/24"
subnetSpoke1Name="Subnet1"
subnetSpoke1Prefix="172.16.161.0/28"
vnetSpoke2Name="$prefix-$location-VNET-Spoke2"
vnetSpoke2Prefix="172.16.162.0/24"
vnetSpokeFGTName="$prefix-VNET"
subnetSpoke2Name="Subnet1"
subnetSpoke2Prefix="172.16.162.0/28"
vhubRouteTable1Name="RT_Shared"
vhubRouteTable2Name="RT_V2B"

# Create resource group
echo ""
echo "--> Creating $rg resource group ..."
if [ $(az group exists --name $rg) = false ]; then
    az group create --location "$location" --name "$rg"
fi

# Create Virtual Network Spoke1
echo ""
echo "--> Creating virtual network $vnetSpoke1Name [$vnetSpoke1Prefix]..."
az network vnet show --name "$vnetSpoke1Name" --resource-group "$rg"
if [ $? != 0 ];
then
    az network vnet create \
        --resource-group "$rg" \
        --name "$vnetSpoke1Name" \
        --address-prefix "$vnetSpoke1Prefix" \
        --subnet-name "$subnetSpoke1Name" \
        --subnet-prefix "$subnetSpoke1Prefix"
fi

# Create Virtual Network Spoke2
echo ""
echo "--> Creating virtual network $vnetSpoke2Name [$vnetSpoke2Prefix]..."
az network vnet show --name "$vnetSpoke2Name" --resource-group "$rg"
if [ $? != 0 ];
then
    az network vnet create \
        --resource-group "$rg" \
        --name "$vnetSpoke2Name" \
        --address-prefix "$vnetSpoke2Prefix" \
        --subnet-name "$subnetSpoke2Name" \
        --subnet-prefix "$subnetSpoke2Prefix"
fi

# Deploy FortiGate next-generation firewall
echo "--> Deployment of FortiGate NGFW ..."
az deployment group create --resource-group "$rg" \
                           --template-uri "https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/A-Single-VM/azuredeploy.json" \
                           --parameters adminUsername="$USERNAME" adminPassword="$PASSWORD" fortiGateNamePrefix="$prefix"
result=$?
if [[ $result != 0 ]];
then
    echo "--> Deployment failed ..."
    exit $result;
fi

# Create Virtual WAN
echo ""
echo "--> Creating Azure Virtual WAN $vwanName ..."
az network vwan show --name "$vwanName" --resource-group "$rg"
if [ $? != 0 ];
then
    az network vwan create --name "$vwanName" --resource-group "$rg"
fi

# Create Virtual HUB
echo ""
echo "--> Creating Azure Virtual HUB $vhubName ..."
az network vhub show --name "$vhubName" --resource-group "$rg"
if [ $? != 0 ];
then
    az network vhub create \
        --name "$vhubName" \
        --resource-group "$rg" \
        --address-prefix "$vhubAddressPrefix" \
        --location "$location" \
        --vwan "$vwanName" \
        --sku "Standard"
fi
vhubRouteTableDefaultId=$(az network vhub route-table show --name defaultRouteTable --resource-group $rg --vhub-name $vhubName --query "id")

# Create Virtual HUB Route Table RT_Shared
echo ""
echo "--> Creating Azure Virtual HUB route table $vhubRouteTable1Name ..."
az network vhub route-table show --name "$vhubRouteTable1Name" --resource-group "$rg" --vhub-name "$vhubName"
if [ $? != 0 ];
then
    az network vhub route-table create \
        --name "$vhubRouteTable1Name" \
        --resource-group "$rg" \
        --vhub-name "$vhubName"
fi
vhubRouteTable1Id=$(az network vhub route-table show --name $vhubRouteTable1Name --resource-group $rg --vhub-name $vhubName --output tsv --query "id")

# Create Virtual HUB Route Table RT_V2B
echo ""
echo "--> Creating Azure Virtual HUB route table $vhubRouteTable2Name ..."
az network vhub route-table show --name "$vhubRouteTable2Name" --resource-group "$rg" --vhub-name "$vhubName"
if [ $? != 0 ];
then
    az network vhub route-table create \
        --name "$vhubRouteTable2Name" \
        --resource-group "$rg" \
        --vhub-name "$vhubName"
fi
vhubRouteTable2Id=$(az network vhub route-table show --name $vhubRouteTable2Name --resource-group $rg --vhub-name $vhubName --output tsv --query "id")

# Create Virtual HUB peering to spoke1
echo ""
echo "--> Creating Azure Virtual HUB peering to $vnetSpoke1Name ..."
az network vhub connection show --name "$vhubNameTo$vnetSpoke1Name" --resource-group "$rg" --vhub-name "$vhubName"
if [ $? != 0 ];
then
    az network vhub connection create \
        --name "$vhubNameTo$vnetSpoke1Name" \
        --resource-group "$rg" \
        --vhub-name "$vhubName" \
        --associated-route-table "$vhubRouteTable2Id" \
        --propagated-route-tables "$vhubRouteTable1Id" "$vhubRouteTable2Id" \
        --remote-vnet "$vnetSpoke1Name"
fi

# Create Virtual HUB peering to spoke2
echo ""
echo "--> Creating Azure Virtual HUB peering to $vnetSpoke2Name ..."
az network vhub connection show --name "$vhubNameTo$vnetSpoke2Name" --resource-group "$rg" --vhub-name "$vhubName"
if [ $? != 0 ];
then
    az network vhub connection create \
        --name "$vhubNameTo$vnetSpoke2Name" \
        --resource-group "$rg" \
        --vhub-name "$vhubName" \
        --associated-route-table "$vhubRouteTable2Id" \
        --propagated-route-tables "$vhubRouteTable1Id" "$vhubRouteTable2Id" \
        --remote-vnet "$vnetSpoke2Name"
fi

# Create Virtual HUB peering to FGT
echo ""
echo "--> Creating Azure Virtual HUB peering to $vnetSpokeFGTName ..."
az network vhub connection show --name "$vhubNameTo$vnetSpokeFGTName" --resource-group "$rg" --vhub-name "$vhubName"
if [ $? != 0 ];
then
    az network vhub connection create \
        --name "$vhubNameTo$vnetSpokeFGTName" \
        --resource-group "$rg" \
        --vhub-name "$vhubName" \
        --associated-route-table "$vhubRouteTable1Id" \
        --propagated-route-tables "$vhubRouteTable1Id" \
        --remote-vnet "$vnetSpokeFGTName"
fi

echo "
##############################################################################################################
#
#
##############################################################################################################
"

exit 0

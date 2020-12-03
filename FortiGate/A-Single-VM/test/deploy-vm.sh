#!/bin/bash
echo "
##############################################################################################################
#
##############################################################################################################

"

if [ -z "$DEPLOY_LOCATION" ]
then
    # Input location
    echo -n "Enter location (e.g. eastus2): "
    stty_orig=`stty -g` # save original terminal setting.
    read location         # read the location
    stty $stty_orig     # restore terminal setting.
    if [ -z "$location" ]
    then
        location="westeurope"
    fi
else
    location="$DEPLOY_LOCATION"
fi
echo ""
echo "--> Deployment in $location location ..."
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
        prefix="CUDA"
    fi
else
    prefix="$DEPLOY_PREFIX"
fi
echo ""
echo "--> Using prefix $prefix for all resources ..."
echo ""
rg="$prefix-RG"

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

for TIER in ProtectedA ProtectedB
do
    echo "--> Deployment $TIER NIC ..."
    az vm nic show --resource-group "$rg" --nic "$prefix-VM-$TIER-NIC" --vm-name "$prefix-VM-$TIER"  &> /dev/null
    if [[ $? != 0 ]];
    then
        vnet="$prefix-VNET"
        az network nic create --resource-group "$rg" --name "$prefix-VM-$TIER-NIC" --vnet-name "$vnet" --subnet "${TIER}Subnet"
        result=$?
        if [[ $result != 0 ]];
        then
            echo "--> Deployment $TIER NIC failed ..."
            exit $rc;
        fi
    else
            echo "--> Deployment $TIER NIC found ..."
    fi

    echo "--> Deployment $TIER VM ..."
    az vm show -g "$rg" -n "$prefix-VM-$TIER" &> /dev/null
    if [[ $? != 0 ]];
    then
        az vm create --resource-group "$rg" --name "$prefix-VM-$TIER" --nics "$prefix-VM-$TIER-NIC" --image UbuntuLTS \
            --admin-username azureuser --admin-password "$passwd" --output json
        result=$?
        if [[ $result != 0 ]];
        then
            echo "--> Deployment $TIER VM failed ..."
            exit $rc;
        fi
    else
            echo "--> Deployment $TIER VM found ..."
    fi
done

echo "
##############################################################################################################
#
##############################################################################################################
 IP Assignment:
"
query="[?virtualMachine.name.starts_with(@, '$prefix')].{virtualMachine:virtualMachine.name, publicIP:virtualMachine.network.publicIpAddresses[0].ipAddress,privateIP:virtualMachine.network.privateIpAddresses[0]}"
az vm list-ip-addresses --query "$query" --output tsv
echo "
##############################################################################################################
"
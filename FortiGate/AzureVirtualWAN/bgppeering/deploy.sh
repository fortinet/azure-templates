#!/bin/bash
echo "
##############################################################################################################
#
# Azure Virtual WAN and FortiGate eBGP peering
#
##############################################################################################################

"

if [ -z "$DEPLOY_LOCATION_A" ]; then
    # Input location
    echo -n "Enter Hub A location (e.g. westeurope): "
    stty_orig=$(stty -g) # save original terminal setting.
    read location        # read the location
    stty $stty_orig      # restore terminal setting.
    if [ -z "$location" ]; then
        location="westeurope"
    fi
else
    location="$DEPLOY_LOCATION_A"
fi
echo ""
echo "--> Deployment Hub A in '$location' location ..."

if [ -z "$DEPLOY_LOCATION_B" ]; then
    # Input location
    echo -n "Enter Hub B location (e.g. eastus2): "
    stty_orig=$(stty -g) # save original terminal setting.
    read locationB       # read the location
    stty $stty_orig      # restore terminal setting.
    if [ -z "$location" ]; then
        locationB="eastus2"
    fi
else
    locationB="$DEPLOY_LOCATION_B"
fi
echo ""
echo "--> Deployment Hub B in '$locationB' location ..."

if [ -z "$DEPLOY_PREFIX" ]; then
    # Input prefix
    echo -n "Enter prefix: "
    stty_orig=$(stty -g) # save original terminal setting.
    read prefix          # read the prefix
    stty $stty_orig      # restore terminal setting.
    if [ -z "$prefix" ]; then
        prefix="FORTI"
    fi
else
    prefix="$DEPLOY_PREFIX"
fi
echo ""
echo "--> Using prefix '$prefix' for all resources ..."

if [ -z "$DEPLOY_USERNAME" ]; then
    # Input username
    echo -n "Enter username: "
    stty_orig=$(stty -g) # save original terminal setting.
    read username        # read the prefix
    stty $stty_orig      # restore terminal setting.
    if [ -z "$username" ]; then
        username="azureuser"
    fi
else
    username="$DEPLOY_USERNAME"
fi
echo ""
echo "--> Using username '$username' ..."

if [ -z "$DEPLOY_PASSWORD" ]; then
    # Input password
    echo -n "Enter password: "
    stty_orig=$(stty -g) # save original terminal setting.
    stty -echo           # turn-off echoing.
    read password        # read the password
    stty $stty_orig      # restore terminal setting.
else
    password="$DEPLOY_PASSWORD"
    echo ""
    echo "--> Using password found in env variable DEPLOY_PASSWORD ..."
fi

startaddress() {
    in=$1
    add=$2
    netaddr=(${in//\// })
    netaddrint="$(ip2int ${netaddr[0]})"
    echo "$(int2ip $((netaddrint + add)))"
}
ip2int() {
    local a b c d
    { IFS=. read a b c d; } <<<$1
    echo $(((((((a << 8) | b) << 8) | c) << 8) | d))
}

int2ip() {
    local ui32=$1
    shift
    local ip n
    for n in 1 2 3 4; do
        ip=$((ui32 & 0xff))${ip:+.}$ip
        ui32=$((ui32 >> 8))
    done
    echo $ip
}

##############################################################################################################
# Variables
##############################################################################################################
rg="$prefix-RG"
rgfgt="$prefix-FGT-RG"

vwanName="$prefix-VWAN"
lnxSize="Standard_B1ls"
lnxImageURN="Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest"

##############################################################################################################
# Variables: Virtual WAN Hub A
##############################################################################################################
vhubAName="$prefix-$location-HUB"
vhubAAddressPrefix="172.16.110.0/24"
vhubAASN="65515"
vhubABGPPeerA="172.16.110.68"
vhubABGPPeerB="172.16.110.69"

vhubAFGTSKU="fortinet_fg-vm_payg_2023"
#vhubAFGTSKU="fortinet_fg-vm"
vhubAFGTASN="65007"
vhubASpokeFGTName="$prefix-$location-VNET"
vhubASpokeFGTPrefix="172.16.120.0/24"
vhubASpokeFGTSubnet1Name="ExternalSubnet"
vhubASpokeFGTSubnet1Prefix="172.16.120.0/28"
vhubASpokeFGTSubnet1StartAddress="$(startaddress $vhubASpokeFGTSubnet1Prefix 4)"
vhubASpokeFGTSubnet2Name="InternalSubnet"
vhubASpokeFGTSubnet2Prefix="172.16.120.16/28"
vhubASpokeFGTSubnet2Gateway="$(startaddress $vhubASpokeFGTSubnet2Prefix 1)"
vhubASpokeFGTSubnet2StartAddress="$(startaddress $vhubASpokeFGTSubnet2Prefix 4)"
vhubASpokeFGTSubnet3Name="HASyncSubnet"
vhubASpokeFGTSubnet3Prefix="172.16.120.32/28"
vhubASpokeFGTSubnet4Name="MGMTSubnet"
vhubASpokeFGTSubnet4Prefix="172.16.120.48/28"
vhubASpokeFGTSubnet5Name="ProtectedSubnet"
vhubASpokeFGTSubnet5Prefix="172.16.120.64/28"

vhubASpoke1Name="$prefix-$location-VNET-Spoke1"
vhubASpoke1RT="$prefix-$location-VNET-Spoke1-RT"
vhubASpoke1Prefix="172.16.121.0/24"
vhubASubnetSpoke1Name="Spoke1Subnet"
vhubASubnetSpoke1Prefix="172.16.121.0/28"

vhubASpoke2Name="$prefix-$location-VNET-Spoke2"
vhubASpoke2RT="$prefix-$location-VNET-Spoke2-RT"
vhubASpoke2Prefix="172.16.122.0/24"
vhubASubnetSpoke2Name="Spoke2Subnet"
vhubASubnetSpoke2Prefix="172.16.122.0/28"

vhubASpoke3Name="$prefix-$location-VNET-Spoke3"
vhubASpoke3Prefix="172.16.123.0/24"
vhubASubnetSpoke3Name="Spoke3Subnet"
vhubASubnetSpoke3Prefix="172.16.123.0/28"

vhubAFGTCustomData="
config system global
    set gui-theme onyx
    set timezone 26
    set admintimeout 480
end
config router bgp
    set as $vhubAFGTASN
    set keepalive-timer 1
    set holdtime-timer 3
    set ebgp-multipath enable
    set graceful-restart enable
    config neighbor
        edit "$vhubABGPPeerA"
            set ebgp-enforce-multihop enable
            set soft-reconfiguration enable
            set interface "port2"
            set remote-as $vhubAASN
        next
        edit "$vhubABGPPeerB"
            set ebgp-enforce-multihop enable
            set soft-reconfiguration enable
            set interface "port2"
            set remote-as $vhubAASN
        next
    end
    config network
        edit 1
            set prefix $vhubASpoke1Prefix
        next
        edit 2
            set prefix $vhubASpoke2Prefix
        next
    end
end
config router static
    edit 3
        set dst $vhubASpoke1Prefix
        set gateway $vhubASpokeFGTSubnet2Gateway
        set device "port2"
    next
    edit 4
        set dst $vhubASpoke2Prefix
        set gateway $vhubASpokeFGTSubnet2Gateway
        set device "port2"
    next
    edit 5
        set dst $vhubAAddressPrefix
        set gateway $vhubASpokeFGTSubnet2Gateway
        set device "port2"
    next
end
config firewall policy
    edit 1
        set name "Inbound"
        set srcintf "port1"
        set dstintf "port2"
        set action accept
        set srcaddr "all"
        set dstaddr "all"
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set logtraffic-start enable
    next
    edit 2
        set name "Outbound"
        set srcintf "port2"
        set dstintf "port1"
        set action accept
        set srcaddr "all"
        set dstaddr "all"
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set logtraffic-start enable
    next
end
"

##############################################################################################################
# Variables: Virtual WAN Hub B
##############################################################################################################
vhubBName="$prefix-$locationB-HUB"
vhubBAddressPrefix="172.16.111.0/24"
vhubBASN="65515"
vhubBBGPPeerA="172.16.111.68"
vhubBBGPPeerB="172.16.111.69"

vhubBFGTSKU="fortinet_fg-vm_payg_2023"
vhubBFGTASN="65008"
vhubBSpokeFGTName="$prefix-$locationB-VNET"
vhubBSpokeFGTPrefix="172.16.130.0/24"
vhubBSpokeFGTSubnet1Name="ExternalSubnet"
vhubBSpokeFGTSubnet1Prefix="172.16.130.0/28"
vhubBSpokeFGTSubnet1StartAddress="$(startaddress $vhubBSpokeFGTSubnet1Prefix 4)"
vhubBSpokeFGTSubnet2Name="InternalSubnet"
vhubBSpokeFGTSubnet2Prefix="172.16.130.16/28"
vhubBSpokeFGTSubnet2Gateway="$(startaddress $vhubBSpokeFGTSubnet2Prefix 1)"
vhubBSpokeFGTSubnet2StartAddress="$(startaddress $vhubBSpokeFGTSubnet2Prefix 4)"
vhubBSpokeFGTSubnet3Name="HASyncSubnet"
vhubBSpokeFGTSubnet3Prefix="172.16.130.32/28"
vhubBSpokeFGTSubnet4Name="MGMTSubnet"
vhubBSpokeFGTSubnet4Prefix="172.16.130.48/28"
vhubBSpokeFGTSubnet5Name="ProtectedSubnet"
vhubBSpokeFGTSubnet5Prefix="172.16.130.64/28"

vhubBSpoke1Name="$prefix-$locationB-VNET-Spoke1"
vhubBSpoke1RT="$prefix-$locationB-VNET-Spoke1-RT"
vhubBSpoke1Prefix="172.16.131.0/24"
vhubBSubnetSpoke1Name="Spoke1Subnet"
vhubBSubnetSpoke1Prefix="172.16.131.0/28"

vhubBSpoke2Name="$prefix-$locationB-VNET-Spoke2"
vhubBSpoke2RT="$prefix-$locationB-VNET-Spoke2-RT"
vhubBSpoke2Prefix="172.16.132.0/24"
vhubBSubnetSpoke2Name="Spoke2Subnet"
vhubBSubnetSpoke2Prefix="172.16.132.0/28"

vhubBSpoke3Name="$prefix-$locationB-VNET-Spoke3"
vhubBSpoke3Prefix="172.16.133.0/24"
vhubBSubnetSpoke3Name="Spoke3Subnet"
vhubBSubnetSpoke3Prefix="172.16.133.0/28"

vhubBFGTCustomData="
config system global
    set gui-theme onyx
    set timezone 26
    set admintimeout 480
end
config router bgp
    set as $vhubBFGTASN
    set keepalive-timer 1
    set holdtime-timer 3
    set ebgp-multipath enable
    set graceful-restart enable
    config neighbor
        edit "$vhubBBGPPeerA"
        set ebgp-enforce-multihop enable
        set soft-reconfiguration enable
        set interface "port1"
        set remote-as $vhubBASN
    next
    edit "$vhubBBGPPeerB"
        set ebgp-enforce-multihop enable
        set soft-reconfiguration enable
        set interface "port1"
        set remote-as $vhubBASN
    next
    end
    config network
        edit 1
            set prefix "$vhubBSpoke1Prefix"
        next
        edit 2
            set prefix "$vhubBSpoke2Prefix"
        next
    end
end
config router static
    edit 3
        set dst $vhubBSpoke1Prefix
        set gateway $vhubBSpokeFGTSubnet2Gateway
        set device "port2"
    next
    edit 4
        set dst $vhubBSpoke2Prefix
        set gateway $vhubBSpokeFGTSubnet2Gateway
        set device "port2"
    next
    edit 5
        set dst $vhubBAddressPrefix
        set gateway $vhubBSpokeFGTSubnet2Gateway
        set device "port2"
    next
end
config firewall policy
    edit 1
        set name "Inbound"
        set srcintf "port1"
        set dstintf "port2"
        set action accept
        set srcaddr "all"
        set dstaddr "all"
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set logtraffic-start enable
    next
    edit 2
        set name "Outbound"
        set srcintf "port2"
        set dstintf "port1"
        set action accept
        set srcaddr "all"
        set dstaddr "all"
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set logtraffic-start enable
    next
end
"
##############################################################################################################
# Resource Group
##############################################################################################################
echo ""
if [ $(az group exists --name $rg) = false ]; then
    echo "--> Creating $rg resource group ..."
    az group create --location "$location" --name "$rg"
fi

##############################################################################################################
# Hub A
##############################################################################################################
echo ""
echo "--> Hub A: Azure Virtual HUB A $vhubBName ..."
az network vhub show --name "$vhubAName" --resource-group "$rg"
if [ $? != 0 ]; then
    az network vhub create --name "$vhubAName" --resource-group "$rg" --address-prefix "$vhubAAddressPrefix" --location "$location" --vwan "$vwanName" --sku "Standard"
fi

##############################################################################################################
# Hub A: VNET FGT
##############################################################################################################
echo ""
echo "--> VNET $vhubASpokeFGTName ..."
az network vnet show --name "$vhubASpokeFGTName" --resource-group "$rg"
if [ $? != 0 ]; then
    az network vnet create --name "$vhubASpokeFGTName" --resource-group "$rg" --address-prefixes "$vhubASpokeFGTPrefix"
    az network vnet subnet create --resource-group "$rg" --vnet-name "$vhubASpokeFGTName" --name "$vhubASpokeFGTSubnet1Name" --address-prefixes "$vhubASpokeFGTSubnet1Prefix"
    az network vnet subnet create --resource-group "$rg" --vnet-name "$vhubASpokeFGTName" --name "$vhubASpokeFGTSubnet2Name" --address-prefixes "$vhubASpokeFGTSubnet2Prefix"
    az network vnet subnet create --resource-group "$rg" --vnet-name "$vhubASpokeFGTName" --name "$vhubASpokeFGTSubnet3Name" --address-prefixes "$vhubASpokeFGTSubnet3Prefix"
    az network vnet subnet create --resource-group "$rg" --vnet-name "$vhubASpokeFGTName" --name "$vhubASpokeFGTSubnet4Name" --address-prefixes "$vhubASpokeFGTSubnet4Prefix"
    az network vnet subnet create --resource-group "$rg" --vnet-name "$vhubASpokeFGTName" --name "$vhubASpokeFGTSubnet5Name" --address-prefixes "$vhubASpokeFGTSubnet5Prefix"
fi
az network vhub connection create --name HUBA-2-SPOKEFGT --vhub-name "$vhubAName" --resource-group "$rg" --remote-vnet "$vhubASpokeFGTName"
result=$?
if [[ $result != 0 ]]; then
    echo "--> $locationB: Deployment virtual network $vhubASpokeFGTName [$vhubASpokeFGTPrefix] peering failed ..."
    exit $result
fi

##############################################################################################################
# Hub A: VNET Spoke 1
##############################################################################################################
echo ""
echo "--> $location: virtual network $vhubASpoke1Name [$vhubASpoke1Prefix]..."
az network vnet show --name "$vhubASpoke1Name" --resource-group "$rg"
if [ $? != 0 ]; then
    az network vnet create --resource-group "$rg" --name "$vhubASpoke1Name" --address-prefix "$vhubASpoke1Prefix" --subnet-name "$vhubASubnetSpoke1Name" --subnet-prefix "$vhubASubnetSpoke1Prefix"
fi
az network vnet peering create --resource-group "$rg" --name HUBA-2-SPOKE1 --vnet-name "$vhubASpokeFGTName" --remote-vnet "$vhubASpoke1Name" --allow-vnet-access --allow-forwarded-traffic
az network vnet peering create --resource-group "$rg" --name HUBA-2-SPOKE1 --vnet-name "$vhubASpoke1Name" --remote-vnet "$vhubASpokeFGTName" --allow-vnet-access --allow-forwarded-traffic
az network route-table create --resource-group "$rg" --name "$vhubASpoke1RT"
az network route-table route create --resource-group "$rg" --route-table-name "$vhubASpoke1RT" --name default --next-hop-type VirtualAppliance --address-prefix 0.0.0.0/0 --next-hop-ip-address "$vhubASpokeFGTSubnet2StartAddress"
az network vnet subnet update --resource-group "$rg" --name "$vhubASubnetSpoke1Name" --vnet-name "$vhubASpoke1Name" --route-table "$vhubASpoke1RT"

##############################################################################################################
# Hub A: VNET Spoke 2
##############################################################################################################
echo ""
echo "--> $location: virtual network $vhubASpoke2Name [$vhubASpoke2Prefix]..."
az network vnet show --name "$vhubASpoke2Name" --resource-group "$rg"
if [ $? != 0 ]; then
    az network vnet create --resource-group "$rg" --name "$vhubASpoke2Name" --address-prefix "$vhubASpoke2Prefix" --subnet-name "$vhubASubnetSpoke2Name" --subnet-prefix "$vhubASubnetSpoke2Prefix"
fi
az network vnet peering create --resource-group "$rg" --name HUBA-2-SPOKE2 --vnet-name "$vhubASpokeFGTName" --remote-vnet "$vhubASpoke2Name" --allow-vnet-access --allow-forwarded-traffic
az network vnet peering create --resource-group "$rg" --name HUBA-2-SPOKE2 --vnet-name "$vhubASpoke2Name" --remote-vnet "$vhubASpokeFGTName" --allow-vnet-access --allow-forwarded-traffic
az network route-table create --resource-group "$rg" --name "$vhubASpoke2RT"
az network route-table route create --resource-group "$rg" --route-table-name "$vhubASpoke2RT" --name default --next-hop-type VirtualAppliance --address-prefix 0.0.0.0/0 --next-hop-ip-address "$vhubASpokeFGTSubnet2StartAddress"
az network vnet subnet update --resource-group "$rg" --name "$vhubASubnetSpoke2Name" --vnet-name "$vhubASpoke2Name" --route-table "$vhubASpoke2RT"

##############################################################################################################
# Hub A: VNET Spoke 3
##############################################################################################################
echo ""
echo "--> $location: virtual network $vhubASpoke3Name [$vhubASpoke3Prefix]..."
az network vnet show --name "$vhubASpoke3Name" --resource-group "$rg"
if [ $? != 0 ]; then
    az network vnet create --resource-group "$rg" --name "$vhubASpoke3Name" --address-prefix "$vhubASpoke3Prefix" --subnet-name "$vhubASubnetSpoke3Name" --subnet-prefix "$vhubASubnetSpoke3Prefix"
fi
az network vhub connection create --name HUBA-2-SPOKE3 --vhub-name "$vhubAName" --resource-group "$rg" --remote-vnet "$vhubASpoke3Name"

##############################################################################################################
# Hub B
##############################################################################################################
echo ""
echo "--> $locationB: Azure Virtual HUB B $vhubBName ..."
az network vhub show --name "$vhubBName" --resource-group "$rg"
if [ $? != 0 ]; then
    az network vhub create --name "$vhubBName" --resource-group "$rg" --address-prefix "$vhubBAddressPrefix" --location "$locationB" --vwan "$vwanName" --sku "Standard"
fi

##############################################################################################################
# Hub B: VNET FGT
##############################################################################################################
echo ""
echo "--> $locationB: VNET $vhubBSpokeFGTName ..."
az network vnet show --name "$vhubBSpokeFGTName" --resource-group "$rg"
if [ $? != 0 ]; then
    az network vnet create --name "$vhubBSpokeFGTName" --resource-group "$rg" --address-prefixes "$vhubBSpokeFGTPrefix" --location "$locationB"
    az network vnet subnet create --resource-group "$rg" --vnet-name "$vhubBSpokeFGTName" --name "$vhubBSpokeFGTSubnet1Name" --address-prefixes "$vhubBSpokeFGTSubnet1Prefix"
    az network vnet subnet create --resource-group "$rg" --vnet-name "$vhubBSpokeFGTName" --name "$vhubBSpokeFGTSubnet2Name" --address-prefixes "$vhubBSpokeFGTSubnet2Prefix"
    az network vnet subnet create --resource-group "$rg" --vnet-name "$vhubBSpokeFGTName" --name "$vhubBSpokeFGTSubnet3Name" --address-prefixes "$vhubBSpokeFGTSubnet3Prefix"
    az network vnet subnet create --resource-group "$rg" --vnet-name "$vhubBSpokeFGTName" --name "$vhubBSpokeFGTSubnet4Name" --address-prefixes "$vhubBSpokeFGTSubnet4Prefix"
    az network vnet subnet create --resource-group "$rg" --vnet-name "$vhubBSpokeFGTName" --name "$vhubBSpokeFGTSubnet5Name" --address-prefixes "$vhubBSpokeFGTSubnet5Prefix"
fi
az network vhub connection create --name HUBB-2-SPOKEFGT --vhub-name "$vhubBName" --resource-group "$rg" --remote-vnet "$vhubBSpokeFGTName"
result=$?
if [[ $result != 0 ]]; then
    echo "--> $locationB: Deployment virtual network $vhubBSpokeFGTName [$vhubBSpokeFGTPrefix] peering failed ..."
    exit $result
fi

##############################################################################################################
# Hub B: VNET Spoke 1
##############################################################################################################
echo ""
echo "--> $locationB: virtual network $vhubBSpoke1Name [$vhubBSpoke1Prefix]..."
az network vnet show --name "$vhubBSpoke1Name" --resource-group "$rg"
if [ $? != 0 ]; then
    az network vnet create --resource-group "$rg" --name "$vhubBSpoke1Name" --address-prefix "$vhubBSpoke1Prefix" --subnet-name "$vhubBSubnetSpoke1Name" --subnet-prefix "$vhubBSubnetSpoke1Prefix" --location "$locationB"
fi
az network vnet peering create --resource-group "$rg" --name HUBB-2-SPOKE1 --vnet-name "$vhubBSpokeFGTName" --remote-vnet "$vhubBSpoke1Name" --allow-vnet-access --allow-forwarded-traffic
az network vnet peering create --resource-group "$rg" --name HUBB-2-SPOKE1 --vnet-name "$vhubBSpoke1Name" --remote-vnet "$vhubBSpokeFGTName" --allow-vnet-access --allow-forwarded-traffic
az network route-table create --resource-group "$rg" --name "$vhubBSpoke1RT" --location "$locationB"
az network route-table route create --resource-group "$rg" --route-table-name "$vhubBSpoke1RT" --name default --next-hop-type VirtualAppliance --address-prefix 0.0.0.0/0 --next-hop-ip-address "$vhubBSpokeFGTSubnet2StartAddress"
az network vnet subnet update --resource-group "$rg" --name "$vhubBSubnetSpoke1Name" --vnet-name "$vhubBSpoke1Name" --route-table "$vhubBSpoke1RT"

##############################################################################################################
# Hub B: VNET Spoke 2
##############################################################################################################
echo ""
echo "--> $locationB: virtual network $vhubBSpoke2Name [$vhubBSpoke2Prefix]..."
az network vnet show --name "$vhubBSpoke2Name" --resource-group "$rg"
if [ $? != 0 ]; then
    az network vnet create --resource-group "$rg" --name "$vhubBSpoke2Name" --address-prefix "$vhubBSpoke2Prefix" --subnet-name "$vhubBSubnetSpoke2Name" --subnet-prefix "$vhubBSubnetSpoke2Prefix" --location "$locationB"
fi
az network vnet peering create --resource-group "$rg" --name HUBB-2-SPOKE2 --vnet-name "$vhubBSpokeFGTName" --remote-vnet "$vhubBSpoke2Name" --allow-vnet-access --allow-forwarded-traffic
az network vnet peering create --resource-group "$rg" --name HUBB-2-SPOKE2 --vnet-name "$vhubBSpoke2Name" --remote-vnet "$vhubBSpokeFGTName" --allow-vnet-access --allow-forwarded-traffic
az network route-table create --resource-group "$rg" --name "$vhubBSpoke2RT" --location "$locationB"
az network route-table route create --resource-group "$rg" --route-table-name "$vhubBSpoke2RT" --name default --next-hop-type VirtualAppliance --address-prefix 0.0.0.0/0 --next-hop-ip-address "$vhubBSpokeFGTSubnet1StartAddress"
az network vnet subnet update --resource-group "$rg" --name "$vhubBSubnetSpoke2Name" --vnet-name "$vhubBSpoke2Name" --route-table "$vhubBSpoke2RT"

##############################################################################################################
# Hub B: VNET Spoke 3
##############################################################################################################
echo ""
echo "--> $locationB: virtual network $vhubBSpoke3 [$vhubBSpoke3Prefix]..."
az network vnet show --name "$vhubBSpoke3Name" --resource-group "$rg"
if [ $? != 0 ]; then
    az network vnet create --resource-group "$rg" --name "$vhubBSpoke3Name" --address-prefix "$vhubBSpoke3Prefix" --subnet-name "$vhubBSubnetSpoke3Name" --subnet-prefix "$vhubBSubnetSpoke3Prefix" --location "$locationB"
    result=$?
    if [[ $result != 0 ]]; then
        echo "--> $locationB: Deployment virtual network $vhubBSpoke3 [$vhubBSpoke3Prefix] failed ..."
        exit $rc
    fi
fi
az network vhub connection create --name HUBB-2-SPOKE3 --vhub-name "$vhubBName" --resource-group "$rg" --remote-vnet "$vhubBSpoke3Name"
result=$?
if [[ $result != 0 ]]; then
    echo "--> $locationB: Deployment virtual network $vhubBSpoke3 [$vhubBSpoke3Prefix] peering failed ..."
    exit $result
fi

##############################################################################################################
# Clients
##############################################################################################################
for LOC in $location $locationB; do
    for TIER in Protected Spoke1 Spoke2 Spoke3; do
        vmName="$prefix-$LOC-VM-$TIER"
        nicName="$vmName-NIC"
        echo "--> $LOC: Deployment $TIER NIC ..."
        az vm nic show --resource-group "$rg" --nic "$nicName" --vm-name "$vmName" &>/dev/null
        if [[ $? != 0 ]]; then
            vnet="$prefix-$LOC-VNET"
            if [[ "$TIER" == "Spoke1" || "$TIER" == "Spoke2" || "$TIER" == "Spoke3" ]]; then
                vnet="$prefix-$LOC-VNET-$TIER"
            fi
            az network nic create --resource-group "$rg" --name "$nicName" --vnet-name "$vnet" --subnet "${TIER}Subnet" --location "$LOC"
            result=$?
            if [[ $result != 0 ]]; then
                echo "--> $LOC: Deployment $TIER NIC failed ..."
                exit $rc
            fi
        else
            echo "--> $LOC: Deployment $TIER NIC found ..."
        fi

        echo "--> $LOC: Deployment $TIER VM ..."
        az vm show -g "$rg" -n "$vmName" &>/dev/null
        if [[ $? != 0 ]]; then
            az vm create --resource-group "$rg" --name "$vmName" --nics "$nicName" --image UbuntuLTS --location "$LOC" --size "$lnxSize" \
                --admin-username "$username" --admin-password "$password" --image "$lnxImageURN" --output json
            result=$?
            if [[ $result != 0 ]]; then
                echo "--> $LOC: Deployment $TIER VM failed ..."
                exit $result
            fi
        else
            echo "--> $LOC: Deployment $TIER VM found ..."
        fi
    done
done

##############################################################################################################
# HubA: FortiGate NGFW
##############################################################################################################
echo "--> $location: FortiGate deployment ..."
az deployment group create --resource-group "$rg" \
    --template-uri "https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/A-Single-VM/azuredeploy.json" \
    --parameters adminUsername="$username" adminPassword="$password" fortiGateNamePrefix="$prefix-$location" fortiGateImageSKU="$vhubAFGTSKU" \
    vnetNewOrExisting="existing" vnetName="$vhubASpokeFGTName" vnetResourceGroup="$rg" \
    vnetAddressPrefix="$vhubASpokeFGTPrefix" fortiGateAdditionalCustomData="$vhubAFGTCustomData" \
    subnet1Name="$vhubASpokeFGTSubnet1Name" subnet1Prefix="$vhubASpokeFGTSubnet1Prefix" subnet1StartAddress="$vhubASpokeFGTSubnet1StartAddress" \
    subnet2Name="$vhubASpokeFGTSubnet2Name" subnet2Prefix="$vhubASpokeFGTSubnet2Prefix" subnet2StartAddress="$vhubASpokeFGTSubnet2StartAddress" \
    subnet3Name="$vhubASpokeFGTSubnet5Name" subnet3Prefix="$vhubASpokeFGTSubnet5Prefix"
result=$?
if [[ $result != 0 ]]; then
    echo "--> $location: FortiGate deployment failed ..."
    exit $result
fi

##############################################################################################################
# HubB: FortiGate NGFW
##############################################################################################################
echo "--> $locationB: FortiGate deployment ..."
az deployment group create --resource-group "$rg" \
    --template-uri "https://raw.githubusercontent.com/40net-cloud/fortinet-azure-solutions/main/FortiGate/A-Single-VM/azuredeploy.json" \
    --parameters adminUsername="$username" adminPassword="$password" location="$locationB" fortiGateNamePrefix="$prefix-$locationB" fortiGateImageSKU="$vhubBFGTSKU" \
    vnetNewOrExisting="existing" vnetName="$vhubBSpokeFGTName" vnetResourceGroup="$rg" \
    vnetAddressPrefix="$vhubBSpokeFGTPrefix" fortiGateAdditionalCustomData="$vhubBFGTCustomData" \
    subnet1Name="$vhubBSpokeFGTSubnet1Name" subnet1Prefix="$vhubBSpokeFGTSubnet1Prefix" subnet1StartAddress="$vhubBSpokeFGTSubnet1StartAddress" \
    subnet2Name="$vhubBSpokeFGTSubnet2Name" subnet2Prefix="$vhubBSpokeFGTSubnet2Prefix" subnet2StartAddress="$vhubBSpokeFGTSubnet2StartAddress" \
    subnet3Name="$vhubBSpokeFGTSubnet5Name" subnet3Prefix="$vhubBSpokeFGTSubnet5Prefix"
result=$?
if [[ $result != 0 ]]; then
    echo "--> $locationB: FortiGate deployment failed ..."
    exit $result
fi

echo "
##############################################################################################################
#
# Azure Virtual WAN and FortiGate eBGP peering
#
# The FortiGate systems are reachable via the management public IP addresses of the firewalls
# on HTTPS/443 and SSH/22.
#
##############################################################################################################
Deployment information:
Username: $username
FortiGate IP addesses
"
query="[?virtualMachine.name.starts_with(@, '$prefix')].{virtualMachine:virtualMachine.name, publicIP:virtualMachine.network.publicIpAddresses[0].ipAddress,privateIP:virtualMachine.network.privateIpAddresses[0]}"
az vm list-ip-addresses --query "$query" --output tsv
echo "
##############################################################################################################
"

exit 0


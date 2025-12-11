# Azure Virtual WAN BGP peering

## Introduction

Azure Virtual WAN allows exchange of routing information using the BGP protocol between the Virtual WAN Hub router and the FortiGate NGFW system. This provides benefits over the static routing options updating both sides as new environments become available, e.g. new VPN tunnels are connected to the FortiGate are forwarded to Virtual WAN Hub, routing updates towards the FGT as new hubs and spokes are provisioned.

More information about the BGP peering integration can be found [here](https://docs.microsoft.com/en-us/azure/virtual-wan/scenario-bgp-peering-hub).

## Design

To showcase the capabilities of the BGP integration a dual hub Azure Virtual WAN setup is deployed om this demo to clarify the functionality and the limitations.

The deployment is currently available in the form of a script using Azure CLI. It will automatically deploy a full working environment containing the the following components.

  - 2 single FortiGate firewall's one in each region
  - 4 VNETs per region: FortiGate Hub, Spoke1, Spoke2 and Spoke3. Spoke 1 and 2 are peered with the FortiGate VNET. FortiGate Hub and Spoke3 are peered directly to the VirtualHUB
	- 3 public IPs. The first public IP is for cluster access to/through the active FortiGate.  The other two PIPs are for Management access. To deploy with public IPs on the FortiGate VMs you can use the 'Azure Portal Wizard - Deploy to Azure' button and select none for the the second and third public IP
  - User Defined Routes (UDR) for the FortiGate VM and Spoke 1 and Spoke 2 per region pointing towards the FortiGate VM

![active/passive design](images/fgt-vwan-bgp.png)

This script can also be extended or customized based on your requirements. Additional subnets besides the one's mentioned above are not automatically generated. By adapting the script, you can add additional subnets which preferably require their own routing tables.

## How to deploy

The FortiGate solution is deployed using the Azure Portal combined with a script that uses Azure CLI.

There are minimal 5 variables needed to complete the deployment.

  - PREFIX : This prefix will be added to each of the resources created by the templates for easy of use, manageability and visibility.
  - LOCATION Hub A : This is the Azure region for hub A
  - LOCATION Hub B : This is the Azure region for hub B
  - USERNAME : The username used to login to the FortiGate GUI and SSH management UI.
  - PASSWORD : The password used for the FortiGate GUI and SSH management UI.

### Step 1: Deployment of the demo environment

The setup of the demo environment is currently available using a script that uses Azure CLI commands. The easiest way to get started is to open the Azure Cloud Shell on the Azure Portal via this URL: [https://shell.azure.com/](https://shell.azure.com/)


### Azure CLI

`cd ~/clouddrive/ && wget -qO- https://github.com/40net-cloud/fortinet-azure-solutions/archive/main.tar.gz | tar zxf - && cd ~/clouddrive/fortinet-azure-solutions-main/FortiGate/AzureVirtualWAN/bgppeering/ && ./deploy.sh`

### Step 2: Configure BGP peering

The BGP peering is setup on the FortiGate but still needs to be configured on the Virtual WAN Hub. The BGP connectivity on the FortiGate is created on port 2.

- Locate your VWAN configuration using the search bar.
- Open the first HUB and select BGP Peers
- Add the BGP peer configuration entering the ASN, internal FortiGate IP address and the Virtual Network connection linked to the FortiGate.
- Make sure to enable this on both Virtual Hub

![bgp peering config hub A](images/bgppeeringa.png)

![bgp peering config hub B](images/bgppeeringb.png)

After configuration, the routing tables on both the FortiGate and Azure Virtual WAN will show all the networks.

#### Routing table on FortiGate A:

```
JVH92-westeurope-FGT-A # get router info routing-table all
Codes: K - kernel, C - connected, S - static, R - RIP, B - BGP
       O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, L1 - IS-IS level-1, L2 - IS-IS level-2, ia - IS-IS inter area
       * - candidate default

Routing table for VRF=0
S*      0.0.0.0/0 [10/0] via 172.16.120.1, port1
S       172.16.110.0/24 [10/0] via 172.16.120.17, port2
S       172.16.120.0/24 [10/0] via 172.16.120.17, port2
C       172.16.120.0/28 is directly connected, port1
C       172.16.120.16/28 is directly connected, port2
S       172.16.121.0/24 [10/0] via 172.16.120.17, port2
S       172.16.122.0/24 [10/0] via 172.16.120.17, port2
B       172.16.123.0/24 [20/0] via 172.16.110.68 (recursive via 172.16.120.17, port2), 00:05:54
                        [20/0] via 172.16.110.69 (recursive via 172.16.120.17, port2), 00:05:54
B       172.16.130.0/24 [20/0] via 172.16.110.68 (recursive via 172.16.120.17, port2), 00:05:54
                        [20/0] via 172.16.110.69 (recursive via 172.16.120.17, port2), 00:05:54
B       172.16.131.0/24 [20/0] via 172.16.110.68 (recursive via 172.16.120.17, port2), 00:00:41
                        [20/0] via 172.16.110.69 (recursive via 172.16.120.17, port2), 00:00:41
B       172.16.132.0/24 [20/0] via 172.16.110.68 (recursive via 172.16.120.17, port2), 00:00:41
                        [20/0] via 172.16.110.69 (recursive via 172.16.120.17, port2), 00:00:41
B       172.16.133.0/24 [20/0] via 172.16.110.68 (recursive via 172.16.120.17, port2), 00:05:54
                        [20/0] via 172.16.110.69 (recursive via 172.16.120.17, port2), 00:05:54
```

#### Routing table on FortiGate B:

```
JVH92-eastus2-FGT-A # get router info routing-table all
Codes: K - kernel, C - connected, S - static, R - RIP, B - BGP
       O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, L1 - IS-IS level-1, L2 - IS-IS level-2, ia - IS-IS inter area
       * - candidate default

Routing table for VRF=0
S*      0.0.0.0/0 [10/0] via 172.16.130.1, port1
S       172.16.111.0/24 [10/0] via 172.16.130.17, port2
B       172.16.120.0/24 [20/0] via 172.16.111.68 (recursive via 172.16.130.17, port2), 00:00:35
                        [20/0] via 172.16.111.69 (recursive via 172.16.130.17, port2), 00:00:35
B       172.16.121.0/24 [20/0] via 172.16.111.68 (recursive via 172.16.130.17, port2), 00:00:35
                        [20/0] via 172.16.111.69 (recursive via 172.16.130.17, port2), 00:00:35
B       172.16.122.0/24 [20/0] via 172.16.111.68 (recursive via 172.16.130.17, port2), 00:00:35
                        [20/0] via 172.16.111.69 (recursive via 172.16.130.17, port2), 00:00:35
B       172.16.123.0/24 [20/0] via 172.16.111.68 (recursive via 172.16.130.17, port2), 00:00:35
                        [20/0] via 172.16.111.69 (recursive via 172.16.130.17, port2), 00:00:35
S       172.16.130.0/24 [10/0] via 172.16.130.17, port2
C       172.16.130.0/28 is directly connected, port1
C       172.16.130.16/28 is directly connected, port2
S       172.16.131.0/24 [10/0] via 172.16.130.17, port2
S       172.16.132.0/24 [10/0] via 172.16.130.17, port2
B       172.16.133.0/24 [20/0] via 172.16.111.68 (recursive via 172.16.130.17, port2), 00:00:35
                        [20/0] via 172.16.111.69 (recursive via 172.16.130.17, port2), 00:00:35
```

#### Effective routing table on Virtual Hub A

![effective routing table hub A](images/effectiveroutesa.png)

#### Effective routing table on Virtual Hub B

![effective routing table hub B](images/effectiveroutesb.png)

# FortiGate configuration

The FortiGate VMs need a specific configuration to operate in your environment. This configuration can be injected during provisioning or afterwards via the different management options including GUI, CLI, FortiManager or REST API.

- [Default configuration using this template](doc/config-provisioning.md)

# Requirements and limitations

Any limitations from the [single VM deployment](../../A-Single-VM/README.md) apply here as well.

The Azure Virtual WAN has some considerations to be taken into account and are listed [here](https://docs.microsoft.com/en-us/azure/virtual-wan/scenario-bgp-peering-hub#benefits-and-considerations).

# Support
Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/fortinet/azure-templates/issues) tab of this GitHub project.
For other questions related to this project, contact [github@fortinet.com](mailto:github@fortinet.com).

# License
[License](/../../blob/main/LICENSE) © Fortinet Technologies. All rights reserved.
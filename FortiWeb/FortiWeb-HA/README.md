## High Availability for FortiWeb on Azure

FortiWeb's High Availability (HA) solution on Azure uses Azure Load Balancer to achieve Active-Active HA and Active-Passive HA.

![Example Diagram](./images/fortiweb-ha.png)

The following resources will be created during the deployment process:

- An Azure Load Balancer with a public IP address.
- Two FortiWeb-VM instances. By default, these two VMs are added to the Azure Load Balancer's backend pool.
- A public-facing subnet connecting the FortiWeb outgoing interface (port1) to the Azure Load Balancer.
- A private subnet where one or more web application VMs that FortiWeb protects are located.

### How it works

All web traffic passes through the Azure Load Balancer first and is then directed to a collection of VMs called a backend pool. In the diagram above, the pool consists of FortiWeb-VM1 and FortiWeb-VM2.

In the Active-Active HA scenario, web traffic is distributed between FortiWeb-VM1 and FortiWeb-VM2.

In the Active-Passive HA scenario, web traffic is directed only to the master node (FortiWeb-VM1 in the diagram above). When FortiWeb-VM1 fails to operate, the Azure Load Balancer will distribute web traffic to FortiWeb-VM2, which is now the master node.

This use case overview is also available in the Fortinet Document Library:

  * [ FortiWeb / Overview of High Availability for FortiWeb on Azure](http://docs2.fortinet.com/vm/azure/fortiweb/6.0/use-case-high-availability-for-fortiweb-on-azure/6.0.2/82738/overview)

# Support
Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/fortinet/azure-templates/issues) tab of this GitHub project.
For other questions related to this project, contact [github@fortinet.com](mailto:github@fortinet.com).

## License
[License](./LICENSE) © Fortinet Technologies. All rights reserved.

# FortiGate Autoscale for Azure

## Introduction

## Design

Autoscaling is documented on the [Fortinet documenation site](https://docs.fortinet.com/document/fortigate-public-cloud/7.2.0/azure-administration-guide/161167/deploying-autoscaling-on-azure). By default a hybird license setup (using both BYOL and PAYG) is created to take into account the total cost of ownership of this deployment. It is of course also possible to only use one of the license types.

![FortiGate Autoscale (hybrid licensing)](https://fortinetweb.s3.amazonaws.com/docs.fortinet.com/v2/resources/0489513b-b3c1-11e9-a989-00505692583a/images/665e0b1344961387f060f12cd394091e_fig-AzureAS-HybridLicensing.png)

## Deployment

The combined solution for the Autoscale deployment is available on the [Fortinet GitHub](https://github.com/fortinet/fortigate-autoscale/tree/master/azure). Combined with the step by step guide to setup all the different components. Or you can use the the script on this GitHub page to automate this process.

There are 5 variables needed to complete kickstart the deployment. The deploy.sh script will ask them automatically. When you deploy the ARM template the Azure Portal will request the variables as a requirement.

  - PREFIX : This prefix will be added to each of the resources created by the templates for easy of use, manageability and visibility.
  - LOCATION : This is the Azure region where the deployment will be deployed
  - INSTANCETYPE : This is the Azure instance type for each of the Fortigate VM that will be deployed. By default this is set to Standard_F4s.
  - USERNAME : The username used to login to the FortiGate GUI and SSH mangement UI.
  - PASSWORD : The password used for the FortiGate GUI and SSH management UI.
  - CLIENT_ID : The service principal id used by the Azure Function to connect with the resources in Microsoft Azure. More info [here](https://docs.fortinet.com/document/fortigate-public-cloud/7.2.0/azure-administration-guide/948968/azure-sdn-connector-service-principal-configuration-requirements)
  - CLIENT_SECRET : The service principal secret used by the Azure Function to connect with the resources in Microsoft Azure. More info [here](https://docs.fortinet.com/document/fortigate-public-cloud/7.2.0/azure-administration-guide/948968/azure-sdn-connector-service-principal-configuration-requirements)

### Azure CLI
To fast track the deployment, use the Azure Cloud Shell. The Azure Cloud Shell is an in-browser CLI that contains Terraform and other tools for deployment into Microsoft Azure. It is accessible via the Azure Portal or directly at [https://shell.azure.com/](https://shell.azure.com). You can copy and paste the below one-liner to get started with your deployment.

To provision the FortiGate BYOL systems with a license create a directory called 'license' in the presistent clouddrive directory. [Copy](https://microsoft.github.io/AzureTipsAndTricks/blog/tip127.html) the license files to the directory '~/clouddrive/license' on the Azure Cloud Shell.

`cd ~/clouddrive/ && wget -qO- https://github.com/jvhoof/azure-templates/archive/main.tar.gz | tar zxf - && cd ~/clouddrive/azure-templates-main/FortiGate/Autoscale/ && ./deploy.sh`

![Azure Cloud Shell](images/azure-cloud-shell.png)

After deployment, you will be shown the IP addresses of all deployed components. You can access the management GUI's using the public IP addresses using HTTPS on ports 40030 and above.

## Requirements and limitations

The Azure ARM template deployment deploys different resources and is required to have the access rights and quota in your Microsoft Azure subscription to deploy the resources.

- The template will deploy Standard F4s VMs
- Licenses for Fortigate
  - BYOL: A demo license can be made available via your Fortinet partner or on our website. These can be injected during deployment or added after deployment.
  - PAYG or OnDemand: These licenses are automatically generated during the deployment of the FortiGate systems.

## Support
Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/jvhoof/azure-templates/issues) tab of this GitHub project.

## License
[License](/../../blob/main/LICENSE) © Fortinet Technologies. All rights reserved.

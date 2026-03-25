# FortiGate Next-Generation Firewall - A Single VM - Legacy

As of March 2026, new FortiGate SKUs were introduced in the Azure Marketplace that provide access to the latest marketplace features. In specific regions and deployment scenarios, legacy SKUs (e.g. GovCloud, private offers, ...) are still required; this directory contains those legacy artifacts. [For current SKU documentation and deployment instructions, see the parent directory](../).

## Deployment

For the deployment, you can use the Azure Portal, Azure CLI, Powershell or Azure Cloud Shell. The Azure ARM templates are exclusive to Microsoft Azure and can't be used in other cloud environments. The main template is the `azuredeploy.json` which you can use in the Azure Portal. A `deploy.sh` script is provided to facilitate the deployment. You'll be prompted to provide the 4 required variables:

- PREFIX : This prefix will be added to each of the resources created by the template for ease of use and visibility.
- LOCATION : This is the Azure region where the deployment will be deployed.
- USERNAME : The username used to login to the FortiGate-VM GUI and SSH management UI.
- PASSWORD : The password used for the FortiGate-VM GUI and SSH management UI.

### Azure Portal

Azure Portal Wizard:
[![Azure Portal Wizard](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FA-Single-VM%2Flegacy%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FA-Single-VM%2Flegacy%2FcreateUiDefinition.json)

Custom Deployment:
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FA-Single-VM%2Flegacy%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions$2Fmain%2FFortiGate%2FA-Single-VM%2Flegacy%2Fazuredeploy.json)

- Marketplace information:
  - Publisher: fortinet
  - Offer: fortinet_fortigate-vm_v5
  - SKU / plan: fortinet_fg-vm, fortinet_fg-vm_arm64, fortinet_fg-vm_g2, fortinet_fg-vm_payg, fortinet_fg-vm_payg_20190624, fortinet_fg-vm_payg_2022, fortinet_fg-vm_2023, fortinet_fg-vm_2023_arm64, fortinet_fg-vm_2023_g2

# FortiGate Next-Generation Firewall - Active/Passive ELB-ILB - Legacy

As of March 2026, new FortiGate SKUs were introduced in the Azure Marketplace that provide access to the latest marketplace features. In specific regions and deployment scenarios, legacy SKUs (e.g. GovCloud, private offers, ...) are still required; this directory contains those legacy artifacts. [For current SKU documentation and deployment instructions, see the parent directory](../).

## Deployment

This folder contains legacy artifacts for Active/Passive ELB/ILB FortiGate deployments. You can deploy using Azure Portal, Azure CLI, PowerShell, or Azure Cloud Shell. Azure ARM templates are specific to Microsoft Azure and cannot be used in other cloud environments. The main template is `azuredeploy.json`. A `deploy.sh` script is provided to facilitate deployment.

When the script runs, it prompts for the following required variables:

- PREFIX: Prefix for every resource created by the template.
- LOCATION: Azure region for deployment.
- USERNAME: User name for FortiGate VM GUI and SSH management.
- PASSWORD: Password for FortiGate VM GUI and SSH management.

### Azure Portal

Azure Portal Wizard:
[![Azure Portal Wizard](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FActive-Passive-ELB-ILB%2Flegacy%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FActive-Passive-ELB-ILB%2Flegacy%2FcreateUiDefinition.json)

Custom Deployment:
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FActive-Passive-ELB-ILB%2Flegacy%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2F40net-cloud%2Ffortinet-azure-solutions%2Fmain%2FFortiGate%2FActive-Passive-ELB-ILB%2Flegacy%2Fazuredeploy.json)

- Marketplace information:
  - Publisher: fortinet
  - Offer: fortinet_fortigate-vm_v5
  - SKU / plan: fortinet_fg-vm, fortinet_fg-vm_arm64, fortinet_fg-vm_g2, fortinet_fg-vm_payg, fortinet_fg-vm_payg_20190624, fortinet_fg-vm_payg_2022, fortinet_fg-vm_2023, fortinet_fg-vm_2023_arm64, fortinet_fg-vm_2023_g2

###############################################################################################################
#
# Cloud Security Services Hub
# using VNET peering and FortiGate Active/Passive High Availability with Azure Standard Load Balancer - External and Internal
# Fortinet FortiGate Terraform deployment template
#
##############################################################################################################
#
# Input variables
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "PREFIX" {
  description = "Added name to each deployed resource"
}

variable "LOCATION" {
  description = "Azure region"
}

variable "USERNAME" {
}

variable "PASSWORD" {
}

##############################################################################################################
# FortiGate variables
##############################################################################################################

variable "FGT_IMAGE_SKU" {
  description = "Azure Marketplace default image sku hourly (PAYG 'fortinet_fg-vm_payg_20190624') or byol (Bring your own license 'fortinet_fg-vm')"
  default     = "fortinet_fg-vm_payg_20190624"
}

variable "FGT_VERSION" {
  description = "FortiGate version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "latest"
}

variable "FGT_BYOL_LICENSE_FILE_A" {
  default = ""
}

variable "FGT_BYOL_LICENSE_FILE_B" {
  default = ""
}

variable "FGT_BYOL_FLEXVM_LICENSE_FILE_A" {
  default = ""
}

variable "FGT_BYOL_FLEXVM_LICENSE_FILE_B" {
  default = ""
}

variable "FGT_SSH_PUBLIC_KEY_FILE" {
  default = ""
}

##############################################################################################################
# Accelerated Networking
# Only supported on specific VM series and CPU count: D/DSv2, D/DSv3, E/ESv3, F/FS, FSv2, and Ms/Mms
# https://azure.microsoft.com/en-us/blog/maximize-your-vm-s-performance-with-accelerated-networking-now-generally-available-for-both-windows-and-linux/
##############################################################################################################
variable "FGT_ACCELERATED_NETWORKING" {
  description = "Enables Accelerated Networking for the network interfaces of the FortiGate"
  default     = "true"
}

##############################################################################################################
# Deployment in Microsoft Azure
##############################################################################################################

terraform {
  required_version = ">= 0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

##############################################################################################################
# Accept the Terms license for the FortiGate Marketplace image
# This is a one-time agreement that needs to be accepted per subscription
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement
##############################################################################################################
resource "azurerm_marketplace_agreement" "fortinet" {
  publisher = "fortinet"
  offer     = "fortinet_fortigate-vm_v5"
  plan      = var.FGT_IMAGE_SKU
}

##############################################################################################################
# Static variables - HUB network
##############################################################################################################

variable "vnet" {
  description = ""
  default     = "172.16.136.0/22"
}

variable "subnet" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.0/26"   # External
    "2" = "172.16.136.64/26"  # Internal
    "3" = "172.16.136.128/26" # HASYNC
    "4" = "172.16.136.192/26" # MGMT
    "5" = "172.16.137.0/24"   # Protected a
    "6" = "172.16.138.0/24"   # Protected b
  }
}

variable "subnetmask" {
  type        = map(string)
  description = ""

  default = {
    "1" = "26" # External
    "2" = "26" # Internal
    "3" = "26" # HASYNC
    "4" = "26" # MGMT
    "5" = "24" # Protected a
    "6" = "24" # Protected b
  }
}

variable "fgt_ipaddress_a" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.5"   # External
    "2" = "172.16.136.69"  # Internal
    "3" = "172.16.136.133" # HASYNC
    "4" = "172.16.136.197" # MGMT
  }
}

variable "fgt_ipaddress_b" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.6"   # External
    "2" = "172.16.136.70"  # Internal
    "3" = "172.16.136.134" # HASYNC
    "4" = "172.16.136.198" # MGMT
  }
}

variable "gateway_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.1"   # External
    "2" = "172.16.136.65"  # Internal
    "3" = "172.16.136.133" # HASYNC
    "4" = "172.16.136.193" # MGMT
  }
}

variable "lb_internal_ipaddress" {
  description = ""

  default = "172.16.136.68"
}

variable "fgt_vmsize" {
  default = "Standard_F4s"
}

variable "fortinet_tags" {
  type = map(string)
  default = {
    publisher : "Fortinet",
    template : "VNET Peering",
    provider : "7EB3B02F-50E5-4A3E-8CB8-2E12925831AB-VNETPeering"
  }
}

##############################################################################################################
# Static variables - SPOKE 1 network
##############################################################################################################

variable "vnetspoke1" {
  description = ""
  default     = "172.16.140.0/24"
}

variable "subnetspoke1" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.140.0/26" # SUBNET 1 in SPOKE 1
  }
}

##############################################################################################################
# Static variables - SPOKE 2 network
##############################################################################################################

variable "vnetspoke2" {
  description = ""
  default     = "172.16.142.0/24"
}

variable "subnetspoke2" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.142.0/26" # SUBNET 1 in SPOKE 2
  }
}

##############################################################################################################
# Resource Group
##############################################################################################################

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.PREFIX}-RG"
  location = var.LOCATION
}

##############################################################################################################

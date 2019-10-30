##############################################################################################################
#
# FortiGate Terraform deployment
# Active Passive High Availability with Azure Standard Load Balancer - External and Internal
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "PREFIX" {
  description = "Added name to each deployed resource"
}

variable "LOCATION" {
  description = "Azure region"
}

variable "USERNAME" {}

variable "PASSWORD" {}

##############################################################################################################
# FortiGate license type
##############################################################################################################

variable "FGT_IMAGE_SKU" {
  description = "Azure Marketplace default image sku hourly (PAYG 'fortinet_fg-vm_payg_20190624') or byol (Bring your own license 'fortinet_fg-vm')"
  default = "fortinet_fg-vm_payg_20190624"
}

variable "FGT_VERSION" {
  description = "FortiGate version by default the 'latest' available version in the Azure Marketplace is selected"
  default = "latest"
}

variable "FGT_BYOL_LICENSE_FILE_A" {
  default = ""
}

variable "FGT_BYOL_LICENSE_FILE_B" {
  default = ""
}

variable "FGT_SSH_PUBLIC_KEY_FILE" {
  default = ""
}

##############################################################################################################
# Microsoft Azure Storage Account for storage of Terraform state file
##############################################################################################################

terraform {
  required_version = ">= 0.11"
}

##############################################################################################################
# Deployment in Microsoft Azure
##############################################################################################################

provider "azurerm" {
}

##############################################################################################################
# Static variables
##############################################################################################################

variable "vnet" {
  description = ""
  default = "172.16.136.0/22"
}

variable "subnet" {
  type        = "map"
  description = ""

  default = {
    "1" = "172.16.136.0/26"        # External
    "2" = "172.16.136.64/26"       # Internal
    "3" = "172.16.136.128/26"      # HASYNC
    "4" = "172.16.136.192/26"      # MGMT
    "5" = "172.16.137.0/24"        # Protected a
    "6" = "172.16.138.0/24"        # Protected b
  }
}

variable "subnetmask" {
  type        = "map"
  description = ""

  default = {
    "1" = "26"        # External
    "2" = "26"        # Internal
    "3" = "26"        # HASYNC
    "4" = "26"        # MGMT
    "5" = "24"        # Protected a
    "6" = "24"        # Protected b
  }
}

variable "fgt_ipaddress_a" {
  type        = "map"
  description = ""

  default = {
    "1" = "172.16.136.5"        # External
    "2" = "172.16.136.69"       # Internal
    "3" = "172.16.136.133"      # HASYNC
    "4" = "172.16.136.197"      # MGMT
  }
}

variable "fgt_ipaddress_b" {
  type        = "map"
  description = ""

  default = {
    "1" = "172.16.136.6"        # External
    "2" = "172.16.136.70"       # Internal
    "3" = "172.16.136.134"      # HASYNC
    "4" = "172.16.136.198"      # MGMT
  }
}

variable "gateway_ipaddress" {
  type        = "map"
  description = ""

  default = {
    "1" = "172.16.136.1"        # External
    "2" = "172.16.136.65"       # Internal
    "3" = "172.16.136.133"      # HASYNC
    "4" = "172.16.136.193"      # MGMT
  }
}

variable "lb_internal_ipaddress" {
  description = ""

  default = "172.16.136.68"
}

variable "fgt_vmsize" {
  default = "Standard_F4s"
}

##############################################################################################################
# Resource Group
##############################################################################################################

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.PREFIX}-RG"
  location = "${var.LOCATION}"
}

##############################################################################################################

##############################################################################################################
# Retrieve client public IP for Rest API ACL
##############################################################################################################

data "external" "client_public_ip" {
  program = ["sh", "${path.module}/get-public-ip.sh"]
}

output "ip" {
    value = "${data.external.client_public_ip.result["ip"]}"
}
##############################################################################################################

##############################################################################################################
# Generate random key for api usage
##############################################################################################################

resource "random_string" "fgt_api_key" {
  length = 16
  special = true
}
##############################################################################################################
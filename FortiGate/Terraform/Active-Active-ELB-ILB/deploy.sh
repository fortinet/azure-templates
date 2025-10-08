#!/bin/bash
echo "
##############################################################################################################
#
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Microsoft Azure
#
##############################################################################################################
"

# Stop running when command returns error
set -e

##############################################################################################################
# Azure Service Principal
##############################################################################################################
# AZURE_CLIENT_ID=''
# AZURE_CLIENT_SECRET=''
# AZURE_SUBSCRIPTION_ID=''
# AZURE_TENANT_ID=''

##############################################################################################################
# FortiGate variables
#
# FortiGate License type PAYG or BYOL
# Default = PAYG
# FGT_IMAGE_SKU PAYG/ONDEMAND = fortinet_fg-vm_payg_2023
# FGT_IMAGE_SKU BYOL = fortinet_fg-vm
#
# FortiGate version
# Default = latest
#
##############################################################################################################
#export TF_VAR_FGT_IMAGE_SKU=""
#export TF_VAR_FGT_VERSION=""
#export TF_VAR_FGT_BYOL_LICENSE_FILE_A=""
#export TF_VAR_FGT_BYOL_LICENSE_FILE_B=""

PLAN="terraform.tfplan"

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
export TF_VAR_location="$location"
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
        prefix="FORTI"
    fi
else
    prefix="$DEPLOY_PREFIX"
fi
export TF_VAR_prefix="$prefix"
echo ""
echo "--> Using prefix $prefix for all resources ..."
echo ""
rg_cgf="$prefix-RG"

if [ -z "$DEPLOY_USERNAME" ]
then
    # Input username
    echo -n "Enter username (default: azureuser): "
    stty_orig=`stty -g` # save original terminal setting.
    read username         # read the prefix
    stty $stty_orig     # restore terminal setting.
    if [ -z "$USERNAME" ]
    then
        username="azureuser"
    fi
else
    username="$DEPLOY_USERNAME"
fi
echo ""
echo "--> Using username '$username' ..."
echo ""

if [ -z "$DEPLOY_PASSWORD" ]
then
    # Input password
    echo -n "Enter password: "
    stty_orig=`stty -g` # save original terminal setting.
    stty -echo          # turn-off echoing.
    read PASSWORD         # read the password
    stty $stty_orig     # restore terminal setting.
    echo ""
else
    password="$DEPLOY_PASSWORD"
    echo ""
    echo "--> Using password found in env variable DEPLOY_PASSWORD ..."
    echo ""
fi

if [ -z "$DEPLOY_SUBSCRIPTION_ID" ]
then
    detected_id=`az account show | jq ".id" -r`
    # Input username
    echo -n "Enter subscription ID (press enter for detected id: '$detected_id'): "
    stty_orig=`stty -g` # save original terminal setting.
    read subscription_id         # read the subscription id
    stty $stty_orig     # restore terminal setting.
    if [ -z "$subscription_id" ]
    then
        subscription_id="$detected_id"
    fi
else
    subscription_id="$DEPLOY_SUBSCRIPTION_ID"
fi
export TF_VAR_subscription_id="$subscription_id"
echo ""
echo "--> Using subscription id '$subscription_id' ..."
echo ""

SUMMARY="summary.out"

echo ""
echo "==> Starting Terraform deployment"
echo ""
cd terraform/

echo ""
echo "==> Terraform init"
echo ""
terraform init

echo ""
echo "==> Terraform plan"
echo ""
terraform plan --out "$PLAN" \
                -var "username=$username" \
                -var "password=$password"

echo ""
echo "==> Terraform apply"
echo ""
terraform apply "$PLAN"
if [[ $? != 0 ]];
then
    echo "--> ERROR: Deployment failed ..."
    exit $result;
fi

echo ""
echo "==> Terraform output deployment summary"
echo ""
terraform output -raw deployment_summary > "../output/$SUMMARY"

cd ../
cat "output/$SUMMARY"

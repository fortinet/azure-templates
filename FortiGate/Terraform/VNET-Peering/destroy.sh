#!/bin/bash
echo "
##############################################################################################################
#
# Cloud Security Services Hub
# using VNET peering and FortiGate Active/Passive High Availability with Azure Standard Load Balancer - External and Internal
# Fortinet FortiGate Terraform deployment template
#
# Remove the deployed environment based on the state file
#
##############################################################################################################
"

# Stop running when command returns error
set -e

PLAN="terraform.tfplan"

cd terraform/
echo ""
echo "==> Starting Terraform destroy"
echo ""

echo ""
echo "==> Terraform init"
echo ""
terraform init

echo ""
echo "==> terraform destroy"
echo ""
terraform destroy -var "USERNAME=x" -var "PASSWORD=x" -var "PREFIX=x" -auto-approve
if [[ $? != 0 ]];
then
    echo "--> ERROR: Destroy failed ..."
    rg=`grep -m 1 -o '"resource_group_name": "[^"]*' terraform.tfstate | grep -o '[^"]*$'`
    echo "--> Trying to delete the resource group $rg..."
    az group delete --name "$rg"
    exit $rc;
fi

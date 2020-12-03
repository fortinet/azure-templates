#!/bin/bash
echo "
##############################################################################################################
#
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Microsoft Azure
#
# Remove the deployed environment based on the state file
#
##############################################################################################################
"

# Stop running when command returns error
set -e

PLAN="terraform.tfplan"
STATE="terraform.tfstate"

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
terraform destroy -var "USERNAME=x" -var "PASSWORD=x" -var "LOCATION=x" -var "PREFIX=x" -auto-approve
echo "return value: [$?]"
if [[ $? != 0 ]];
then
    echo "--> ERROR: Destroy failed ..."
    rg=`grep -m 1 -o '"resource_group_name": "[^"]*' "$STATE" | grep -o '[^"]*$'`
    echo "--> Trying to delete the resource group $rg..."
    az group delete --resource-group "$rg"
    exit $rc;
fi
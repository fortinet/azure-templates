#!/bin/bash
echo "
################################################################################
#
# Fortinet Quickstart VNET Peering
# 
# Remove the deployed environment based on the state file.
################################################################################
"

# Stop running when command returns error
set -e

STATE="terraform.tfstate"

cd terraform/
echo ""
echo "==> Starting Terraform deployment"
echo ""

echo ""
echo "==> Terraform init"
echo ""
terraform init

echo ""
echo "==> Terraform plan -destroy"
echo ""
terraform plan -var "USERNAME=x" -var "PASSWORD=x" -var "LOCATION=x" -var "PREFIX=x" -destroy

echo ""
echo "==> Terraform destroy"
echo ""
terraform destroy -var "USERNAME=x" -var "PASSWORD=x" -var "LOCATION=x" -var "PREFIX=x" -auto-approve 

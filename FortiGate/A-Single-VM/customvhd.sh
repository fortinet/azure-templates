#!/bin/bash
echo "
##############################################################################################################
#
# Customer VHD
# Download the FortiGate VHD from support.fortinet.com
# Upload VHD to a storage account
# Create an Azure Compute Gallery with an Image and specific Image Version
#
# This can be used for both x86 and ARM version of FortiGate
#
##############################################################################################################

"
# Stop on error
set +e

##############################################################################################################
# Update the below variable to your environment
##############################################################################################################
PREFIX="test"
LOCATION="westeurope"
# ARCHITECTURE: arm64 or x86
ARCHITECTURE="arm64"
# HYPER_V_GENERATION: currenlty FortiGate x86 uses V1, arm64 uses V2
HYPER_V_GENERATION="V2"
# VHD image with path
FORTIGATE_IMAGE_DIRECTORY="$PWD"
FORTIGATE_IMAGE_FILENAME="fortios.vhd"
FORTIGATE_IMAGE_LOCATION="${FORTIGATE_IMAGE_DIRECTORY}/${FORTIGATE_IMAGE_FILENAME}"
FORTIGATE_VERSION="7.2.4"

##############################################################################################################
# Static variables
##############################################################################################################
resource_group="${PREFIX}-rg"
storage_account_name="${PREFIX}imagestorage"
storage_container_name="vhds"
gallery_name="${PREFIX}gallery"
image_definition_name="FortiGate"
offer="fortinet-fortigate-vm_v5"
publisher="fortinet"
sku="fortinet_fg-vm_${ARCHITECTURE}"

# Create resource group
echo ""
echo "--> Creating ${resource_group} resource group ..."
az group create --location "${LOCATION}" --name "${resource_group}"

echo ""
echo "--> Creating ${storage_account_name} storage account ..."
# Create Azure Storage Account to upload the VHD image
az storage account create --resource-group "${resource_group}" --name "${storage_account_name}" --location "${LOCATION}" --sku Standard_LRS

echo ""
echo "--> Creating container and uploading file ${FORTIGATE_IMAGE_LOCATION} to storage account ..."
# Retrieve access key and upload fortios vhd
storage_account_key=$(az storage account keys list --resource-group "${resource_group}" --account-name "${storage_account_name}" --query '[0].value' -o tsv)
az storage container create --name "${storage_container_name}" --account-name "${storage_account_name}" --account-key "${storage_account_key}" --public-access blob
result=$?
if [ $result != 0 ];
then
    echo "--> Deployment failed: unable to create container '${storage_account_name}' in Azure Storage Account [$storage_account_name] ..."
    exit $result
fi
az storage blob upload --account-name "${storage_account_name}" --account-key "${storage_account_key}" --file "${FORTIGATE_IMAGE_LOCATION}" --container-name "${storage_container_name}"
result=$?
if [ $result != 0 ];
then
    echo "--> Deployment failed: unable to upload vhd image to the Azure Storage Account [$storage_account_name] ..."
    exit $result
fi
storage_account_url=$(az storage account show --name "${storage_account_name}" --resource-group "${resource_group}" --query "primaryEndpoints.blob" -o tsv)
vhd_url="${storage_account_url}${storage_container_name}/${FORTIGATE_IMAGE_FILENAME}"

echo ""
echo "--> Creating ${gallery_name} Azure Compute Gallery ..."
# Create Azure Compute Gallery
az sig create --resource-group "${resource_group}" \
	      --gallery-name "${gallery_name}"

echo ""
echo "--> Creating Image Definition ..."
# Create Image definition - publisher, sku and offer can be customized
az sig image-definition create --resource-group "${resource_group}" \
			       --gallery-name "${gallery_name}" \
                   --location "${LOCATION}" \
                   --gallery-image-definition "${image_definition_name}" \
			       --offer "${offer}" \
			       --publisher "${publisher}" \
			       --sku "${sku}" \
			       --os-type linux \
			       --architecture "${ARCHITECTURE}" \
		 	       --hyper-v-generation "${HYPER_V_GENERATION}" \
			       --os-state generalized

echo ""
echo "--> Creating Image Version ..."
# Create an image version. This needs to be available in the region where you want to deploy the FortiGate
az sig image-version create --resource-group "${resource_group}" \
                            --gallery-name "${gallery_name}" \
                            --gallery-image-definition "${image_definition_name}" \
                            --gallery-image-version "${FORTIGATE_VERSION}" \
                            --target-regions "${LOCATION}=1=standard_zrs" \
                            --replica-count 1 \
                            --os-vhd-uri "${vhd_url}" \
                            --os-vhd-storage-account "${storage_account_name}"

echo ""
echo "--> Use the below resource ID to deploy a FortiGate with a custom VHD ..."
az sig image-version show --gallery-image-definition "${image_definition_name}" \
                          --gallery-image-version "${FORTIGATE_VERSION}" \
                          --gallery-name "${gallery_name}" \
                          --resource-group "${resource_group}" \
                          --query "id" -o tsv

exit 0

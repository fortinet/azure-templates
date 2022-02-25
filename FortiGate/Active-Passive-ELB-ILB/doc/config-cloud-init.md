# Configuration at provisioning time

## Cloud init and custom data

Microsoft Azure offers the possibility to inject a configuration during deployment. This method is referred to as Cloud-Init. Both using templates (ARM or Terraform) or via CLI (Powershell, AzureCLI), it is possible to provide a file with this configuration. In the case of FortiGate there are 3 options available.

### Inline configuration file

In this ARM template, a FortiGate configuration is passed via the customdata field used by Azure for the Cloud-Init process. Using variables and parameters you can customize the configuration based on the input provided during deployment. The full configuration injected during deployment with the default parameters can be found [here](config-provisioning.md).

```text
...
    "fgaCustomData": "[base64(concat('config system...
...
  "osProfile": {
...
    "customData": "[variables('fgaCustomData')]"
  },
...
```

### Inline configuration and license file

To provide the configuration and the license during deployment it is required to encode both using MIME. Part 1 will contain the FortiGate configuration and part 2 can contain the FortiGate license file. The code snippet below requires the config and license file content in the respective bold text placeholders.

```text
Content-Type: multipart/mixed; boundary="===============0086047718136476635=="
MIME-Version: 1.0

--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"

<b>Your FortiGate configuration file</b>

--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="${fgt_license_file}"

<b>Your FortiGate license file content</b>

--===============0086047718136476635==--

```

If you want to inject the license file via the AzureCLI, Powershell or via the Azure Portal (Custom Deployment) as a string, you need to remove the newline characters. The string in the 'fortiGateLicenseBYOLA' or 'fortiGateLicenseBYOLB' parameters should be a without newline. To remove the newline or carriage return out of the license file retrieved from Fortinet support you can use the below command:

Bash
```text
$ tr -d '\r\n' < FGVMXXXXXXXXXXXX.lic

-----BEGIN FGT VM LICENSE-----YourLicenseCode-----END FGT VM LICENSE-----
```

Powershell
```text
> (Get-Content 'FGVMXXXXXXXXXXXX.lic') -join ''

-----BEGIN FGT VM LICENSE-----YourLicenseCode-----END FGT VM LICENSE-----
```

### Externally loaded configuration and/or license file

In certain environments it is possible to pull a configuration and license from a central repository. For example an Azure Storage Account or configuration management system. It is possible to provide these instead of the full configuration. The configURI and licenseURI need to be replaced with a HTTP(S) url that is accessible by the FortiGate during deployment.

```text
{
  "config-url": "<b>configURI</b>",
  "license-url": "<b>licenseURI</b>"
}
```

It is recommended to secure the access to the configuration and license file using an SAS token. More information can be found [here](https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview).

## More information

These links give you more information on these provisioning techniques:

- [https://docs.microsoft.com/en-us/azure/virtual-machines/custom-data](https://docs.microsoft.com/en-us/azure/virtual-machines/custom-data)
- [https://docs.fortinet.com/document/fortigate/6.2.0/azure-cookbook/281476/bootstrapping-the-fortigate-cli-at-initial-bootup-using-user-data](https://docs.fortinet.com/document/fortigate/6.2.0/azure-cookbook/281476/bootstrapping-the-fortigate-cli-at-initial-bootup-using-user-data)

## Debugging

After deployment, it is possible to review the cloudinit data on the FortiGate by running the command 'diag debug cloudinit show'

```text
FTNT-FGT-A # diagnose debug cloudinit show
 >> Checking metadata source azure
 >> Azure waiting for customdata file
 >> Azure waiting for customdata file
 >> Azure customdata file found
 >> Azure cloudinit decrypt successfully
 >> MIME parsed config script
 >> MIME parsed VM license
 >> Azure customdata processed successfully
 >> Trying to install vmlicense ...
 >> Run config script
 >> Finish running script
 >> FTNT-FGT-A $  config system sdn-connector
 >> FTNT-FGT-A (sdn-connector) $  edit AzureSDN
 >> FTNT-FGT-A (AzureSDN) $  set type azure
 >> FTNT-FGT-A (AzureSDN) $  next
 >> FTNT-FGT-A (sdn-connector) $  end
 >> FTNT-FGT-A $  config router static
 >> FTNT-FGT-A (static) $  edit 1
...
```

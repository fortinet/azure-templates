# Configuration at provisioning time

## Cloud init and custom data

Microsoft Azure offers, like many other cloud providers, the possibility to inject a configuration during deployment. This method is referred to as Cloud-Init. Both using templates (ARM or Terraform) or via CLI (Powershell, AzureCLI), it is possible to provide a file with this configuration. In the case of FortiGate there are 3 formatting options available.

### Inline configuration file

In this ARM template, a FortiGate configuration is passed via the customdata field used by Azure for the Cloud-Init process. Using variables and parameters you can customize the configuration based on the input provided during deployment. The full configuration injected during deployment with the default parameters can be found at the end of this documentation.

<pre>
...
    "fgaCustomData": "[base64(concat('config system...
...
  "osProfile": {
...
    "customData": "[variables('fgaCustomData')]"
  },
...
</pre>

### Inline configuration and license file

To provide the configuration and the license during deployment it is required to encode both using MIME. Similar to how email is encoded it is possible to pass in one variable both the FortiGate configuration in part 1 and the license file in part 2. The code snippet below requires the config and license file content in the respective bold text placeholders.

<pre>
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

</pre>

### Externally loaded configuration and/or license file

In certain environments it is possible to pull a configuration and license from a central repository. For example an Azure Storage Account or configuration management system. It is possible to provide these instead of the full configuration. The configURI and licenseURI need to be replaced with a HTTP(S) url that is accessible by the FortiGate during deployment.

<pre>
{
  "config-url": "<b>configURI</b>",
  "license-url": "<b>licenseURI</b>"
}
</pre>

## More information

These links give you more information on these provisioning techniques:

  - https://docs.microsoft.com/en-us/azure/virtual-machines/custom-data

  - https://docs.fortinet.com/document/fortigate/6.2.0/azure-cookbook/281476/bootstrapping-the-fortigate-cli-at-initial-bootup-using-user-data

## Debugging

After deployment, it is possible to review the cloudinit data on the FortiGate by running the command 'diag debug cloudinit show'

<pre>
fgtasg-byol300000W # diag debug cloudinit show
>> Run config script
>> Finish running script
>> fgtasg-byol300000W $ config sys interface
>> fgtasg-byol300000W (interface) $ edit "port2"
>> fgtasg-byol300000W (port2) $ set mode dhcp
</pre>
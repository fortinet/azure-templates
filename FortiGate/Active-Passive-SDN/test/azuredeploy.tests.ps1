#Requires -Modules Pester
<#
.SYNOPSIS
    Tests a specific ARM template
.EXAMPLE
    Invoke-Pester
.NOTES
    This file has been created as an example of using Pester to evaluate ARM templates
#>

param (
    [string]$sshkey,
    [string]$sshkeypub
)

BeforeAll {
    $templateName = "Active-Passive-SDN"
    $sourcePath = "$env:GITHUB_WORKSPACE\FortiGate\$templateName"
    $templateFileName = "azuredeploy.json"
    $templateFileLocation = "$sourcePath\$templateFileName"
    $templateMetadataFileName = "metadata.json"
    $templateMetadataFileLocation = "$sourcePath\$templateMetadataFileName"
    $templateParameterFileName = "azuredeploy.parameters.json"
    $templateParameterFileLocation = "$sourcePath\$templateParameterFileName"

    # Basic Variables
    $testsRandom = Get-Random 10001
    $testsPrefix = "FORTIQA"
    $testsResourceGroupName = "FORTIQA-$testsRandom-$templateName"
    $testsAdminUsername = "azureuser"
    $testsResourceGroupLocation = "West Europe"

    # ARM Template Variables
    $config = "config system global `n set gui-theme mariner `n end `n config system admin `n edit devops `n set accprofile super_admin `n set ssh-public-key1 `""
    $config += Get-Content $sshkeypub
    $config += "`" `n set password $testsResourceGroupName `n next `n end"
    $publicIP2Name = "$testsPrefix-FGT-A-MGMT-PIP"
    $publicIP3Name = "$testsPrefix-FGT-B-MGMT-PIP"
    $params = @{ 'adminUsername'=$testsAdminUsername
                 'adminPassword'=$testsResourceGroupName
                 'fortiGateNamePrefix'=$testsPrefix
                 'fortiGateAdditionalCustomData'=$config
                 'publicIP2Name'=$publicIP2Name
                 'publicIP3Name'=$publicIP3Name
               }
    $ports = @(443, 22)
}

Describe 'FGT A/P SDN' {
    Context 'Validation' {
        It 'Has a JSON template' {
            $templateFileLocation | Should -Exist
        }

        It 'Has a parameters file' {
            $templateParameterFileLocation | Should -Exist
        }

        It 'Has a metadata file' {
            $templateMetadataFileLocation | Should -Exist
        }

        It 'Converts from JSON and has the expected properties' {
            $expectedProperties = '$schema',
            'contentVersion',
            'outputs',
            'parameters',
            'resources',
            'variables'
            $templateProperties = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | % Name
            $templateProperties | Should -Be $expectedProperties
        }

        It 'Creates the expected Azure resources' {
            $expectedResources = 'Microsoft.Resources/deployments',
                                 'Microsoft.Storage/storageAccounts',
                                 'Microsoft.Compute/availabilitySets',
                                 'Microsoft.Network/routeTables',
                                 'Microsoft.Network/virtualNetworks',
                                 'Microsoft.Network/networkSecurityGroups',
                                 'Microsoft.Network/publicIPAddresses',
                                 'Microsoft.Network/publicIPAddresses',
                                 'Microsoft.Network/publicIPAddresses',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Compute/virtualMachines',
                                 'Microsoft.Compute/virtualMachines'
            $templateResources = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
            $templateResources | Should -Be $expectedResources
        }

        It 'Contains the expected parameters' {
            $expectedTemplateParameters = 'acceleratedNetworking',
                                          'adminPassword',
                                          'adminUsername',
                                          'availabilityOptions',
                                          'fortiGateAdditionalCustomData',
                                          'fortiGateImageSKU',
                                          'fortiGateImageVersion',
                                          'fortiGateLicenseBYOLA',
                                          'fortiGateLicenseBYOLB',
                                          'fortiGateLicenseFlexVMA',
                                          'fortiGateLicenseFlexVMB',
                                          'fortiGateNamePrefix',
                                          'fortiManager',
                                          'fortiManagerIP',
                                          'fortiManagerSerial',
                                          'fortinetTags',
                                          'instanceType',
                                          'location',
                                          'publicIP1AddressSku',
                                          'publicIP1AddressType',
                                          'publicIP1Name',
                                          'publicIP1NewOrExisting',
                                          'publicIP1ResourceGroup',
                                          'publicIP2AddressSku',
                                          'publicIP2AddressType',
                                          'publicIP2Name',
                                          'publicIP2NewOrExisting',
                                          'publicIP2ResourceGroup',
                                          'publicIP3AddressSKU',
                                          'publicIP3AddressType',
                                          'publicIP3Name',
                                          'publicIP3NewOrExisting',
                                          'publicIP3ResourceGroup',
                                          'serialConsole',
                                          'subnet1Name',
                                          'subnet1Prefix',
                                          'subnet1StartAddress',
                                          'subnet2Name',
                                          'subnet2Prefix',
                                          'subnet2StartAddress',
                                          'subnet3Name',
                                          'subnet3Prefix',
                                          'subnet3StartAddress',
                                          'subnet4Name',
                                          'subnet4Prefix',
                                          'subnet4StartAddress',
                                          'subnet5Name',
                                          'subnet5Prefix',
                                          'vnetAddressPrefix',
                                          'vnetName',
                                          'vnetNewOrExisting',
                                          'vnetResourceGroup'
            $templateParameters = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters | Get-Member -MemberType NoteProperty | % Name | sort
            $templateParameters | Should -Be $expectedTemplateParameters
        }
    }

    Context 'Deployment' {

        It "Test Deployment" {
            New-AzResourceGroup -Name $testsResourceGroupName -Location "$testsResourceGroupLocation"
            (Test-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName" -TemplateFile "$templateFileLocation" -TemplateParameterObject $params).Count | Should -Not -BeGreaterThan 0
        }
        It "Deployment" {
            $resultDeployment = New-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName" -TemplateFile "$templateFileLocation" -TemplateParameterObject $params
            Write-Host ($resultDeployment | Format-Table | Out-String)
            Write-Host ("Deployment state: " + $resultDeployment.ProvisioningState | Out-String)
            $resultDeployment.ProvisioningState | Should -Be "Succeeded"
        }
        It "Search deployment" {
            $result = Get-AzVM | Where-Object { $_.Name -like "$testsPrefix*" }
            Write-Host ($result | Format-Table | Out-String)
            $result | Should -Not -Be $null
        }
    }

    Context 'Deployment test' {

        BeforeAll {
            $fgta = (Get-AzPublicIpAddress -Name $publicIP2Name -ResourceGroupName $testsResourceGroupName).IpAddress
            $fgtb = (Get-AzPublicIpAddress -Name $publicIP3Name -ResourceGroupName $testsResourceGroupName).IpAddress
            Write-Host ("FortiGate A public IP: " + $fgta)
            Write-Host ("FortiGate B public IP: " + $fgtb)
            chmod 400 $sshkey
            $verify_commands = @'
            config system console
            set output standard
            end
            show system interface
            show router static
            diag debug cloudinit show
            exit
'@
            $OFS = "`n"
        }
        It "FGT A: Ports listening" {
            ForEach( $port in $ports ) {
                Write-Host ("Check port: $port" )
                $portListening = (Test-Connection -TargetName $fgta -TCPPort $port -TimeoutSeconds 100)
                $portListening | Should -Be $true
            }
        }
        It "FGT B: Ports listening" {
            ForEach( $port in $ports ) {
                Write-Host ("Check port: $port" )
                $portListening = (Test-Connection -TargetName $fgtb -TCPPort $port -TimeoutSeconds 100)
                $portListening | Should -Be $true
            }
        }
        It "FGT A: Verify configuration" {
            $result = $verify_commands | ssh -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgta
            Write-Host ("Config: " + $result) -Separator `n
        }
        It "FGT B: Verify configuration" {
            $result = $verify_commands | ssh -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgtb
            Write-Host ("Config: " + $result) -Separator `n
        }
    }

    Context 'Cleanup' {
        It "Cleanup of deployment" {
            Remove-AzResourceGroup -Name $testsResourceGroupName -Force
        }
    }
}
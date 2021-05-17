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

$templateName = "A-Single-VM"
$sourcePath = "$env:BUILD_SOURCESDIRECTORY\FortiGate\$templateName"
$scriptPath = "$env:BUILD_SOURCESDIRECTORY\FortiGate\$templateName\test"
$templateFileName = "azuredeploy.json"
$templateFileLocation = "$sourcePath\$templateFileName"
$templateParameterFileName = "azuredeploy.parameters.json"
$templateParameterFileLocation = "$sourcePath\$templateParameterFileName"

# Basic Variables
$testsRandom = Get-Random 10001
$testsPrefix = "FORTIQA"
$testsResourceGroupName = "FORTIQA-$testsRandom-$templateName"
$testsAdminUsername = "azureuser"
$testsResourceGroupLocation = "westeurope"

Describe 'FGT Single VM' {
    Context 'Validation' {
        It 'Has a JSON template' {
            $templateFileLocation | Should Exist
        }

        It 'Has a parameters file' {
            $templateParameterFileLocation | Should Exist
        }

        It 'Converts from JSON and has the expected properties' {
            $expectedProperties = '$schema',
            'contentVersion',
            'parameters',
            'resources',
            'variables'
            $templateProperties = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | % Name
            $templateProperties | Should Be $expectedProperties
        }

        It 'Creates the expected Azure resources' {
            $expectedResources = 'Microsoft.Resources/deployments',
                                 'Microsoft.Network/routeTables',
                                 'Microsoft.Network/virtualNetworks',
                                 'Microsoft.Network/networkSecurityGroups',
                                 'Microsoft.Network/publicIPAddresses',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Network/networkInterfaces',
                                 'Microsoft.Compute/virtualMachines'
            $templateResources = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
            $templateResources | Should Be $expectedResources
        }

        ('acceleratedNetworking', 'adminPassword', 'adminUsername', 'fortiGateAditionalCustomData', 'fortiGateImageSKU', 'fortiGateImageVersion', 'fortiGateLicenseBYOL', 'fortiGateNamePrefix', 'fortiManager', 'fortiManagerIP')
        ('acceleratedNetworking', 'adminPassword', 'adminUsername', 'fortiGateAditionalCustomData', 'fortiGateImageSKU', 'fortiGateImageVersion', 'fortiGateLicenseBYOL', 'fortiGateNamePrefix', 'fortiManager', 'fortiManagerIP')

        It 'Contains the expected parameters' {
            $expectedTemplateParameters = 'acceleratedNetworking',
                                          'adminPassword',
                                          'adminUsername',
                                          'fortiGateAditionalCustomData',
                                          'fortiGateImageSKU',
                                          'fortiGateImageVersion',
                                          'fortiGateLicenseBYOL',
                                          'fortiGateNamePrefix',
                                          'fortiManager',
                                          'fortiManagerIP',
                                          'fortiManagerSerial',
                                          'fortinetTags',
                                          'instanceType',
                                          'location',
                                          'publicIPAddressType',
                                          'publicIPName',
                                          'publicIPNewOrExisting',
                                          'publicIPResourceGroup',
                                          'subnet1Name',
                                          'subnet1Prefix',
                                          'subnet1StartAddress',
                                          'subnet2Name',
                                          'subnet2Prefix',
                                          'subnet2StartAddress',
                                          'subnet3Name',
                                          'subnet3Prefix',
                                          'vnetAddressPrefix',
                                          'vnetName',
                                          'vnetNewOrExisting',
                                          'vnetResourceGroup'
            $templateParameters = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters | Get-Member -MemberType NoteProperty | % Name | Sort-Object
            $templateParameters | Should Be $expectedTemplateParameters
        }

    }

    Context 'Deployment' {

        # Set working directory & create resource group
        Set-Location $sourcePath
        New-AzResourceGroup -Name $testsResourceGroupName -Location "$testsResourceGroupLocation"

        # Validate all ARM templates one by one
        $config = "config system global `n set gui-theme mariner `n end `n config system admin `n edit devops `n set accprofile super_admin `n set ssh-public-key1 `""
        $config += Get-Content $sshkeypub
        $config += "`" `n set password $testsResourceGroupName `n next `n end"

        $params = @{ 'adminUsername'=$testsAdminUsername
                     'adminPassword'=$testsResourceGroupName
                     'fortiGateNamePrefix'=$testsPrefix
                     'fortiGateAditionalCustomData'=$config
                    }
        $publicIPName = "$testsPrefix-FGT-PIP"

        It "Test Deployment" {
            (Test-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName" -TemplateFile "$templateFileName" -TemplateParameterObject $params).Count | Should not BeGreaterThan 0
        }
        It "Deployment" {
            Write-Host ( "Deployment name: $testsResourceGroupName" )

            $resultDeployment = New-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName" -TemplateFile "$templateFileName" -TemplateParameterObject $params
            Write-Host ($resultDeployment | Format-Table | Out-String)
            Write-Host ("Deployment state: " + $resultDeployment.ProvisioningState | Out-String)
            $resultDeployment.ProvisioningState | Should Be "Succeeded"
        }
        It "Search deployment" {
            $result = Get-AzVM | Where-Object { $_.Name -like "$testsPrefix*" }
            Write-Host ($result | Format-Table | Out-String)
            $result | Should Not Be $null
        }

        443, 22 | Foreach-Object {
            it "FGT: Port [$_] is listening" {
                $result = Get-AzPublicIpAddress -Name $publicIPName -ResourceGroupName $testsResourceGroupName
                $portListening = (Test-Connection -TargetName $result.IpAddress -TCPPort $_ -TimeoutSeconds 100)
                $portListening | Should -Be $true

                $fgt = $result.IpAddress
                Write-Host ("Host: " + $fgt)

                Start-Sleep -Seconds 120

                chmod 400 $sshkey
                $verify_commands = @'
                set output standard
                end
                show system interface
                show router static
                exit
'@

                $result = $verify_commands | ssh -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgt
                Write-Output ("Output: " + $result)
                "Output 2: " + $result
                Write-Host ("Output 3: " + $result)

#                $output = sshpass -p "$testsResourceGroupName" ssh -t -o StrictHostKeyChecking=no $testsAdminUsername@$fgt 'show system interface'
#                "Output: " + $output
            }

        }

        It "Cleanup of deployment" {
            Remove-AzResourceGroup -Name $testsResourceGroupName -Force
        }
    }
}

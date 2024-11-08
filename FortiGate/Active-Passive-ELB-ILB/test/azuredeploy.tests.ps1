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
  $templateName = "Active-Passive-ELB-ILB"
  $sourcePath = "$env:GITHUB_WORKSPACE\FortiGate\$templateName"
  $scriptPath = "$env:GITHUB_WORKSPACE\FortiGate\$templateName\test"
  $templateFileName = "azuredeploy.json"
  $templateFileLocation = "$sourcePath\$templateFileName"
  $templateParameterFileName = "azuredeploy.parameters.json"
  $templateParameterFileLocation = "$sourcePath\$templateParameterFileName"

  # Basic Variables
  $testsRandom = Get-Random 10001
  $testsPrefix = "FORTIQA"
  $testsResourceGroupName_x64 = "FORTIQA-$testsRandom-$templateName"
  $testsResourceGroupName_arm64 = "FORTIQA-$testsRandom-$templateName"
  $testsAdminUsername = "azureuser"
  $testsResourceGroupLocation_x64 = "westeurope"
  $testsResourceGroupLocation_arm64 = "westeurop3"

  # ARM Template Variables
  $config = "config system console `n set output standard `n end `n config system global `n set gui-theme mariner `n end `n config system admin `n edit devops `n set accprofile super_admin `n set ssh-public-key1 `""
  $config += Get-Content $sshkeypub
  $config += "`" `n set password $testsResourceGroupName_x64 `n next `n end"
  $publicIP2Name = "$testsPrefix-FGT-A-MGMT-PIP"
  $publicIP3Name = "$testsPrefix-FGT-B-MGMT-PIP"
  $params_x64 = @{ 'adminUsername'  = $testsAdminUsername
    'adminPassword'                 = $testsResourceGroupName_x64
    'fortiGateNamePrefix'           = $testsPrefix
    'fortiGateAdditionalCustomData' = $config
    'publicIP2Name'                 = $publicIP2Name
    'publicIP3Name'                 = $publicIP3Name
  }
  $params_arm64 = @{ 'adminUsername' = $testsAdminUsername
    'adminPassword'                  = $testsResourceGroupName_x64
    'fortiGateNamePrefix'            = $testsPrefix
    'fortiGateAdditionalCustomData'  = $config
    'publicIP2Name'                  = $publicIP2Name
    'publicIP3Name'                  = $publicIP3Name
    'fortiGateInstanceArchitecture'  = 'arm64'
  }
  $ports = @(443, 22)
}

Describe 'FGT A/P LB' {
  Context 'Validation' {
    It 'Has a JSON template' {
      $templateFileLocation | Should -Exist
    }

    It 'Has a parameters file' {
      $templateParameterFileLocation | Should -Exist
    }

    It 'Converts from JSON and has the expected properties' {
      $expectedProperties = '$schema',
      'contentVersion',
      'outputs',
      'parameters',
      'resources',
      'variables'
      $templateProperties = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | % Name
      $diff = ( Compare-Object -ReferenceObject $expectedProperties -DifferenceObject $templateProperties | Format-Table | Out-String )
      if ($diff) { Write-Host ( "Diff: $diff" ) }
      $templateProperties | Should -Be $expectedProperties
    }

    It 'Creates the expected Azure resources' {
      $expectedResources = 'Microsoft.Resources/deployments',
      'Microsoft.Compute/availabilitySets',
      'Microsoft.Network/virtualNetworks',
      'Microsoft.Network/routeTables',
      'Microsoft.Network/networkSecurityGroups',
      'Microsoft.Network/publicIPAddresses',
      'Microsoft.Network/publicIPAddresses',
      'Microsoft.Network/publicIPAddresses',
      'Microsoft.Network/loadBalancers',
      'Microsoft.Network/loadBalancers',
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
      $diff = ( Compare-Object -ReferenceObject $expectedResources -DifferenceObject $templateResources | Format-Table | Out-String )
      if ($diff) { Write-Host ( "Diff: $diff" ) }
      $templateResources | Should -Be $expectedResources
    }

    It 'Contains the expected parameters' {
      $expectedTemplateParameters = 'acceleratedConnections',
      'acceleratedConnectionsSku',
      'acceleratedNetworking',
      'adminPassword',
      'adminUsername',
      'availabilityOptions',
      'customImageReference',
      'fortiGateAdditionalCustomData',
      'fortiGateImageSKU_arm64',
      'fortiGateImageSKU_x64',
      'fortiGateImageVersion_arm64',
      'fortiGateImageVersion_x64',
      'fortiGateInstanceArchitecture',
      'fortiGateLicenseBYOLA',
      'fortiGateLicenseBYOLB',
      'fortiGateLicenseFortiFlexA',
      'fortiGateLicenseFortiFlexB',
      'fortiGateNamePrefix',
      'fortiManager',
      'fortiManagerIP',
      'fortiManagerSerial',
      'fortinetTags',
      'instanceType_arm64',
      'instanceType_x64',
      'location',
      'publicIP1Name',
      'publicIP1NewOrExisting',
      'publicIP1ResourceGroup',
      'publicIP2Name',
      'publicIP2NewOrExisting',
      'publicIP2ResourceGroup',
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
      'tagsByResource',
      'vnetAddressPrefix',
      'vnetName',
      'vnetNewOrExisting',
      'vnetResourceGroup'
      $templateParameters = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters | Get-Member -MemberType NoteProperty | % Name | sort
      $diff = ( Compare-Object -ReferenceObject $expectedTemplateParameters -DifferenceObject $templateParameters | Format-Table | Out-String )
      if ($diff) { Write-Host ( "Diff: $diff" ) }
      $templateParameters | Should -Be $expectedTemplateParameters
    }
  }

  Context 'Deployment x64' {

    It "Test Deployment" {
      New-AzResourceGroup -Name $testsResourceGroupName_x64 -Location "$testsResourceGroupLocation_x64"
            (Test-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName_x64" -TemplateFile "$templateFileLocation" -TemplateParameterObject $params_x64).Count | Should -Not -BeGreaterThan 0
    }
    It "Deployment" {
      $resultDeployment = New-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName_x64" -TemplateFile "$templateFileLocation" -TemplateParameterObject $params_x64
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

  Context 'Deployment test x64' {

    BeforeAll {
      $fgta = (Get-AzPublicIpAddress -Name $publicIP2Name -ResourceGroupName $testsResourceGroupName_x64).IpAddress
      $fgtb = (Get-AzPublicIpAddress -Name $publicIP3Name -ResourceGroupName $testsResourceGroupName_x64).IpAddress
      Write-Host ("FortiGate A public IP: " + $fgta)
      Write-Host ("FortiGate B public IP: " + $fgtb)
      chmod 400 $sshkey
      $verify_commands = @'
            get system status
            show system interface
            show router static
            diag debug cloudinit show
            exit
'@
      $OFS = "`n"
    }
    It "FGT A: Ports listening" {
      ForEach ( $port in $ports ) {
        $portListening = (Test-Connection -TargetName $fgta -TCPPort $port -TimeoutSeconds 100)
        $portListening | Should -Be $true
        Write-Host ("Check port - $port : " + $portListening )
      }
    }
    It "FGT B: Ports listening" {
      ForEach ( $port in $ports ) {
        $portListening = (Test-Connection -TargetName $fgtb -TCPPort $port -TimeoutSeconds 100)
        $portListening | Should -Be $true
        Write-Host ("Check port - $port : " + $portListening )
      }
    }
    It "FGT A: Verify configuration" {
      $result = $verify_commands | ssh -v -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgta
      $LASTEXITCODE | Should -Be "0"
      Write-Host ("FGT CLI info: " + $result) -Separator `n
      $result | Should -Not -BeLike "*Command fail*"
    }
    It "FGT B: Verify configuration" {
      $result = $verify_commands | ssh -v -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgtb
      $LASTEXITCODE | Should -Be "0"
      Write-Host ("Config: " + $result) -Separator `n
      $result | Should -Not -BeLike "*Command fail*"
    }
  }

  Context 'Cleanup x64' {
    It "Cleanup of deployment" {
      Remove-AzResourceGroup -Name $testsResourceGroupName_x64 -Force
    }
  }
}

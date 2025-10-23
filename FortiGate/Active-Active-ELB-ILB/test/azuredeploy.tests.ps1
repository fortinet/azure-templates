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
  $templateName = "Active-Active-ELB-ILB"
  $sourcePath = "$env:GITHUB_WORKSPACE\FortiGate\$templateName"
  $scriptPath = "$env:GITHUB_WORKSPACE\FortiGate\$templateName\test"
  $templateFileName = "azuredeploy.json"
  $templateFileLocation = "$sourcePath\$templateFileName"
  $templateParameterFileName = "azuredeploy.parameters.json"
  $templateParameterFileLocation = "$sourcePath\$templateParameterFileName"

  # Basic Variables
  $testsRandom = Get-Random 10001
  $testsPrefix = "FORTIQA"
  $testsResourceGroupName_x64 = "FORTIQA-$testsRandom-$templateName-x64"
  $testsResourceGroupName_x64_g2 = "FORTIQA-$testsRandom-$templateName-x64_g2"
  $testsResourceGroupName_arm64 = "FORTIQA-$testsRandom-$templateName-arm64"
  $testsAdminUsername = "azureuser"
  $testsResourceGroupLocation_x64 = "westeurope"
  $testsResourceGroupLocation_x64_g2 = "francecentral"
  $testsResourceGroupLocation_arm64 = "francecentral"

  # ARM Template Variables
  $config = "config system console `n set output standard `n end `n config system global `n set gui-theme mariner `n end `n config system admin `n edit devops `n set accprofile super_admin `n set ssh-public-key1 `""
  $config += Get-Content $sshkeypub
  $config += "`" `n set password $testsResourceGroupName_x64 `n next `n end"
  $publicIPName = "$testsPrefix-externalloadbalancer-pip"
  $fortiGateCount = 3
  $params_x64 = @{ 'adminUsername'  = $testsAdminUsername
    'adminPassword'                 = $testsResourceGroupName_x64
    'fortiGateNamePrefix'           = $testsPrefix
    'fortiGateAdditionalCustomData' = $config
    'fortiGateCount'                = $fortiGateCount
  }
  $params_x64_g2 = @{ 'adminUsername'  = $testsAdminUsername
    'adminPassword'                 = $testsResourceGroupName_x64_g2
    'fortiGateNamePrefix'           = $testsPrefix
    'fortiGateAdditionalCustomData' = $config
    'fortiGateCount'                = $fortiGateCount
    'fortiGateInstanceArchitecture' = 'x64_g2'
  }
  $params_arm64 = @{ 'adminUsername' = $testsAdminUsername
    'adminPassword'                  = $testsResourceGroupName_arm64
    'fortiGateNamePrefix'            = $testsPrefix
    'fortiGateAdditionalCustomData'  = $config
    'fortiGateCount'                 = $fortiGateCount
    'fortiGateInstanceArchitecture'  = 'arm64'
  }
  $ports = @(40030, 50030, 40031, 50031)
}

Describe 'FGT A/A' {
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
      'functions',
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
      'Microsoft.Network/virtualNetworks/subnets',
      'Microsoft.Network/natGateways',
      'Microsoft.Network/routeTables',
      'Microsoft.Network/networkSecurityGroups',
      'Microsoft.Network/publicIPAddresses',
      'Microsoft.Network/publicIPAddresses',
      'Microsoft.Network/publicIPAddresses',
      'Microsoft.Network/loadBalancers',
      'Microsoft.Network/loadBalancers/inboundNatRules',
      'Microsoft.Network/loadBalancers/inboundNatRules',
      'Microsoft.Network/loadBalancers',
      'Microsoft.Network/networkInterfaces',
      'Microsoft.Network/networkInterfaces',
      'Microsoft.Compute/virtualMachines'
      $templateResources = (get-content $templateFileLocation | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
      $diff = ( Compare-Object -ReferenceObject $expectedResources -DifferenceObject $templateResources | Format-Table | Out-String )
      if ($diff) { Write-Host ( "Diff: $diff" ) }
      $templateResources | Should -Be $expectedResources
    }

    It 'Contains the expected parameters' {
      $expectedTemplateParameters = '1nicDeployment',
      'acceleratedConnections',
      'acceleratedConnectionsSku',
      'acceleratedNetworking',
      'adminPassword',
      'adminUsername',
      'availabilityOptions',
      'customImageReference',
      'externalLoadBalancer',
      'fortiGateAdditionalCustomData',
      'fortiGateCount',
      'fortiGateImageSKU_arm64',
      'fortiGateImageSKU_x64',
      'fortiGateImageSKU_x64_g2',
      'fortiGateImageVersion_arm64',
      'fortiGateImageVersion_x64',
      'fortiGateImageVersion_x64_g2',
      'fortiGateInstanceArchitecture',
      'fortiGateLicenseBYOL1',
      'fortiGateLicenseBYOL2',
      'fortiGateLicenseBYOL3',
      'fortiGateLicenseBYOL4',
      'fortiGateLicenseBYOL5',
      'fortiGateLicenseBYOL6',
      'fortiGateLicenseBYOL7',
      'fortiGateLicenseBYOL8',
      'fortiGateLicenseFortiFlex1',
      'fortiGateLicenseFortiFlex2',
      'fortiGateLicenseFortiFlex3',
      'fortiGateLicenseFortiFlex4',
      'fortiGateLicenseFortiFlex5',
      'fortiGateLicenseFortiFlex6',
      'fortiGateLicenseFortiFlex7',
      'fortiGateLicenseFortiFlex8',
      'fortiGateNamePrefix',
      'fortiGateProbeResponse',
      'fortiGateSessionSync',
      'fortiManager',
      'fortiManagerIP',
      'fortiManagerSerial',
      'fortinetTags',
      'instanceType_arm64',
      'instanceType_x64',
      'instanceType_x64_g2',
      'location',
      'outboundConnectivity',
      'serialConsole',
      'subnet1Name',
      'subnet1Prefix',
      'subnet1StartAddress',
      'subnet2Name',
      'subnet2Prefix',
      'subnet2StartAddress',
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

    It "Test deployment" {
      New-AzResourceGroup -Name $testsResourceGroupName_x64 -Location "$testsResourceGroupLocation_x64"
      $result = Test-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName_x64" -TemplateFile "$templateFileLocation" -TemplateParameterObject $params_x64
      Write-Host ($result | Format-Table -Wrap -Autosize | Out-String)
      $result.Count | Should -Not -BeGreaterThan 0
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
      $fgt = (Get-AzPublicIpAddress -Name $publicIPName -ResourceGroupName $testsResourceGroupName_x64).IpAddress
      Write-Host ("FortiGate public IP: " + $fgt)
      $verify_commands = @'
            get system status
            show system interface
            show router static
            diag debug cloudinit show
            exit
'@
      $OFS = "`n"
    }
    It "FGT: Ports listening" {
      ForEach ( $port in $ports ) {
        Write-Host ("Check port: $port" )
        $portListening = (Test-Connection -TargetName $fgt -TCPPort $port -TimeoutSeconds 100)
        $portListening | Should -Be $true
      }
    }
    It "FGT A: Verify configuration" {
      $result = $verify_commands | ssh -p 50030 -v -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgt
      $LASTEXITCODE | Should -Be "0"
      Write-Host ("FGT CLI info: " + $result) -Separator `n
      $result | Should -Not -BeLike "*Command fail*"
    }
    It "FGT B: Verify configuration" {
      $result = $verify_commands | ssh -p 50031 -v -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgt
      $LASTEXITCODE | Should -Be "0"
      Write-Host ("FGT CLI info: " + $result) -Separator `n
      $result | Should -Not -BeLike "*Command fail*"
    }
  }

  Context 'Cleanup x64' {
    It "Cleanup of deployment" {
      Remove-AzResourceGroup -Name $testsResourceGroupName_x64 -Force
    }
  }
Context 'Deployment x64_g2' {

    It "Test deployment" {
      New-AzResourceGroup -Name $testsResourceGroupName_x64_g2 -Location "$testsResourceGroupLocation_x64_g2"
      $result = Test-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName_x64_g2" -TemplateFile "$templateFileLocation" -TemplateParameterObject $params_x64_g2
      Write-Host ($result | Format-Table -Wrap -Autosize | Out-String)
      $result.Count | Should -Not -BeGreaterThan 0
    }
    It "Deployment" {
      $resultDeployment = New-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName_x64_g2" -TemplateFile "$templateFileLocation" -TemplateParameterObject $params_x64_g2
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

  Context 'Deployment test x64_g2' {

    BeforeAll {
      $fgt = (Get-AzPublicIpAddress -Name $publicIPName -ResourceGroupName $testsResourceGroupName_x64_g2).IpAddress
      Write-Host ("FortiGate public IP: " + $fgt)
      $verify_commands = @'
            get system status
            show system interface
            show router static
            diag debug cloudinit show
            exit
'@
      $OFS = "`n"
    }
    It "FGT: Ports listening" {
      ForEach ( $port in $ports ) {
        Write-Host ("Check port: $port" )
        $portListening = (Test-Connection -TargetName $fgt -TCPPort $port -TimeoutSeconds 100)
        $portListening | Should -Be $true
      }
    }
    It "FGT A: Verify configuration" {
      $result = $verify_commands | ssh -p 50030 -v -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgt
      $LASTEXITCODE | Should -Be "0"
      Write-Host ("FGT CLI info: " + $result) -Separator `n
      $result | Should -Not -BeLike "*Command fail*"
    }
    It "FGT B: Verify configuration" {
      $result = $verify_commands | ssh -p 50031 -v -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgt
      $LASTEXITCODE | Should -Be "0"
      Write-Host ("FGT CLI info: " + $result) -Separator `n
      $result | Should -Not -BeLike "*Command fail*"
    }
  }

  Context 'Cleanup x64_g2' {
    It "Cleanup of deployment" {
      Remove-AzResourceGroup -Name $testsResourceGroupName_x64_g2 -Force
    }
  }
Context 'Deployment arm64' {

    It "Test deployment" {
      New-AzResourceGroup -Name $testsResourceGroupName_arm64 -Location "$testsResourceGroupLocation_arm64"
      $result = Test-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName_arm64" -TemplateFile "$templateFileLocation" -TemplateParameterObject $params_arm64
      Write-Host ($result | Format-Table -Wrap -Autosize | Out-String)
      $result.Count | Should -Not -BeGreaterThan 0
    }
    It "Deployment" {
      $resultDeployment = New-AzResourceGroupDeployment -ResourceGroupName "$testsResourceGroupName_arm64" -TemplateFile "$templateFileLocation" -TemplateParameterObject $params_arm64
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

  Context 'Deployment test arm64' {

    BeforeAll {
      $fgt = (Get-AzPublicIpAddress -Name $publicIPName -ResourceGroupName $testsResourceGroupName_arm64).IpAddress
      Write-Host ("FortiGate public IP: " + $fgt)
      $verify_commands = @'
            get system status
            show system interface
            show router static
            diag debug cloudinit show
            exit
'@
      $OFS = "`n"
    }
    It "FGT: Ports listening" {
      ForEach ( $port in $ports ) {
        Write-Host ("Check port: $port" )
        $portListening = (Test-Connection -TargetName $fgt -TCPPort $port -TimeoutSeconds 100)
        $portListening | Should -Be $true
      }
    }
    It "FGT A: Verify configuration" {
      $result = $verify_commands | ssh -p 50030 -v -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgt
      $LASTEXITCODE | Should -Be "0"
      Write-Host ("FGT CLI info: " + $result) -Separator `n
      $result | Should -Not -BeLike "*Command fail*"
    }
    It "FGT B: Verify configuration" {
      $result = $verify_commands | ssh -p 50031 -v -tt -i $sshkey -o StrictHostKeyChecking=no devops@$fgt
      $LASTEXITCODE | Should -Be "0"
      Write-Host ("FGT CLI info: " + $result) -Separator `n
      $result | Should -Not -BeLike "*Command fail*"
    }
  }

  Context 'Cleanup arm64' {
    It "Cleanup of deployment" {
      Remove-AzResourceGroup -Name $testsResourceGroupName_arm64 -Force
    }
  }
}

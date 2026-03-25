#Requires -Modules Pester
<#
.SYNOPSIS
    Pester v5 tests for the Active-Passive-ELB-ILB Legacy ARM template
.DESCRIPTION
    Validates the template structure, deploys to Azure, and verifies both FortiGates are
    reachable on their individual management public IPs. Run one scenario per invocation
    (x64, x64_g2, arm64) so that matrix jobs in GitHub Actions can execute all three
    in parallel.
    The legacy template uses the fortinet_fortigate-vm_v5 image offer and separate
    per-architecture SKU parameters instead of the combined fortiGateLicenseType.
.EXAMPLE
    Invoke-Pester
    ./test/Invoke-Tests.ps1 -Scenario x64_g2
#>

param (
    [string]$sshkey    = "",
    [string]$sshkeypub = "",
    [ValidateSet('x64', 'x64_g2', 'arm64')]
    [string]$scenario  = "x64"
)

BeforeAll {
    $templateName = "Active-Passive-ELB-ILB"

    # Resolve source path — works both in GitHub Actions and locally
    $sourcePath = if ($env:GITHUB_WORKSPACE) {
        "$env:GITHUB_WORKSPACE/FortiGate/$templateName/legacy"
    } else {
        (Resolve-Path "$PSScriptRoot/..").Path
    }

    $templateFileLocation = "$sourcePath/azuredeploy.json"

    # Unique prefix per run to avoid resource name collisions
    $testsRandom        = Get-Random 10001
    $testsPrefix        = "FORTIQA"
    $testsAdminUsername = "azureuser"

    # Resource names derived from template variable defaults
    $fgtaVmName    = "$testsPrefix-FGT-A"
    $fgtbVmName    = "$testsPrefix-FGT-B"
    $publicIP2Name = "$testsPrefix-fgt-a-mgmt-pip"
    $publicIP3Name = "$testsPrefix-fgt-b-mgmt-pip"

    # Scenario-specific location and resource group
    switch ($scenario) {
        'x64' {
            $testsResourceGroupLocation = "westeurope"
            $testsResourceGroupName     = "FORTIQA-$testsRandom-$templateName-legacy-x64"
        }
        'x64_g2' {
            $testsResourceGroupLocation = "francecentral"
            $testsResourceGroupName     = "FORTIQA-$testsRandom-$templateName-legacy-x64_g2"
        }
        'arm64' {
            $testsResourceGroupLocation = "francecentral"
            $testsResourceGroupName     = "FORTIQA-$testsRandom-$templateName-legacy-arm64"
        }
    }

    # FortiGate cloud-init: add a devops admin with the test SSH public key
    $config = ""
    if ($sshkeypub -and (Test-Path $sshkeypub)) {
        $pubkey  = Get-Content $sshkeypub
        $config  = "config system console`nset output standard`nend`n"
        $config += "config system global`nset gui-theme mariner`nend`n"
        $config += "config system admin`nedit devops`nset accprofile super_admin`n"
        $config += "set ssh-public-key1 `"$pubkey`"`n"
        $config += "set password $testsResourceGroupName`nnext`nend"
    }

    $params = @{
        adminUsername                 = $testsAdminUsername
        adminPassword                 = $testsResourceGroupName
        fortiGateNamePrefix           = $testsPrefix
        fortiGateAdditionalCustomData = $config
    }

    # Legacy template uses 'x64', 'x64_g2', 'arm64' for fortiGateInstanceArchitecture
    switch ($scenario) {
        'x64_g2' { $params['fortiGateInstanceArchitecture'] = 'x64_g2' }
        'arm64'  { $params['fortiGateInstanceArchitecture'] = 'arm64'  }
    }
}

AfterAll {
    if ($testsResourceGroupName -and
        (Get-AzResourceGroup -Name $testsResourceGroupName -ErrorAction SilentlyContinue)) {
        Write-Host "Cleaning up resource group: $testsResourceGroupName"
        Remove-AzResourceGroup -Name $testsResourceGroupName -Force
    }
}

Describe "FGT Active-Passive ELB-ILB Legacy - $scenario" {

    Context 'Validation' {

        It 'Has a JSON template' {
            $templateFileLocation | Should -Exist
        }

        It 'Converts from JSON and has the expected top-level properties' {
            $expectedProperties = '$schema', 'contentVersion', 'outputs', 'parameters', 'resources', 'variables'
            $templateProperties = (Get-Content $templateFileLocation |
                ConvertFrom-Json -ErrorAction SilentlyContinue) |
                Get-Member -MemberType NoteProperty | ForEach-Object Name
            $diff = Compare-Object -ReferenceObject $expectedProperties -DifferenceObject $templateProperties |
                Format-Table | Out-String
            if ($diff.Trim()) { Write-Host "Diff: $diff" }
            $templateProperties | Should -Be $expectedProperties
        }

        It 'Declares the expected Azure resource types' {
            $expectedResources = @(
                'Microsoft.Resources/deployments',
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
            )
            $templateResources = (Get-Content $templateFileLocation |
                ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
            $diff = Compare-Object -ReferenceObject $expectedResources -DifferenceObject $templateResources |
                Format-Table | Out-String
            if ($diff.Trim()) { Write-Host "Diff: $diff" }
            $templateResources | Should -Be $expectedResources
        }

        It 'Contains the expected parameters' {
            $expectedTemplateParameters = @(
                'acceleratedConnections',
                'acceleratedConnectionsSku',
                'acceleratedNetworking',
                'adminPassword',
                'adminUsername',
                'availabilityOptions',
                'customImageReference',
                'fortiGateAdditionalCustomData',
                'fortiGateImageSKU_arm64',
                'fortiGateImageSKU_x64',
                'fortiGateImageSKU_x64_g2',
                'fortiGateImageVersion_arm64',
                'fortiGateImageVersion_x64',
                'fortiGateImageVersion_x64_g2',
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
                'instanceType_x64_g2',
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
            )
            $templateParameters = (Get-Content $templateFileLocation |
                ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters |
                Get-Member -MemberType NoteProperty | ForEach-Object Name | Sort-Object
            $diff = Compare-Object -ReferenceObject $expectedTemplateParameters -DifferenceObject $templateParameters |
                Format-Table | Out-String
            if ($diff.Trim()) { Write-Host "Diff: $diff" }
            $templateParameters | Should -Be $expectedTemplateParameters
        }
    }

    Context "Deployment - $scenario" {

        It 'ARM template validation passes' {
            New-AzResourceGroup -Name $testsResourceGroupName -Location $testsResourceGroupLocation
            $result = Test-AzResourceGroupDeployment `
                -ResourceGroupName $testsResourceGroupName `
                -TemplateFile $templateFileLocation `
                -TemplateParameterObject $params
            Write-Host ($result | Format-Table -Wrap -AutoSize | Out-String)
            $result.Count | Should -Not -BeGreaterThan 0
        }

        It 'ARM template deploys successfully' {
            $script:deployment = New-AzResourceGroupDeployment `
                -ResourceGroupName $testsResourceGroupName `
                -TemplateFile $templateFileLocation `
                -TemplateParameterObject $params
            Write-Host ("Provisioning state: " + $script:deployment.ProvisioningState)
            $script:deployment.ProvisioningState | Should -Be "Succeeded"
        }

        It 'FortiGate-A VM exists in the resource group' {
            $vm = Get-AzVM -ResourceGroupName $testsResourceGroupName -Name $fgtaVmName
            Write-Host ($vm | Format-Table | Out-String)
            $vm | Should -Not -Be $null
        }

        It 'FortiGate-B VM exists in the resource group' {
            $vm = Get-AzVM -ResourceGroupName $testsResourceGroupName -Name $fgtbVmName
            Write-Host ($vm | Format-Table | Out-String)
            $vm | Should -Not -Be $null
        }
    }

    Context "Connectivity - $scenario" {

        BeforeAll {
            # Use deployment outputs for management public IPs
            $script:fgta = if ($script:deployment -and $script:deployment.Outputs['fortiGateAManagementPublicIP']) {
                $script:deployment.Outputs['fortiGateAManagementPublicIP'].Value
            } else {
                (Get-AzPublicIpAddress -Name $publicIP2Name -ResourceGroupName $testsResourceGroupName).IpAddress
            }
            $script:fgtb = if ($script:deployment -and $script:deployment.Outputs['fortiGateBManagementPublicIP']) {
                $script:deployment.Outputs['fortiGateBManagementPublicIP'].Value
            } else {
                (Get-AzPublicIpAddress -Name $publicIP3Name -ResourceGroupName $testsResourceGroupName).IpAddress
            }
            Write-Host "FortiGate-A management IP: $($script:fgta)"
            Write-Host "FortiGate-B management IP: $($script:fgtb)"

            $script:verify_commands = @'
get system status
show system interface
show router static
diag debug cloudinit show
exit
'@
        }

        It 'FGT-A: port <port> is reachable' -ForEach @(
            @{ port = 443 },
            @{ port = 22  }
        ) {
            $listening = Test-Connection -TargetName $script:fgta -TCPPort $port -TimeoutSeconds 100
            $listening | Should -Be $true
        }

        It 'FGT-B: port <port> is reachable' -ForEach @(
            @{ port = 443 },
            @{ port = 22  }
        ) {
            $listening = Test-Connection -TargetName $script:fgtb -TCPPort $port -TimeoutSeconds 100
            $listening | Should -Be $true
        }

        It 'SSH: FGT-A configuration applied correctly' {
            $result = $script:verify_commands | ssh -tt -i $sshkey -o StrictHostKeyChecking=no devops@$($script:fgta)
            $LASTEXITCODE | Should -Be 0
            Write-Host ("FGT-A CLI output:`n" + ($result -join "`n"))
            $result | Should -Not -BeLike "*Command fail*"
        }

        It 'SSH: FGT-B configuration applied correctly' {
            $result = $script:verify_commands | ssh -tt -i $sshkey -o StrictHostKeyChecking=no devops@$($script:fgtb)
            $LASTEXITCODE | Should -Be 0
            Write-Host ("FGT-B CLI output:`n" + ($result -join "`n"))
            $result | Should -Not -BeLike "*Command fail*"
        }
    }
}

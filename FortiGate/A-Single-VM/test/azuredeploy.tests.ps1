#Requires -Modules Pester
<#
.SYNOPSIS
    Pester v5 tests for the A-Single-VM ARM template
.DESCRIPTION
    Validates the template structure, deploys to Azure, and verifies the FortiGate is
    reachable. Run one scenario per invocation (x64, x64_g2, arm64) so that matrix
    jobs in GitHub Actions can execute all three in parallel.
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
    $templateName = "A-Single-VM"

    # Resolve source path — works both in GitHub Actions and locally
    $sourcePath = if ($env:GITHUB_WORKSPACE) {
        "$env:GITHUB_WORKSPACE/FortiGate/$templateName"
    } else {
        (Resolve-Path "$PSScriptRoot/..").Path
    }

    $templateFileLocation          = "$sourcePath/azuredeploy.json"
    $templateParameterFileLocation = "$sourcePath/azuredeploy.parameters.json"

    # Unique prefix per run to avoid resource name collisions
    $testsRandom             = Get-Random 10001
    $testsPrefix             = "FORTIQA"
    $testsAdminUsername      = "azureuser"
    $fgtVmName               = "$testsPrefix-fgt"
    $publicIPName            = "$testsPrefix-fgt-pip"

    # Scenario-specific location and ARM parameters
    switch ($scenario) {
        'x64' {
            $testsResourceGroupLocation = "westeurope"
            $testsResourceGroupName     = "FORTIQA-$testsRandom-$templateName-x64"
        }
        'x64_g2' {
            $testsResourceGroupLocation = "francecentral"
            $testsResourceGroupName     = "FORTIQA-$testsRandom-$templateName-x64_g2"
        }
        'arm64' {
            $testsResourceGroupLocation = "francecentral"
            $testsResourceGroupName     = "FORTIQA-$testsRandom-$templateName-arm64"
        }
    }

    # FortiGate cloud-init: add a devops admin with the test SSH public key
    $config = ""
    if ($sshkeypub -and (Test-Path $sshkeypub)) {
        $pubkey = Get-Content $sshkeypub
        $config  = "config system console`nset output standard`nend`n"
        $config += "config system global`nset gui-theme mariner`nend`n"
        $config += "config system admin`nedit devops`nset accprofile super_admin`n"
        $config += "set ssh-public-key1 `"$pubkey`"`n"
        $config += "set password $testsResourceGroupName`nnext`nend"
    }

    $params = @{
        adminUsername               = $testsAdminUsername
        adminPassword               = $testsResourceGroupName
        fortiGateNamePrefix         = $testsPrefix
        fortiGateAdditionalCustomData = $config
    }

    switch ($scenario) {
        'x64_g2' { $params['fortiGateInstanceArchitecture'] = '_g2'    }
        'arm64'  { $params['fortiGateInstanceArchitecture'] = '_arm64' }
    }
}

AfterAll {
    if ($testsResourceGroupName -and
        (Get-AzResourceGroup -Name $testsResourceGroupName -ErrorAction SilentlyContinue)) {
        Write-Host "Cleaning up resource group: $testsResourceGroupName"
        Remove-AzResourceGroup -Name $testsResourceGroupName -Force
    }
}

Describe "FGT Single VM - $scenario" {

    Context 'Validation' {

        It 'Has a JSON template' {
            $templateFileLocation | Should -Exist
        }

        It 'Has a parameters file' {
            $templateParameterFileLocation | Should -Exist
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
                'Microsoft.Network/networkInterfaces',
                'Microsoft.Network/networkInterfaces',
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
                'availabilityZoneNumber',
                'customImageReference',
                'customVHDSource',
                'existingAvailabilitySetName',
                'fortiGateAdditionalCustomData',
                'fortiGateImageVersion_arm64',
                'fortiGateImageVersion_x64',
                'fortiGateImageVersion_x64_g2',
                'fortiGateInstanceArchitecture',
                'fortiGateLicenseBYOL',
                'fortiGateLicenseFortiFlex',
                'fortiGateLicenseType',
                'fortiGateName',
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
                'serialConsole',
                'subnet1Name',
                'subnet1Prefix',
                'subnet1StartAddress',
                'subnet2Name',
                'subnet2Prefix',
                'subnet2StartAddress',
                'subnet3Name',
                'subnet3Prefix',
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

        It 'FortiGate VM exists in the resource group' {
            $vm = Get-AzVM -ResourceGroupName $testsResourceGroupName -Name $fgtVmName
            Write-Host ($vm | Format-Table | Out-String)
            $vm | Should -Not -Be $null
        }
    }

    Context "Connectivity - $scenario" {

        BeforeAll {
            # Prefer the deployment output; fall back to a direct lookup
            $script:fgtPublicIP = if ($script:deployment -and $script:deployment.Outputs['fortiGatePublicIP']) {
                $script:deployment.Outputs['fortiGatePublicIP'].Value
            } else {
                (Get-AzPublicIpAddress -Name $publicIPName -ResourceGroupName $testsResourceGroupName).IpAddress
            }
            Write-Host "FortiGate public IP: $($script:fgtPublicIP)"

            $script:verify_commands = @'
get system status
show system interface
show router static
diag debug cloudinit show
exit
'@
        }

        It 'HTTPS (443) is reachable' {
            $listening = Test-Connection -TargetName $script:fgtPublicIP -TCPPort 443 -TimeoutSeconds 100
            $listening | Should -Be $true
        }

        It 'SSH (22) is reachable' {
            $listening = Test-Connection -TargetName $script:fgtPublicIP -TCPPort 22 -TimeoutSeconds 100
            $listening | Should -Be $true
        }

        It 'SSH: FortiGate configuration applied correctly' {
            $result = $script:verify_commands | ssh -tt -i $sshkey -o StrictHostKeyChecking=no devops@$($script:fgtPublicIP)
            $LASTEXITCODE | Should -Be 0
            Write-Host ("FGT CLI output:`n" + ($result -join "`n"))
            $result | Should -Not -BeLike "*Command fail*"
        }
    }
}

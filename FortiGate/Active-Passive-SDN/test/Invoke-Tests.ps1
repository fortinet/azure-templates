<#
.SYNOPSIS
    Runs the Active-Passive-SDN ARM template Pester tests locally.
.DESCRIPTION
    Mirrors the GitHub Actions workflow so you can test and debug without pushing.
    Assumes you are already logged into Azure (Connect-AzAccount or az login).
.PARAMETER Scenario
    Architecture to test: x64, x64_g2, or arm64. Default: x64
.PARAMETER SSHKeyPath
    Path to an existing ed25519 private key. If omitted a temporary key is generated
    at ~/.ssh/fgt_test_ed25519 and reused on subsequent runs.
.PARAMETER SSHKeyPubPath
    Path to the matching public key. Defaults to <SSHKeyPath>.pub
.PARAMETER OutputPath
    Destination for the NUnit XML result file.
    Default: <this-script-dir>/test-custom-<scenario>.xml
.EXAMPLE
    ./test/Invoke-Tests.ps1
    ./test/Invoke-Tests.ps1 -Scenario arm64
    ./test/Invoke-Tests.ps1 -Scenario x64_g2 -SSHKeyPath ~/.ssh/id_ed25519
#>
[CmdletBinding()]
param (
    [ValidateSet('x64', 'x64_g2', 'arm64')]
    [string]$Scenario      = 'x64',

    [string]$SSHKeyPath    = "",
    [string]$SSHKeyPubPath = "",
    [string]$OutputPath    = ""
)

$ErrorActionPreference = 'Stop'

# ── Paths ────────────────────────────────────────────────────────────────────

$testDir = $PSScriptRoot

if (-not $OutputPath) {
    $OutputPath = "$testDir/test-custom-$Scenario.xml"
}

# ── SSH keys ─────────────────────────────────────────────────────────────────

if (-not $SSHKeyPath) {
    $sshDir        = "$HOME/.ssh"
    $SSHKeyPath    = "$sshDir/fgt_test_ed25519"
    $SSHKeyPubPath = "$SSHKeyPath.pub"

    if (-not (Test-Path $SSHKeyPath)) {
        Write-Host "Generating SSH key pair at $SSHKeyPath ..."
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
        ssh-keygen -t ed25519 -f $SSHKeyPath -C "fortigate_test@local" -N '' 2>&1 | Out-Null
        Write-Host "Done."
    }
}

if (-not $SSHKeyPubPath) {
    $SSHKeyPubPath = "$SSHKeyPath.pub"
}

if (-not (Test-Path $SSHKeyPath))    { throw "SSH private key not found: $SSHKeyPath" }
if (-not (Test-Path $SSHKeyPubPath)) { throw "SSH public key not found: $SSHKeyPubPath" }

# ── Azure login check ─────────────────────────────────────────────────────────

try {
    $ctx = Get-AzContext
    if (-not $ctx -or -not $ctx.Subscription) { throw }
    Write-Host "Azure subscription : $($ctx.Subscription.Name)"
    Write-Host "Azure account      : $($ctx.Account.Id)"
} catch {
    Write-Warning "Not logged into Azure. Run Connect-AzAccount (PowerShell) or az login (CLI) first."
    exit 1
}

# ── Pester ───────────────────────────────────────────────────────────────────

$pesterMinVersion = [version]'5.7.1'
$installedPester  = Get-Module -ListAvailable -Name Pester |
    Where-Object { $_.Version -ge $pesterMinVersion } |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $installedPester) {
    Write-Host "Installing Pester >= 5.7.1 ..."
    Set-PSRepository psgallery -InstallationPolicy trusted
    Install-Module -Name Pester -MinimumVersion 5.7.1 -Confirm:$false -Force -SkipPublisherCheck
}

Import-Module Pester -MinimumVersion 5.7.1 -Force

# ── Run ──────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Scenario  : $Scenario"
Write-Host "SSH key   : $SSHKeyPath"
Write-Host "Test dir  : $testDir"
Write-Host "Output    : $OutputPath"
Write-Host ""

$container = New-PesterContainer -Path $testDir -Data @{
    sshkey    = $SSHKeyPath
    sshkeypub = $SSHKeyPubPath
    scenario  = $Scenario
}

$config = New-PesterConfiguration
$config.Run.Container           = $container
$config.Run.Exit                = $false   # don't kill the shell on failure
$config.Run.PassThru            = $true
$config.TestResult.Enabled      = $true
$config.TestResult.OutputFormat = "NUnitXML"
$config.TestResult.OutputPath   = $OutputPath
$config.Output.Verbosity        = 'Detailed'

$result = Invoke-Pester -Configuration $config

if ($result.FailedCount -gt 0) { exit 1 }

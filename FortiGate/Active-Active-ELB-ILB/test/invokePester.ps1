param (
    [string]$templatename
)

$SourceDir = Join-Path $env:BUILD_SOURCESDIRECTORY "$templatename"
$TempDir = [IO.Path]::GetTempPath()
$modulePath = Join-Path $TempDir arm-ttk-master\arm-ttk\arm-ttk.psd1

if (-not(Test-Path $modulePath)) {

    # Note: PSGet and chocolatey are not supported in hosted vsts build agent
    $tempFile = Join-Path $TempDir arm-ttk.zip
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest https://github.com/Azure/arm-ttk/archive/master.zip -OutFile $tempFile

    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempFile, $tempDir)

    Remove-Item $tempFile
}

Import-Module $modulePath -DisableNameChecking

$modulePath = Join-Path $TempDir Pester-master/Pester.psm1

if (-not(Test-Path $modulePath)) {

    # Note: PSGet and chocolatey are not supported in hosted vsts build agent
    $tempFile = Join-Path $TempDir pester.zip
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest https://github.com/pester/Pester/archive/master.zip -OutFile $tempFile

    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempFile, $tempDir)

    Remove-Item $tempFile
}

Import-Module $modulePath -DisableNameChecking

$modulePath = Join-Path $TempDir Export-NUnitXml.psm1

if (-not(Test-Path $modulePath)) {

    $tempFile = Join-Path $TempDir Export-NUnitXml.psm1
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest https://raw.githubusercontent.com/sam-cogan/arm-ttk-extension/master/task/Export-NUnitXml.psm1 -OutFile $tempFile
}

Import-Module $modulePath -DisableNameChecking

$outputFile = Join-Path $SourceDir "TEST-armttk.xml";

"Running ARM TTK"
$results = @(Test-AzTemplate -TemplatePath $SourceDir)
$results
Export-NUnitXml -TestResults $results -Path $SourceDir

$outputFile = Join-Path $SourceDir "TEST-custom.xml";

"Running custom tests"
Invoke-Pester -Path $SourceDir -PassThru -OutputFile $outputFile -OutputFormat NUnitXml -EnableExit

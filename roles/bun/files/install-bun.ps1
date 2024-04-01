# see https://github.com/oven-sh/bun/releases

param(
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$archiveUrl = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-windows-x64.zip"
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
$binaryPath = "$env:ChocolateyInstall\bin\bun.exe"

# bail when its already installed.
if (Test-Path $binaryPath) {
    # e.g. 1.1.0
    $actualVersionText = &$binaryPath --version
    if ($actualVersionText -notmatch '(.+)') {
        throw "unable to parse the bun.exe version from: $actualVersionText"
    }
    if ($Matches[1] -eq $version) {
        Exit 0
    }
}

# download and install.
Write-Host "Downloading $archiveUrl..."
$tempPath = "$env:TEMP\bun-${version}"
$archivePath = "$tempPath\bun-${version}.zip"
if (Test-Path $tempPath) {
    Remove-Item -Recurse $tempPath
}
mkdir $tempPath | Out-Null
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
Expand-Archive $archivePath $tempPath
$tempBinaryPath = Resolve-Path "$tempPath\*\bun.exe"
Copy-Item $tempBinaryPath $binaryPath
Remove-Item -Recurse $tempPath

$Ansible.Changed = $true

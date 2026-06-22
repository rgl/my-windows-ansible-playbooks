# see https://github.com/hashicorp/packer/releases
# see https://releases.hashicorp.com/packer

param(
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$archiveUrl = "https://releases.hashicorp.com/packer/${version}/packer_${version}_windows_amd64.zip"
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
$binaryPath = "$env:ChocolateyInstall\bin\packer.exe"

# bail when its already installed.
if (Test-Path $binaryPath) {
    # e.g. Packer v1.14.1
    $actualVersionText = &$binaryPath --version
    if ($actualVersionText -notmatch 'Packer v(.+)') {
        throw "unable to parse the packer.exe version from: $actualVersionText"
    }
    if ($Matches[1] -eq $version) {
        Exit 0
    }
}

# download and install.
Write-Host "Downloading $archiveUrl..."
$tempPath = "$env:TEMP\packer-${version}"
$archivePath = "$tempPath\packer-${version}.zip"
if (Test-Path $tempPath) {
    Remove-Item -Recurse $tempPath
}
mkdir $tempPath | Out-Null
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
Expand-Archive $archivePath $tempPath
Move-Item "$tempPath\packer.exe" $binaryPath
Remove-Item -Recurse $tempPath

$Ansible.Changed = $true

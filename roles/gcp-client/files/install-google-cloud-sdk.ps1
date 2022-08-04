# see https://cloud.google.com/sdk/docs/install
# see https://cloud.google.com/sdk/docs/downloads-versioned-archives

param (
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$archiveUrl = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-$version-windows-x86_64-bundled-python.zip"
$archivePath = "$env:TEMP\$(Split-Path -Leaf $archiveUrl)"
$installPath = 'C:\Program Files\google-cloud-sdk'
$gcloud = "$installPath\bin\gcloud.ps1"

# bail when its already installed.
# TODO there's a VERSION file... use that instead?
if (Test-Path $gcloud) {
    # e.g. Google Cloud SDK 394.0.0
    if ((&$gcloud --version) -match "Google Cloud SDK $([regex]::Escape($version))") {
        Exit 0
    }
}

# download.
Write-Host "Downloading $archiveUrl..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)

# install.
Write-Host "Installing..."
if (Test-Path $installPath) {
    Remove-Item -Recurse $installPath
}
Expand-Archive $archivePath $installPath
Move-Item $installPath\google-cloud-sdk\* $installPath
Remove-Item $installPath\google-cloud-sdk
Remove-Item $archivePath

$Ansible.Changed = $true

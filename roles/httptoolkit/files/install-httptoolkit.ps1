# see https://github.com/httptoolkit/httptoolkit-desktop/releases

param(
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$archiveUrl = "https://github.com/httptoolkit/httptoolkit-desktop/releases/download/v$version/HttpToolkit-$version-win-x64.zip"
$archivePath = "$env:TEMP\$(Split-Path -Leaf $archiveUrl)"
$installPath = 'C:\Program Files\HTTP Toolkit'
$manifestPath = "$installPath\resources\httptoolkit-server\package.json"

# bail when its already installed.
if (Test-Path $manifestPath) {
    $manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
    if ($manifest.version -eq $version) {
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

$Ansible.Changed = $true

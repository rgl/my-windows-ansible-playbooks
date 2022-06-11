# see https://github.com/httptoolkit/httptoolkit-desktop/releases

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$version = '1.8.1'
$archiveUrl = "https://github.com/httptoolkit/httptoolkit-desktop/releases/download/v$version/HttpToolkit-win-x64-$version.zip"
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

# see https://github.com/ashaduri/gsmartcontrol/releases

param(
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$archiveUrl = "https://github.com/ashaduri/gsmartcontrol/releases/download/v$version/gsmartcontrol-$version-win64.zip"
$archivePath = "$env:TEMP\$(Split-Path -Leaf $archiveUrl)"
$installPath = 'C:\Program Files\GSmartControl'
$gsmartcontrolPath = "$installPath\gsmartcontrol.exe"

# bail when its already installed.
if (Test-Path $gsmartcontrolPath) {
    $actualVersion = (Get-ChildItem $gsmartcontrolPath).VersionInfo.ProductVersion
    if ($actualVersion -eq $version) {
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
Move-Item "$installPath\gsmartcontrol-$version-win64\*" $installPath
Remove-Item "$installPath\gsmartcontrol-$version-win64"

$Ansible.Changed = $true

param(
    [string]$version
)

# see https://github.com/solokeys/solo2-cli

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$archiveUrl = "https://github.com/solokeys/solo2-cli/releases/download/v${version}/solo2-v${version}-x86_64-pc-windows-msvc.exe"
$archivePath = "$env:ChocolateyInstall\bin\solo2.exe"

# bail when its already installed.
if ((Test-Path $archivePath) -and ((&$archivePath --version) -match '^solo2 (.+)')) {
    $actualVersionValue = $Matches[1]
    if ($actualVersionValue -eq $version) {
        Exit 0
    }
}

# download and install.
Write-Host "Downloading $archiveUrl..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)

$Ansible.Changed = $true

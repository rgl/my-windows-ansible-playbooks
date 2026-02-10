# see https://github.com/netbirdio/netbird/releases

param(
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$archiveUrl = "https://github.com/netbirdio/netbird/releases/download/v${version}/netbird_installer_${version}_windows_amd64.exe"
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
$binaryPath = "$env:ProgramFiles\Netbird\netbird.exe"

# check whether the expected version is already installed.
$installBinaries = if (Test-Path $binaryPath) {
    # e.g. 0.64.5
    $actualVersionText = &$binaryPath version
    if ($actualVersionText -notmatch '(.+)') {
        throw "unable to parse the netbird.exe version from: $actualVersionText"
    }
    $Matches[1] -ne $version
} else {
    $true
}

# install.
if ($installBinaries) {
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    &$archivePath /S | Out-String -Stream
    Remove-Item -Force $archivePath | Out-Null
    $Ansible.Changed = $true
}

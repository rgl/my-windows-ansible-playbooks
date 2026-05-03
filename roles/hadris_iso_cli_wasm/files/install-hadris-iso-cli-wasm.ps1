# see https://github.com/rgl/hadris-iso-cli-wasm/releases

param(
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$archiveUrl = "https://github.com/rgl/hadris-iso-cli-wasm/releases/download/v${version}/hadris-iso-cli.wasm"
$binaryPath = "$env:ChocolateyInstall\bin\hadris-iso-cli.wasm"

# bail when its already installed.
if (Test-Path $binaryPath) {
    # e.g. hadris-iso 1.1.20260502
    $actualVersionText = wasmtime.exe $binaryPath --version
    if ($actualVersionText -notmatch '^hadris-iso (.+)') {
        throw "unable to parse the hadris-iso-cli.wasm version from: $actualVersionText"
    }
    if ($Matches[1] -eq $version) {
        Exit 0
    }
}

# download and install.
Write-Host "Downloading $archiveUrl..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $binaryPath)

$Ansible.Changed = $true

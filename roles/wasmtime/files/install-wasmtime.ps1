param(
    [string]$version
)

# see https://github.com/bytecodealliance/wasmtime

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$archiveUrl = "https://github.com/bytecodealliance/wasmtime/releases/download/v${version}/wasmtime-v${version}-x86_64-windows.zip"
$binaryPath = "$env:ChocolateyInstall\bin\wasmtime.exe"

# bail when its already installed.
# e.g. wasmtime 43.0.1 (cd4b6ed9b 2026-04-09)
if ((Test-Path $binaryPath) -and ((&$binaryPath --version) -match '^wasmtime ([^ ]+)')) {
    $actualVersionValue = $Matches[1]
    if ($actualVersionValue -eq $version) {
        Exit 0
    }
}

# download and install.
Write-Host "Downloading $archiveUrl..."
$tempPath = "$env:TEMP\wasmtime-${version}"
$archivePath = "$tempPath\wasmtime-${version}.zip"
if (Test-Path $tempPath) {
    Remove-Item -Recurse $tempPath
}
mkdir $tempPath | Out-Null
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
Expand-Archive $archivePath $tempPath
$tempBinaryPath = Resolve-Path "$tempPath\*\wasmtime.exe"
Copy-Item $tempBinaryPath $binaryPath
Remove-Item -Recurse $tempPath

$Ansible.Changed = $true

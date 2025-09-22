# see https://github.com/denoland/deno/releases

param(
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$archiveUrl = "https://github.com/denoland/deno/releases/download/v${version}/deno-x86_64-pc-windows-msvc.zip"
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
$binaryPath = "$env:ChocolateyInstall\bin\deno.exe"

# bail when its already installed.
if (Test-Path $binaryPath) {
    # e.g. deno 2.5.1 (stable, release, x86_64-pc-windows-msvc)
    $versionRe = '^deno ([^ +]+)'
    $actualVersionText = &$binaryPath --version | Where-Object { $_ -match $versionRe }
    if ($actualVersionText -notmatch $versionRe) {
        throw "unable to parse the deno.exe version from: $actualVersionText"
    }
    if ($Matches[1] -eq $version) {
        Exit 0
    }
}

# download and install.
Write-Host "Downloading $archiveUrl..."
$tempPath = "$env:TEMP\deno-${version}"
$archivePath = "$tempPath\deno-${version}.zip"
if (Test-Path $tempPath) {
    Remove-Item -Recurse $tempPath
}
mkdir $tempPath | Out-Null
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
Expand-Archive $archivePath $tempPath
$tempBinaryPath = Resolve-Path "$tempPath\deno.exe"
Copy-Item $tempBinaryPath $binaryPath
Remove-Item -Recurse $tempPath

$Ansible.Changed = $true

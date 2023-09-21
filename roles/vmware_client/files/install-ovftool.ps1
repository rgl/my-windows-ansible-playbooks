param(
    [string]$version
)

# see https://github.com/rgl/ovftool-binaries

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

# transform version from <major>.<minor>.<patch>.<build> to <major>.<minor>.<patch>-<build>.
if ($version -match '(.+)\.(.+)') {
    $ovftoolVersion = "$($Matches[1])-$($Matches[2])"
} else {
    throw "failed to parse version"
}

$archiveUrl = "https://github.com/rgl/ovftool-binaries/raw/main/archive/VMware-ovftool-$ovftoolVersion-win.x86_64.zip"
$installPath = 'C:\Program Files\ovftool'
$ovftool = "$installPath\ovftool.exe"
$ovftoolShimPath = "$env:ChocolateyInstall\bin\ovftool.exe"

# install.
# e.g. VMware ovftool 4.6.0 (build-21452615)
$install = $true
if ((Test-Path $ovftool) -and ((&$ovftool --version) -match '^VMware ovftool (.+) \(build(-.+)\)')) {
    $actualVersionValue = "$($Matches[1])$($Matches[2])"
    if ($actualVersionValue -eq $ovftoolVersion) {
        $install = $false
    }
}
if ($install) {
    Write-Host "Downloading $archiveUrl..."
    $archivePath = "$env:TEMP\ovftool-$version.zip"
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    if (Test-Path $installPath) {
        Remove-Item -Recurse $installPath
    }
    Write-Host "Installing..."
    mkdir $installPath | Out-Null
    Expand-Archive $archivePath $installPath
    Move-Item $installPath\ovftool\* $installPath
    Remove-Item $installPath\ovftool
    Remove-Item $archivePath
    $Ansible.Changed = $true
}

# install the shim.
if (!(Test-Path $ovftoolShimPath)) {
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"
    Install-BinFile -Name ovftool -Path "$installPath\ovftool.exe"
    $Ansible.Changed = $true
}

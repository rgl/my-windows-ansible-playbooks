# see https://github.com/eryph-org/guest-services

param(
    [string]$version,
    [string]$checksum
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$appHome = "$env:ProgramFiles\egs-tool"
$appPath = "$appHome\bin\egs-tool.exe"
$appShimPath = "$env:ChocolateyInstall\bin\egs-tool.exe"

# check whether the expected version is already installed.
$installBinaries = if (Test-Path $appPath) {
    # e.g. 0.2.0+Branch.tags-v0.2.Sha.9994af911b9e1a919a5a3aa8c8947a451a72bc83
    $actualVersion = (Get-ChildItem $appPath).VersionInfo.ProductVersion -replace '\+.*',''
    $actualVersion -ne $version
} else {
    $true
}

# download and install the binaries.
if ($installBinaries) {
    # remove the existing binaries.
    if (Test-Path $appHome) {
        Remove-Item -Force -Recurse $appHome | Out-Null
    }
    # install the binaries.
    $archiveVersion = $version
    $archiveName = "egs-tool-$archiveVersion.zip"
    $archiveUrl = "https://releases.dbosoft.eu/eryph/guest-services/$version/egs-tool_${version}_windows_amd64.zip"
    $archiveHash = $checksum
    $archivePath = "$env:TEMP\$archiveName"
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    $archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
    if ($archiveActualHash -ne $archiveHash) {
        throw "the $archiveUrl file hash $archiveActualHash does not match the expected $archiveHash"
    }
    Expand-Archive $archivePath -DestinationPath $appHome
    Remove-Item $archivePath
    $Ansible.Changed = $true
}

# initialize.
# see https://github.com/eryph-org/guest-services/blob/v0.6.0/src/Eryph.GuestServices.Tool/Commands/InitializeCommand.cs
$result = &$appPath initialize
if ($LASTEXITCODE) {
    throw "failed to initialize with exit code $LASTEXITCODE (0x$($LASTEXITCODE.ToString('X8')))"
}
if ($result -notcontains 'The SSH key already exists.') {
    $Ansible.Changed = $true
}

# install the shim.
if (!(Test-Path $appShimPath)) {
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"
    Install-BinFile `
        -Name ([System.IO.Path]::GetFileNameWithoutExtension($appShimPath)) `
        -Path $appPath
    $Ansible.Changed = $true
}

param(
    [version]$xaml_dependency_version
)

# see https://www.nuget.org/packages/Microsoft.UI.Xaml

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$archiveUrl = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/$xaml_dependency_version"
$archivePath = "$env:TEMP\microsoft.ui.xaml.$xaml_dependency_version.nupkg.zip"
$appxName = "Microsoft.UI.Xaml.$($xaml_dependency_version.Major).$($xaml_dependency_version.Minor)"

# bail when its already installed.
if (Get-AppxPackage -AllUsers $appxName) {
    Exit 0
}

# download.
Write-Host "Downloading $archiveUrl..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)

# install.
Write-Host "Installing $appxName..."
$tempInstallPath = "$archivePath-files"
if (Test-Path $tempInstallPath) {
    Remove-Item -Recurse $tempInstallPath
}
Expand-Archive $archivePath -DestinationPath $tempInstallPath
Add-AppxProvisionedPackage `
    -Online `
    -SkipLicense `
    -PackagePath "$tempInstallPath\tools\AppX\x64\Release\$appxName.appx"
Remove-Item -Recurse $tempInstallPath
Remove-Item $archivePath

$Ansible.Changed = $true

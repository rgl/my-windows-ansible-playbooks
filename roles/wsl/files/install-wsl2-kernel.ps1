# see https://ubuntu.com/blog/ubuntu-on-wsl-2-is-generally-available
# see https://aka.ms/wsl2kernel

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$uninstall = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* `
    | Select-Object DisplayName,DisplayVersion,Publisher,InstallDate `
    | Where-Object {
        $_.DisplayName -eq 'Windows Subsystem for Linux Update' -and
        $_.Publisher -eq 'Microsoft Corporation'
    }

# install when its not already installed.
if (!$uninstall) {
    # download.
    $archiveUrl = 'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi'
    $archiveName = Split-Path -Leaf $archiveUrl
    $archivePath = "$env:TEMP\$archiveName"
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    # install.
    msiexec `
        /i $archivePath `
        /qn `
        /L*v "$archivePath.log" `
        | Out-String -Stream
    if ($LASTEXITCODE) {
        throw "$archiveName installation failed with exit code $LASTEXITCODE. See $archivePath.log."
    }
    Remove-Item $archivePath
    $Ansible.Changed = $true
}

# see https://support.hp.com/us-en/drivers/selfservice/hp-elitedesk-800-65w-g4-desktop-mini-pc/21353734
# NB this installs the binaries at C:\Program Files (x86)\Intel\Intel(R) Management Engine Components.
# NB this also installs an uninstaller named Intel(R) Management Engine Components.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$version = '2227.3.14.0' # Oct 19, 2022.
$archiveUrl = 'https://ftp.hp.com/pub/softpaq/sp143001-143500/sp143098.exe'
$archiveHash = 'bd8729ae32f8fa6ac1b2e6dc52d5fb8aeee124d7d01c2bc05bf5f31da56fb300'
$archivePath = "$env:TEMP\$(Split-Path -Leaf $archiveUrl)"

# bail when its already installed.
$actualVersionValue = Get-ItemProperty `
    -Path HKLM:\SOFTWARE\ManageableUpdatePackage\Intel\ME `
    -Name Version `
    -ErrorAction SilentlyContinue
if ($actualVersionValue -and $actualVersionValue.Version -eq $version) {
    Exit 0
}

# download.
Write-Host "Downloading $archiveUrl..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash -Algorithm SHA256 $archivePath).Hash
if ($archiveActualHash -ne $archiveHash) {
    throw "the $archiveUrl file hash $archiveActualHash does not match the expected $archiveHash"
}

# install.
Write-Host "Installing..."
&$archivePath /s | Out-String -Stream
if ($LASTEXITCODE) {
    throw "installation failed with exit code $LASTEXITCODE. see the logs at C:\System.sav\logs."
}
Remove-Item $archivePath

# remove the temporary files left behind by the installer.
Remove-Item -Recurse C:\SWSetup
Remove-Item -Recurse C:\System.sav

$Ansible.Changed = $true

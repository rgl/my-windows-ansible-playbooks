# see https://support.hp.com/us-en/drivers/selfservice/hp-elitedesk-800-65w-g4-desktop-mini-pc/21353734
# NB this installs the binaries at C:\Program Files (x86)\Intel\Intel(R) Management Engine Components.
# NB this also installs an uninstaller named Intel(R) Management Engine Components.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$version = '2205.15.0.2623'
$archiveUrl = 'https://ftp.ext.hp.com/pub/softpaq/sp139501-140000/sp139844.exe'
$archiveHash = '00c63978e0f13673ddf329e6b4619370dd22bb7eb4667d83352b145a873a5051'
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

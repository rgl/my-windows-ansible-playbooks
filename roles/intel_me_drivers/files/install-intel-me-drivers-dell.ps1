# see https://www.dell.com/support/home/en-us/product-support/product/optiplex-7060-desktop/drivers
# NB this installs the binaries at C:\Program Files (x86)\Intel\Intel(R) Management Engine Components.
# NB this also installs an uninstaller named Intel(R) Management Engine Components.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$version = '2229.3.16.0' # Oct 10, 2022.
$archiveUrl = 'https://dl.dell.com/FOLDER09021432M/4/Intel-Management-Engine-Components-Installer_3DC3X_WIN64_2229.3.16.0_A11.EXE'
$archiveHash = '7d8825c020691f4052ef62a69f9da01c1ba53f5cc9ffc7312a50b8a85c10a872'
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

$Ansible.Changed = $true

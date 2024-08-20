# see https://www.dell.com/support/home/en-us/product-support/product/optiplex-7060-desktop/drivers
# see https://github.com/rgl/dell-drivers-scraper/blob/main/data/optiplex-7060-desktop.json
# NB this installs the binaries at C:\Program Files (x86)\Intel\Intel(R) Management Engine Components.
# NB this also installs an uninstaller named Intel(R) Management Engine Components.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$version = '2345.5.42.0' # Jan 29, 2024.
$archiveUrl = 'https://dl.dell.com/FOLDER10938937M/2/Intel-Management-Engine-Components-Installer_7FHFF_WIN64_2345.5.42.0_A13.EXE'
$archiveHash = '034fafde87448770c0b016fd8429ce50a93064fe1babb4cfc83bec1e6bddd737'
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
$webClient = New-Object System.Net.WebClient
$webClient.Headers["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64)"
$webClient.DownloadFile($archiveUrl, $archivePath)
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

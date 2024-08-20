# see https://support.hp.com/us-en/drivers/selfservice/hp-elitedesk-800-65w-g4-desktop-mini-pc/21353734
# see https://github.com/rgl/hp-drivers-scraper
# NB this installs the binaries at C:\Program Files (x86)\Intel\Intel(R) Management Engine Components.
# NB this also installs an uninstaller named Intel(R) Management Engine Components.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$version = '2313.4.16.0' # June 16, 2023.
$archiveUrl = 'https://ftp.hp.com/pub/softpaq/sp147501-148000/sp147824.exe'
$archiveHash = '5c02c349b0c57a6abb40aae8372d25ff64ee9c544ad337c0dd17df759f8bbdfd'
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

# remove the temporary files left behind by the installer.
Remove-Item -Recurse C:\SWSetup
Remove-Item -Recurse C:\System.sav

$Ansible.Changed = $true

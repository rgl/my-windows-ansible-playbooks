# see https://github.com/rgl/WinDHCP/releases
# see https://github.com/rgl/WinDHCP/blob/master/install.ps1

param(
    [string]$version,
    [string]$checksum
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$serviceName = 'WinDHCP'
$serviceHome = "$env:ProgramFiles\WinDHCP"

# check whether the expected version is already installed.
$installBinaries = if (Test-Path "$serviceHome\WinDHCP.exe") {
    $actualVersion = (Get-ChildItem "$serviceHome\WinDHCP.exe").VersionInfo.ProductVersion
    $actualVersion -ne $version
} else {
    $true
}

# download and install the binaries.
if ($installBinaries) {
    # uninstall the service.
    if (Get-Service -ErrorAction SilentlyContinue $serviceName) {
        Stop-Service $serviceName
        $result = sc.exe delete $serviceName
        if ($result -ne '[SC] DeleteService SUCCESS') {
            throw "sc.exe config failed with $result"
        }
    }
    # remove the existing binaries.
    if (Test-Path $serviceHome) {
        Remove-Item -Force -Recurse $serviceHome | Out-Null
    }
    # install the binaries.
    $archiveVersion = $version
    $archiveName = "WinDHCP-$archiveVersion.zip"
    $archiveUrl = "https://github.com/rgl/WinDHCP/releases/download/v$archiveVersion/WinDHCP.zip"
    $archiveHash = $checksum
    $archivePath = "$env:TEMP\$archiveName"
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    $archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
    if ($archiveActualHash -ne $archiveHash) {
        throw "the $archiveUrl file hash $archiveActualHash does not match the expected $archiveHash"
    }
    Expand-Archive $archivePath -DestinationPath $serviceHome
    Remove-Item $archivePath
    $Ansible.Changed = $true
}

# install and start the service.
$service = Get-Service -ErrorAction SilentlyContinue $serviceName
if (!$service) {
    &"$serviceHome\install.ps1" `
        -networkInterface 'vEthernet (Vagrant)' `
        -gateway '192.168.192.1' `
        -startAddress '192.168.192.100' `
        -endAddress '192.168.192.250' `
        -subnet '255.255.255.0' `
        -leaseDuration '0.01:00:00' `
        -dnsServers @('1.1.1.1', '1.0.0.1')
    $Ansible.Changed = $true
} elseif ($service.Status -ne 'Running') {
    Restart-Service $serviceName
    $Ansible.Changed = $true
}

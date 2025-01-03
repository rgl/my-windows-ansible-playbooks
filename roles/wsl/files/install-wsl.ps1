# see https://devblogs.microsoft.com/commandline/the-windows-subsystem-for-linux-in-the-microsoft-store-is-now-generally-available-on-windows-10-and-11/
# see https://learn.microsoft.com/en-us/windows/wsl/wsl-config
# see https://learn.microsoft.com/en-us/windows/wsl/systemd
# see https://github.com/microsoft/WSL2-Linux-Kernel
# see https://github.com/microsoft/WSL

param(
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if (!(Test-Path Variable:Ansible)) {
    $Ansible = @{}
}
$Ansible.Changed = $false

# force the installation.
$forceInstall = $false

# see https://github.com/microsoft/WSL/releases/tag/0.64.0
# see https://github.com/microsoft/WSL/issues/4607
$env:WSL_UTF8 = '1'

function Get-NormalizedVersion([version]$v) {
    [version]"$(if ($v.Major -ge 0) {$v.Major} else {0}).$(if ($v.Minor -ge 0) {$v.Minor} else {0}).$(if ($v.Build -ge 0) {$v.Build} else {0}).$(if ($v.Revision -ge 0) {$v.Revision} else {0})"
}

# NB this is faster then using Get-CimInstance Win32_Product.
# NB Get-ItemProperty HKLM:\SOFTWARE\Classes\Installer\Products\* returns the
#    MSI installed products. but its more complex to parse.
# NB Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
#    returns the generic windows installed application.
# NB at the time of writing, the Windows Subsystem for Linux Id was
#    {408A5C50-34F2-4025-968E-A21D6A515D48} which is represented in
#    the registry as a little-endian guid.
function Get-InstalledApp {
    Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* `
        | ForEach-Object {
            if ('DisplayName' -notin $_.PSObject.Properties.Name) {
                return
            }
            if ('DisplayVersion' -notin $_.PSObject.Properties.Name) {
                return
            }
            New-Object PSObject -Property @{
                Id = (Split-Path -Leaf $_.PSPath)
                Name = $_.DisplayName
                Version = (Get-NormalizedVersion $_.DisplayVersion)
            }
        }
}

function wsl {
    &"$env:ProgramFiles\WSL\wsl.exe" @Args
    if ($LASTEXITCODE) {
        throw "failed with exit code $LASTEXITCODE"
    }
}

$expectedVersion = Get-NormalizedVersion $version
$archiveUrl = "https://github.com/microsoft/WSL/releases/download/$version/wsl.${expectedVersion}.x64.msi"
$archivePath = "$env:TEMP\$(Split-Path -Leaf $archiveUrl)"

# bail when its already installed.
# NB at the time of writting, this package details were:
#       Name:               MicrosoftCorporationII.WindowsSubsystemForLinux
#       PackageFamilyName:  MicrosoftCorporationII.WindowsSubsystemForLinux_8wekyb3d8bbwe
#       PackageFullName:    MicrosoftCorporationII.WindowsSubsystemForLinux_2.3.26.0_x64__8wekyb3d8bbwe
#       PublisherId:        8wekyb3d8bbwe
#       InstallLocation:    C:\Program Files\WindowsApps\MicrosoftCorporationII.WindowsSubsystemForLinux_2.3.26.0_x64__8wekyb3d8bbwe
# NB we can check the installation with:
#       Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq 'MicrosoftCorporationII.WindowsSubsystemForLinux' }
#       Get-AppxPackage | Where-Object { $_.Name -eq 'MicrosoftCorporationII.WindowsSubsystemForLinux' }
# NB and with:
#       Get-CimInstance Win32_Product -Filter "Name = 'Windows Subsystem for Linux'"
#       dir HKLM:\SOFTWARE\Classes\Installer\Products
$msiInstalled = Get-InstalledApp | Where-Object {
    ($_.Name -eq 'Windows Subsystem for Linux') `
    -and `
    ($_.Version -eq $expectedVersion)
}
$storeInstalled = Get-AppxPackage -AllUsers 'MicrosoftCorporationII.WindowsSubsystemForLinux' | Where-Object {
    (Get-NormalizedVersion $_.Version) -eq $expectedVersion
}
if (!$forceInstall -and $msiInstalled -and $storeInstalled) {
    return
}

$Ansible.Changed = $true

# shutdown wsl.
Write-Host "Shutting down WSL..."
if (Test-Path "$env:ProgramFiles\WSL\wsl.exe") {
    &"$env:ProgramFiles\WSL\wsl.exe" --shutdown
} else {
    wsl.exe --shutdown
}

# uninstall the wsl msi installation.
Get-InstalledApp | Where-Object Name -eq 'Windows Subsystem for Linux' | ForEach-Object {
    Write-Host "Uninstalling the WSL msi installation..."
    $logPath = "$archivePath.uninstall.log"
    msiexec `
        /x `
        $_.Id `
        /qn `
        /L*v $logPath `
        | Out-String -Stream
    if ($LASTEXITCODE) {
        throw "uninstallation failed with exit code $LASTEXITCODE. See $logPath."
    }
}

# uninstall the wsl store installation/shim.
Get-AppxPackage -AllUsers 'MicrosoftCorporationII.WindowsSubsystemForLinux' | ForEach-Object {
    Write-Host "Uninstalling the WSL store installation..."
    $_ | Remove-AppxPackage -AllUsers
}

# download.
Write-Host "Downloading $archiveUrl..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)

# install.
# NB we do not use wsl.exe --install because we might want to install a
#    specific version.
Write-Host "Installing $archivePath..."
msiexec `
    /i `
    $archivePath `
    /qn `
    /L*v "$archivePath.log" `
    | Out-String -Stream
if ($LASTEXITCODE) {
    throw "installation failed with exit code $LASTEXITCODE. See $archivePath.log."
}

# remove the downloaded archive.
Remove-Item $archivePath

# show the wsl version.
Write-Host "Getting the wsl.exe version..."
wsl --version

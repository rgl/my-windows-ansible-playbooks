# see https://devblogs.microsoft.com/commandline/the-windows-subsystem-for-linux-in-the-microsoft-store-is-now-generally-available-on-windows-10-and-11/
# see https://learn.microsoft.com/en-us/windows/wsl/wsl-config
# see https://learn.microsoft.com/en-us/windows/wsl/systemd
# see https://github.com/microsoft/WSL2-Linux-Kernel
# see https://github.com/microsoft/WSL

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
trap {
    Write-Host
    Write-Host "ERROR: $_"
    ($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1' | Write-Host
    ($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1' | Write-Host
    Exit 1
}

# see https://github.com/microsoft/WSL/releases/tag/0.64.0
# see https://github.com/microsoft/WSL/issues/4607
$env:WSL_UTF8 = '1'

function Get-NormalizedVersion([version]$v) {
    [version]"$($v.Major).$(if ($v.Minor -ge 0) {$v.Minor} else {0}).$(if ($v.Build -ge 0) {$v.Build} else {0}).$(if ($v.Revision -ge 0) {$v.Revision} else {0})"
}

function wsl {
    wsl.exe @Args
    if ($LASTEXITCODE) {
        throw "failed with exit code $LASTEXITCODE"
    }
}

function Invoke-WslDistroScript([string]$distroName, [string]$script) {
    $scriptPath = 'C:\Windows\Temp\invoke-wsl-script.sh'
    Set-Content -NoNewline -Encoding ascii -Path $scriptPath -Value $script
    wsl.exe --distribution $distroName -- `
        /mnt/c/Windows/Temp/invoke-wsl-script.sh `
        @Args
    if ($LASTEXITCODE) {
        throw "failed to execute $scriptPath inside the $distroName wsl distro with exit code $LASTEXITCODE"
    }
    Remove-Item $scriptPath
}

function Install-Wsl {
    # see https://github.com/microsoft/WSL/releases
    # renovate: datasource=github-releases depName=WSL/releases
    $version = '1.2.5'
    $expectedVersion = Get-NormalizedVersion $version
    $archiveUrl = "https://github.com/microsoft/WSL/releases/download/$version/Microsoft.WSL_${expectedVersion}_x64_ARM64.msixbundle"
    $archivePath = "$env:TEMP\$(Split-Path -Leaf $archiveUrl)"

    # bail when its already installed.
    $installed = wsl.exe --version | ForEach-Object {
        if ($_ -match 'WSL version: (?<actualVersion>.+)') {
            $actualVersion = Get-NormalizedVersion $Matches['actualVersion']
            if ($actualVersion -ge $expectedVersion) {
                $true
            }
        }
    }
    if ($installed) {
        return
    }

    # download.
    Write-Host "Downloading $archiveUrl..."
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)

    # install.
    # NB we do not use wsl.exe --install because we might want to install a
    #    specific version.
    # NB at the time of writting, this package details were:
    #       Name:               MicrosoftCorporationII.WindowsSubsystemForLinux
    #       PackageFamilyName:  MicrosoftCorporationII.WindowsSubsystemForLinux_8wekyb3d8bbwe
    #       PackageFullName:    MicrosoftCorporationII.WindowsSubsystemForLinux_1.2.5.0_x64__8wekyb3d8bbwe
    #       PublisherId:        8wekyb3d8bbwe
    #       InstallLocation:    C:\Program Files\WindowsApps\MicrosoftCorporationII.WindowsSubsystemForLinux_1.2.5.0_x64__8wekyb3d8bbwe
    # NB we can check the installation with:
    #       Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq 'MicrosoftCorporationII.WindowsSubsystemForLinux' }
    #       Get-AppxPackage | Where-Object { $_.Name -eq 'MicrosoftCorporationII.WindowsSubsystemForLinux' }
    Write-Host "Installing $archivePath..."
    Add-AppxPackage $archivePath | Out-Null
    Remove-Item $archivePath

    # show the wsl version.
    Write-Host "Getting the wsl.exe version..."
    wsl --version
}

function Install-DebianFlavoredWslDistro([string]$distroName, [string]$archiveUrl) {
    $distroUser = 'wsl'
    $distroPath = "C:\Wsl\$distroName"
    $archivePath = "$env:TEMP\wsl-$distroName-rootfs.tgz"
    $changed = $false

    # install.
    if (!(wsl --list --quiet | Where-Object { $_ -eq $distroName })) {
        Write-Host "Downloading $distroName..."
        (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
        Write-Host "Installing $distroName to $distroPath..."
        mkdir -Force (Split-Path -Parent $distroPath) | Out-Null
        wsl --import $distroName $distroPath $archivePath
        Remove-Item $archivePath
        $changed = $true
    }

    # upgrade the distribution.
    # NB we must execute with sudo because the default wsl user might
    #    already be installed.
    Write-Host "Upgrading $distroName..."
    Invoke-WslDistroScript $distroName @'
set -euo pipefail; exec 2>&1; set -x
sudo bash -euxo pipefail /dev/stdin <<'EOF_SUDO'
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get dist-upgrade -y
apt-get clean -y
EOF_SUDO
'@ | Tee-Object -Variable result
    $resultSummaryRe = '(\d+) upgraded, (\d+) newly installed, (\d+) to remove and (\d+) not upgraded\.'
    $resultSummary = $result | Where-Object { $_ -match $resultSummaryRe }
    if ($resultSummary -match $resultSummaryRe) {
        $changes = [int]$Matches[1] + [int]$Matches[2] + [int]$Matches[3] + [int]$Matches[4]
        if ($changes -ne 0) {
            $changed = $true
        }
    } else {
        throw "failed to parse results from: $result"
    }

    # add the default wsl user.
    # NB we must execute with sudo because the default wsl user might
    #    already be installed.
    Write-Host "Adding the default $distroUser user..."
    Invoke-WslDistroScript $distroName @'
set -euo pipefail; exec 2>&1; set -x
sudo bash -euxo pipefail /dev/stdin "$1" <<'EOF_SUDO'
distro_user="$1"

if ! getent group admin >/dev/null 2>&1; then
    groupadd --system admin
    echo INSTALLATION CHANGED
fi

s='%admin ALL=(ALL) NOPASSWD:ALL'
if ! grep "$s" /etc/sudoers >/dev/null 2>&1; then
    sed -i -E "s,^%admin.+,$s,g" /etc/sudoers
    if ! grep "$s" /etc/sudoers >/dev/null 2>&1; then
        echo "$s" >>/etc/sudoers
    fi
    echo INSTALLATION CHANGED
fi

if ! getent group "$distro_user" >/dev/null 2>&1; then
    groupadd "$distro_user"
    echo INSTALLATION CHANGED
fi

if ! id -u "$distro_user" >/dev/null 2>&1; then
    adduser --disabled-password --gecos '' --ingroup "$distro_user" --force-badname "$distro_user"
    usermod -a -G admin "$distro_user"
    echo INSTALLATION CHANGED
fi

# configure wsl to use the default wsl user by default.
# TODO compare the whole file.
if ! grep "default=$distro_user" /etc/wsl.conf >/dev/null 2>&1; then
    cat >/etc/wsl.conf <<EOF
[user]
default=$distro_user

[boot]
systemd=true
EOF
    echo INSTALLATION CHANGED
fi
EOF_SUDO
'@ $distroUser | Tee-Object -Variable result
    if ('INSTALLATION CHANGED' -in $result) {
        $changed = $true
    }

    if ($changed) {
        Write-Host "Terminating the $distroName distribution..."
        wsl --terminate $distroName
    }
}

function Install-DebianWslDistro([string]$distroName='Debian') {
    # see https://salsa.debian.org/debian/WSL
    # renovate: datasource=gitlab-tags depName=debian/WSL registryUrl=https://salsa.debian.org
    $version = '1.15.0.0'
    $archiveUrl = "https://salsa.debian.org/debian/WSL/-/raw/v$version/x64/install.tar.gz"
    Install-DebianFlavoredWslDistro $distroName $archiveUrl
}

function Install-UbuntuWslDistro([string]$distroName='Ubuntu') {
    # see https://cloud-images.ubuntu.com/wsl
    $archiveUrl = 'https://cloud-images.ubuntu.com/wsl/jammy/current/ubuntu-jammy-wsl-amd64-wsl.rootfs.tar.gz'
    Install-DebianFlavoredWslDistro $distroName $archiveUrl
}

Install-Wsl
Install-DebianWslDistro
Install-UbuntuWslDistro

Write-Host "Listing the installed distributions..."
wsl --list --verbose

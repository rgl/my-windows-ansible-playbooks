# NB you can remove a distro altogether with, e.g.:
#       wsl --unregister Debian-12
#       Remove-Item -Recurse C:\Wsl\Debian-12

param(
    [string]$distroName,
    [string]$distroUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if (!(Test-Path Variable:Ansible)) {
    $Ansible = @{}
}
$Ansible.Changed = $false

# see https://github.com/microsoft/WSL/releases/tag/0.64.0
# see https://github.com/microsoft/WSL/issues/4607
$env:WSL_UTF8 = '1'

function wsl {
    &"$env:ProgramFiles\WSL\wsl.exe" @Args
    if ($LASTEXITCODE) {
        throw "failed with exit code $LASTEXITCODE"
    }
}

function Invoke-WslDistroScript([string]$distroName, [string]$script) {
    $scriptPath = 'C:\Windows\Temp\invoke-wsl-script.sh'
    Set-Content -NoNewline -Encoding ascii -Path $scriptPath -Value $script
    &"$env:ProgramFiles\WSL\wsl.exe" --distribution $distroName -- `
        /mnt/c/Windows/Temp/invoke-wsl-script.sh `
        @Args
    if ($LASTEXITCODE) {
        throw "failed to execute $scriptPath inside the $distroName wsl distro with exit code $LASTEXITCODE"
    }
    Remove-Item $scriptPath
}

function Install-WslDebianFlavor([string]$distroName, [string]$distroUrl) {
    $distroUser = 'wsl'
    $distroPath = "C:\Wsl\$distroName"
    $archivePath = "$env:TEMP\wsl-$distroName-rootfs.tgz"
    $changed = $false

    # install.
    if (!(wsl --list --quiet | Where-Object { $_ -eq $distroName })) {
        Write-Host "Downloading $distroName..."
        (New-Object System.Net.WebClient).DownloadFile($distroUrl, $archivePath)
        Write-Host "Installing $distroName to $distroPath..."
        mkdir -Force (Split-Path -Parent $distroPath) | Out-Null
        if (Test-Path $distroPath) {
            Remove-Item -Recurse $distroPath
        }
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
    $resultSummaryRe = '(?<upgraded>\d+) upgraded, (?<newlyInstalled>\d+) newly installed, (?<toRemove>\d+) to remove and (?<notUpgraded>\d+) not upgraded\.'
    $resultSummary = $result | Where-Object { $_ -match $resultSummaryRe }
    if ($resultSummary -match $resultSummaryRe) {
        # NB notUpgraded is not used (it does not count as a change).
        $changes = [int]$Matches['upgraded'] + [int]$Matches['newlyInstalled'] + [int]$Matches['toRemove']
        if ($changes -ne 0) {
            Write-Host "Installation changed: upgrade changed ($changes changes detected)."
            $changed = $true
        }
    } else {
        throw "failed to parse results from: $result"
    }

    # add the default wsl user.
    # NB we must execute with sudo because the default wsl user might
    #    already be installed.
    Invoke-WslDistroScript $distroName @'
set -euo pipefail; exec 2>&1; set -x
sudo bash -euxo pipefail /dev/stdin "$1" <<'EOF_SUDO'
distro_user="$1"

if ! getent group admin >/dev/null 2>&1; then
    echo 'adding the admin group...'
    groupadd --system admin
    echo INSTALLATION CHANGED
fi

s='%admin ALL=(ALL) NOPASSWD:ALL'
if ! grep "$s" /etc/sudoers >/dev/null 2>&1; then
    echo 'modifying sudoers...'
    sed -i -E "s,^%admin.+,$s,g" /etc/sudoers
    if ! grep "$s" /etc/sudoers >/dev/null 2>&1; then
        echo "$s" >>/etc/sudoers
    fi
    echo INSTALLATION CHANGED
fi

if ! getent group "$distro_user" >/dev/null 2>&1; then
    echo 'adding distro user group...'
    groupadd "$distro_user"
    echo INSTALLATION CHANGED
fi

if ! id -u "$distro_user" >/dev/null 2>&1; then
    echo 'adding distro user...'
    adduser --disabled-password --gecos '' --ingroup "$distro_user" --force-badname "$distro_user"
    usermod -a -G admin "$distro_user"
    echo INSTALLATION CHANGED
fi

# configure wsl to use the default wsl user by default.
# TODO compare the whole file.
if ! grep "default=$distro_user" /etc/wsl.conf >/dev/null 2>&1; then
    echo 'setting the wsl configuration...'
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
        Write-Host "Installation changed: configuration changed."
        $changed = $true
    }

    if ($changed) {
        Write-Host "Terminating the $distroName distribution..."
        wsl --terminate $distroName
    }

    if ($changed) {
        $Ansible.Changed = $true
    }
}

Install-WslDebianFlavor `
    $distroName `
    $distroUrl

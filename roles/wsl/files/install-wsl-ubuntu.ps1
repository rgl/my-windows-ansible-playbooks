# see https://docs.microsoft.com/en-us/windows/wsl/wsl-config

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$distroUser = 'wsl'
$distroName = 'Ubuntu-20.04'
$distroPath = "C:\Wsl\$distroName"
$archiveUrl = 'https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-wsl.rootfs.tar.gz'
$archivePath = "$env:TEMP\$(Split-Path -Leaf $archiveUrl)"

function Invoke-WslCommand {
    # NB the wsl.exe command itself returns UTF-16 encoded strings; BUT when
    #    wsl.exe is executing a script inside the distribution, it returns
    #    UTF-8 encoded strings.
    # see https://github.com/microsoft/WSL/issues/4607#issuecomment-717876058
    $consoleOutputEncoding = [System.Console]::OutputEncoding
    try {
        [System.Console]::OutputEncoding = New-Object System.Text.UnicodeEncoding
        wsl.exe @Args
    } finally {
        [System.Console]::OutputEncoding = $consoleOutputEncoding
    }
}

function Invoke-WslScript([string]$script) {
    # NB the wsl.exe command itself returns UTF-16 encoded strings; BUT when
    #    wsl.exe is executing a script inside the distribution, it returns
    #    UTF-8 encoded strings.
    $scriptPath = 'C:\Windows\Temp\invoke-wsl-script.sh'
    Set-Content -NoNewline -Encoding ascii -Path $scriptPath -Value $script
    wsl.exe --distribution $distroName -- `
        /mnt/c/Windows/Temp/invoke-wsl-script.sh `
        @Args
    Remove-Item $scriptPath
}

# install.
if (!(Invoke-WslCommand --list | Where-Object { $_ -match "^$([Regex]::Escape($distroName))\s*" })) {
    Write-Host "Downloading $distroName..."
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)

    Write-Host "Installing Ubuntu to $distroPath..."
    mkdir -Force (Split-Path -Parent $distroPath) | Out-Null
    Invoke-WslCommand --import $distroName $distroPath $archivePath
    Remove-Item $archivePath

    $Ansible.Changed = $true
}

# upgrade the distribution.
# NB we must execute with sudo because the default wsl user might
#    already be installed.
Write-Host "Upgrading Ubuntu..."
$result = Invoke-WslScript @'
set -euo pipefail; exec 2>&1; set -x
sudo bash -euxo pipefail /dev/stdin <<'EOF_SUDO'
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get clean -y
EOF_SUDO
'@
$resultSummaryRe = '(\d+) upgraded, (\d+) newly installed, (\d+) to remove and (\d+) not upgraded\.'
$resultSummary = $result | Where-Object { $_ -match $resultSummaryRe }
if ($resultSummary -match $resultSummaryRe) {
    $changes = [int]$Matches[1] + [int]$Matches[2] + [int]$Matches[3] + [int]$Matches[4]
    if ($changes -ne 0) {
        $Ansible.Changed = $true
    }
} else {
    throw "failed to parse results from: $result"
}

# add the default wsl user.
# NB we must execute with sudo because the default wsl user might
#    already be installed.
Write-Host "Add default user..."
$result = Invoke-WslScript @'
set -euo pipefail; exec 2>&1; set -x
sudo bash -euxo pipefail /dev/stdin "$1" <<'EOF_SUDO'
distro_user="$1"

if ! getent group "$distro_user" >/dev/null 2>&1; then
    groupadd "$distro_user"
    echo ANSIBLE CHANGED
fi

if ! id -u "$distro_user" >/dev/null 2>&1; then
    adduser --disabled-password --gecos '' --ingroup "$distro_user" --force-badname "$distro_user"
    usermod -a -G admin "$distro_user"
    echo ANSIBLE CHANGED
fi

if ! grep '%admin ALL=(ALL) NOPASSWD:ALL' /etc/sudoers >/dev/null 2>&1; then
    sed -i -E 's,^%admin.+,%admin ALL=(ALL) NOPASSWD:ALL,g' /etc/sudoers
    echo ANSIBLE CHANGED
fi

# configure wsl to use the default wsl user by default.
# NB for this to be applied, you must restart the distro with:
#       wsl.exe --shutdown
if ! grep "default=$distro_user" /etc/wsl.conf >/dev/null 2>&1; then
    cat >/etc/wsl.conf <<EOF
[user]
default=$distro_user
EOF
    echo ANSIBLE CHANGED
fi
EOF_SUDO
'@ $distroUser
if ($result -eq 'ANSIBLE CHANGED') {
    $Ansible.Changed = $true
}

# shutdown the distro to apply the packages upgrades or the wsl.conf changes.
if ($Ansible.Changed) {
    Invoke-WslCommand --distribution $distroName --shutdown
}

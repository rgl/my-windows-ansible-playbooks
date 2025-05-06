# NB you can remove a distro altogether with, e.g.:
#       wsl --unregister Ubuntu-24.04
#       Remove-Item -Recurse C:\Wsl\Ubuntu-24.04
# NB we can configure ubuntu using cloud-init.
#    see https://documentation.ubuntu.com/wsl/en/stable/howto/cloud-init/
#    see https://cloudinit.readthedocs.io/en/latest/reference/datasources/wsl.html

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
    # NB we have to change the preference (and 2>&1) because wsl.exe writes to
    #    stderr and that trips powershell into thinking the command failed...
    #    the string that is written to stderr is:
    #       wsl: Failed to configure network (networkingMode Nat), falling back to networkingMode VirtioProxy.
    #    that does not seem to prevent wsl.exe from actually working, so this
    #    is not looking for that error at all. nor any other error string,
    #    instead, we rely on the exit code.
    $ErrorActionPreference = 'Continue'
    if (Test-Path variable:PSNativeCommandUseErrorActionPreference) {
        $PSNativeCommandUseErrorActionPreference = $false
    }
    &"$env:ProgramFiles\WSL\wsl.exe" @Args 2>&1
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE) {
        throw "failed with exit code $LASTEXITCODE"
    }
}

function Invoke-WslDistroScript([string]$distroName, [string]$script, [int[]]$validExitCodes=@(0)) {
    $scriptPath = "C:\Windows\Temp\$distroName-invoke-wsl-script.sh"
    Set-Content -NoNewline -Encoding ascii -Path $scriptPath -Value $script
    # NB we have to change the preference (and 2>&1) because wsl.exe writes to
    #    stderr and that trips powershell into thinking the command failed...
    #    the string that is written to stderr is:
    #       wsl: Failed to configure network (networkingMode Nat), falling back to networkingMode VirtioProxy.
    #    that does not seem to prevent wsl.exe from actually working, so this
    #    is not looking for that error at all. nor any other error string,
    #    instead, we rely on the exit code.
    $ErrorActionPreference = 'Continue'
    if (Test-Path variable:PSNativeCommandUseErrorActionPreference) {
        $PSNativeCommandUseErrorActionPreference = $false
    }
    &"$env:ProgramFiles\WSL\wsl.exe" --distribution $distroName -- `
        "/mnt/c/Windows/Temp/$(Split-Path -Leaf "$scriptPath")" `
        @Args `
        2>&1
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -notin $validExitCodes) {
        throw "failed to execute $scriptPath inside the $distroName wsl distro with exit code $LASTEXITCODE"
    }
    Remove-Item $scriptPath
}

function Install-WslUbuntu([string]$distroName, [string]$distroUrl) {
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

    # start the wsl distribution.
    if ($changed) {
        Write-Host "Terminating the $distroName distribution..."
        wsl --terminate $distroName
        Write-Host "Starting the $distroName distribution and waiting for cloud-init to finish..."
        # NB the valid exit codes are:
        #       0 - success
        #       1 - unrecoverable error
        #       2 - recoverable error
        # see https://cloudinit.readthedocs.io/en/latest/explanation/failure_states.html#cloud-init-error-codes
        Invoke-WslDistroScript -validExitCodes @(0, 2) $distroName @'
#!/bin/bash
set -euo pipefail
cloud-init status --long --wait
'@
    }

    if ($changed) {
        $Ansible.Changed = $true
    }
}

Install-WslUbuntu `
    $distroName `
    $distroUrl

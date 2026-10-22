Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$msys2BasePath = "$env:ChocolateyToolsLocation\msys64"

# define a function for easing the execution of bash scripts.
$bashPath = "$msys2BasePath\usr\bin\bash.exe"
function Bash([string]$script, [int[]]$successExitCodes=@(0)) {
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        # we also redirect the stderr to stdout because PowerShell
        # oddly interleaves them.
        # see https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin
        Write-Output 'exec 2>&1; export PATH="/usr/bin:$PATH"; MSYS2_PATH_TYPE=inherit; source shell ucrt64; set -eu;' $script | &$bashPath
        if ($LASTEXITCODE -notin $successExitCodes) {
            throw "bash execution failed with exit code $LASTEXITCODE"
        }
        if ($LASTEXITCODE -ne 0) {
            # force $LASTEXITCODE to 0 and $? to $true. these are normally checked
            # by the CI system to known whether the command was successful or not.
            $global:LASTEXITCODE = 0
            $? | Out-Null
        }
    } finally {
        $ErrorActionPreference = $eap
    }
}

# configure the pacman mirror.
# see https://www.msys2.org/dev/mirrors/
# see /etc/pacman.conf
# see the pacman-conf command output
Bash @'
echo 'Server = https://mirror.accum.se/mirror/msys2.org/mingw/$repo' >/etc/pacman.d/mirrorlist.mingw
echo 'Server = https://mirror.accum.se/mirror/msys2.org/msys/$arch' >/etc/pacman.d/mirrorlist.msys
'@

# upgrade msys2.
# NB the update is done when the following "there is nothing to do" lines are seen.
#       :: Starting core system upgrade...
#        there is nothing to do
#       :: Starting full system upgrade...
#        there is nothing to do
$upgradeCount = 0
while ($true) {
    ++$upgradeCount
    Write-Output "Upgrading msys2 #$upgradeCount..."
    $doneCount = 0
    Bash -successExitCodes @(0, 1) -script '/usr/bin/update-ca-trust && pacman --noconfirm -Syuu --disable-download-timeout' | ForEach-Object {
        Write-Output "$_"
        if ("$_" -match 'there is nothing to do') {
            $script:doneCount += 1
        }
    }
    if ($doneCount -ge 2) {
        break
    }
    if ($upgradeCount -ge 5) {
        throw "failed to upgrade"
    }
    $Ansible.Changed = $true
}

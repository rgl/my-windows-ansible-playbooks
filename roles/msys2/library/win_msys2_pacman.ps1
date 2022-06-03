#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = "list"; elements = "str"; required = $true }
        # TODO support state: present and absent.
    }
    # TODO supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$msys2BasePath = "$env:ChocolateyToolsLocation\msys64"
$pacmanPath = "$msys2BasePath\usr\bin\pacman.exe"

function Start-Pacman([string[]]$Arguments, [int[]]$SuccessExitCodes=@(0)) {
    Start-PacmanProcess $Arguments | ForEach-Object { "$_" }
    if ($SuccessExitCodes -notcontains $LASTEXITCODE) {
        throw "$(@('pacman')+$Arguments | ConvertTo-Json -Compress) failed with exit code $LASTEXITCODE"
    }
}

function Start-PacmanProcess([string[]]$Arguments) {
    $eap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        &$pacmanPath @Arguments 2>&1
    } finally {
        $ErrorActionPreference = $eap
    }
}

function Start-PacmanProcessCapture([string[]]$Arguments) {
    $stdout = $()
    $stderr = $()
    Start-PacmanProcess $Arguments | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) {
            $stderr += "$_"
        } else {
            $stdout += "$_"
        }
    }
    [PSCustomObject]@{
        stdout = $stdout
        stderr = $stderr
        exitCode = $LASTEXITCODE
    }
}

function pacman {
    Start-Pacman $Args
}

$names = $module.Params.name

# pacman --query --info netcat
# Name            : gnu-netcat
# Provides        : netcat
# ...
$actualNames = pacman --query --quiet

$missingNames = @(Compare-Object `
    -ReferenceObject $actualNames `
    -DifferenceObject $names `
    -PassThru `
    | Where-Object { $_.SideIndicator -eq '=>' })

if ($missingNames) {
    # aka pacman -Syu.
    # -S, --sync
    # -y, --refresh
    # -u, --sysupgrade
    # --needed
    $arguments = @(
        '--sync'
        '--refresh'
        '--sysupgrade'
        '--needed'
        '--quiet'
        '--noconfirm'
        '--noprogressbar'
    )
    $missingNames | ForEach-Object {
        $arguments += $_
    }
    $result = Start-PacmanProcessCapture $arguments
    $module.Result.changed = $true
    $module.Result.stdout = $result.stdout
    $module.Result.stderr = $result.stderr
    if ($result.exitCode) {
        $module.FailJson("pacman failed with exit code $($result.exitCode)")
    }
}

$module.ExitJson()

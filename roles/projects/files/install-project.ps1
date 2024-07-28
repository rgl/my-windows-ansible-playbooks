param(
    [string]$repo,
    [string]$dest,
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

if ($dest -match '^~[/\\]') {
    $dest = Join-Path (Resolve-Path ~) ($dest -replace '^~[/\\]','')
}

if (Test-Path $dest) {
    Exit 0
}

$eap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    git clone --branch $version $repo $dest | ForEach-Object {
        "$_"
    }
    if ($LASTEXITCODE) {
        throw "failed to clone with exit code $LASTEXITCODE"
    }
} finally {
    $ErrorActionPreference = $eap
}

$Ansible.Changed = $true

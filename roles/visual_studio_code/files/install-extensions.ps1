param(
    [string[]]$extensions
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

# TODO add support for upgrading the extension to the latest version.

# install the missing extensions.
# NB we could also use --show-versions to include the version as @VERSION suffix.
# NB extension ids are case-insensitive.
$installed = code --list-extensions
$missing = if ($installed) {
    Compare-Object $extensions $installed `
        | Where-Object { $_.SideIndicator -eq '<=' } `
        | Select-Object -ExpandProperty InputObject
} else {
    $extensions
}
$missing | ForEach-Object {
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        code --install-extension $_ 2>&1 | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) {
                "ERROR: $_"
            } else {
                "$_"
            }
        }
        if ($LASTEXITCODE) {
            throw "$_ installation failed with exit code $LASTEXITCODE"
        }
        $Ansible.Changed = $true
    } finally {
        $ErrorActionPreference = $eap
    }
}

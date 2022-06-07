Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$expectedDefaultVersion = '2'

function wsl {
    # see https://github.com/microsoft/WSL/issues/4607#issuecomment-717876058
    $consoleOutputEncoding = [System.Console]::OutputEncoding
    try {
        [System.Console]::OutputEncoding = New-Object System.Text.UnicodeEncoding
        wsl.exe @Args
    } finally {
        [System.Console]::OutputEncoding = $consoleOutputEncoding
    }
}

# set the default version.
$defaultVersionRe = '^Default Version: (.+)'
$defaultVersionText = wsl --status | Where-Object { $_ -match $defaultVersionRe }
$actualVersion = if ($defaultVersionText -match $defaultVersionRe) {
    $Matches[1].Trim()
} else {
    ''
}
if ($actualVersion -ne $expectedDefaultVersion) {
    wsl --set-default-version $expectedDefaultVersion
    $Ansible.Changed = $true
}

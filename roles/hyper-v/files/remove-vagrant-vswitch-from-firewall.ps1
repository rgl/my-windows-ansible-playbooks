# see https://github.com/rgl/windows-vagrant#hyper-v-usage

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$changed = $false
$name = 'Vagrant'
$netAdapterName = "vEthernet ($name)"

Get-NetFirewallProfile | ForEach-Object {
    if ($_.DisabledInterfaceAliases -notcontains $netAdapterName) {
        Set-NetFirewallProfile -DisabledInterfaceAliases @($_.DisabledInterfaceAliases, $netAdapterName)
        $changed = $true
    }
}

$Ansible.Changed = $changed

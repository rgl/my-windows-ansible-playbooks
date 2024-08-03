# see https://github.com/rgl/windows-vagrant#hyper-v-usage

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$name = 'Vagrant'
$netAdapterName = "vEthernet ($name)"
$validNetAdapterNames = (Get-NetAdapter).Name

Get-NetFirewallProfile | ForEach-Object {
    if ($_.DisabledInterfaceAliases -notcontains $netAdapterName) {
        # ensure only valid aliases are used, otherwise, Set-NetFirewallProfile fails.
        $disabledInterfaceAliases = @($_.DisabledInterfaceAliases | Where-Object {
            $validNetAdapterNames -contains $_
        })
        Set-NetFirewallProfile `
            -Profile $_.Name `
            -DisabledInterfaceAliases ($disabledInterfaceAliases + $netAdapterName)
        $Ansible.Changed = $true
    }
}

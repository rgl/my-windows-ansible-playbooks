# see https://github.com/rgl/windows-vagrant#hyper-v-usage

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$name = 'Vagrant'
$netAdapterName = "vEthernet ($name)"
$ipAddress = '192.168.192.1'
$ipAddressPrefix = '24'

# create the vSwitch.
$vmSwitch = Get-VMSwitch -SwitchName $name -ErrorAction SilentlyContinue
if (!$vmSwitch) {
    $vmSwitch = New-VMSwitch -SwitchName $name -SwitchType Internal
    $Ansible.Changed = $true
}
# TODO verify that it has the expected configuration.

$netAdapter = Get-NetAdapter -Name $netAdapterName

# disable IPv6.
$netAdapterIpv6Binding = $netAdapter | Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
if ($netAdapterIpv6Binding -and $netAdapterIpv6Binding.Enabled) {
    $netAdapter | Disable-NetAdapterBinding -ComponentID ms_tcpip6
    $Ansible.Changed = $true
}

# assign the IP address.
$netAdapterIpAddress = $netAdapter | Get-NetIPAddress -IPAddress $ipAddress -ErrorAction SilentlyContinue
if (!$netAdapterIpAddress) {
    $netAdapter | New-NetIPAddress -IPAddress $ipAddress -PrefixLength $ipAddressPrefix
    $Ansible.Changed = $true
}

# create the NAT network.
$netNat = Get-NetNat -Name $name -ErrorAction SilentlyContinue
if (!$netNat) {
    New-NetNat -Name $name -InternalIPInterfaceAddressPrefix "$ipAddress/$ipAddressPrefix"
    $Ansible.Changed = $true
}
# TODO verify that it has the expected configuration.

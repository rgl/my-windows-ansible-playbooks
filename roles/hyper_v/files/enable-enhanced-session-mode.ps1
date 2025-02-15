Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

Import-Module Hyper-V

if (!(Get-VMHost).EnableEnhancedSessionMode) {
    Set-VMHost -EnableEnhancedSessionMode $true
    $Ansible.Changed = $true
}

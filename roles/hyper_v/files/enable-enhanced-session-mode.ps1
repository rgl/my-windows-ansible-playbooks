Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

if (!(Get-VMHost).EnableEnhancedSessionMode) {
    Set-VMHost -EnableEnhancedSessionMode $true
    $Ansible.Changed = $true
}

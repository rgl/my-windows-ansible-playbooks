Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$originalSettings = powercfg /query

# ensure sleep timeout when plugged in is set to never (0 minutes)
powercfg /change standby-timeout-ac 0

# ensure hibernate timeout when plugged in is set to never (0 minutes)
powercfg /change hibernate-timeout-ac 0

$currentSettings = powercfg /query
if (Compare-Object $originalSettings $currentSettings) {
    $Ansible.Changed = $true
}

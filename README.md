# About

[![Build status](https://github.com/rgl/my-windows-ansible-playbooks/workflows/build/badge.svg)](https://github.com/rgl/my-windows-ansible-playbooks/actions?query=workflow%3Abuild)

This is My Windows Ansible Playbooks Playground.

This targets Windows Server 2022 and Windows 11.

# Disclaimer

* These playbooks might work only when you start from scratch, in a machine that only has a minimal installation.
  * They might seem to work in other scenarios, but that is by pure luck.
  * There is no support for upgrades, downgrades, or un-installations.

# Usage

Add your machines into the Ansible [`inventory.yml` file](inventory.yml).

Review the [`development.yml` playbook](development.yml).

See the facts about the `dm1` machine:

```bash
./ansible.sh dm1 -m ansible.builtin.setup
```

Run an ad-hoc command in the `dm1` machine:

```bash
./ansible.sh dm1 -m win_command -a 'whoami /all'
./ansible.sh dm1 -m win_shell -a 'Get-PSSessionConfiguration'
```

Lint the [`development.yml` playbook](development.yml) playbook:

```bash
./ansible-lint.sh --offline --parseable development.yml
./mega-linter.sh
```

Run the [`development.yml` playbook](development.yml) against the `dm1` machine:

```bash
./ansible-playbook.sh --limit=dm1 development.yml
```

List this repository dependencies (and which have newer versions):

```bash
export GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN'
./renovate.sh
```

## WSL 2

Since WSL 2 moved to a Store application, [it cannot be remotely configured from a SSH/WinRM session (e.g. with Ansible)](https://learn.microsoft.com/en-us/windows/wsl/store-release-notes#known-issues). So the `wsl` Ansible Role only installs the required WSL 2 dependencies, and copies the install script to `C:\Wsl\install.ps1`, which you must manually execute as `PowerShell -File C:\Wsl\install.ps1`.

## Windows Management

Ansible can use one of the native Windows management protocols: [psrp](https://docs.ansible.com/ansible-core/2.15/collections/ansible/builtin/psrp_connection.html) (recommended) or [winrm](https://docs.ansible.com/ansible-core/2.15/collections/ansible/builtin/winrm_connection.html).

Its also advisable to use the `credssp` transport, as its the most flexible transport:

| transport   | local accounts | active directory accounts | credentials delegation | encryption |
|-------------|----------------|---------------------------|------------------------|------------|
| basic       | yes            | no                        | no                     | no         |
| certificate | yes            | no                        | no                     | no         |
| kerberos    | no             | yes                       | yes                    | yes        |
| ntlm        | yes            | yes                       | no                     | yes        |
| credssp     | yes            | yes                       | yes                    | yes        |

For more information see the [Ansible CredSSP documentation](https://docs.ansible.com/ansible-core/2.15/os_guide/windows_winrm.html#credssp).

### Troubleshoot

In a Windows PowerShell session, with Administration privileges, use the
following commands to troubleshoot the machine and the WinRM service.

Try connecting to a machine with, e.g.:

```powershell
Test-WSMan
winrm id
winrs -r:127.0.0.1:5985 "-u:Administrator" "-p:MyPassword" "whoami /all"
Enter-PSSession -ComputerName 127.0.0.1 -Port 5985
Invoke-Command -ComputerName 127.0.0.1 -Port 5985 -ScriptBlock { whoami /all }
```

Verify the listening addresses:

```powershell
Get-NetConnectionProfile # NB WinRM only works on non-Public network profiles.
(Get-NetIPAddress).IPAddress
netsh http show iplisten
netsh interface portproxy show all # NB if not empty, watch for conflicts.
netstat -aon | Select-String :5985
winrm enumerate winrm/config/listener
winrm get winrm/config
```

If required, modify the network profile, or delete/add listening
addresses with, e.g.:

```powershell
Get-NetConnectionProfile `
  | Where-Object { $_.NetworkCategory -ne 'DomainAuthenticated' } `
  | Set-NetConnectionProfile -NetworkCategory Private
netsh http delete iplisten ipaddress=127.0.0.1
netsh http add iplisten ipaddress=127.0.0.1
Remove-WSManInstance winrm/config/Listener -SelectorSet @{Address="*";Transport="http"}
New-WSManInstance winrm/config/Listener -SelectorSet @{Address="*";Transport="http"}
Restart-Service WinRM
```

Verify the Group Policy (GPO) or Local Policy:

```powershell
gpresult.exe /h gporesult.html && start gporesult.html
# NB ensure the policy filters are set to * or
#    the policy/filters do not exist at all.
$winRmPolicyKeyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service'
if (Test-Path $winRmPolicyKeyPath) {
  Get-ItemProperty -Path $winRmPolicyKeyPath -Name IPv4Filter
  Get-ItemProperty -Path $winRmPolicyKeyPath -Name IPv6Filter
}
```

If required, modify them with, e.g.:

```powershell
$winRmPolicyKeyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service'
if (!(Test-Path $winRmPolicyKeyPath)) {
  New-Item -Force -Path $winRmPolicyKeyPath | Out-Null
}
Set-ItemProperty -Path $winRmPolicyKeyPath -Name IPv4Filter -Value '*'
Set-ItemProperty -Path $winRmPolicyKeyPath -Name IPv6Filter -Value '*'
Remove-ItemProperty -Path $winRmPolicyKeyPath -Name IPv4Filter
Remove-ItemProperty -Path $winRmPolicyKeyPath -Name IPv6Filter
Restart-Service WinRM
```

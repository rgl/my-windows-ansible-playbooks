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

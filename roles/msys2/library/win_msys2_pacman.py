#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: win_msys2_pacman
short_description: Manage packages with MSYS2 I(pacman)
description:
  - Manage packages with the MSYS2 I(pacman) package manager.
options:
  name:
    description:
      - Name or list of names of the package to install.
    type: list
    elements: str
notes:
  - This assumes MSYS2 is installed at I(%ChocolateyToolsLocation%\msys64).
  - >
    pacman --query also installs groups and packages that provide other
    packages (like netcat; these can be ambiguous because multiple
    packages might provide the same target, which makes it ambiguous to
    decide which package to install. pacman would typically prompt the
    user, but since this ansible module has no UI, the installation
    will fail).
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Install a single package
  win_msys2_pacman:
    name: zip

- name: Install multiple packages
  win_msys2_pacman:
    name:
      - zip
      - unzip
'''

RETURN = '''
stdout:
  description:
    - Output from pacman.
  returned: always
  type: str
stderr:
  description:
    - Error output from pacman.
  returned: always
  type: str
'''

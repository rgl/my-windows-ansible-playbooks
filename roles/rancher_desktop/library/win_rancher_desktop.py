#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: win_rancher_desktop
short_description: Manage Rancher Desktop
description:
  - Manage Rancher Desktop.
options:
  version:
    description:
      - Rancher Desktop Version to install.
      - See https://github.com/rancher-sandbox/rancher-desktop/releases.
    type: str
  container_engine:
    description:
      - Container engine to use.
      - Use one of: moby or containerd.
    type: str
  kubernetes_enabled:
    description:
      - Whether Kubernetes is enabled.
    type: bool
  kubernetes_version:
    description:
      - Kubernetes Version to install.
    type: str
notes:
  - This requires WSL2.
  - This requires Windows 11.
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Install Rancher Desktop
  win_rancher_desktop:
    version: '1.7.0'
    container_engine: 'moby'
    kubernetes_enabled: true
    kubernetes_version: '1.25.5'
'''

RETURN = '''
'''

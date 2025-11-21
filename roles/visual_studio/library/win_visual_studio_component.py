#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: win_visual_studio_component
short_description: Manage Visual Studio Components
description:
  - Manage Visual Studio Components Installation.
options:
  name:
    description:
      - Name or list of names of the Components to install.
      - See https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?view=visualstudio
    type: list
    elements: str
notes:
  - This requires the Visual Studio Installer.
author:
  - Rui Lopes (ruilopes.com)
'''  # noqa: E501

EXAMPLES = '''
- name: Install the Windows App SDK C# Templates
  win_visual_studio_component:
    name: Microsoft.VisualStudio.ComponentGroup.WindowsAppSDK.Cs
'''

RETURN = '''
'''

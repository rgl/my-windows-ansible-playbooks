#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: win_user_keyboard
short_description: Manage the current user keyboard layout
description:
  - Manage the current user keyboard layout.
options:
  language:
    description:
      - Name of the keyboard language.
    type: str
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Set the keyboard layout
  win_user_keyboard:
    language: pt-PT
'''

RETURN = '''
'''

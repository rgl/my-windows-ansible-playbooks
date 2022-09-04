#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: win_visual_effects
short_description: Manage the current user visual effects
description:
  - Manage the current user visual effects.
options:
  show_window_contents_while_dragging:
    description:
      - Show window contents while dragging.
    type: bool
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Set visual effects
  win_visual_effects:
    show_window_contents_while_dragging: true
'''

RETURN = '''
'''

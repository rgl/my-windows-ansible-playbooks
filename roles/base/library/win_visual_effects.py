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
  smooth_edges_of_screen_fonts:
    description:
      - Smooth edges of screen fonts.
    type: bool
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Set visual effects
  win_visual_effects:
    show_window_contents_while_dragging: true
    smooth_edges_of_screen_fonts: true
'''

RETURN = '''
'''

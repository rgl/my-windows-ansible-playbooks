#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: win_user_languages
short_description: Manage the current user languages
description:
  - Manage the current user languages.
options:
  languages:
    description:
      - Name or list of names of the languages.
    type: list
    elements: str
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Set the user languages
  win_user_languages:
    languages:
      - en-US
      - pt-PT
'''

RETURN = '''
'''

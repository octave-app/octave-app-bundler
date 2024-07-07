#!/usr/bin/env python
#
# set_exe_icon_py2 - Set icons for an executable
#
# OBSOLETE! Only works on older versions of macOS, pre macOS 12, and is not currently
# used. This file is kept around only for reference.
#
#     set_exe_icon_py2.py <icons_file> <exe_file>
#
# This is a Python 2.x script, and requires the macOS-specific Cocoa module that was
# shipped with the system Python 2.x in older versions.
#
# This is broken as of macOS 12, and maybe earlier. It fails with a
# "ModuleNotFoundError: No module named 'Cocoa'" error. Looks like the Cocoa module
# doesn't exist in the newer Pythons shipped with macOS. It may have been a Python 2
# thing; macOS has switched to Python 3 since the last time this worked.


import sys
import Cocoa

icons_file = sys.argv[1].decode("utf-8")
oct_gui_file = sys.argv[2].decode("utf-8")
wksp = Cocoa.NSWorkspace.sharedWorkspace()
icons_data = Cocoa.NSImage.alloc().initWithContentsOfFile_(icons_file)
ok = wksp.setIcon_forFile_options_(icons_data, oct_gui_file, 0)
if not ok:
  sys.exit("Unable to set file icons for file " + oct_gui_file + " from icons file " + icons_file)

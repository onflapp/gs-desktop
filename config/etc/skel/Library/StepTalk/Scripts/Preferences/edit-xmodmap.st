Environment loadModule:'SystemShell'.

Shell executeCommand:'touch' withArguments:#('~/.Xmodmap').

NSWorkspace sharedWorkspace openFile:('~/.Xmodmap' stringByExpandingTildeInPath).
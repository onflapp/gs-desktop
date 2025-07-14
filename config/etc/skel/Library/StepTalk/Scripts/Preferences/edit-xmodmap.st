Environment loadModule:'SystemShell'.

f := ('~/.Xmodmap' stringByExpandingTildeInPath).

Shell executeCommand:'touch' withArguments:(NSArray new) + f.

NSWorkspace sharedWorkspace openFile:f.

lf := '/tmp/terminal.txt'.

term := currentTerminal.
term dumpScrollBuffer:lf.

ws := NSWorkspace sharedWorkspace.
ws openFile:lf.

Environment loadModule:'SystemShell'.

d := ImageViewer currentDocument.
t := '/tmp/a.tiff'.
d writeImageDataToFile:t.

a := (NSArray new) + '-flip' + t + t.
Shell executeCommand:'convert' withArguments:a.

d readImageDataFromFile:t.

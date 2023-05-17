Environment loadModule:'SystemShell'.

d := ImageViewer currentDocument.
t := '/tmp/a.tiff'.
x := '/tmp/a1.tiff'.
v := '75%'.
d writeImageDataToFile:t.

a := (NSArray new) + t + '-resize' + v + x.
Shell executeCommand:'convert' withArguments:a.

d := ImageViewer newDocument.
d readImageDataFromFile:x.

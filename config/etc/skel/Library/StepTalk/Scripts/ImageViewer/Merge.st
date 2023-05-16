Environment loadModule:'SystemShell'.

docs := ImageViewer documents.
args := (NSMutableArray new).

args += '-append'.

0 to: (docs count) - 1 do:
[ :i |
  d := docs objectAtIndex: i.
  t := ('/tmp/', (i stringValue), '.tiff').
  d writeImageDataToFile:t.
  args += t.
].

t := '/tmp/ta.tiff'.
args += t.

Shell executeCommand:'convert' withArguments:args.

Transcript show:args.

doc := ImageViewer newDocument.
doc displayFile:t.
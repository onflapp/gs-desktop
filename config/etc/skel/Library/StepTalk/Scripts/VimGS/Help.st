doc := currentDocument.
doc sendCommand:':help\n'.

win := doc window.
win makeKeyAndOrderFront:self.

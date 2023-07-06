path := currentDocument fileName.
dir := path stringByDeletingLastPathComponent.
ws := NSWorkspace sharedWorkspace.
ws selectFile:path inFileViewerRootedAtPath:dir.

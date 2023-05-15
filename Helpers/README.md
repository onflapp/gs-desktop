# Helper Apps

Helpers are important part of GNUstep Desktop support infrastructure.
Their main purpose is to provide services to other applications.
For example, ImageConverter app makes it possible for ImageViewer.app 
to open image files that NSImage does not support natively.
This is done by leveraging NSPasteboard's filter API.

1. ImageViwer.app asks for a data format to be filter to TIFF
2. If appropriate filter is found, the data format will be passed to that filter
3. The filter runs and returns data as TIFF format

The filters are usually scripts that call other command line utilities 
to do the actual conversion.

The Helper apps do not only exposes filters but also services and/or act as launchers for files or URLs though standard GNUstep mechanisms. 

The easiest way to edit or create your own filter is to use WrapperFactory.app.

Help
Help app
Image app
Doc app

#### Noted features include:

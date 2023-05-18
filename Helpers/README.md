# Helper Apps

Helpers are important part of GNUstep Desktop support infrastructure.
Their main purpose is to provide services to other applications.
For example, ImageConverter helper makes it possible for ImageViewer.app 
to open image files that NSImage does not support natively.
This is done by leveraging [NSPasteboard's filter API](https://gnustep.github.io/resources/documentation/Developer/Gui/ProgrammingManual/AppKit_13.html).

1. ImageViwer.app asks for a data format to be filter to TIFF
2. If appropriate filter is found, the data format will be passed to that filter
3. The filter runs and returns data as TIFF format

The filters are usually scripts that call other command line utilities 
to do the actual conversion.

The Helper apps do not only exposes filters but also services and/or act as launchers for files or URLs through standard GNUstep mechanisms. 

The easiest way to edit or create your own filter is to use [WrapperFactory.app](https://github.com/onflapp/gs-desktop/tree/main/Applications/WrapperFactory).

#### Application using helpers:

- [HelpViewer](https://github.com/onflapp/gs-desktop/tree/main/Applications/HelpViewer) to display _gsdoc_, _man_ and _info_ pages
- [ImageViewer](https://github.com/onflapp/gs-desktop/tree/main/Applications/ImageViewer) to display various image formats supported by ImageMagic.
- [DocViewer](https://github.com/onflapp/gs-desktop/tree/main/Applications/DocViewer) to display _ps_, _md_ files

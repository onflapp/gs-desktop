# WrapperFactory.app

Application for creating app-wrappers (app bundles) for non-GNUstep applications.
It is also used heavily by GNUstep Desktop to "wrap" scripts and command line utilities to 
extend functionality of other applications.

For example: provide image and document conversion filters or services

../../Scripts

This WrapperFactory has been forked from a version maintained by Raffael Herzog I found on some random SVN server.
It has been clean up and greatly enhanced.

#### Noted features include:

- the wrapped itself doesn't contain any binaries (it symlinks to system binary)
- services - a script can provide GNUstep service
- filter - a script can be used as GNUstep pasteboard service (e.g. for conversion)
- support to handle URLs

### The Future Direction

It would be cool to use it together with WebBrowser.app to create "web apps".
For example, one could make "GMail.app" by launching dedicated WebBrowser.app session.
The wrapper could also include site-specific javascripts to customize it further.

Tighter integration with StepTalk.

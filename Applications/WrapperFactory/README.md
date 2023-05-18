# WrapperFactory.app

Application for creating app-wrappers (app bundles) for non-GNUstep applications.
It is also used heavily by GNUstep Desktop to "wrap" scripts and command line utilities to provide services to other apps ([Helpers](https://github.com/onflapp/gs-desktop/blob/main/Helpers)).

This WrapperFactory has been forked from a version maintained by Raffael Herzog I found on some random SVN server. It has been clean up and greatly enhanced.

#### Noted features include:

- the wrapped itself doesn't contain any binaries. It symlinks to system binary so the wrapper itself is plaform agnostic
- _services_ - a script can provide GNUstep service
- _filter_ - a script can be used as GNUstep pasteboard service (e.g. for conversion of datatypes)
- supports for handling custom URLs

### The Future Direction

It would be cool to use it together with WebBrowser.app to create "web apps".
For example, one could make "GMail.app" by launching dedicated WebBrowser.app session directed to gmail's URL.

The wrapper could also include site-specific javascripts or CSS to customize it further.

Tighter integration with [StepTalk](https://github.com/onflapp/libs-steptalk). Although it is possible to run scripts now via `stexec`, the wrapper could provide additional functionality, such as UI panels for the script to utilize.

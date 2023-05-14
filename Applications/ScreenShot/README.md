# ScreenShot.app

Application for taking screenshots of your desktop. 
It is loosely based on Grab.app from NeXT/MacOS X and it is intended to be used as part of GNUstep Desktop.
It can take screenshots in 3 different ways:

- use mouse to select selection of your screen
- focused window (the screenshot will be take after 1s)
- entire screen

Pressing <esc> key will about the action

You can use app icon's menu (right click application's icon while it is running) to invoke desired action
without ScreenShot getting in your way.

Resulting image will be opened in ImageViewer.app.

### Prerequisites

Please note that ScreenShot.app relies on wonderful command line utility called `scrot`.

You can install `scrot` on any recent Debian/Ubuntu system by doing:

```
sudo apt install scrot
```

### The Future Direction

The next step is to make it scriptable so that you can invoke it as part of a workflow.

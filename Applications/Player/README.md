# Player.app

Application for playing video/audio files. 
It uses VLC behind the scenes so it will support any media format supported by VLC installed on your system.

### Prerequisites

Make sure you have VLC properly installed.
As Player.app is the front-end, you do not need to (and probably should not) install any other VLC front-end.
Following command will install all required modules on any Debian/Ubuntu system.

```
sudo apt install \
 vlc-bin \
 vlc-data \
 vlc-plugin-video-output \
 vlc-plugin-base
```

### Scriptability

Player.app is scriptable using StepTalk.
For example, you can stop the current document playing by invoking following script:

```
Player currentDocument stop.
```

### The Future Direction

1. make it more scriptable
2. support URLs (e.g. dvd:// or http:// streaming)
3. full screen support

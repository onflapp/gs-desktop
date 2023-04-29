# GS Desktop

GNUstep Desktop attempts to build fully functional GNUstep desktop by bringing apps from various sources together and making sure everything works together to create unified user experience.

It should work on any Debian-based system (I personally use Raspberry PI4 as the main development and user platform) and possibly any modern Linux distribution with a bit tweaking.

### 1. Install Dependencies

The desktop relies on many other libraries and binaries to work as intended. This step is more important than you might realize at first.

There is a script you can use to help you install all that is needed.

```
cd dependencies
./install-dependencies-debian.sh debian11.txt
```

My favorite way to get GS Desktop working is to install minimal Debian distribution (no X or any desktop environment) and then do something like this:

```
apt-get install git
git clone https://github.com/onflapp/gs-desktop
cd gs-desktop/dependencies
./install-dependencies-debian.sh debian11.txt
```

### 2. Fetch sources

GS Desktop come from different places. Some are official github repos, others are my forks.

```
./fetch_world.sh
```

### 3. Build and install 

The script will build and install everything that is required. It needs to be run as root!

```
sudo -E ./build_world.sh
```

The whole desktop is going to be installed in /Application, /System and /Library directories. Although this doesn't follow GNUstep/Linux conventions, it simplifies system scripts etc. as everything is in predictable place.

### Start the GS Desktop

If you use modern login manager, you will see two new xsessions (normal startup and safe mode) for you to choose to log in.

Otherwise use `/System/bin/startgsde` to start the desktop manually or add it into your `~/.xinitrc`

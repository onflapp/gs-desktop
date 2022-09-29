# GS Desktop

GNUstep Desktop is source distribution that attempts to build fully functional GNUstep desktop.

It should work on any Debian-based system (I personally use Raspberry PI4 for its development) and possibly any modern Linux distribution with a bit tweaking.

### 1. Install Dependencies

The desktop on other libraries and binaries to work properly. This step is more important than you might realize at first.

```
cd dependencies
./install-dependencies-debian.sh debian11.txt
```

My favorite way to get GS Desktop working, is to install minimal Debian distribution (no X or any desktop environment) and then do something like this:

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

The script will ask you for admin password at one point.

```
./build_world.sh
```

The whole desktop is going to be installed in /Application, /System and /Library directories. Although this doesn't follow GNUstep/Linux conventions, it simplifies system scripts etc. as everything is in predictable place.

### Start the GS Desktop

Two xsession files (normal startup and safe mode) should be installed for you so that you can simply choose it from you login manager.

You can also use `/System/bin/startgsde` to start the desktop manually

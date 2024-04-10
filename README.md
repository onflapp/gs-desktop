# GNUstep Desktop - GSDE

[GNUstep Desktop](https://onflapp.github.io/gs-desktop/index.html) attempts to build fully functional desktop by bringing various GNUstep apps together and making sure everything works as expected.

### Important concepts:
- filters and services to enhance functionality - [Helpers](https://github.com/onflapp/gs-desktop/blob/main/Helpers/README.md)
- scriptability - [StepTalk](https://github.com/onflapp/libs-steptalk)
- intergration with command line utilities / scripts [Tools](https://github.com/onflapp/gs-desktop/tree/main/Applications/Tools)

It should work on any modern Debian or Fedora-based system (I personally use Raspberry PI4 as my main development and user platform) and possibly any modern Linux distribution with a bit tweaking.

## Installation

### 1. Install Dependencies

The desktop relies on many other libraries and binaries to work as intended. This step is more important than you might realize at first. As many build systems use autoconfig to find dependencies, a missing dependency will not necessarily result in failed build but it might cause all kinds of weird runtime problems or desktop not working as intended.

There is a script you can use to help you install all that is needed.

```
cd dependencies
sudo ./install-dependencies-debian.sh
```

### 2. Fetch sources

GSDE come from different places. Some are official github repos, others are my forks. Many apps have been patched and/or configured in a way to "play nice with others". Hopefully most of those changes will be merged back to the original source tree one day.

```
git clone https://github.com/onflapp/gs-desktop
cd gs-desktop

./fetch_world.sh
```

### 3. Build and install 

The script will build and install everything that is required. It needs to be run as root!

```
sudo -E ./build_world.sh
```

The whole desktop is going to be installed in `/Application`, `/System` and `/Library` directories. Although this doesn't follow GNUstep/Linux conventions, it simplifies system scripts etc. as everything is in predictable place.

### 4. Start GS Desktop

If you use modern login manager, you will see two new xsessions (normal startup and safe mode) for you to choose to log into.

To install XDM as your loging manager execute the following command:

```
sudo -E ./config/install_wdm.sh
```

Otherwise, use `/System/bin/startgsde` to start the desktop directly from console, within your existing X session or add it to your `~/.xsessionrc` or `~/.xinitrc`.

## Minimal/clean build on Debian

My favorite way to get GSDE working is to install minimal Debian distribution (no X or any desktop environment) and then do something like this as *root*:

```
# install git and sudo
apt-get install git sudo

# make sure normal user can use sudo
usermod -G sudo <normal user>
```

login as *normal user* and continue with:


```
# clone core source code repo
mkdir src
cd src
git clone https://github.com/onflapp/gs-desktop

# install dependencies
cd gs-desktop/dependencies
sudo ./install-dependencies-debian.sh

# clone all relevant source repos
cd ..
./fetch_world.sh

# build and install entire desktop
sudo -E ./build_world.sh

# install WDM as default login manager
sudo ./config/install_wdm.sh
```

If all goes well, you should be greeted by GSDE's login window.

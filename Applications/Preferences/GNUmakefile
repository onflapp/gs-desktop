# -*- mode: makefile-gmake -*-

GNUSTEP_INSTALLATION_DOMAIN = LOCAL
include $(GNUSTEP_MAKEFILES)/common.make

#GNUSTEP_BUILD_DIR = /Users/me/Projects/==BUILD==/Preferences.build

#
# Application
#
VERSION = 0.5
PACKAGE_NAME = Preferences
APP_NAME = Preferences
$(APP_NAME)_APPLICATION_ICON = Mask.tiff

SUBPROJECTS = \
	Modules/Localization \
	Modules/Font \
	Modules/Display \
	Modules/Themes \
	Modules/Screen \
	Modules/Keyboard \
	Modules/Mouse \
	Modules/Touch \
	Modules/Sound \
	Modules/Expert \
	Modules/Password \
	Modules/Date \
	Modules/Services \
	Modules/Power

#
# Resource files
#
$(APP_NAME)_RESOURCE_FILES = \
	Resources/apply_config \
	Resources/ApplicationScripting.xlp \
	Resources/ScriptingInfo.plist \
	Modules/Localization/Localization.preferences \
	Modules/Font/Font.preferences \
	Modules/Display/Display.preferences \
	Modules/Themes/Themes.preferences \
	Modules/Screen/Screen.preferences \
	Modules/Keyboard/Keyboard.preferences \
	Modules/Mouse/Mouse.preferences \
	Modules/Touch/Touch.preferences \
	Modules/Sound/Sound.preferences \
	Modules/Expert/Expert.preferences \
	Modules/Password/Password.preferences \
	Modules/Services/Services.preferences \
	Modules/Date/Date.preferences \
	Modules/Power/Power.preferences

#
# Localization
#
$(APP_NAME)_LANGUAGES = English
$(APP_NAME)_LOCALIZED_RESOURCE_FILES = \
	Preferences.gorm \
	PrefsWindow.gorm \
	InfoPanel.gorm \
	Preferences.tiff \
	Preferences.png \
	ClockViewTile.tiff \
	WorldMap.tiff

#
# Header files
#
$(APP_NAME)_HEADER_FILES = Prefernces.h
$(APP_NAME)_HEADER_FILES_INSTALL_DIR = $(GNUSTEP_SYSTEM_HEADERS)/apps

#
# Class files
#
$(APP_NAME)_OBJC_FILES = \
AppController.m \
KeyboardStatusMonitor.m \
STScriptingSupport.m \
PrefsController.m

#
# Other sources
#
$(APP_NAME)_OBJC_FILES += \
Preferences_main.m 

#
# Makefiles
#
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

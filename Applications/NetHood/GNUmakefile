#
# GNUmakefile - Generated by ProjectCenter
#
ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(warning )
    $(warning Unable to obtain GNUSTEP_MAKEFILES setting from gnustep-config!)
    $(warning Perhaps gnustep-make is not properly installed,)
    $(warning so gnustep-config is not in your PATH.)
    $(warning )
    $(warning Your PATH is currently $(PATH))
    $(warning )
  endif
endif
ifeq ($(GNUSTEP_MAKEFILES),)
 $(error You need to set GNUSTEP_MAKEFILES before compiling!)
endif

include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
PACKAGE_NAME = NetHood
APP_NAME = NetHood
NetHood_APPLICATION_ICON = neighbor.tiff


#
# Resource files
#
NetHood_RESOURCE_FILES = \
Resources/NetHood.gorm \
Resources/neighbor.tiff \
Resources/services \
Resources/ApplicationScripting.xlp \
Resources/ScriptingInfo.plist 


#
# Header files
#
NetHood_HEADER_FILES = \
AppController.h \
NetworkServices.h

#
# Objective-C Class files
#
NetHood_OBJC_FILES = \
AppController.m \
NetworkServices.m \
AppController+scripting.m

#
# Other sources
#
NetHood_OBJC_FILES += \
NetHood_main.m 

#
# Makefiles
#
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

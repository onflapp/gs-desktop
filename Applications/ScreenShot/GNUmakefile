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
PACKAGE_NAME = ScreenShot
APP_NAME = ScreenShot
ScreenShot_APPLICATION_ICON = ScreenShot.tiff


#
# Resource files
#
ScreenShot_RESOURCE_FILES = \
Resources/ScreenShot.gorm \
Resources/ScreenShot.tiff \
Resources/takeshot \
Resources/ApplicationScripting.xlp \
Resources/ScriptingInfo.plist \
Resources/capture 


#
# Header files
#
ScreenShot_HEADER_FILES = \
AppController.h \
STScriptingSupport.h \
MiniView.h

#
# Objective-C Class files
#
ScreenShot_OBJC_FILES = \
AppController.m \
AppController+scripting.m \
STScriptingSupport.m \
MiniView.m

#
# Other sources
#
ScreenShot_OBJC_FILES += \
ScreenShot_main.m 

#
# Makefiles
#
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

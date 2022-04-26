#
# This GNUmakefile is public domain.
# Do whatever you want with it.
#
# Author: Ludovic Marcotte <ludovic@Sophos.ca>
#
-include $(GNUSTEP_MAKEFILES)/common.make
APP_NAME = SimpleSMTP
SimpleSMTP_OBJC_FILES = SimpleSMTP.m
SimpleSMTP_LIB_DIRS = -L../$(GNUSTEP_LIBRARIES_ROOT)
ADDITIONAL_OBJCFLAGS = -Wall -Wno-import
ifeq ($(GNUSTEP_TARGET_OS),mingw32)
ADDITIONAL_GUI_LIBS = -lPantomime
else
ADDITIONAL_LDFLAGS = -lPantomime
endif
-include $(GNUSTEP_MAKEFILES)/application.make

#
# If GNUstep Make isn't installed, as it is
# often the case on Mac OS X,  we compile
# things 'manually'. To compile and run it:
# a) Copy Pantomime.framework in /Library/Frameworks
# b) Type "make"
# c) Type "SimpleSMTP.app/SimpleSMTP"
#
example:
	mkdir -p SimpleSMTP.app
	gcc -DMACOSX -o SimpleSMTP.app/SimpleSMTP SimpleSMTP.m -framework Foundation -framework AppKit -framework Pantomime 

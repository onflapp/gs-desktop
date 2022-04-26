#
# This GNUmakefile is public domain.
# Do whatever you want with it.
#
# Author: Ludovic Marcotte <ludovic@Sophos.ca>
#
-include $(GNUSTEP_MAKEFILES)/common.make
APP_NAME = SimplePOP3
SimplePOP3_OBJC_FILES = SimplePOP3.m
SimplePOP3_LIB_DIRS = -L../$(GNUSTEP_LIBRARIES_ROOT)
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
# c) Type "SimplePOP3.app/SimplePOP3"
#
example:
	mkdir -p SimplePOP3.app
	gcc -DMACOSX -o SimplePOP3.app/SimplePOP3 SimplePOP3.m -framework Foundation -framework AppKit -framework Pantomime 

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME=adserver

adserver_OBJC_FILES=adserver.m
adserver_OBJCFLAGS=-I../Frameworks -Wall
adserver_LDFLAGS += -L../../Frameworks/Addresses/Addresses.framework
adserver_TOOL_LIBS += -lAddresses
adserver_INCLUDE_DIRS = -I../../Frameworks

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = soundtool

$(TOOL_NAME)_STANDARD_INSTALL = no

$(TOOL_NAME)_OBJC_FILES = soundtool_main.m

$(TOOL_NAME)_NEEDS_GUI = no

ADDITIONAL_TOOL_LIBS += -lSoundKit -lpulse -lsndfile -lgnustep-gui

include $(GNUSTEP_MAKEFILES)/tool.make
include $(GNUSTEP_MAKEFILES)/ctool.make

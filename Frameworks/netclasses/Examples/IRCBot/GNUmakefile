include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = IRCBot
IRCBot_OBJC_FILES = main.m IRCBot.m 

ifeq ($(OBJC_RUNTIME_LIB), apple)
IRCBot_TOOL_LIBS = -framework netclasses $(ADDITIONAL_FRAMEWORK_DIRS)
else
IRCBot_TOOL_LIBS = -lnetclasses
endif

GUI_LIB =

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make


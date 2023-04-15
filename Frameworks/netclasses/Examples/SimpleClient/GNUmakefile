include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = SimpleClient
SimpleClient_OBJC_FILES = main.m SimpleClient.m

GUI_LIB =

ifeq ($(OBJC_RUNTIME_LIB), apple)
	SimpleClient_TOOL_LIBS = -framework netclasses $(ADDITIONAL_FRAMEWORK_DIRS)
else
	SimpleClient_TOOL_LIBS = -lnetclasses
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make

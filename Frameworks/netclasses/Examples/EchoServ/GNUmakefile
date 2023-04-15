include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = EchoServ
EchoServ_OBJC_FILES = main.m EchoServ.m

GUI_LIB =

ifeq ($(OBJC_RUNTIME_LIB), apple)
	EchoServ_TOOL_LIBS = -framework netclasses $(ADDITIONAL_FRAMEWORK_DIRS)
else
	EchoServ_TOOL_LIBS = -lnetclasses
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make

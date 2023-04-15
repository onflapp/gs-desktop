include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = Skeleton
Skeleton_OBJC_FILES = main.m

GUI_LIB =

ifeq ($(OBJC_RUNTIME_LIB), apple)
	Skeleton_TOOL_LIBS = -framework netclasses $(ADDITIONAL_FRAMEWORK_DIRS)
else
	Skeleton_TOOL_LIBS = -lnetclasses
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make

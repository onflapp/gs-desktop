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
PACKAGE_NAME = Sketch
APP_NAME = Sketch
Sketch_APPLICATION_ICON = Sketch.tiff


#
# Resource files
#
Sketch_RESOURCE_FILES = \
Resources/Sketch.gorm \
Resources/DrawWindow.gorm \
Resources/ToolPalette.gorm \
Resources/Inspector.gorm \
Resources/GridPanel.gorm \
Resources/Preferences.gorm \
Resources/Arrow.tiff \
Resources/Circle.tiff \
Resources/Cross.tiff \
Resources/Line.tiff \
Resources/Rectangle.tiff \
Resources/TextGraphic.tiff \
Resources/Sketch.tiff 


#
# Header files
#
Sketch_HEADER_FILES = \
SKTAppDelegate.h \
SKTCircle.h \
SKTDocument.h \
SKTError.h \
SKTGraphic.h \
SKTGraphicView.h \
SKTGrid.h \
SKTImage.h \
SKTLine.h \
SKTRectangle.h \
SKTRenderingView.h \
SKTText.h \
SKTToolPaletteController.h \
SKTWindowController.h \
SKTZoomingScrollView.h \
SKGridPanelController.h \
SKInspectorController.h

#
# Objective-C Class files
#
Sketch_OBJC_FILES = \
SKTAppDelegate.m \
SKTCircle.m \
SKTDocument.m \
SKTError.m \
SKTGraphic.m \
SKTGraphicView.m \
SKTGrid.m \
SKTImage.m \
SKTLine.m \
SKTRectangle.m \
SKTRenderingView.m \
SKTText.m \
SKTToolPaletteController.m \
SKTWindowController.m \
SKTZoomingScrollView.m \
SKGridPanelController.m \
SKInspectorController.m

#
# Other sources
#
Sketch_OBJC_FILES += \
Sketch_main.m 

#
# Makefiles
#
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

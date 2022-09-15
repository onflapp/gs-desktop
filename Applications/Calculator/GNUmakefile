include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = EdenMath
VERSION = 1.1.0

APP_NAME = EdenMath
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)/
EdenMath_APPLICATION_ICON = EdenMath.tiff
EdenMath_MAIN_MODEL_FILE = MainMenu.gorm

EdenMath_HEADERS = \
	EMController.h \
	EMResponder.h
	
EdenMath_OBJC_FILES = \
	EMController.m \
	EMResponder.m \
	main.m
	
EdenMath_RESOURCE_FILES = \
	EdenMath.tiff \

EdenMath_LANGUAGES = English

EdenMath_LOCALIZED_RESOURCE_FILES = \
	MainMenu.gorm
                                 
ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

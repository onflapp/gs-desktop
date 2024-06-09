# -*- mode: makefile-gmake -*-

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = Touch
BUNDLE_EXTENSION = .preferences

$(BUNDLE_NAME)_PRINCIPAL_CLASS = Touch
$(BUNDLE_NAME)_STANDARD_INSTALL = no

$(BUNDLE_NAME)_LANGUAGES = \
	English

$(BUNDLE_NAME)_LOCALIZED_RESOURCE_FILES= \
	Touch.gorm

$(BUNDLE_NAME)_RESOURCE_FILES = \
	Resources/Touch.tiff \
	Resources/bundle.registry

$(BUNDLE_NAME)_OBJC_FILES= \
	Touch.m

$(BUNDLE_NAME)_HEADERS= \
	Touch.h

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

#
# GNUmakefile - Font Manager
#
# Copyright 2007 Isaiah Beerbower.
#
# Author: Isaiah Beerbower
# Created: 05/31/07
# License: Modified BSD license (see file COPYING)
#

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = FontManager

FontManager_OBJC_FILES = \
  PQMain.m \
  PQCharacterView.m \
  PQCharactersController.m \
  PQCharactersView.m \
  PQController.m \
  PQFontDocument.m \
  PQFontFamily.m \
  PQFontManager.m \
  PQFontSampleView.m \
  PQSampleController.m


FontManager_LANGUAGES = \
  English

FontManager_LOCALIZED_RESOURCE_FILES = \
  MainMenu.gorm \
  FontDocument.gorm \
  Localizable.strings

FontManager_RESOURCE_FILES = \
  Resources/FontManager.tif \
  Resources/Document-Font.tif \
  Resources/UnicodeBlockNames.plist \
  Resources/UnicodeBlocks.plist


FontManager_MAIN_MODEL_FILE = MainMenu.gorm

include $(GNUSTEP_MAKEFILES)/application.make


-include ../../../etoile.make

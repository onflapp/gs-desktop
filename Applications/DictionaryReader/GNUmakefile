#
# Dictionary Reader Makefile
#

include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(warnings), yes)
ADDITIONAL_OBJCFLAGS += -W
ADDITIONAL_OBJCPPFLAGS += -W
ADDITIONAL_CFLAGS += -W
ADDITIONAL_CPPFLAGS += -W
endif
ifeq ($(allwarnings), yes)
ADDITIONAL_OBJCFLAGS += -Wall
ADDITIONAL_OBJCPPFLAGS += -Wall
ADDITIONAL_CFLAGS += -Wall
ADDITIONAL_CPPFLAGS += -Wall
endif

APP_NAME = DictionaryReader

DictionaryReader_OBJC_FILES = \
AppController.m \
StreamLineWriter.m \
StreamLineReader.m \
DictConnection.m \
HistoryManager.m \
NSString+Convenience.m \
NSString+Clickable.m \
NSString+DictLineParsing.m \
DictionaryHandle.m \
NSScanner+Base64Encoding.m \
LocalDictionary.m \
Preferences.m \
main.m \


DictionaryReader_HEADER_FILES = \
AppController.h \
StreamLineWriter.h \
StreamLineReader.h \
DictConnection.h \
HistoryManager.h \
NSString+Convenience.h \
NSString+Clickable.h \
NSString+DictLineParsing.h \
DefintionWriter.h \
DictionaryHandle.h \
NSScanner+Base64Encoding.h \
LocalDictionary.h \
Preferences.h \



DictionaryReader_OBJCC_FILES = 
DictionaryReader_C_FILES = 
DictionaryReader_RESOURCE_FILES = \
Resources/dict.png \
Resources/Dictionaries/jargon/jargon.index \
Resources/Dictionaries/jargon/jargon.dict \


DictionaryReader_LANGUAGES = English

DictionaryReader_LOCALIZED_RESOURCE_FILES = \
DictionaryReader.gorm \
Preferences.gorm \
DictionaryReader.nib \
Preferences.nib


DictionaryReader_MAIN_MODEL_FILE = DictionaryReader.gorm

DictionaryReader_PRINCIPAL_CLASS = 

# If we're compiling on Etoile, we'll link to EtoileFoundation
# to not duplicate UKNibOwner in the code.
ifeq ($(etoile), yes)
	ADDITIONAL_GUI_LIBS += -lEtoileFoundation
	ADDITIONAL_OBJC_FLAGS += -DETOILE
else
	DictionaryReader_OBJC_FILES += UKNibOwner.m
	DictionaryReader_HEADER_FILES += UKNibOwner.h
endif

SUBPROJECTS = 
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../../etoile.make
-include GNUmakefile.postamble




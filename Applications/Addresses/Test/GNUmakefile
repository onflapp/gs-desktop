include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME=ADSingleTest
ADSingleTest_OBJC_FILES=Controller.m main.m
ADSingleTest_HEADER_FILES=Controller.h 
ADSingleTest_MAIN_MODEL_FILE=ADSingleTest.gorm
ADSingleTest_RESOURCE_FILES=ADSingleTest.gorm

ADSingleTest_OBJCFLAGS=-I../Frameworks -Wall
ADSingleTest_LDFLAGS=\
	-L../Frameworks/AddressView/AddressView.framework/Versions/A \
	-L../Frameworks/Addresses/Addresses.framework/Versions/A     \
	-lAddressView -lAddresses

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

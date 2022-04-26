include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME=AddressManager
AddressManager_APPLICATION_ICON=AddressManager.tiff
AddressManager_OBJC_FILES=\
			Controller.m \
			DragDropMatrix.m \
			main.m
AddressManager_HEADER_FILES=\
			Controller.h \
			DragDropMatrix.h
AddressManager_MAIN_MODEL_FILE=AddressManager.gorm

AddressManager_RESOURCE_FILES=                           \
			AddressManager.tiff              \
			VCFImage.tiff VCFImageMulti.tiff \
			VCFFile.tiff                     \
			AddressManagerInfo.plist
AddressManager_LOCALIZED_RESOURCE_FILES=\
			AddressManager.gorm \
			Localizable.strings \
			ISOCountryCodes.dict
AddressManager_LANGUAGES=Dutch English French German Spanish
AddressManager_OBJCFLAGS=-I../Frameworks -Wall
#AddressManager_LDFLAGS=\
	-L../Frameworks/AddressView/AddressView.framework/$(GNUSTEP_TARGET_LDIR) \
	-L../Frameworks/Addresses/Addresses.framework/$(GNUSTEP_TARGET_LDIR)     \
	-lAddressView -lAddresses

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble


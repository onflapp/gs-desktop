include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME=Addresses
Addresses_APPLICATION_ICON=AddressManager.tiff
Addresses_OBJC_FILES=\
			Controller.m \
			DragDropMatrix.m \
			STScriptingSupport.m \
			main.m
Addresses_HEADER_FILES=\
			Controller.h \
			STScriptingSupport.h \
			DragDropMatrix.h
Addresses_MAIN_MODEL_FILE=AddressManager.gorm

Addresses_RESOURCE_FILES=\
			AddressManager.tiff \
			VCFImage.tiff VCFImageMulti.tiff \
			VCFFile.tiff \
			ScriptingInfo.plist \
			ApplicationScripting.xlp \
			AddressManagerInfo.plist
Addresses_LOCALIZED_RESOURCE_FILES=\
			AddressManager.gorm \
			Localizable.strings \
			ISOCountryCodes.dict
Addresses_LANGUAGES=Dutch English French German Spanish
Addresses_OBJCFLAGS=-I../Frameworks -Wall
#AddressManager_LDFLAGS=\
	-L../Frameworks/AddressView/AddressView.framework/$(GNUSTEP_TARGET_LDIR) \
	-L../Frameworks/Addresses/Addresses.framework/$(GNUSTEP_TARGET_LDIR)     \
	-lAddressView -lAddresses

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble


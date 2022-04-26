include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME=Addresses

Addresses_OBJC_FILES= \
	ADAddressBook.m         \
	ADConverter.m           \
	ADEnvelopeAddressBook.m \
	ADGlobals.m             \
	ADGroup.m		\
	ADImageLoading.m        \
	ADLocalAddressBook.m    \
	ADMultiValue.m          \
	ADPerson.m              \
	ADPListConverter.m      \
	ADPlugin.m              \
	ADPublicAddressBook.m   \
	ADRecord.m              \
	ADSearchElement.m       \
	ADVCFConverter.m 
Addresses_HEADER_FILES= \
	ADAddressBook.h         \
	ADConverter.h           \
	ADEnvelopeAddressBook.h \
	ADGlobals.h             \
	ADGroup.h		\
	ADImageLoading.h        \
	ADLocalAddressBook.h    \
	ADMultiValue.h          \
	ADPerson.h              \
	ADPListConverter.h      \
	ADPlugin.h              \
	ADPublicAddressBook.h   \
	ADRecord.h              \
	ADSearchElement.h       \
	ADTypedefs.h            \
	ADVCFConverter.h        \
	Addresses.h             \
	AddressBook.h

Addresses_RESOURCE_FILES=ScriptingInfo.plist
Addresses_LOCALIZED_RESOURCE_FILES=PropertiesAndLabels.strings
Addresses_LANGUAGES=Dutch English French German Spanish

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/framework.make
-include GNUmakefile.postamble

ifneq ($(FOUNDATION_LIB), apple)
after-Addresses-install::
	@echo "Installing the compatibility header <AddressBook/AddressBook.h> ..."
	-$(MKINSTALLDIRS) $(GNUSTEP_HEADERS)/AddressBook
	-$(INSTALL_DATA)  AddressBook.h $(GNUSTEP_HEADERS)/AddressBook/
endif

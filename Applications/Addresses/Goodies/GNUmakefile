include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECTS =

ifneq (yes,$(disable-vcfviewer))
SUBPROJECTS += VCFViewer
endif

ifneq (yes,$(disable-adgnumailconverter))
SUBPROJECTS += adgnumailconverter
endif

ifneq (yes,$(disable-adserver))
SUBPROJECTS += adserver
endif

ifneq (yes,$(disable-adtool))
SUBPROJECTS += adtool
endif

ifneq (yes,$(disable-ldapaddressbook))
SUBPROJECTS += LDAPAddressBook
endif

-include GNUMakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUMakefile.postamble


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

PACKAGE_NAME = Addresses
CVS_MODULE_NAME = Addresses
VERSION = 0.4.9

SUBPROJECTS =     \
   Frameworks     \
   AddressManager     

-include GNUMakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUMakefile.postamble

after-clean::
	$(MAKE) -C Goodies clean
after-distclean::
	$(MAKE) -C Goodies distclean
goodies:
	$(MAKE) -C Goodies
goodies-install:
	$(MAKE) -C Goodies install

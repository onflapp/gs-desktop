# -*-makefile-*-

ADDITIONAL_INCLUDE_DIRS += $(foreach fdir,$(foreach fdir,$(FRAMEWORKS_DIRS),$(foreach framework,$(FRAMEWORKS),$(wildcard $(fdir)/$(framework).framework))),-I$(fdir)/Headers)
ifeq (yes, $(local-build))
  _ldflags = $(foreach framework,$(FRAMEWORKS),$(foreach efdir,$(foreach fdir,$(FRAMEWORKS_DIRS),$(wildcard $(fdir)/$(framework).framework)), -Wl,-rpath,$(if $(wildcard $(shell pwd)/$(efdir)),$(shell pwd)/$(efdir),$(efdir))/Versions/Current -L$(efdir)/Versions/Current) -l$(framework))
else
  _ldflags = $(foreach framework,$(FRAMEWORKS),$(foreach efdir,$(foreach fdir,$(FRAMEWORKS_DIRS),$(wildcard $(fdir)/$(framework).framework)), -L$(efdir)/Versions/Current) -l$(framework))
endif

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
ADDITIONAL_GUI_LIBS += -L$(FRAMEWORKS_DIRS)/../../Cynthiune.app $(_ldflags)
else
ADDITIONAL_GUI_LIBS += $(_ldflags)
endif

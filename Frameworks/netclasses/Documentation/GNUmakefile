include $(GNUSTEP_MAKEFILES)/common.make

DOCUMENT_NAME = netclasses

netclasses_DOC_INSTALL_DIR = Developer/
netclasses_AGSDOC_FILES = index.gsdoc overview.gsdoc synchronous.gsdoc \
  ../Source/NetBase.h ../Source/NetBase.m ../Source/LineObject.h\
  ../Source/LineObject.m ../Source/NetTCP.h ../Source/NetTCP.m\
  ../Source/IRCObject.h ../Source/IRCObject.m

# netclasses_INSTALL_FILES = rfc1459.txt 
# We do this step manually in the postamble.  I really don't like how
# the documentation puts the autogsdoc files in a different place than
# the regularly installed files.  So I made sure that didn't happen

netclasses_AGSDOC_FLAGS = -Up index

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/documentation.make
-include GNUmakefile.postamble


#
#	GNUmakefile
#
#       Compile the xpdf backend that is used by ImageKit to render
#       PDF content.
#
#	Copyright (C) 2003 Stefan Kleine Stegemann <stefan@wms-network.de>
#
#	This Makefile is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public License
#	as published by the Free Software Foundation; either version 2
#	of the License, or (at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#	See the GNU General Public License for more details.
#

include $(GNUSTEP_MAKEFILES)/common.make
include ../xpdf-src

SUBPROJECT_NAME = xpdf

xpdf_SUBPROJECTS = \
	bridge

xpdf_C_FILES = 

SUBPROJECTS = \
	$(XPDF_SRC)

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble

# GNUmakefile - this file is part of Cynthiune
#
# Copyright (C) 2010 Free Software Foundation, Inc.
#
# Author: Yavor Doganov <yavor@gnu.org>
#
# Cynthiune is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# Cynthiune is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
# Boston, MA 02110-1301, USA.

include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = ALSA
BUNDLE_NAME = ALSA
BUNDLE_EXTENSION = .output
BUNDLE_INSTALL_DIR = $(GNUSTEP_BUNDLES)/Cynthiune
ALSA_PRINCIPAL_CLASS = ALSA

ALSA_HEADERS = ALSA.h

ALSA_OBJC_FILES = ALSA.m

ADDITIONAL_INCLUDE_DIRS += -I../../Frameworks

FRAMEWORKS_DIRS = ../../Frameworks/Cynthiune
FRAMEWORKS = Cynthiune

include ../../frameworks.make

include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

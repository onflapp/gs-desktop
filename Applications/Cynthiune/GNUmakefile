# GNUmakefile - this file is part of Cynthiune
#
# Copyright (C) 2003-2006  Wolfgang Sourdeau
#
# Author: Wolfgang Sourdeau <wolfgang@contre.com>
#
# This file is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.
#

include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORKS_DIRS = Frameworks/Cynthiune
FRAMEWORKS = Cynthiune

#
# Subprojects
#

BUNDLES =

ifneq (yes,$(disable-bundles))
ifneq (yes,$(disable-mp3))
BUNDLES += MP3

ifneq (yes,$(disable-id3tag))
BUNDLES += ID3Tag
endif

endif

ifneq (yes,$(disable-ogg))
BUNDLES += Ogg

ifneq (yes,$(disable-vorbistags))
BUNDLES += VorbisTags
endif

endif

ifneq (yes,$(disable-audiofile))
BUNDLES += AudioFile
endif

ifneq (yes,$(disable-flac))
BUNDLES += FLAC

ifneq (yes,$(disable-flactags))
BUNDLES += FLACTags
endif

endif

ifneq (yes,$(disable-mod))
BUNDLES += Mod
endif

ifneq (yes,$(disable-windowsmedia))
BUNDLES += WindowsMedia
endif

ifneq (yes,$(disable-musepack))
BUNDLES += Musepack
endif

ifneq (yes,$(disable-timidity))
BUNDLES += Timidity
endif
ifneq (yes,$(disable-taglib))
BUNDLES += Taglib
endif

ifneq (yes,$(disable-asftags))
BUNDLES += ASFTags
endif

ifeq (mingw32,$(GNUSTEP_TARGET_OS))

ifneq (yes,$(disable-waveout))
BUNDLES += WaveOut
endif

else

# GNUSTEP_TARGET_OS is defined to `linux-gnueabi' on armel and
# `linux-gnuspe' on powerpcspe.
ifneq (,$(findstring linux-gnu,$(GNUSTEP_TARGET_OS)))

ifneq (yes,$(disable-alsa))
BUNDLES += ALSA
endif

endif

ifneq (yes,$(disable-oss))
#BUNDLES += OSS
endif

# sndio is OpenBSD only
ifeq ($(findstring openbsd, $(GNUSTEP_TARGET_OS)), openbsd)
ifneq (yes,$(disable-sndio))
BUNDLES += Sndio
endif
endif

ifneq (yes,$(disable-esound))
#BUNDLES += Esound
endif

ifneq (yes,$(disable-ao))
BUNDLES += AO
endif

# disable arts by default, rarely used
ifeq (yes,$(enable-arts))
BUNDLES += aRts
endif

endif

endif

SUBPROJECTS = Frameworks/Cynthiune $(addprefix Bundles/,$(BUNDLES))

#
# Main application
#

PACKAGE_NAME=Cynthiune
APP_NAME=Cynthiune
VERSION=1.0.0

Cynthiune_APPLICATION_ICON=Cynthiune.tiff
Cynthiune_MAIN_MODEL_FILE=Cynthiune.gorm
Cynthiune_LANGUAGES= \
Armenian English French German Hungarian Italian \
Slovak Spanish TraditionalChinese
Cynthiune_LOCALIZED_RESOURCE_FILES=Localizable.strings

#
# Additional libraries
#

ADDITIONAL_GUI_LIBS +=

#
# Resource files
#

NIB_FILES = \
Cynthiune.gorm \
GeneralPreference.gorm \
Preferences.gorm \
SongInspector.gorm

buttons_IMAGE_FILES = \
Images/add.tiff \
Images/cleanup.tiff \
Images/eject.tiff \
Images/eject-pushed.tiff \
Images/next.tiff \
Images/next-pushed.tiff \
Images/pause.tiff \
Images/pause-pushed.tiff \
Images/play.tiff \
Images/play-pushed.tiff \
Images/playlist.tiff \
Images/playlist-pushed.tiff \
Images/previous.tiff \
Images/previous-pushed.tiff \
Images/remove.tiff \
Images/repeat.tiff \
Images/repeat-pushed.tiff \
Images/save-as.tiff \
Images/shuffle.tiff \
Images/shuffle-pushed.tiff \
Images/song-inspector.tiff \
Images/song-inspector-pushed.tiff \
Images/stop.tiff \
Images/stop-pushed.tiff

Cynthiune_RESOURCE_FILES= \
Images/Cynthiune.tiff \
Images/Cynthiune-song-48.tiff \
Images/Cynthiune-playlist-48.tiff \
Images/cynthiune-splash.tiff \
Images/cynthiune-splash-faded.tiff \
Images/anim-logo-1.tiff \
Images/anim-logo-2.tiff \
Images/anim-logo-3.tiff \
Images/anim-logo-4.tiff \
Images/anim-logo-5.tiff \
Images/anim-logo-6.tiff \
Images/anim-logo-7.tiff \
Images/anim-logo-8.tiff \
Images/lock.tiff \
Images/lookup-mb-on.tiff \
Images/lookup-mb-off.tiff \
Images/dragged-song.tiff \
Images/dragged-songs.tiff \
Images/slider-knob-disabled.tiff \
Images/slider-knob-enabled.tiff \
Images/song-pointer.tiff \
Images/common_ToolbarSeparatorItem.tiff \
$(buttons_IMAGE_FILES) \
$(NIB_FILES) \
COPYING

#
# Header files
#

Cynthiune_HEADERS= \
BundleManager.h \
CynthiuneAnimatedImageView.h \
CynthiuneController.h \
CynthiuneFadingTextField.h \
CynthiuneHeaderCell.h \
CynthiunePauseButton.h \
CynthiunePopUpButton.h \
CynthiuneSliderCell.h \
CynthiuneSongTitleCell.h \
CynthiuneTextCell.h \
CynthiuneWindow.h \
DictionaryCoder.h \
FormatTester.h \
GeneralPreference.h \
InfoDisplayController.h \
M3UArchiver.h \
MBResultsPanel.h \
Player.h \
PlayerController.h \
PlayerPreference.h \
Playlist.h \
PlaylistArchiver.h \
PlaylistController.h \
PlaylistView.h \
PlaylistViewController.h \
PLSArchiver.h \
PreferencesController.h \
Song.h \
SongInspectorController.h

#
# Class files
#

Cynthiune_OBJC_FILES= \
main.m \
BundleManager.m \
CynthiuneAnimatedImageView.m \
CynthiuneController.m \
CynthiuneFadingTextField.m \
CynthiuneHeaderCell.m \
CynthiunePauseButton.m \
CynthiunePopUpButton.m \
CynthiuneSliderCell.m \
CynthiuneSongTitleCell.m \
CynthiuneTextCell.m \
CynthiuneWindow.m \
DictionaryCoder.m \
FormatTester.m \
GeneralPreference.m \
InfoDisplayController.m \
M3UArchiver.m \
MBResultsPanel.m \
Player.m \
PlayerController.m \
PlayerPreference.m \
Playlist.m \
PlaylistArchiver.m \
PlaylistController.m \
PlaylistView.m \
PlaylistViewController.m \
PLSArchiver.m \
PreferencesController.m \
Song.m \
SongInspectorController.m

ifeq (yes,$(enable-goom))
Cynthiune_OBJC_FILES += GoomView.m
endif

ADDITIONAL_INCLUDE_DIRS += -IFrameworks

include frameworks.make

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble


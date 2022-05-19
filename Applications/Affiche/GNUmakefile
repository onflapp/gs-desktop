#
#  Affiche Makefile for GNUstep
#  Copyright (C) 2001, 2002
#
#  Author: Ludovic Marcotte <ludovic@Sophos.ca>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#   
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#   
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. */

include $(GNUSTEP_MAKEFILES)/common.make

# The application to be compiled
APP_NAME = Affiche

# The Objective-C source files to be compiled
Affiche_OBJC_FILES = Affiche.m ColorView.m Constants.m LabelWidget.m Note.m NoteInfoWindow.m NoteInfoWindowController.m NoteView.m NoteWindow.m NoteWindowController.m PreferencesPanel.m PreferencesPanelController.m

# The Objective-C headers
Affiche_HEADERS = Affiche.h  ColorView.h Constants.h LabelWidget.h Note.h NoteInfoWindow.h NoteInfoWindowController.h NoteView.m NoteWindow.h NoteWindowController.h PreferencesPanel.h PreferencesPanelController.h

# The Resource files to be copied into the app's resources directory
Affiche_RESOURCE_FILES = Images/Affiche.tiff Images/buttons_blue.tiff Images/resize_blue.tiff Images/buttons_green.tiff Images/resize_green.tiff Images/buttons_gray.tiff Images/resize_gray.tiff Images/buttons_purple.tiff Images/resize_purple.tiff Images/buttons_yellow.tiff Images/resize_yellow.tiff

Affiche_LANGUAGES = English French Lojban German Spanish Swedish

Affiche_LOCALIZED_RESOURCE_FILES = Localizable.strings

# We want to get all the warnings... 
ADDITIONAL_OBJCFLAGS = -Wall

include $(GNUSTEP_MAKEFILES)/application.make

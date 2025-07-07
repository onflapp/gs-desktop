/* -*- mode: objc -*- */
//
// Project: Preferences
//
// Copyright (C) 2014-2019 Sergii Stoian
//
// This application is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation; either
// version 2 of the License, or (at your option) any later version.
//
// This application is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Library General Public License for more details.
//
// You should have received a copy of the GNU General Public
// License along with this library; if not, write to the Free
// Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
//

#import <AppKit/AppKit.h>
#import "PrefsController.h"

@class NXTClockView;

@interface AppController : NSObject
{
  NXTClockView		*clockView;
  PrefsController	*prefsController;

  // Info -> Info Panel
  id infoPanel;
}

- (void)showPreferencesWindow;
- (void)showPreferencesForModule:(NSString*) name;
- (void)showPreferencesWindow:(id)sender;

@end

@interface AppController (ModulesDelegate)

// Display and Screen
- (void)applySavedDisplayPreferences;
- (void)saveDisplayPreferences;
// Info Panel
- (void)showInfoPanel:(id)sender;
@end



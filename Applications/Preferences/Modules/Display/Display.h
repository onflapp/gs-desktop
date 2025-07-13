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

#import <AppKit/NSImage.h>
#import <AppKit/NSColorWell.h>
#import <Preferences.h>

@interface DisplayPrefs : NSObject <PrefsModule>
{
  id view;
  id window;
  id brightnessBox;
  id brightnessField;
  id brightnessSlider;
  id gammaField;
  id gammaSlider;
  id monitorsList;
  id monitorsScroll;
  id rateBtn;
  id resolutionBtn;
  id rotationBtn;
  id reflectionBtn;
  id managedBackgroundBtn;
  NSColorWell *colorBtn;

  NSImage    *image;
  OSEScreen  *systemScreen;
  OSEDisplay *selectedDisplay;
  NSColor    *desktopBackground;

  NSTimer    *saveConfigTimer;

  NSTimeInterval lastChange;
}

//
// Helper methods
//
- (void)fillRateButton;
- (void)setResolution;
- (void)selectFirstEnabledMonitor;

@end

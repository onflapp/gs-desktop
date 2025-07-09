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

@interface Mixer : NSObject
{
  SNDServer *soundServer;
  id window;
  id cardWindow;
  id infoWindow;
  
  //
  id modeButton;
  //
  id deviceProfileBtn;
  //
  id appBrowser;
  id appMuteBtn;
  id appVolumeSlider;
  id appVolumeMuteImg;
  id appVolumeLoudImg;
  //
  id deviceBox;
  id cardDescription;
  id cardBtn;
  id deviceMuteBtn;
  id devicePortBtn;
  id deviceVolumeSlider;
  id deviceBalance;
  id deviceVolumeMuteImg;
  id deviceVolumeLoudImg;
  id deviceBalanceLeftImg;
  id deviceBalanceRightImg;

  SNDStream *selectedApp;
}

- (id)initWithServer:(SNDServer *)server;
- (id)window;

- (void)reloadAppBrowser;
- (void)updateDeviceList;
- (void)updateProfileList;
- (void)updateDeviceControls;

@end

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
#import <Preferences.h>
#import "UserManager.h"

typedef enum {
  PAMStart,
  PAMEnterOld,
  PAMEnterNew,
  PAMConfirmNew,
  PAMAbort
} PasswordState;

@interface Password: NSObject <PrefsModule>
{
  id window;
  id view;
  id lockView;

  id passwordBox;
  id messageField;
  id passwordField;
  id infoField;

  id nameField;
  id shellField;
  id userField;

  id okButton;
  id cancelButton;

  NSImage *lockOpenImage;
  NSImage *lockImage;
  NSImage *image;
  NSTimer *fieldTimer;

  PasswordState state;

  UserManager *userManager;
  id userManagerView;
}

- (NSString *)password;
- (void)setMessage:(NSString *)text;
- (void)setInfo:(NSString *)text;

@end

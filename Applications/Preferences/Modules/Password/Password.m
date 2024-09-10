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

#include <unistd.h>
#include <string.h>
#include <pwd.h>

#import <Foundation/Foundation.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSView.h>
#import <AppKit/NSBox.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSSecureTextField.h>
#import <AppKit/NSEvent.h>

#import "Password.h"

@implementation Password

- (void)dealloc
{
  NSLog(@"Password -dealloc");
  [image release];
  [userManager release];
  [super dealloc];
}

- (id)init
{
  NSBundle *bundle;
  
  self = [super init];
  
  bundle = [NSBundle bundleForClass:[self class]];
  image = [[NSImage alloc]
            initWithContentsOfFile:[bundle pathForResource:@"Password"
                                                    ofType:@"tiff"]];
  userManager = [[UserManager alloc]init];
  return self;
}

- (void)awakeFromNib
{
  [view retain];
  [window release];

  uid_t uid = geteuid();
  struct passwd *pwd = getpwuid(uid);

  if (pwd) {
    [nameField setStringValue:[NSString stringWithCString:pwd->pw_name]];
    [userField setStringValue:[NSString stringWithCString:pwd->pw_gecos]];
    [shellField setStringValue:[NSString stringWithCString:pwd->pw_shell]];
  }
  else {
    [nameField setStringValue:@"Unknown"];
  }  

  userManagerView = [userManager view];
  [view addSubview:userManagerView];
  [userManagerView setHidden:YES];
  [userManagerView setFrame:[view frame]];
}

- (NSView *)view
{
  if (view == nil) {
    if (![NSBundle loadNibNamed:@"Password" owner:self]) {
      NSLog (@"Password.preferences: Could not load NIB, aborting.");
      return nil;
    }
  }
  
  return view;
}

- (NSString *)buttonCaption
{
  return @"Password Preferences";
}

- (NSImage *)buttonImage
{
  return image;
}

//
// Action methods
//

- (void)manageUsers:(id)sender
{
  [userManagerView setHidden:NO];
  [userManager showPanelAndRunManager:sender];
}

@end

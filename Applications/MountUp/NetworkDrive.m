/*
   Project: MountUp

   Copyright (C) 2022 Free Software Foundation

   Author: Parallels

   Created: 2022-11-02 17:46:05 +0000 by parallels

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "NetworkDrive.h"
#import "NetworkServiceTask.h"

@implementation NetworkDrive
- (id) init {
  self = [super init];

  [NSBundle loadNibNamed:@"NetworkDrive" owner:self];
  [panel setFrameAutosaveName:@"network_window"];

  return self;
}

- (void) dealloc {
  [super dealloc];
}

- (IBAction) connect:(id) sender {
  if ([[location stringValue] length] == 0) return;
  NSInteger i = [type indexOfSelectedItem];
  NSString* ustr = [user stringValue];
  NSString* pstr = [password stringValue];

  NSMutableString* url = [NSMutableString string];
  if (i == 1) {
    [url appendString:@"dav://"];
  }
  else if (i == 2) {
    [url appendFormat:@"sftp://%@@", ustr];
  }
  else {
    [url appendString:@"smb://"];
    ustr = [ustr stringByAppendingString:@"\n"];//default domain
  }
  [url appendString:[location stringValue]];

  NetworkServiceTask* task = [[NetworkServiceTask alloc]initWithURL:url];
  [task setUser:ustr];
  [task setPassword:pstr];
  [task startTask];

  [panel orderOut:self];
}

- (void) showPanel {  
  [panel makeKeyAndOrderFront:self];
}

- (void) showPanelWithURL:(NSURL*)url {
  NSString* h = [url host];
  NSString* u = [url user];
  NSString* x = [url password];
  NSString* p = [url path];
  NSString* t = [url scheme];
  NSNumber* o = [url port];

  if (x) [password setStringValue:x];
  if (u) [user setStringValue:u];

  if (h) {
    NSMutableString* l = [NSMutableString string];
    [l appendString:h];
    if (o) {
      [l appendFormat:@":%@", o];
    }
    if (p) {
      p = [p stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      [l appendString:p];
    }

    [location setStringValue:l];
  }

  if ([t isEqualToString:@"dav"] || [t isEqualToString:@"davs"]) {
    [type selectItemAtIndex:1];
  }
  else if ([t isEqualToString:@"sftp"]) {
    [type selectItemAtIndex:2];
  }
  else {
    [type selectItemAtIndex:0];
  }

  [panel makeKeyAndOrderFront:self];
}

- (void) closePanel {
  [panel orderOut:self];
}

@end

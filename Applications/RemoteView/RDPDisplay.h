/*
   Project: RemoteView

   Copyright (C) 2023 Free Software Foundation

   Author: Parallels

   Created: 2023-05-09 07:51:37 +0000 by parallels

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

#ifndef _RDPDISPLAY_H_
#define _RDPDISPLAY_H_

#import <AppKit/AppKit.h>
#import "RDPDisplayView.h"

@interface RDPDisplay : NSObject
{
  BOOL connected;
  NSWindow* window;
  RDPDisplayView* displayView;

  NSURL* displayURL;

  NSTask* task;
  NSFileHandle* fin;
  NSFileHandle* fout;
  NSMutableData* buff;
}
- (void) connect;
- (void) setURL:(NSURL*) url;
- (void) showWindow;

@end

#endif // _RDPDISPLAY_H_


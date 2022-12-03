/*
   Project: Player

   Copyright (C) 2022 Free Software Foundation

   Author: Parallels

   Created: 2022-11-02 17:46:30 +0000 by parallels

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

#ifndef _MEDIADOCUMENT_H_
#define _MEDIADOCUMENT_H_

#import <AppKit/AppKit.h>

@interface MediaDocument : NSObject
{
  IBOutlet NSWindow* window;
  IBOutlet NSButton* playButton;
  IBOutlet NSTextField* statusField;
  IBOutlet NSSlider* locationSlider;

  NSString* mediaFile;
  
  NSTask* task;
  NSFileHandle* fin;
  NSFileHandle* fout;
  NSMutableData* buff;

  BOOL running;
  BOOL playing;
  BOOL paused;
  NSInteger len;
  NSInteger pos;
  NSInteger __linepart;

  NSInteger volume;
}

- (void) loadFile:(NSString*) file;

- (IBAction) play:(id) sender;

@end

#endif // _MEDIADOCUMENT_H_


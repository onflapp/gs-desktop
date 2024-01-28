/*
   Project: VolMon

   Copyright (C) 2022 Free Software Foundation

   Author: ,,,

   Created: 2022-11-01 20:28:45 +0000 by pi

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

#ifndef _MINIVIEW_H_
#define _MINIVIEW_H_

#import <AppKit/AppKit.h>

@interface MiniViewTextField : NSTextField
{
}
@end

@interface MiniView : NSView
{
  NSImage *tileImage;
}

@end

#endif // _MINIVIEW_H_


/* Copyright (C) 2004 Raffael Herzog
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 * $Id: WrapperDelegate.h 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/libGSWrapper/WrapperDelegate.h $
 */

#ifndef GSWrapper_libGSWrapper_WrappedApp_H
#define GSWrapper_libGSWrapper_WrappedApp_H


#import <AppKit/AppKit.h>
#import "Actions.h"
#import "ShellUIProxy.h"
#import "ShellUITask.h"
#import "WrappedWin.h"
#include "X11/Xutil.h"
#include "X11/Xatom.h"

@interface WrappedApp : NSObject
{
  BOOL wrappedAppIsActive;
  NSTimeInterval lastActionTime;
  NSString* wrappedAppClassName;
  id delegate;
}

- (id)initWithClassName:(NSString*) cname;
- (void) startObservingEvents;
- (NSString*)wrappedAppClassName;
- (void)setDelegate:(id)del;
- (BOOL)isActive;
- (WrappedWin*) wrappedWindowForID:(Window) wid;

@end

#endif

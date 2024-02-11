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

#ifndef GSWrapper_libGSWrapper_WrappedWin_H
#define GSWrapper_libGSWrapper_WrappedWin_H


#import <AppKit/AppKit.h>
#import "Actions.h"
#import "ShellUIProxy.h"
#import "ShellUITask.h"
#include "X11/Xutil.h"

@interface WrappedWin : NSWindow
{
  Window winid;
}
- (id)initWithWindowID:(Window) wid;
- (Window) windowID;
@end

#endif

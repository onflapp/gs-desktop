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
 * $Id: NSApplication+AppName.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/libGSWrapper/NSApplication+AppName.m $
 */

#include <AppKit/AppKit.h>

#include "NSApplication+AppName.h"

@implementation MYApplication

- (BOOL) suppressActivation
{
    return suppressActivation;
}

- (void) setSuppressActivation:(BOOL) flag
{
    suppressActivation = flag;
}
- (void) activateIgnoringOtherApps:(BOOL) flag
{
    if (suppressActivation) {
        NSLog(@"activateIgnoringOtherApps, suppress");
    }
    else {
        [super activateIgnoringOtherApps:flag];
    }
}
- (void) setKeyWindow:(id) key
{
    if (suppressActivation) {
        ASSIGN(keyWindow, key);
    }
}
- (id) keyWindow
{
    if (suppressActivation) {
        return keyWindow;
    }
    else {
        return [super keyWindow];
    }
}

@end

@implementation NSApplication (AppName)
+ (NSApplication *) sharedApplication
{
    if (NSApp == nil) 
    {
        [[MYApplication alloc] init];
    }
    return NSApp;
}


- (NSString *)applicationName
{
    return (NSString *)[[[NSBundle mainBundle] infoDictionary] objectForKey: @"ApplicationName"];
}

@end

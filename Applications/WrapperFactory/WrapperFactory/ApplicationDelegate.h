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
 * $Id: ApplicationDelegate.h 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/ApplicationDelegate.h $
 */

#ifndef _GSWrapper_GSWrapper_H
#define _GSWrapper_GSWrapper_H

#include <AppKit/AppKit.h>

#include "ServicesProvider.h"


@interface ApplicationDelegate : NSObject
{
    IBOutlet NSMenuItem *windowsMenuItem;
    IBOutlet NSMenuItem *servicesMenuItem;

    ServicesProvider *servicesProvider;
}


- (void)awakeFromNib;


/*
 * application delegate
 */

- (void)applicationDidFinishLaunching: (NSNotification *)not;
- (void)applicationDidFinishLaunching: (NSNotification *)not;
- (NSApplicationTerminateReply)applicationShouldTerminate: (NSNotification *)not;
- (void)applicationWillTerminate: (NSNotification *)not;

- (void)application: (NSApplication *)app
           openFile: (NSString *)file;
- (void)application: (NSApplication *)app
          openFiles: (NSArray *)files;


/*
 * outlets
 */

- (void)setWindowsMenuItem: (NSMenuItem *)menuItem;
//- (NSMenu *)windowsMenu;

- (void)setServicesMenuItem: (NSMenuItem *)menuItem;
//- (NSMenu *)servicesMenu;

@end


#endif

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
 * $Id: ApplicationDelegate.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/ApplicationDelegate.m $
 */

#include <AppKit/AppKit.h>

#include "ApplicationDelegate.h"
#include "WrapperDocument.h"


@implementation ApplicationDelegate

- (void)awakeFromNib
{
    //documentController = [NSDocumentController sharedController];
}


/*
 * Application delegate
 */

- (void)applicationWillFinishLaunching: (NSNotification *)not
{
    [NSApp setWindowsMenu: [windowsMenuItem submenu]];
    [NSApp setServicesMenu: [servicesMenuItem submenu]];
    NSArray *types = [NSArray arrayWithObjects: NSStringPboardType, NSTIFFPboardType, nil];
    RETAIN(types);
    [NSApp registerServicesMenuSendTypes: types
           returnTypes: (types)];
}

- (void)applicationDidFinishLaunching: (NSNotification *)not
{
    servicesProvider = [[ServicesProvider alloc] init];
    [NSApp setServicesProvider: servicesProvider];
}

- (BOOL)applicationOpenUntitledFile: (NSApplication *)app
{
    [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType: ApplicationType
                                                     display: (YES)];
    return YES;
}

- (BOOL)applicationShouldOpenUntitledFile: (NSApplication *)app
{
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate: (NSNotification *)not
{
    if ( [[NSDocumentController sharedDocumentController] closeAllDocuments] ) {
        return NSTerminateNow;
    }
    else {
        return NSTerminateCancel;
    }
}

- (void)applicationWillTerminate: (NSNotification *)not
{
}


- (void)application: (NSApplication *)app
           openFile: (NSString *)file
{
    [self application: app
          openFiles: ([NSArray arrayWithObject: file])];
    //openFiles: (AUTORELEASE([NSArray arrayWithObject: file]))];
}

- (void)application: (NSApplication *)app
          openFiles: (NSArray *)files
{
    int i;
    int count = [files count];
    NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
    for ( i=0; i<count; i++ ) {
        NSString *f = [files objectAtIndex: i];
        [documentController openDocumentWithContentsOfFile: f
                            display: (YES)];
    }
}


/*
 * outlets
 */

- (void)setWindowsMenuItem: (NSMenuItem *)menuItem
{
    windowsMenuItem = menuItem;
}

- (void)setServicesMenuItem: (NSMenuItem *)menuItem
{
    servicesMenuItem = menuItem;
}

@end

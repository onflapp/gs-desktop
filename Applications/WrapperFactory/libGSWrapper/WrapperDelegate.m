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
 * $Id: WrapperDelegate.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/libGSWrapper/WrapperDelegate.m $
 */

#include <AppKit/AppKit.h>

#include "WrapperDelegate.h"
#include "NSApplication+AppName.h"


@implementation WrapperDelegate

/*
 * application delegate
 */

- (id)init
{
    self = [super init];
    appDidFinishLaunching = NO;
    startupFiles = nil;
    return self;
}

- (void)applicationWillFinishLaunching: (NSNotification*)not
{
}

- (void)applicationDidFinishLaunching: (NSNotification*)not
{
    appDidFinishLaunching = YES;

    NSString *path = [[NSBundle mainBundle] pathForResource: @"GSWrapper"
                                            ofType: @"plist"];
    properties = RETAIN([NSDictionary dictionaryWithContentsOfFile: path]);

    if ( startupFiles ) {
        mainAction = [self actionForMessage: @"StartOpen"];
    }
    else {
        mainAction = [self actionForMessage: @"Start"];
    }
    [mainAction executeWithFiles: startupFiles];
    if ( !mainAction ) {
        [NSApp terminate: self];
        return;
    }
    if ( ![mainAction task] ) {
        NSLog(@"Main action has no task assigned - exiting");
        [NSApp terminate: self];
        return;
    }

    [[NSNotificationCenter defaultCenter] addObserver: self
                                          selector: @selector(unixAppExited:)
                                          name: (NSTaskDidTerminateNotification)
                                          object: [mainAction task]];
}

- (BOOL)application: (NSApplication*)app
           openFile: (NSString*)file
{
    return [self application: app
                 openFiles: [NSArray arrayWithObject: file]];
}

- (BOOL)application: (NSApplication*)app
          openFiles: (NSArray*)files
{
    NSLog(@"Open files: %@", files);
    if ( ! appDidFinishLaunching ) {
        startupFiles = RETAIN(files);
        return YES;
    }
    else {
        if ( !openAction ) {
            openAction = [self actionForMessage: @"Open"];
        }
        if ( !openAction ) {
            return NO;
        }

        BOOL retval = [openAction executeWithFiles: files];
        NSTask *task = [openAction task];
        if ( !task ) {
            return retval;
        }
        else {
            [task waitUntilExit];
            if ( [task terminationStatus] ) {
                NSRunCriticalAlertPanel([NSApp applicationName],
                                        [NSString stringWithFormat: @"Script exited with exit code %d",
                                                  [task terminationStatus]],
                                        @"OK", nil, nil);
                return NO;
            }
            else {
                return YES;
            }
        }
    }
}



/*
 * task notification
 */

- (void)unixAppExited: (NSNotification*)not
{
    int status = [[not object] terminationStatus];
    NSLog(@"UNIX application exited with code %d", status);
    if ( status ) {
        NSRunCriticalAlertPanel([NSApp applicationName],
                                [NSString stringWithFormat: @"UNIX appliation exited with exit code %d",
                                          status],
                                @"OK", nil, nil);
    }
    [NSApp terminate: self];
}



/*
 * initializing actions
 */

- (id<Action>)actionForMessage: (NSString *)msg
{
    NSDictionary *actionProps = [properties objectForKey: msg];
    if ( !actionProps ) {
        actionProps = AUTORELEASE([[NSDictionary alloc] init]);
    }
    NSString *actionName = [actionProps objectForKey: @"Action"];
    if ( ! actionName ) {
        NSLog(@"Warning: No type specified for message %@ - defaulting to RunScript", msg);
        actionName = @"RunScript";
    }
    if ( [actionName isEqualToString: @"RunScript"] ) {
        return [[RunScriptAction alloc] initWithActionName: msg properties: actionProps];
    }
    else if ( [actionName isEqualToString: @"Fail"] ) {
        return [[ErrorDialogAction alloc] initWithActionName: msg properties: actionProps];
    }
    else if ( [actionName isEqualToString: @"Ignore"] ) {
        return [[IgnoreAction alloc] initWithActionName: msg properties: actionProps];
    }
    else {
        NSRunCriticalAlertPanel([NSApp applicationName],
                                [NSString stringWithFormat: @"Unknown action %@ specified for message %@", actionName, msg],
                                @"OK", nil, nil);
        return nil;
    }
}

@end

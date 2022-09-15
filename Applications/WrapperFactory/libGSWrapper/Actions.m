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
 * $Id: Actions.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/libGSWrapper/Actions.m $
 */

#include <AppKit/AppKit.h>

#include "Actions.h"

#include "NSApplication+AppName.h"


@implementation AbstractAction

- (id)initWithActionName: (NSString *)name
              properties: (NSDictionary *)props
{
    self = [self init];
    if ( self ) {
        actionName = RETAIN(name);
        properties = RETAIN(props);
    }
    return self;
}

- (BOOL)execute
{
    return [self executeWithFiles: nil];
}

- (BOOL)executeWithFiles: (NSArray *)files
{
    [NSException raise: @"NotImplementedException"
                 format: @"- (BOOL)exceptionWithFiles is not implemented in %@", [self class]];
    return NO;
}

- (NSString *)name
{
    return actionName;
}

- (NSTask *)task
{
    return nil;
}

- (NSDictionary *)properties
{
    return properties;
}

@end


@implementation ErrorDialogAction : AbstractAction

- (BOOL)executeWithFiles: (NSArray *)files
{
    NSRunInformationalAlertPanel([NSApp applicationName],
                                 [NSString stringWithFormat: @"The action \'%@\' is not supported", [self name]],
                                 @"OK", nil, nil);
    return NO;
}

@end


@implementation IgnoreAction

- (BOOL)executeWithFiles: (NSArray *)files;
{
    NSLog(@"Ignored action %@", [self name]);
    return NO;
}

@end


@implementation RunScriptAction

- (BOOL)executeWithFiles: (NSArray *)files;
{
    NSString *shell;
    NSString *script;
    NSArray *args;
    NSMutableArray *realArgs;
    int fileCount;
    int i;

    if ( files ) {
        fileCount = [files count];
    }
    else {
        fileCount = 0;
    }

    script = [[NSBundle mainBundle] pathForResource: [self name]
                                    ofType: (nil)];
    if ( ! script ) {
        NSRunCriticalAlertPanel([NSApp applicationName],
                                [NSString stringWithFormat: @"Could not find script for action %@", [self name]],
                                @"OK", nil, nil);
        return NO;
    }
    shell = [[self properties] objectForKey: @"Shell"];
    if ( ! shell ) {
        shell = @"/bin/sh";
    }
    args = [[self properties] objectForKey: @"ShellArgs"];
    if ( args ) {
        int argCount = [args count];
        realArgs = [NSMutableArray arrayWithCapacity: argCount+fileCount];
        for ( i=0; i<argCount; i++ ) {
            [realArgs addObject: [NSString stringWithFormat: [args objectAtIndex: i], script]];
        }
    }
    else {
        realArgs = [NSMutableArray arrayWithCapacity: fileCount+1];
        [realArgs addObject: script];
    }
    for ( i=0; i<fileCount; i++ ) {
        [realArgs addObject: [files objectAtIndex: i]];
    }

    NSLog(@"Shell: %@", shell);
    NSLog(@"Script: %@", script);
    NSLog(@"Arguments: %@", realArgs);

    task = [[NSTask alloc] init];
    [task setLaunchPath: shell];
    [task setArguments: realArgs];
    [task launch];

    return YES;
}

- (NSTask *)task
{
    return task;
}

@end

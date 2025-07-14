/**
    ScriptingSupport
    Code for loading scripting
    
    Copy and include this file into your application project.
    
    NOTE: Please, do not modify this file. It is part of the StepTalk and
    depends on its interface.   
  
    Copyright (c) 2002 Stefan Urbanek
  
    Written by: Stefan Urbanek <urbanek@host.sk>
    Date: 2002 Apr 13
 
    This file is part of the StepTalk project.
 
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.
  
    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

   */

#include "STScriptingSupport.h"

#include <AppKit/NSApplication.h>
#include <AppKit/NSPanel.h>

#include <Foundation/NSArray.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSString.h>

@interface NSApplication (STPrivateMethods)
- (BOOL)setUpApplicationScripting;
- (NSBundle *) _applicationScriptingBundle;
@end

@implementation NSApplication(STApplicationScriptingInit)
- (BOOL)initializeApplicationScripting
{
    NSBundle      *bundle;

    if(![self isScriptingSupported])
    {
        NSRunAlertPanel(@"Invalid usage of scripting support",
                        @"Please, contact the author of this application "
                        @"and let him know about this error. The author forgot "
                        @"to check whether the scripting is supported or not.",
                        @"Cancel", nil, nil);

        return NO;
    }

    NSLog(@"Loading application scripting support");

    bundle = [self _applicationScriptingBundle];

    if(bundle)
    {
        /* Load the bundle! */

        [[bundle principalClass] class];
        if([self respondsToSelector:@selector(setUpApplicationScripting)])
        {
            return [self setUpApplicationScripting];
        }
        else
        {
            NSRunAlertPanel(@"Broken scripting support",
                            @"Scripting support cannot be loaded, because "
                            @"the application scripting bundle is broken.",
                            @"Cancel", nil, nil);
            return NO;
        }
    }
    else
    {
        NSRunAlertPanel(@"Broken scripting support",
                        @"Application scripting bundle cannot be loaded.",
                        @"Cancel", nil, nil);
        return NO;
    }
}

- (BOOL)isScriptingSupported
{
    return ([self _applicationScriptingBundle] != nil);
}

- (NSBundle *)_applicationScriptingBundle
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSEnumerator  *enumerator;
    NSString      *path;
    NSArray       *paths;
    BOOL           isDir;

    paths = NSStandardLibraryPaths();

    enumerator = [paths objectEnumerator];
    
    while( (path = [enumerator nextObject]) )
    {
    
        path = [path stringByAppendingPathComponent:@"Bundles"];
        path = [path stringByAppendingPathComponent:@"ApplicationScripting"];
        path = [path stringByAppendingPathExtension:@"bundle"];

        if( [manager fileExistsAtPath:path isDirectory:&isDir] && isDir)
        {
            return [NSBundle bundleWithPath:path];
        }
    }
    
    return nil;
}

- (void)_loadAppTalkAndRetryAction:(SEL)sel with:(id)anObject
{
    static BOOL isIn = NO;
    
    if(isIn)
    {
        NSLog(@"Error occured while loading application scripting support");

        isIn = NO;
        return;
    }
    
    isIn = YES;

    if([self initializeApplicationScripting])
    {
        [self performSelector:sel withObject:anObject];
    }

    isIn = NO;
}

- (id)_loadAppTalkAndRetryAction:(SEL)sel
{
    static BOOL isIn = NO;
    id          retval = nil;
    
    if(isIn)
    {
        NSLog(@"Error occured while loading application scripting support");

        isIn = NO;
        return nil;
    }
    
    isIn = YES;

    if([self initializeApplicationScripting])
    {
        retval = [self performSelector:sel];
    }

    isIn = NO;
    
    return retval;
}

/* 
 * doesn't work as it used to, maybe this is due to new runtime?
 * in any case, this should not been needed as we initilized the scripting in the delegate
 *
- (void)orderFrontScriptsPanel:(id)sender
{
    [self _loadAppTalkAndRetryAction:_cmd with:sender];
}

- (void)orderFrontTranscriptWindow:(id)sender
{
    [self _loadAppTalkAndRetryAction:_cmd with:sender];
}
- (NSMenu *)scriptingMenu
{
    return [self _loadAppTalkAndRetryAction:_cmd];
}
*/
@end

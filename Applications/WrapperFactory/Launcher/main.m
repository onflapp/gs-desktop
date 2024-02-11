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
 * $Id: main.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/Launcher/main.m $
 */

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include "WrapperDelegate.h"

static NSBundle* __my_main_bundle;

@interface NSBundle (Launcher)
+ (NSBundle*) mainBundle;
@end

@implementation NSBundle (Launcher)
+ (NSBundle*) mainBundle 
{
    return __my_main_bundle;
}
@end

static NSString* __my_process_name;
static NSString* __my_process_cmd;
static NSMutableArray* __my_process_args;

@interface NSProcessInfo (Launcher)
- (NSString*) processName;
- (NSArray*) arguments;
@end

@implementation NSProcessInfo (Launcher)
- (NSString*) processName 
{
    return __my_process_name;
}
- (NSArray*) arguments 
{
    return __my_process_args;
}
@end

int main(int argc, const char *argv[]) {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* cd      = [fm currentDirectoryPath];
    __my_process_name = [[[cd lastPathComponent] stringByDeletingPathExtension] retain];
    __my_process_cmd  = [[cd stringByAppendingPathComponent:__my_process_name] retain];
    __my_process_args = [[NSMutableArray alloc] init];

    [__my_process_args addObject:__my_process_cmd];
    for (int c = 1; c < argc; c++) {
        NSString* a = [NSString stringWithUTF8String:argv[c]];
        [__my_process_args addObject:a];
    }

    __my_main_bundle  = [NSBundle bundleWithPath:cd];

    NSApplication* app = [NSConnection rootProxyForConnectionWithRegisteredName:__my_process_name host:nil];
    if (app) {
        NSLog(@"running already %@", app);
        [app activateIgnoringOtherApps:YES];
        return 0;
    }
    else {
        app = [NSApplication sharedApplication];
        [NSApp setDelegate: [[WrapperDelegate alloc] init]];
        return NSApplicationMain(argc, argv);
    }
}

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
 * $Id: ServicesProvider.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/ServicesProvider.m $
 */

#include <AppKit/AppKit.h>

#include "ServicesProvider.h"
#include "WrapperDocument.h"


@implementation ServicesProvider

- (void) dealloc
{
    NSLog(@"ServicesProvider dealloced");
}

- (void) createWrapperForExecutable: (NSPasteboard *)pboard
                           userData: (NSString *)userData
                              error: (NSString **)error
{
    NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
    NSArray *files = [pboard propertyListForType: NSFilenamesPboardType];
    NSString *file;
    NSString *appName;
    WrapperDocument *doc;
    NSString *userRoot = [[[NSProcessInfo processInfo] environment] objectForKey: @"GNUSTEP_USER_ROOT"];
    int i;
    int count = [files count];
    BOOL shouldCreate = [documentController shouldCreateUI];
    [documentController setShouldCreateUI: YES];
    [NSApp activateIgnoringOtherApps: YES];
    for ( i=0; i<count; i++ ) {
        file = [files objectAtIndex: i];
        doc = [documentController openUntitledDocumentOfType: ApplicationType
                                  display: (YES)];
        [doc setStartScript: [NSString stringWithFormat: @"exec %@", file]];
        [doc setStartOpenScript: [NSString stringWithFormat: @"exec %@ \"$@\"", file]];
        [doc setOpenScript: @"exit 1"];
        appName = [NSString stringWithFormat: @"%@.app", [file lastPathComponent]];
        [doc setName: appName];
        appName = [NSString pathWithComponents: [NSArray arrayWithObjects:
                                                         userRoot,
                                                         @"Applications",
                                                         appName,
                                                         nil]];

        //[doc setFileName: appName];
    }
    [documentController setShouldCreateUI: shouldCreate];
}

- (void) editWrapper: (NSPasteboard *)pboard
            userData: (NSString *)userData
               error: (NSString **)error
{
    NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
    NSArray *files = [pboard propertyListForType: NSFilenamesPboardType];
    NSMutableArray *failedFiles = AUTORELEASE([[NSMutableArray alloc] init]);
    NSString *file;
    NSDocument *doc;
    int i;
    int count = [files count];
    BOOL shouldCreate = [documentController shouldCreateUI];
    [documentController setShouldCreateUI: YES];
    for ( i=0; i<count; i++ ) {
        file = [files objectAtIndex: i];
        NSLog(@"Filename: %@", file);
        doc = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile: file
                                                               display: (YES)];
        if ( ! doc ) {
            [failedFiles addObject: file];
        }
        else {
            [NSApp activateIgnoringOtherApps: YES];
            [doc showWindows];
        }
    }
    [documentController setShouldCreateUI: shouldCreate];
    count = [failedFiles count];
    if ( count ) {
        NSString *format;
        if ( count == 1 ) {
            format = _(@"Failed to open file:\n%@");
        }
        else {
            format = _(@"Failed to open files:\n%@");
        }
        *error = [NSString stringWithFormat: format, [failedFiles componentsJoinedByString: @", "]];
    }
}

@end

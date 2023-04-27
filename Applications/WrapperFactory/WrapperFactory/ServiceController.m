/* Copyright (C) 2003 Raffael Herzog
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
 * $Id: TypeController.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/TypeController.m $
 */

#include <AppKit/AppKit.h>

#include "ServiceController.h"


@implementation ServiceController

- (Service *)service
{
    return service;
}
- (void)setService: (Service *)s
{
    ASSIGN(service, s);
    [nameTextField setStringValue: [service name]];
    [shellTextField setStringValue: [service shell]];
    [[[actionTextView textStorage] mutableString] setString:[service action]];

    NSString *type = [service returnType];
    NSInteger tag = 0;

    if ([type isEqualToString: @"NSStringPboardType"]) {
        tag = 1;
    }
    else if ([type isEqualToString: @"NSRTFPboardType"]) {
        tag = 10;
    }
    else if ([type isEqualToString: @"NSPDFPboardType"]) {
        tag = 11;
    }
    else if ([type isEqualToString: @"NSTIFFPboardType"]) {
        tag = 12;
    }
    
    [returnTypePopUp selectItemAtIndex: [returnTypePopUp indexOfItemWithTag: tag]];

    type = [service sendType];
    tag = 0;

    if ([type isEqualToString: @"NSStringPboardType"]) {
        tag = 1;
    }
    else if ([type isEqualToString: @"NSFilenamesPboardType"]) {
        tag = 2;
    }

    [sendTypePopUp selectItemAtIndex: [sendTypePopUp indexOfItemWithTag: tag]];
}

/*
 * UI actions
 */

- (void)changeType: (id) sender
{
    if ( sender == sendTypePopUp ) {
        NSInteger tag = [[sendTypePopUp selectedItem] tag];
        if (tag == 1) {
            [service setSendType:@"NSStringPboardType"];
        }
        else if (tag == 2) {
            [service setSendType:@"NSFilenamesPboardType"];
        }
        else {
            [service setSendType:@""];
        }
    }
    else if ( sender == returnTypePopUp ) {
        NSInteger tag = [[returnTypePopUp selectedItem] tag];
        if (tag == 1) {
            [service setReturnType:@"NSStringPboardType"];
        }
        else if (tag == 10) {
            [service setReturnType:@"NSRTFPboardType"];
        }
        else if (tag == 11) {
            [service setReturnType:@"NSPDFPboardType"];
        }
        else if (tag == 12) {
            [service setReturnType:@"NSTIFFPboardType"];
        }
        else {
            [service setReturnType:@""];
        }
    }
}

/*
 * NSTextField delegate
 */

- (void)controlTextDidChange: (NSNotification *)not
{
    [self textDidChange: not];
}

- (void)textDidChange: (NSNotification *)not
{
    id sender = [not object];
    if ( !sender ) {
        NSLog(@"Sender is nil");
        return;
    }
    if ( !service ) {
        NSLog(@"No type");
        return;
    }
    else if ( sender == nameTextField ) {
        [service setName: [nameTextField stringValue]];
    }
    else if ( sender == shellTextField ) {
        [service setShell: [shellTextField stringValue]];
    }
    else if ( sender == actionTextView ) {
        NSString* val = [[[actionTextView textStorage] string] copy];
        [service setAction: val];
        [val release];
    }
    else {
        NSLog(@"Got textDidChange from unknown sender: %@", sender);
    }
}

/*
 * Outlets
 */

- (NSTextField *)nameTextField
{
    return nameTextField;
}
- (void)setNameTextField: (NSTextField *)name
{
    ASSIGN(nameTextField, name);
}

- (NSTextField *)shellTextField
{
    return shellTextField;
}
- (void)setShellTextField: (NSTextField *)shell
{
    ASSIGN(shellTextField, shell);
}

- (NSTextView *)actionTextView
{
    return actionTextView;
}
- (void)setActionTextView: (NSTextView *)action
{
    ASSIGN(actionTextView, action);
}

@end

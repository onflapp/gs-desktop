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
    [actionTextView setString: [service action]];
}

/*
 * UI actions
 */


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
        NSString* val = AUTORELEASE([[actionTextView string] copyWithZone: NSDefaultMallocZone()]);
        [service setAction: val];
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

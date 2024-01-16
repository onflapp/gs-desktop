/* Copyright (C) 2024 OnFlApp
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
 */

#include <AppKit/AppKit.h>

#include "InterfaceController.h"


@implementation InterfaceController

- (void) dealloc
{
    RELEASE(action);
    RELEASE(shell);

    [super dealloc];
}

- (NSString*) action 
{
    return action;
}

- (void) setAction:(NSString*) str
{
    ASSIGN(action, str);
    [[[actionTextView textStorage] mutableString] setString:str];
}

- (NSString*) shell 
{
    return shell;
}

- (void) setShell:(NSString*) str
{
    ASSIGN(shell, str);
    [shellTextField setStringValue:str];
}


/*
 * UI actions
 */

- (void)changeType: (id) sender
{
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
    if ( sender == shellTextField ) {
        ASSIGN(shell, [shellTextField stringValue]);
    }
    else if ( sender == actionTextView ) {
        NSString* val = [[[actionTextView textStorage] string] copy];
        ASSIGN(action, val);
        [val release];
    }
    else {
        NSLog(@"Got textDidChange from unknown sender: %@", sender);
    }
}

@end

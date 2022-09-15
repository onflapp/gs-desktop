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

#include "TypeController.h"


@implementation TypeController

- (Type *)type
{
    return type;
}
- (void)setType: (Type *)t
{
    ASSIGN(type, t);
    [iconView setIcon: [type icon]];
    [extensionsTextField setStringValue: [type extensions]];
    [nameTextField setStringValue: [type name]];
    //[rolePopUp selectItemAtIndex: [rolePopUp indexOfItemWithTag: [type role]]];
}


/*
 * UI actions
 */


/*
 * NSTextField delegate
 */

- (void)controlTextDidChange: (NSNotification *)not
{
    id sender = [not object];
    if ( !sender ) {
        NSLog(@"Sender is nil");
        return;
    }
    if ( !type ) {
        NSLog(@"No type");
        return;
    }
    if ( sender == extensionsTextField ) {
        [type setExtensions: [extensionsTextField stringValue]];
    }
    else if ( sender == nameTextField ) {
        [type setName: [nameTextField stringValue]];
    }
    else {
        NSLog(@"Got textDidChange from unknown sender: %@", sender);
    }
}


/*
 * IconView delegate
 */

- (void)iconViewDidChangeIcon: (NSNotification *)not
{
    if ( [not object] != iconView ) {
        NSLog(@"Received iconViewDidChangeIcon from unknown object");
    }
    else {
        if ( !isSettingIcon ) {
            isSettingIcon = YES;
            [type setIcon: [iconView icon]];
            isSettingIcon = NO;
        }
    }
}


/*
 * Outlets
 */

- (IconView *)iconView
{
    return iconView;
}

- (void)setIconView: (IconView *)icon
{
    if ( isSettingIcon ) {
        return;
    }
    isSettingIcon = YES;
    if ( iconView) {
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                              name: (IconViewDidChangeIconNotification)
                                              object: (self)];
    }
    ASSIGN(iconView, icon);
    if ( iconView ) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                              selector: @selector(iconViewDidChangeIcon:)
                                              name: (IconViewDidChangeIconNotification)
                                              object: (iconView)];
    }
    isSettingIcon = NO;
}

- (NSTextField *)extensionsTextField
{
    return extensionsTextField;
}
- (void)setExtensionsTextField: (NSTextField *)extensions
{
    ASSIGN(extensionsTextField, extensions);
}

- (NSTextField *)nameTextField
{
    return nameTextField;
}
- (void)setNameTextField: (NSTextField *)name
{
    ASSIGN(nameTextField, name);
}


@end

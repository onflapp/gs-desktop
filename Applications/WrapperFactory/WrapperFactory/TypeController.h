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
 * $Id: TypeController.h 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/TypeController.h $
 */

#ifndef _GSWrapper_TypeController_H
#define _GSWrapper_TypeController_H

#include <AppKit/AppKit.h>

#include "Type.h"
#include "IconView.h"


@interface TypeController : NSObject
{
    Type *type;

    IBOutlet IconView *iconView;
    IBOutlet NSTextField *extensionsTextField;
    IBOutlet NSTextField *nameTextField;
    IBOutlet NSPopUpButton *rolePopUp;

    BOOL isSettingIcon;
}

- (Type *)type;
- (void)setType: (Type *)t;


/*
 * NSTextField delegate
 */

- (void)controlTextDidChange: (NSNotification *)not;


/*
 * Outlets
 */

- (IconView *)iconView;
- (void)setIconView: (IconView *)icon;

- (NSTextField *)extensionsTextField;
- (void)setExtensionsTextField: (NSTextField *)extensions;

- (NSTextField *)nameTextField;
- (void)setNameTextField: (NSTextField *)name;

@end


#endif

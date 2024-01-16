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
 * $Id: WrapperDocumentController.h 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/WrapperDocumentController.h $
 */

#ifndef _GSWrapper_WrapperDocumentController_H
#define _GSWrapper_WrapperDocumentController_H

#include <AppKit/AppKit.h>

#include "WrapperDocument.h"
#include "IconView.h"


#define StartScript 0
#define StartOpenScript 1
#define OpenScript 2
#define ActivateScript 4
#define FilterScript 3


@interface WrapperDocumentController : NSObject
{
    NSCursor *textCursor;
    NSCursor *defaultCursor;

    IBOutlet NSWindowController *windowController;
    IBOutlet WrapperDocument *document;

    IBOutlet IconView *appIcon;
    IBOutlet NSTextField *name;
    IBOutlet NSTextField *version;
    IBOutlet NSTextField *fullVersion;
    IBOutlet NSTextField *description;
    IBOutlet NSTextField *url;
    IBOutlet NSTextField *authors;
    IBOutlet NSPopUpButton *rolePopUp;

    IBOutlet NSTextField *currentScriptShell;
    IBOutlet NSTextView *currentScript;
    IBOutlet NSPopUpButton *currentScriptActionPopUp;

    IBOutlet NSButton *userInterface;
    IBOutlet NSTextField *userInterfaceShell;
    IBOutlet NSTextView *userInterfaceScript;
    IBOutlet NSPopUpButton *userInterfaceTypePopUp;

    int currentScriptId;
}


/*
 * initialization
 */
- (id)init;
- (void)awakeFromNib;


/*
 * delegate methods
 */

- (void)controlTextDidChange: (id)sender;
- (void)iconViewDidChangeIcon: (NSNotification *)not;

/*
 * actions
 */

- (IBAction)openNibFile: (id)sender;

- (IBAction)setCurrentScriptToStart: (id)sender;
- (IBAction)setCurrentScriptToStartOpen: (id)sender;
- (IBAction)setCurrentScriptToOpen: (id)sender;
- (IBAction)setCurrentScriptToActivate: (id)sender;
- (IBAction)setCurrentScriptToFilter: (id)sender;
- (IBAction)setRole: (id)sender;
- (IBAction)setCurrentScriptAction: (id)sender;

- (IBAction)changeUserInterface: (id)sender;
- (IBAction)changeUserInterfaceType: (id)sender;

/*
 * outlets
 */
- (void)setWindowController: (NSWindowController *)controller;
- (void)setDocument: (WrapperDocument *)d;

- (void)setAppIcon: (IconView *)i;
- (IconView *)appIcon;
- (void)setName: (NSTextField *)n;
- (NSTextField *)name;
- (void)setVersion: (NSTextField *)v;
- (NSTextField *)version;
- (void)setFullVersion: (NSTextField *)v;
- (NSTextField *)fullVersion;
- (void)setDescription: (NSTextField *)d;
- (NSTextField *)description;
- (void)setUrl: (NSTextField *)u;
- (NSTextField *)url;
- (void)setAuthors: (NSTextField *)a;
- (NSTextField *)authors;
- (NSPopUpButton *)rolePopUp;
- (void)setRolePopUp: (NSPopUpButton *)role;

- (void)setCurrentScriptId: (int)i;
- (int)currentScriptId;
- (void)setCurrentScriptShell: (NSTextField *)s;
- (NSTextField *)currentScriptShell;
- (void)setCurrentScript: (NSTextView *)s;
- (NSTextView *)currentScript;
- (void)setCurrentScriptActionPopUp: (NSPopUpButton *)actionPopUp;
- (NSPopUpButton *)currentScriptActionPopUp;

@end


#endif

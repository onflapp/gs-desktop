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
 * $Id: WrapperDocumentController.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/WrapperDocumentController.m $
 */

#include <AppKit/AppKit.h>

#include "WrapperDocumentController.h"
#include "WrapperDocument.h"
#include "Icon.h"

@interface WrapperDocumentController (Notifications)

- (void)wrapperDocumentChangedNotification: (NSNotification *)not;

@end


@implementation WrapperDocumentController

- (id)init
{
    self = [super init];
    if ( self ) {
//         textCursor = [NSCursor IBeamCursor];
//         defaultCursor = [NSCursor arrowCursor];
//         [textCursor setOnMouseEntered: YES];
//         [defaultCursor setOnMouseExited: YES];
    }
    return self;
}

- (void)awakeFromNib
{
//     if ( currentScript ) {
//         NSLog(@"Setting cursor");
//         [currentScript addCursorRect: [currentScript bounds]
//                        cursor: (textCursor)];
//         [currentScript addCursorRect: [currentScript bounds]
//                        cursor: (defaultCursor)];
//     }
//    [self setCurrentScriptId: StartScript];
//

    [userInterface setState: [document userInterface]];

    NSString *uishell = [document userInterfaceScriptShell];
    [userInterfaceShell setStringValue: uishell];

    if ([uishell isEqualToString:@"stexec"]) {
        [userInterfaceTypePopUp selectItemWithTag:1];
    }
    else {
        [userInterfaceTypePopUp selectItemWithTag:0];
    }


    NSString *uiscript = [document userInterfaceScript];
    if ( uiscript ) {
        [[[userInterfaceScript textStorage] mutableString] setString: uiscript];
    }
}

- (IBAction)openNibFile: (id)sender
{
    NSLog(@"open nib");
    NSString* path = [document userInterfacePath];
    if ( path ) {
        [[NSWorkspace sharedWorkspace] openFile: path];
    }
}

- (IBAction)changeUserInterface: (id)sender
{
    if ([sender state] == 1) {
        [document setUserInterface:1];
        [self prepareUserInterfaceFile];
    }
    else {
        [document setUserInterface:0];
    }
}

- (IBAction)changeUserInterfaceType: (id)sender
{
    if ([sender selectedTag] == 1) {
        [userInterfaceShell setStringValue: @"stexec"];
        [document setUserInterfaceScriptShell: @"stexec"];
    }
    else {
        [userInterfaceShell setStringValue: @"/bin/sh"];
        [document setUserInterfaceScriptShell: @"/bin/sh"];
    }

}

- (void) prepareUserInterfaceFile
{
    NSString* uiPath = [document userInterfacePath];
    if (! uiPath ) {
        NSString *nibPath = [[NSBundle mainBundle] pathForResource: @"Launcher" ofType: @"gorm"];
        NSString *tfile = [NSString stringWithFormat:@"%@/Launcher-%lx.gorm", NSTemporaryDirectory(), [document hash]];

        NSError *error = nil;
        NSFileManager* fm = [NSFileManager defaultManager];
        BOOL rv = [fm copyItemAtPath:nibPath
                              toPath:tfile
                               error:&error];

        if (rv) {
            [document setUserInterfacePath:tfile];
        }
        else {
            NSLog(@"writing uifile %@ to %@ %@", nibPath, tfile, error);
        }
    }
}

/*
 * delegate methods
 */

- (void)controlTextDidChange: (NSNotification *)not
{
    [self textDidChange: not];
}

- (void)textDidChange: (NSNotification *)not
{
    id src = [not object];

    if ( src == name ) {
        [document setName: [name stringValue]];
    }
    else if ( src == version ) {
        [document setVersion: [version stringValue]];
    }
    else if ( src == fullVersion ) {
        [document setFullVersion: [fullVersion stringValue]];
    }
    else if ( src == description ) {
        [document setDescription: [description stringValue]];
    }
    else if ( src == url ) {
        [document setUrl: [url stringValue]];
    }
    else if ( src == authors ) {
        [document setAuthors: [authors stringValue]];
    }
    else if ( src == currentScriptShell ) {
        NSString *shell = [currentScriptShell stringValue];
        switch ( currentScriptId ) {
        case StartScript:
            [document setStartScriptShell: shell];
            break;
        case StartOpenScript:
            [document setStartOpenScriptShell: shell];
            break;
        case OpenScript:
            [document setOpenScriptShell: shell];
            break;
        case ActivateScript:
            [document setActivateScriptShell: shell];
            break;
        case FilterScript:
            [document setFilterScriptShell: shell];
            break;
        default:
            NSLog(@"Unknown script ID: %d", currentScriptId);
        }
    }
    else if ( src == currentScript ) {
        NSString *script = [[[currentScript textStorage] string] copy];
        switch ( currentScriptId ) {
        case StartScript:
            [document setStartScript: script];
            break;
        case StartOpenScript:
            [document setStartOpenScript: script];
            break;
        case OpenScript:
            [document setOpenScript: script];
            break;
        case ActivateScript:
            [document setActivateScript: script];
            break;
        case FilterScript:
            [document setFilterScript: script];
            break;
        default:
            NSLog(@"Unknown script ID: %d", currentScriptId);
        }
        [script release];
    }
    else if ( src == userInterfaceShell) {
        NSString *shell = [userInterfaceShell stringValue];
        [document setUserInterfaceScriptShell: shell];
    }
    else if ( src == userInterfaceScript) {
        NSString *script = [[[userInterfaceScript textStorage] string] copy];
        [document setUserInterfaceScript: script];
        [script release];
    }
    else {
        NSLog(@"Received textDidChange notification from unknown control: %@", src);
    }
}

- (void)iconViewDidChangeIcon: (NSNotification *)not
{
    if ( [not object] == appIcon ) {
        [document setAppIcon: [(IconView *)[not object] icon]];
    }
    else {
        NSLog(@"Received iconViewImageChanged notification from unknown ImageView: %@", [not object]);
    }
}


/*
 * actions
 */

- (IBAction)setCurrentScriptToStart: (id)sender
{
    [self setCurrentScriptId: StartScript];
}

- (IBAction)setCurrentScriptToStartOpen: (id)sender
{
    [self setCurrentScriptId: StartOpenScript];
}

- (IBAction)setCurrentScriptToOpen: (id)sender
{
    [self setCurrentScriptId: OpenScript];
}

- (IBAction)setCurrentScriptToActivate: (id)sender
{
    [self setCurrentScriptId: ActivateScript];
}

- (IBAction)setCurrentScriptToFilter: (id)sender
{
    [self setCurrentScriptId: FilterScript];
}


- (IBAction)setRole: (id)sender
{
    int tag = [[sender selectedItem] tag];
    switch ( tag ) {
    case NoneRole:
        [document setRole: NoneRole];
        break;
    case ViewerRole:
        [document setRole: ViewerRole];
        break;
    case EditorRole:
        [document setRole: EditorRole];
        break;
    default:
        NSLog(@"Unknown role: %d", tag);
    }
}

- (IBAction)setCurrentScriptAction: (id)sender
{
    int tag = [[sender selectedItem] tag];
    switch ( currentScriptId ) {
    case StartScript:
        [document setStartScriptAction: tag];
        break;
    case StartOpenScript:
        [document setStartOpenScriptAction: tag];
        break;
    case OpenScript:
        [document setOpenScriptAction: tag];
        break;
    case ActivateScript:
        [document setActivateScriptAction: tag];
        break;
    case FilterScript:
        [document setFilterScriptAction: tag];
        break;
    }
    
    if (tag == RunScriptAction) {
        [currentScript setEditable: YES];
        [currentScript setBackgroundColor: [NSColor textBackgroundColor]];
    }
    else {
        [currentScript setEditable: NO];
        [currentScript setBackgroundColor: [NSColor controlBackgroundColor]];
    }
}


/*
 * outlets
 */

- (void)setWindowController: (NSWindowController *)controller
{
    windowController = controller;
    [self setDocument: [controller document]];
}

- (void)setDocument: (WrapperDocument *)d
{
    if ( document ) {
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                              name: (WrapperChangedNotification)
                                              object: (document)];
    }

    document = d;
    NSString* emptyString = @"";

    if ( ! d ) {
        NSLog(@"Document set to null");
    }
    if ( appIcon ) {
        [appIcon setIcon: [d appIcon]];
    }
    else {
        NSLog(@"No appIcon image view");
    }
    if ( name ) {
        [name setStringValue: d ? [d name] : emptyString];
    }
    else {
        NSLog(@"No name text field");
    }
    if ( version ) {
        [version setStringValue: d ? [d version] : emptyString];
    }
    else {
        NSLog(@"No version text field");
    }
    if ( fullVersion ) {
        [fullVersion setStringValue: d ? [d fullVersion] : emptyString];
    }
    else {
        NSLog(@"No fullVersion text field");
    }
    if ( description ) {
        [description setStringValue: d ? [d description] : emptyString];
    }
    else {
        NSLog(@"No description text field");
    }
    if ( url ) {
        [url setStringValue: d ? [d url] : emptyString];
    }
    else {
        NSLog(@"No url text field");
    }
    if ( authors ) {
        [authors setStringValue: d ? [d authors] : emptyString];
    }
    else {
        NSLog(@"No authors text field");
    }
    [self setCurrentScriptId: currentScriptId];

   
    if ( document ) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                              selector: @selector(wrapperDocumentChangedNotification:)
                                              name: (WrapperChangedNotification)
                                              object: (document)];
    }
}

- (void)setAppIcon: (IconView *)i
{
    if ( appIcon) {
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                              name: (IconViewDidChangeIconNotification)
                                              object: (self)];
    }
    appIcon = i;
    if ( appIcon ) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                              selector: @selector(iconViewDidChangeIcon:)
                                              name: (IconViewDidChangeIconNotification)
                                              object: (appIcon)];
    }
}
- (IconView *)appIcon
{
    return appIcon;
}

- (void)setName: (NSTextField *)n
{
    name = n;
}
- (NSTextField *)name
{
    return name;
}

- (void)setVersion: (NSTextField *)v
{
    version = v;
}
- (NSTextField *)version
{
    return version;
}

- (void)setFullVersion: (NSTextField *)v
{
    fullVersion = v;
}
- (NSTextField *)fullVersion
{
    return fullVersion;
}

- (void)setDescription: (NSTextField *)d
{
    description = d;
}
- (NSTextField *)description
{
    return description;
}

- (void)setUrl: (NSTextField *)u
{
    url = u;
}
- (NSTextField *)url
{
    return url;
}

- (void)setAuthors: (NSTextField *)a
{
    authors = a;
}
- (NSTextField *)authors
{
    return authors;
}

- (NSPopUpButton *)rolePopUp
{
    return rolePopUp;
}
- (void)setRolePopUp: (NSPopUpButton *)role
{
    ASSIGN(rolePopUp, role);
}

- (NSPopUpButton *)currentScriptActionPopUp
{
    return currentScriptActionPopUp;
}
- (void)setCurrentScriptActionPopUp: (NSPopUpButton *)actionPopUp;
{
    ASSIGN(currentScriptActionPopUp, actionPopUp);
}

- (void)setCurrentScriptId: (int)i
{
    NSString *shell;
    NSString *script;
    int action;
    switch ( i ) {
    case StartScript:
        shell = [document startScriptShell];
        script = [document startScript];
        action = [document startScriptAction];
        break;
    case StartOpenScript:
        shell = [document startOpenScriptShell];
        script = [document startOpenScript];
        action = [document startOpenScriptAction];
        break;
    case OpenScript:
        shell = [document openScriptShell];
        script = [document openScript];
        action = [document openScriptAction];
        break;
    case ActivateScript:
        shell = [document activateScriptShell];
        script = [document activateScript];
        action = [document activateScriptAction];
        break;
    case FilterScript:
        shell = [document filterScriptShell];
        script = [document filterScript];
        action = [document filterScriptAction];
        break;
    default:
        NSLog(@"Unknown script ID: %d", currentScriptId);
        return;
    }
    [currentScriptActionPopUp selectItemAtIndex: [currentScriptActionPopUp indexOfItemWithTag: action]];
    currentScriptId = i;

    if ( !script ) {
        script = @"";
    }
    if ( !shell ) {
        shell = @"/bin/sh";
    }

    [currentScriptShell setStringValue: shell];
    [[[currentScript textStorage] mutableString] setString:script];

    if (action == RunScriptAction) {
        [currentScript setEditable: YES];
        [currentScript setBackgroundColor: [NSColor textBackgroundColor]];
    }
    else {
        [currentScript setEditable: NO];
        [currentScript setBackgroundColor: [NSColor controlBackgroundColor]];
    }

}
- (int)currentScriptId
{
    return currentScriptId;
}

- (void)setCurrentScriptShell: (NSTextField *)s
{
    currentScriptShell = s;
}
- (NSTextField *)currentScriptShell
{
    return currentScriptShell;
}

- (void)setCurrentScript: (NSTextView *)s
{
    currentScript = s;
}
- (NSTextView *)currentScript
{
    return currentScript;
}

@end



@implementation WrapperDocumentController (Notifications)

- (void)wrapperDocumentChangedNotification: (NSNotification *)not
{
    NSString *attr = [[not userInfo] objectForKey: WrapperChangedAttributeName];
    id val = [[not userInfo] objectForKey: WrapperChangedAttributeValue];
    if ( [attr isEqualToString: @"appIcon"] && appIcon ) {
        [appIcon setIcon: [Icon iconWithImage: val]];
    }
    else if ( [attr isEqualToString: @"name"] && name ) {
        [name setStringValue: val];
    }
    else if ( [attr isEqualToString: @"version"] && version ) {
        [version setStringValue: val];
    }
    else if ( [attr isEqualToString: @"fullVersion"] && fullVersion ) {
        [fullVersion setStringValue: val];
    }
    else if ( [attr isEqualToString: @"description"] && description ) {
        [description setStringValue: val];
    }
    else if ( [attr isEqualToString: @"url"] && url ) {
        [url setStringValue: val];
    }
    else if ( [attr isEqualToString: @"authors"] && authors ) {
        [authors setStringValue: val];
    }
    else if ( [attr isEqualToString: @"role"] && rolePopUp ) {
        [rolePopUp selectItemAtIndex: [rolePopUp indexOfItemWithTag: [val intValue]]];
    }
    else if ( [attr isEqualToString: @"startScript"] && currentScript) {
        if ( currentScriptId == StartScript ) {
            [[[currentScript textStorage] mutableString] setString:val];
        }
    }
    else if ( [attr isEqualToString: @"startScriptShell"] && currentScriptShell ) {
        if ( currentScriptId == StartScript ) {
            [currentScriptShell setStringValue: val];
        }
    }
    else if ( [attr isEqualToString: @"startScriptAction"] && currentScriptActionPopUp ) {
        if ( currentScriptId == StartScript ) {
            [currentScriptActionPopUp selectItemAtIndex: [currentScriptActionPopUp indexOfItemWithTag: [val intValue]]];
        }
    }
    else if ( [attr isEqualToString: @"activateScript"] && currentScript) {
        if ( currentScriptId == ActivateScript ) {
            [[[currentScript textStorage] mutableString] setString:val];
        }
    }
    else if ( [attr isEqualToString: @"activateScriptShell"] && currentScriptShell ) {
        if ( currentScriptId == ActivateScript ) {
            [currentScriptShell setStringValue: val];
        }
    }
    else if ( [attr isEqualToString: @"activateScriptAction"] && currentScriptActionPopUp ) {
        if ( currentScriptId == ActivateScript ) {
            [currentScriptActionPopUp selectItemAtIndex: [currentScriptActionPopUp indexOfItemWithTag: [val intValue]]];
        }
    }
    else if ( [attr isEqualToString: @"startOpenScript"] && currentScriptActionPopUp ) {
        if ( currentScriptId == StartOpenScript ) {
            [currentScriptActionPopUp selectItemAtIndex: [currentScriptActionPopUp indexOfItemWithTag: [val intValue]]];
        }
    }
    else if ( [attr isEqualToString: @"startOpenScriptShell"] && currentScriptShell ) {
        if ( currentScriptId == StartOpenScript ) {
            [currentScriptShell setStringValue: val];
        }
    }
    else if ( [attr isEqualToString: @"startOpenScriptAction"] && currentScriptActionPopUp ) {
        if ( currentScriptId == StartOpenScript ) {
            [currentScriptActionPopUp selectItemAtIndex: [currentScriptActionPopUp indexOfItemWithTag: [val intValue]]];
        }
    }
    else if ( [attr isEqualToString: @"filterScript"] && currentScriptActionPopUp ) {
        if ( currentScriptId == FilterScript ) {
            [currentScriptActionPopUp selectItemAtIndex: [currentScriptActionPopUp indexOfItemWithTag: [val intValue]]];
        }
    }
    else if ( [attr isEqualToString: @"filterScriptShell"] && currentScriptShell ) {
        if ( currentScriptId == FilterScript ) {
            [currentScriptShell setStringValue: val];
        }
    }
    else if ( [attr isEqualToString: @"filterScriptAction"] && currentScriptActionPopUp ) {
        if ( currentScriptId == FilterScript ) {
            [currentScriptActionPopUp selectItemAtIndex: [currentScriptActionPopUp indexOfItemWithTag: [val intValue]]];
        }
    }

    else if ( [attr isEqualToString: @"openScript"] && currentScript ) {
        if ( currentScriptId == OpenScript ) {
            [[[currentScript textStorage] mutableString] setString:val];
        }
    }
    else if ( [attr isEqualToString: @"openScriptAction"] && currentScriptActionPopUp ) {
        if ( currentScriptId == OpenScript ) {
            [currentScriptActionPopUp selectItemAtIndex: [currentScriptActionPopUp indexOfItemWithTag: [val intValue]]];
        }
    }
    else if ( [attr isEqualToString: @"openScriptShell"] && currentScriptShell ) {
        if ( currentScriptId == OpenScript ) {
            [currentScriptShell setStringValue: val];
        }
    }
    else {
        NSLog(@"Received WrapperChangedNotification for unknown attribute %@", attr);
    }
}

@end

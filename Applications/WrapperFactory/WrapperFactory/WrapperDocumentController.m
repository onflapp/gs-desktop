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


static NSString *emptyString = @"";


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
        settingValue = NO;
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
    if ( settingValue ) {
        return;
    }
    id src = [not object];
    settingValue = YES;
    if ( src == name ) {
        [document setName: AUTORELEASE([[name stringValue] copyWithZone: NSDefaultMallocZone()])];
    }
    else if ( src == version ) {
        [document setVersion: AUTORELEASE([[version stringValue] copyWithZone: NSDefaultMallocZone()])];
    }
    else if ( src == fullVersion ) {
        [document setFullVersion: AUTORELEASE([[fullVersion stringValue] copyWithZone: NSDefaultMallocZone()])];
    }
    else if ( src == description ) {
        [document setDescription: AUTORELEASE([[description stringValue] copyWithZone: NSDefaultMallocZone()])];
    }
    else if ( src == url ) {
        [document setUrl: AUTORELEASE([[url stringValue] copyWithZone: NSDefaultMallocZone()])];
    }
    else if ( src == authors ) {
        [document setAuthors: AUTORELEASE([[authors stringValue] copyWithZone: NSDefaultMallocZone()])];
    }
    else if ( src == currentScriptShell ) {
        NSString *shell = AUTORELEASE([[currentScriptShell stringValue] copyWithZone: NSDefaultMallocZone()]);
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
        default:
            NSLog(@"Unknown script ID: %d", currentScriptId);
        }
    }
    else if ( src == currentScript ) {
        NSString *script = AUTORELEASE([[currentScript string] copyWithZone: NSDefaultMallocZone()]);
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
        default:
            NSLog(@"Unknown script ID: %d", currentScriptId);
        }
    }
    else {
        NSLog(@"Received textDidChange notification from unknown control: %@", src);
    }
    settingValue = NO;
}

- (void)iconViewDidChangeIcon: (NSNotification *)not
{
    if ( settingValue ) {
        return;
    }
    settingValue = YES;
    if ( [not object] == appIcon ) {
        [document setAppIcon: [(IconView *)[not object] icon]];
    }
    else {
        NSLog(@"Received iconViewImageChanged notification from unknown ImageView: %@", [not object]);
    }
    settingValue = NO;
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

- (IBAction)setRole: (id)sender
{
    int tag = [[sender selectedItem] tag];
    settingValue = YES;
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
    settingValue = NO;
}

- (IBAction)setCurrentScriptAction: (id)sender
{
    int tag = [[sender selectedItem] tag];
    settingValue = YES;
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

    settingValue = YES;
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
    settingValue = NO;

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
    if ( currentScriptShell ) {
        [currentScriptShell setStringValue: shell];
    }
    if ( currentScript ) {
        [currentScript setString: script];
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
    if ( settingValue ) {
        return;
    }
    settingValue = YES;
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
            [currentScript setString: val];
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
    else if ( [attr isEqualToString: @"openScript"] && currentScript ) {
        if ( currentScriptId == OpenScript ) {
            [currentScript setString: val];
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
    settingValue = NO;
}

@end

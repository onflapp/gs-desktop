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
 * $Id: WrapperDocument.h 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/WrapperDocument.h $
 */

#ifndef _GSWrapper_WrapperDocument_H
#define _GSWrapper_WrapperDocument_H

#include <AppKit/AppKit.h>

#include "Type.h"
#include "Service.h"


extern NSString * const ApplicationType;

extern NSString * const WrapperChangedNotification;
extern NSString * const WrapperChangedAttributeName;
extern NSString * const WrapperChangedAttributeValue;

extern NSString * const WrapperAggregateChangedNotification;
extern NSString * const WrapperAggregateChangedObject;
extern NSString * const WrapperAggregateChangedAttributeName;
extern NSString * const WrapperAggregateChangedAttributeValue;


typedef enum {
    NoneRole,
    ViewerRole,
    EditorRole
} ApplicationRole;

typedef enum {
    RunScriptAction,
    FailAction,
    IgnoreAction
} ScriptAction;


@interface WrapperDocument : NSDocument
{
    NSFileWrapper *fileWrapper;

    Icon *appIcon;
    NSString *name;
    NSString *version;
    NSString *fullVersion;
    NSString *description;
    NSString *url;
    NSString *authors;
    ApplicationRole role;
    NSInteger userInterface;

    NSString *startScript;
    NSString *startScriptShell;
    ScriptAction startScriptAction;
    NSString *activateScript;
    NSString *activateScriptShell;
    ScriptAction activateScriptAction;
    NSString *startOpenScript;
    NSString *startOpenScriptShell;
    ScriptAction startOpenScriptAction;
    NSString *openScript;
    NSString *openScriptShell;
    ScriptAction openScriptAction;
    NSString *filterScript;
    NSString *filterScriptShell;
    ScriptAction filterScriptAction;

    NSString *userInterfaceScript;
    NSString *userInterfaceScriptShell;
    NSString *userInterfacePath;

    NSMutableArray *types;
    NSMutableArray *services;
}

/*
 * document
 */

- (id)init;

- (BOOL)loadFileWrapperRepresentation: (NSFileWrapper *)file
                               ofType: (NSString *)type;
- (NSFileWrapper *)fileWrapperRepresentationOfType: (NSString *)type;

- (NSString *)windowNibName;

- (int)runModalSavePanel: (NSSavePanel *)savePanel
       withAccessoryView: (NSView *)accessoryView;


/*
 * attributes
 */

- (NSString *)userInterfacePath;
- (void)setUserInterfacePath: (NSString *)path;

- (NSInteger)userInterface;
- (void)setUserInterface: (NSInteger)n;

- (NSString *)userInterfaceScript;
- (void)setUserInterfaceScript: (NSString*)str;

- (NSString *)userInterfaceScriptShell;
- (void)setUserInterfaceScriptShell: (NSString*)str;

- (Icon *)appIcon;
- (void)setAppIcon: (Icon *)i;

- (NSString *)name;
- (void)setName: (NSString *)n;

- (NSString *)version;
- (void)setVersion: (NSString *)n;

- (NSString *)fullVersion;
- (void)setFullVersion: (NSString *)n;

- (NSString *)description;
- (void)setDescription: (NSString *)n;

- (NSString *)url;
- (void)setUrl: (NSString *)n;

- (NSString *)authors;
- (void)setAuthors: (NSString *)n;

- (ApplicationRole)role;
- (void)setRole: (ApplicationRole)r;

- (NSString *)startScript;
- (void)setStartScript: (NSString *)n;

- (NSString *)startScriptShell;
- (void)setStartScriptShell: (NSString *)n;

- (ScriptAction)startScriptAction;
- (void)setStartScriptAction: (ScriptAction)action;

- (NSString *)activateScript;
- (void)setActivateScript: (NSString *)n;

- (NSString *)activateScriptShell;
- (void)setActivateScriptShell: (NSString *)n;

- (ScriptAction)activateScriptAction;
- (void)setActivateScriptAction: (ScriptAction)action;

- (NSString *)startOpenScript;
- (void)setStartOpenScript: (NSString *)n;

- (NSString *)startOpenScriptShell;
- (void)setStartOpenScriptShell: (NSString *)n;

- (ScriptAction)startOpenScriptAction;
- (void)setStartOpenScriptAction: (ScriptAction)action;

- (NSString *)openScript;
- (void)setOpenScript: (NSString *)n;

- (NSString *)openScriptShell;
- (void)setOpenScriptShell: (NSString *)n;

- (ScriptAction)openScriptAction;
- (void)setOpenScriptAction: (ScriptAction)action;

- (NSString *)filterScript;
- (void)setFilterScript: (NSString *)n;

- (NSString *)filterScriptShell;
- (void)setFilterScriptShell: (NSString *)n;

- (ScriptAction)filterScriptAction;
- (void)setFilterScriptAction: (ScriptAction)action;

/*
 * types
 */

- (void)addType: (Type *)type;
- (void)removeType: (Type *)type;
- (int)typeCount;
- (Type *)typeAtIndex: (unsigned)index;
- (unsigned)indexOfType: (Type *)type;

/*
 * services
 */

- (void)addService: (Service *)service;
- (void)removeService: (Service *)service;
- (int)serviceCount;
- (Service *)serviceAtIndex: (unsigned)index;
- (unsigned)indexOfService: (Service *)service;

@end


#endif

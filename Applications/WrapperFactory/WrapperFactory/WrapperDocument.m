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
 * $Id: WrapperDocument.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/WrapperDocument.m $
 */

#include <sys/types.h>
#include <sys/stat.h>

#include <AppKit/AppKit.h>

#include "WrapperDocument.h"
#include "IconView.h"


static const int currentVersion = 1;

NSString * const ApplicationType = @"Application";
NSString * const ServiceType = @"Service";
NSString * const WrapperChangedNotification = @"WrapperChangedNotification";
NSString * const WrapperChangedAttributeName = @"AttributeName";
NSString * const WrapperChangedAttributeValue = @"AttributeValue";

NSString * const WrapperAggregateChangedNotification = @"WrapperAggregateChangedNotification";
NSString * const WrapperAggregateChangedObject = @"Object";
NSString * const WrapperAggregateChangedAttributeName = @"AttributeName";
NSString * const WrapperAggregateChangedAttributeValue = @"AttributeValue";

static NSString *launcherName = @"launcher.sh";
static NSString *FreedesktopApplicationType = @"Freedesktop Application";

static NSString *actionRunScript = @"RunScript";
static NSString *actionFail = @"Fail";
static NSString *actionIgnore = @"Ignore";



/*
 * AppFileWrapper
 */

@interface AppFileWrapper : NSFileWrapper
{
    NSData *script;
    NSData *executable;
}

- (void)setExecutable: (NSData *)exe;
 - (NSData *)executable;

- (BOOL)writeToFile: (NSString *)path
         atomically:(BOOL)atomicFlag
    updateFilenames:(BOOL)updateNamesFlag;

@end

@implementation AppFileWrapper

- (void)dealloc
{
    TEST_RELEASE(executable);
    [super dealloc];
}

- (void)setExecutable: (NSData *)exe
{
    ASSIGN(executable, exe);
}

- (NSData *)executable
{
    return executable;
}

- (BOOL)writeToFile: (NSString *)path
         atomically: (BOOL)atomicFlag
    updateFilenames: (BOOL)updateNamesFlag
{
    BOOL result = [super writeToFile: path
                         atomically: (atomicFlag)
                         updateFilenames: (updateNamesFlag)];

    if ( result ) {
        NSString *basename = [[path lastPathComponent] stringByDeletingPathExtension];
        NSString *p = [path stringByAppendingPathComponent: basename];
        [executable writeToFile: p atomically: NO];

        NSFileManager *fm = [NSFileManager defaultManager];
        NSDictionary *attrs = [fm fileAttributesAtPath: p traverseLink: NO];
        NSNumber *perms = [attrs objectForKey: NSFilePosixPermissions];
        perms = [NSNumber numberWithInt: [perms intValue]|0111];
        attrs = [NSDictionary dictionaryWithObject: perms forKey: NSFilePosixPermissions];
        [fm changeFileAttributes: attrs atPath: p];
    }
    return result;
}

@end



/*
 * WrapperDocument
 */

@interface WrapperDocument (Private)

- (void)attributeChangedName: (NSString *)n
                       value: (id)v;

- (void)documentChanged;

- (void)aggregateChanged: (NSNotification *)not;

- (NSArray *)arrayFromCommaSeparatedString: (NSString *)string;

- (BOOL)loadWrapper: (NSFileWrapper *)file;
- (NSFileWrapper *)saveWrapper;

- (BOOL)loadFreedesktopApplication: (NSFileWrapper *)file;
- (NSFileWrapper *)saveFreedesktopApplication;

+ (ScriptAction)stringToScriptAction: (NSString *)str;
+ (NSString *)scriptActionToString: (ScriptAction)action;

@end


@implementation WrapperDocument

/*
 * document
 */

- (id)init
{
    self = [super init];
    if ( self ) {
        NSImage *img = [[NSImage alloc] initByReferencingFile: [[NSBundle mainBundle] pathForImageResource: @"DefaultAppIcon"]];
        appIcon = RETAIN([Icon iconWithImage: img]);
        name = RETAIN(@"Untitled.app");
        version = RETAIN(@"1.0");
        fullVersion = RETAIN(@"1.0/1.0");
        description = RETAIN(@"A wrapped application");
        url = RETAIN(@"");
        authors = RETAIN(@"");
        role = NoneRole;

        startScript = RETAIN(@"");
        startScriptShell = RETAIN(@"/bin/sh");
        startScriptAction = RunScriptAction;
        startOpenScript = RETAIN(@"");
        startOpenScriptShell = RETAIN(startScriptShell);
        startOpenScriptAction = RunScriptAction;
        activateScript = RETAIN(@"");
        activateScriptShell = RETAIN(startScriptShell);
        activateScriptAction = RunScriptAction;
        openScript = RETAIN(@"");
        openScriptShell = RETAIN(startScriptShell);
        openScriptAction = IgnoreAction;
        filterScript = RETAIN(@"");
        filterScriptShell = RETAIN(startScriptShell);
        filterScriptAction = IgnoreAction;

        userInterface = 0;
        userInterfaceScript = RETAIN(@"");
        userInterfaceScriptShell = RETAIN(@"/bin/sh");

        types = [[NSMutableArray alloc] init];
        services = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    if ( userInterfacePath ) {
        NSFileManager* fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:userInterfacePath error:nil];
    }

    RELEASE(appIcon);
    RELEASE(name);
    RELEASE(version);
    RELEASE(fullVersion);
    RELEASE(description);
    RELEASE(url);
    RELEASE(authors);

    RELEASE(startScript);
    RELEASE(startScriptShell);
    RELEASE(activateScript);
    RELEASE(activateScriptShell);
    RELEASE(startOpenScript);
    RELEASE(startOpenScriptShell);
    RELEASE(openScript);
    RELEASE(openScriptShell);
    RELEASE(filterScript);
    RELEASE(filterScriptShell);

    RELEASE(userInterfaceScript);
    RELEASE(userInterfaceScriptShell);
    RELEASE(userInterfacePath);

    RELEASE(types);
    RELEASE(services);
    [super dealloc];
}

- (BOOL)loadFileWrapperRepresentation: (NSFileWrapper *)file
                               ofType: (NSString *)type
{
    NSLog(@"Loading wrapper: %@", [file filename]);
    if ( [type isEqualToString: ApplicationType]  ) {
        return [self loadWrapper: file];
    }
    else if ( [type isEqualToString: ServiceType]  ) {
        return [self loadWrapper: file];
    }
#ifdef FREEDESKTOP
    else if ( [type isEqualToString: FreedesktopApplicationType] ) {
        if ( [self loadFreedesktopApplication: file] ) {
            [self setFileType: ApplicationType];
            [self setFileName: nil];
            return YES;
        }
        else {
            return NO;
        }
    }
#endif
    else {
        NSLog(@"Type %@ of %@ is not known", type, [file filename]);
        return NO;
    }
}

- (NSFileWrapper *)fileWrapperRepresentationOfType: (NSString *)type
{
    if ( [type isEqualToString: ApplicationType]  ) {
        return [self saveWrapper];
    }
    else if ( [type isEqualToString: ServiceType]  ) {
        return [self saveWrapper];
    }
    else {
        NSLog(@"Type %@ is not known", type);
        return nil;
    }
}

- (NSString *)windowNibName
{
    return @"WrapperDocument";
}


- (int)runModalSavePanel: (NSSavePanel *)savePanel
       withAccessoryView: (NSView *)accessoryView
{
    NSString *directory;
    NSString *file;

    if ([self fileName]) {
        directory = [savePanel directory];
        file = [[[self fileName] lastPathComponent] stringByDeletingPathExtension];
    }
    else {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSUserDomainMask, YES);
        if ( [paths count] > 0 ) {
            directory = [paths objectAtIndex: 0];
        }
        else {
            directory = [[NSDocumentController sharedDocumentController] currentDirectory];
        }
        file = [self name];
        if ( [[file pathExtension] isEqualToString: [savePanel requiredFileType]] ) {
            file = [file stringByDeletingPathExtension];
        }
    }

    [savePanel setAccessoryView: accessoryView];
    return [savePanel runModalForDirectory: directory file: file];
}


/*
 * attributes
 */

- (NSInteger)userInterface
{
    return userInterface;
}
- (void)setUserInterface: (NSInteger)n
{
    userInterface = n;
}

- (NSString *)userInterfacePath
{
    return userInterfacePath;
}
- (void)setUserInterfacePath: (NSString*)path
{
    ASSIGN(userInterfacePath, path);
}
- (NSString *)userInterfaceScript
{
    return userInterfaceScript;
}
- (void)setUserInterfaceScript: (NSString*)str
{
    ASSIGN(userInterfaceScript, str);
}
- (NSString *)userInterfaceScriptShell
{
    return userInterfaceScriptShell;
}
- (void)setUserInterfaceScriptShell: (NSString*)str
{
    ASSIGN(userInterfaceScriptShell, str);
}

- (Icon *)appIcon
{
    return appIcon;
}
- (void)setAppIcon: (Icon *)i
{
    ASSIGN(appIcon, i);
    [self attributeChangedName: @"appIcon" value: i];
}

- (NSString *)name
{
    return name;
}
- (void)setName: (NSString *)n
{
    ASSIGN(name, n);
    [self attributeChangedName: @"name" value: n];
}

- (NSString *)version
{
    return version;
}
- (void)setVersion: (NSString *)v
{
    ASSIGN(version, v);
    [self attributeChangedName: @"version" value: v];
}

- (NSString *)fullVersion
{
    return fullVersion;
}
- (void)setFullVersion: (NSString *)v
{
    ASSIGN(fullVersion, v);
    [self attributeChangedName: @"fullVersion" value: v];
}

- (NSString *)description
{
    return description;
}
- (void)setDescription: (NSString *)d
{
    ASSIGN(description, d);
    [self attributeChangedName: @"description" value: d];
}

- (NSString *)url
{
    return url;
}
- (void)setUrl: (NSString *)u
{
    ASSIGN(url, u);
    [self attributeChangedName: @"url" value: u];
}

- (NSString *)authors
{
    return authors;
}
- (void)setAuthors: (NSString *)a
{
    ASSIGN(authors, a);
    [self attributeChangedName: @"authors" value: a];
}

- (ApplicationRole)role
{
    return role;
}
- (void)setRole: (ApplicationRole)r
{
    role = r;
    [self attributeChangedName: @"role"
          value: [NSNumber numberWithInt: r]];
}

- (NSString *)startScript
{
    return startScript;
}
- (void)setStartScript: (NSString *)s
{
    ASSIGN(startScript, s);
    [self attributeChangedName: @"startScript" value: s];
}

- (NSString *)startScriptShell
{
    return startScriptShell;
}
- (void)setStartScriptShell: (NSString *)s
{
    ASSIGN(startScriptShell, s);
    [self attributeChangedName: @"startScriptShell" value: s];
}

- (ScriptAction)startScriptAction
{
    return startScriptAction;
}
- (void)setStartScriptAction: (ScriptAction)action
{
    startScriptAction = action;
    [self attributeChangedName: @"startScriptAction" value: [NSNumber numberWithInt: action]];
}

- (NSString *)activateScript
{
    return activateScript;
}
- (void)setActivateScript: (NSString *)s
{
    ASSIGN(activateScript, s);
    [self attributeChangedName: @"activateScript" value: s];
}

- (NSString *)activateScriptShell
{
    return activateScriptShell;
}
- (void)setActivateScriptShell: (NSString *)s
{
    ASSIGN(activateScriptShell, s);
    [self attributeChangedName: @"activateScriptShell" value: s];
}

- (ScriptAction)activateScriptAction
{
    return activateScriptAction;
}
- (void)setActivateScriptAction: (ScriptAction)action
{
    activateScriptAction = action;
    [self attributeChangedName: @"activateScriptAction" value: [NSNumber numberWithInt: action]];
}
- (NSString *)startOpenScript
{
    return startOpenScript;
}
- (void)setStartOpenScript: (NSString *)s
{
    ASSIGN(startOpenScript, s);
    [self attributeChangedName: @"startOpenScript" value: s];
}

- (NSString *)startOpenScriptShell
{
    return startOpenScriptShell;
}
- (void)setStartOpenScriptShell: (NSString *)s
{
    ASSIGN(startOpenScriptShell, s);
    [self attributeChangedName: @"startOpenScriptShell" value: s];
}

- (ScriptAction)startOpenScriptAction
{
    return startOpenScriptAction;
}
- (void)setStartOpenScriptAction: (ScriptAction)action
{
    startOpenScriptAction = action;
    [self attributeChangedName: @"startOpenScriptAction" value: [NSNumber numberWithInt: action]];
}

- (NSString *)openScript
{
    return openScript;
}
- (void)setOpenScript: (NSString *)s
{
    ASSIGN(openScript, s);
    [self attributeChangedName: @"openScript" value: s];
}

- (NSString *)openScriptShell
{
    return openScriptShell;
}
- (void)setOpenScriptShell: (NSString *)s
{
    ASSIGN(openScriptShell, s);
    [self attributeChangedName: @"openScriptShell" value: s];
}

- (ScriptAction)openScriptAction
{
    return openScriptAction;
}
- (void)setOpenScriptAction: (ScriptAction)action
{
    openScriptAction = action;
    [self attributeChangedName: @"openScriptAction" value: [NSNumber numberWithInt: action]];
}

- (NSString *)filterScript
{
    return filterScript;
}
- (void)setFilterScript: (NSString *)s
{
    ASSIGN(filterScript, s);
    [self attributeChangedName: @"filterScript" value: s];
}

- (NSString *)filterScriptShell
{
    return filterScriptShell;
}
- (void)setFilterScriptShell: (NSString *)s
{
    ASSIGN(filterScriptShell, s);
    [self attributeChangedName: @"filterScriptShell" value: s];
}

- (ScriptAction)filterScriptAction
{
    return filterScriptAction;
}
- (void)setFilterScriptAction: (ScriptAction)action
{
    filterScriptAction = action;
    [self attributeChangedName: @"filterScriptAction" value: [NSNumber numberWithInt: action]];
}


/*
 * types
 */

- (void)addType: (Type *)type
{
    if ( ! [types containsObject: type] ) {
        [types addObject: type];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                              selector: @selector(aggregateChanged:)
                                              name: (WrapperAggregateChangedNotification)
                                              object: (type)];
        [self documentChanged];
    }
    else {
        NSLog(@"Type %@ already in document, not added", type);
    }
}

- (void)removeType: (Type *)type
{
    if ( [types containsObject: type] ) {
        [types removeObject: type];
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                              name: (WrapperAggregateChangedNotification)
                                              object: (type)];
        [self documentChanged];
    }
    else {
        NSLog(@"Type %@ not in document, not removed", type);
    }
}

- (int)typeCount
{
    return [types count];
}

- (Type *)typeAtIndex: (unsigned)index
{
    return [types objectAtIndex: index];
}

- (unsigned)indexOfType: (Type *)type
{
    return [types indexOfObject: type];
}

/*
 * services
 */

- (void)addService: (Service *)service
{
    if ( ! [services containsObject: service] ) {
        [services addObject: service];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                              selector: @selector(aggregateChanged:)
                                              name: (WrapperAggregateChangedNotification)
                                              object: (service)];
        [self documentChanged];
    }
    else {
        NSLog(@"Service %@ already in document, not added", service);
    }
}

- (void)removeService: (Service *)service
{
    if ( [services containsObject: service] ) {
        [services removeObject: service];
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                              name: (WrapperAggregateChangedNotification)
                                              object: (service)];
        [self documentChanged];
    }
    else {
        NSLog(@"Service %@ not in document, not removed", service);
    }
}

- (int)serviceCount
{
    return [services count];
}

- (Service *)serviceAtIndex: (unsigned)index
{
    return [services objectAtIndex: index];
}

- (unsigned)indexOfService: (Service *)service
{
    return [services indexOfObject: service];
}


@end



/*
 * category Private
 */

@implementation WrapperDocument (Private)


- (void)attributeChangedName: (NSString *)n
                       value: (id)v;
{
    /*
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                           n, WrapperChangedAttributeName,
                                           v, WrapperChangedAttributeValue,
                                           nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: WrapperChangedNotification
                                          object: (self)
                                          userInfo: (userInfo)];
                                          */
    [self documentChanged];
}

- (void)documentChanged
{
    if ( ! [self isDocumentEdited] ) {
        [self updateChangeCount: NSChangeDone];
    }
}

- (void)aggregateChanged: (NSNotification *)not
{
    //NSLog(@"Aggregate changed: %@", not);
    [self documentChanged];
}

- (NSArray *)arrayFromCommaSeparatedString: (NSString *)string
{
    NSArray *array = [string componentsSeparatedByString: @","];
    int count = [array count];
    if ( count <= 0 ) {
        return nil;
    }
    NSMutableArray *result = [NSMutableArray arrayWithCapacity: [array count]];
    NSString *element;
    int i;
    for ( i=0; i<count; i++ ) {
        element = [array objectAtIndex: i];
        element = [element stringByTrimmingSpaces];
        if ( [element length] > 0 ) {
            [result addObject: element];
        }
    }
    if ( [result count] > 0 ) {
        return result;
    }
    else {
        return nil;
    }
}

- (BOOL)loadWrapper: (NSFileWrapper *)file
{
    if ( [file isRegularFile] ) {
        NSLog(@"%@ is a regular file -> not an application wrapper", [file filename]);
        return NO;
    }
    NS_DURING {
        NSString *value;
        NSDictionary *dict;

        NSFileWrapper *resourcesFile = [[file fileWrappers] objectForKey: @"Resources"];
        if ( !resourcesFile ) {
            NSLog(@"Resources directory not found");
            return NO;
        }
        NSDictionary *resources = [resourcesFile fileWrappers];
        NSFileWrapper *infoFile = [resources objectForKey: @"Info-gnustep.plist"];
        if ( !infoFile ) {
            NSLog(@"Resources/Info-gnustep.plist not found");
            return NO;
        }


        // Load GSWrapper.plist
        NSFileWrapper *gsWrapperInfoFile = [resources objectForKey: @"GSWrapper.plist"];
        if ( !gsWrapperInfoFile ) {
            NSLog(@"Resources/GSWrapper.plist not found");
            return NO;
        }
        NSDictionary *gsWrapperInfo = [NSDictionary dictionaryWithContentsOfFile: [gsWrapperInfoFile filename]];
        NSNumber *v = [gsWrapperInfo objectForKey: @"Version"];
        if ( [v intValue] > currentVersion ) {
            NSLog(@"Version %d too new, don't know how to load this", [v intValue]);
            return NO;
        }
        dict = [gsWrapperInfo objectForKey: @"Start"];
        if ( dict ) {
            value = [dict objectForKey: @"Shell"];
            if ( value ) {
                [self setStartScriptShell: value];
            }
            else {
                NSLog(@"No shell for Start script set");
            }
            value = [dict objectForKey: @"Action"];
            if ( value ) {
                [self setStartScriptAction: [WrapperDocument stringToScriptAction: value]];
            }
            else {
                NSLog(@"No action for Start script set");
                [self setStartScriptAction: RunScriptAction];
            }
        }
        else {
            NSLog(@"No info for Start script");
        }
        dict = [gsWrapperInfo objectForKey: @"StartOpen"];
        if ( dict ) {
            value = [dict objectForKey: @"Shell"];
            if ( value ) {
                [self setStartOpenScriptShell: value];
            }
            else {
                NSLog(@"No shell for StartOpen script set");
            }
            value = [dict objectForKey: @"Action"];
            if ( value ) {
                [self setStartOpenScriptAction: [WrapperDocument stringToScriptAction: value]];
            }
            else {
                NSLog(@"No action for StartOpen script set");
                [self setStartOpenScriptAction: RunScriptAction];
            }
        }
        else {
            NSLog(@"No info for StartOpen script");
        }
        dict = [gsWrapperInfo objectForKey: @"Open"];
        if ( dict ) {
            value = [dict objectForKey: @"Shell"];
            if ( value ) {
                [self setOpenScriptShell: value];
            }
            else {
                NSLog(@"No shell for Open script set");
            }
            value = [dict objectForKey: @"Action"];
            if ( value ) {
                [self setOpenScriptAction: [WrapperDocument stringToScriptAction: value]];
            }
            else {
                NSLog(@"No action for Open script set");
                [self setOpenScriptAction: RunScriptAction];
            }
        }
        else {
            NSLog(@"No info for Open script");
        }
        dict = [gsWrapperInfo objectForKey: @"Activate"];
        if ( dict ) {
            value = [dict objectForKey: @"Shell"];
            if ( value ) {
                [self setActivateScriptShell: value];
            }
            else {
                NSLog(@"No shell for Activate script set");
            }
            value = [dict objectForKey: @"Action"];
            if ( value ) {
                [self setActivateScriptAction: [WrapperDocument stringToScriptAction: value]];
            }
            else {
                NSLog(@"No action for Activate script set");
                [self setActivateScriptAction: RunScriptAction];
            }
        }
        else {
            NSLog(@"No info for Activate script");
        }
        dict = [gsWrapperInfo objectForKey: @"Filter"];
        if ( dict ) {
            value = [dict objectForKey: @"Shell"];
            if ( value ) {
                [self setFilterScriptShell: value];
            }
            else {
                NSLog(@"No shell for Filter script set");
            }
            value = [dict objectForKey: @"Action"];
            if ( value ) {
                [self setFilterScriptAction: [WrapperDocument stringToScriptAction: value]];
            }
            else {
                NSLog(@"No action for Filter script set");
                [self setFilterScriptAction: RunScriptAction];
            }
        }
        else {
            NSLog(@"No info for Filter script");
        }
        dict = [gsWrapperInfo objectForKey: @"UserInterface"];
        if ( dict ) {
            value = [dict objectForKey: @"Shell"];
            if ( value ) {
                [self setUserInterfaceScriptShell: value];
            }
            else {
                NSLog(@"No shell for UserInterface script set");
            }
            value = [dict objectForKey: @"Action"];
            if ( [value isEqualToString: @"RunScript"] ) {
                [self setUserInterface:1];
            }
            else {
                NSLog(@"No action for UserInterface script set");
                [self setUserInterface:0];
            }
        }
        else {
            NSLog(@"No info for Activate script");
        }

        // Load Info-gnustep.plist
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile: [infoFile filename]];
        value = [info objectForKey: @"ApplicationName"];
        if ( value ) {
            [self setName: value];
        }
        else {
            NSLog(@"ApplicationName not set");
        }
        value = [info objectForKey: @"ApplicationRelease"];
        if ( value ) {
            [self setVersion: value];
        }
        else {
            NSLog(@"ApplicationRelease not set");
        }
        value = [info objectForKey: @"FullVersionID"];
        if ( value ) {
            [self setFullVersion: value];
        }
        else {
            NSLog(@"FullVersionID not set");
        }
        value = [info objectForKey: @"ApplicationDescription"];
        if ( value ) {
            [self setDescription: value];
        }
        else {
            NSLog(@"ApplicationDescription not set");
        }
        value = [info objectForKey: @"ApplicationURL"];
        if ( value ) {
            [self setUrl: value];
        }
        else {
            NSLog(@"ApplicationURL not set");
        }
        NSArray *authorsArray = [info objectForKey: @"Authors"];
        if ( authorsArray ) {
            [self setAuthors: [authorsArray componentsJoinedByString: @", "]];
        }
        else {
            NSLog(@"Authors not set");
        }

        NSArray *schemesArray = [info objectForKey: @"CFBundleURLTypes"];
        NSMutableArray *schemeExtensions = [NSMutableArray new];
        if ( schemesArray ) {
            for (NSDictionary *it in schemesArray) {
                NSArray *list = [it objectForKey: @"CFBundleURLSchemes"];
                for (NSString *scheme in list) {
                    [schemeExtensions addObject: [NSString stringWithFormat: @"%@:", scheme]];
                }
            }
        }
        if ( [schemeExtensions count] ) {
            Type *type = AUTORELEASE([[Type alloc] init]);
            [type setName: @"Open URL"];
            [type setExtensions: [schemeExtensions componentsJoinedByString: @","]];
            [self addType: type];
        }

        // types
        NSArray *typeDicts = [info objectForKey: @"NSTypes"];
        if ( typeDicts ) {
            int typeCount = [typeDicts count];
            int i;
            for ( i=0; i<typeCount; i++ ) {
                NSDictionary *typeDict = [typeDicts objectAtIndex: i];
                Type *type = AUTORELEASE([[Type alloc] init]);
                value = [typeDict objectForKey: @"NSName"];
                if ( value ) {
                    [type setName: value];
                }
                else {
                    NSLog(@"NSName not set for type #%d", i);
                }
                NSArray *extArray = [typeDict objectForKey: @"NSUnixExtensions"];

                if ( extArray ) {
                    [type setExtensions: [extArray componentsJoinedByString: @", "]];
                }
                else {
                    NSLog(@"NSUnixExtensions not set for type #%d", i);
                }
                NSString *typeIconFileName = [typeDict objectForKey: @"NSIcon"];
                if ( typeIconFileName ) {
                    NSFileWrapper *typeIconFile = [resources objectForKey: typeIconFileName];
                    if ( typeIconFile ) {
                        [type setIcon: [Icon iconWithImage: AUTORELEASE([[NSImage alloc] initByReferencingFile: [typeIconFile filename]])]];
                    }
                    else {
                        NSLog(@"Icon named %@ not found", typeIconFileName);
                    }
                }
                else {
                    NSLog(@"NSIcon not set for type #%d", i);
                }
                [self addType: type];
            }
        }
        else {
            NSLog(@"NSTypes not set");
        }

        // services
        NSArray *serviceDicts = [info objectForKey: @"NSServices"];
        if ( serviceDicts ) {
            int serviceCount = [serviceDicts count];
            int i;
            for ( i=0; i<serviceCount; i++ ) {
                NSDictionary *serviceDict = [serviceDicts objectAtIndex: i];

                /*
                if ([[serviceDict objectForKey:@"NSMessage"] isEqualToString:@"openURL"]) {
                    continue;
                }
                */

                NSString *n = [[serviceDict objectForKey:@"NSMenuItem"] objectForKey:@"default"];
                NSString *f = [serviceDict objectForKey:@"NSFilter"];
                if (f) {
                    Type *type = AUTORELEASE([[Type alloc] init]);
                    NSArray* st = [serviceDict objectForKey:@"NSSendTypes"];
                    NSArray* rt = [serviceDict objectForKey:@"NSReturnTypes"];
                    [type setFilter: YES];

                    NSMutableArray *xs = [NSMutableArray array];
                    for (NSString* it in st) {
                        if ([it hasPrefix:@"NSTypedFileContentsPboardType"]) {
                            [xs addObject: [it substringFromIndex:30]];
                        }
                    }
                    [type setExtensions: [xs componentsJoinedByString: @","]];
                    [type setReturnType: [rt firstObject]];
                    [type setName: [NSString stringWithFormat: @"filter %@", [type extensions]]];
                    [self addType: type];
                }
                else if (n) {
                    Service *service = AUTORELEASE([[Service alloc] init]);
                    [service setName:n];

                    NSString *ud = [serviceDict objectForKey:@"NSUserData"];
                    if (ud) {
                        NSString *inDataType  = [[gsWrapperInfo objectForKey: ud] objectForKey: @"SendType"];
                        NSString *outDataType = [[gsWrapperInfo objectForKey: ud] objectForKey: @"ReturnType"];

                        [service setReturnType: outDataType];
                        [service setSendType: inDataType];

                        NSFileWrapper *serviceFile = [resources objectForKey: ud];
                        NSString *action = [NSString stringWithContentsOfFile: [serviceFile filename]];
                        [service setAction:action];
                    }

                    [self addService: service];
                }
            }
        }
        else {
            NSLog(@"NSServices not set");
        }


        // Load other resources
        NSFileWrapper *appIconFile = [resources objectForKey: @"AppIcon.tiff"];
        if ( appIconFile ) {
            //[self setAppIcon: [IconView imageWithData: [appIconFile regularFileContents]]];
            [self setAppIcon: [Icon iconWithImage: AUTORELEASE([[NSImage alloc] initByReferencingFile: [appIconFile filename]])]];
        }
        else {
            NSLog(@"AppIcon.tiff not found");
        }
        NSFileWrapper *startFile = [resources objectForKey: @"Start"];
        if ( startFile ) {
            [self setStartScript: [NSString stringWithContentsOfFile: [startFile filename]]];
        }
        else {
            NSLog(@"No Start script");
        }
        NSFileWrapper *startOpenFile = [resources objectForKey: @"StartOpen"];
        if ( startOpenFile ) {
            [self setStartOpenScript: [NSString stringWithContentsOfFile: [startOpenFile filename]]];
        }
        else {
            NSLog(@"No StartOpen script");
        }
        NSFileWrapper *openFile = [resources objectForKey: @"Open"];
        if ( openFile ) {
            [self setOpenScript: [NSString stringWithContentsOfFile: [openFile filename]]];
        }
        else {
            NSLog(@"No Open script");
        }
        NSFileWrapper *activateFile = [resources objectForKey: @"Activate"];
        if ( openFile ) {
            [self setActivateScript: [NSString stringWithContentsOfFile: [activateFile filename]]];
        }
        else {
            NSLog(@"No Activate script");
        }
        NSFileWrapper *filterFile = [resources objectForKey: @"Filter"];
        if ( filterFile ) {
            [self setFilterScript: [NSString stringWithContentsOfFile: [filterFile filename]]];
        }
        else {
            NSLog(@"No Filter script");
        }
        NSFileWrapper *userInterfaceFile = [resources objectForKey: @"Launcher"];
        if ( userInterfaceFile ) {
            [self setUserInterfaceScript: [NSString stringWithContentsOfFile: [userInterfaceFile filename]]];
        }
        else {
            NSLog(@"No Launcher script");
        }
        NSFileWrapper *nibFile = [resources objectForKey: @"Launcher.gorm"];
        if ( nibFile ) {
            NSString *tfile = [NSString stringWithFormat:@"%@/Launcher-%lx.gorm", NSTemporaryDirectory(), [self hash]];
            [nibFile writeToFile:tfile atomically:NO updateFilenames:YES];
            ASSIGN(userInterfacePath, tfile);
        }

        // done
        [self updateChangeCount: NSChangeCleared];
        return YES;
    }
    NS_HANDLER {
        NSLog(@"Exception loading wrapper: %@", localException);
        return NO;
    } NS_ENDHANDLER;
}

- (NSFileWrapper *)saveWrapper
{

    //NSSize iconSize = NSMakeSize(48, 48);
    NSData *data;
    NSDictionary *dict;
    int i;

    // Info-gnustep.plist
    NSMutableDictionary *infoDict =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
                             @"AppIcon.tiff", @"NSIcon",
                             name, @"ApplicationName",
                             version, @"ApplicationRelease",
                             fullVersion, @"FullVersionID",
                             description, @"ApplicationDescription",
                             url, @"ApplicationURL",
                             @"NSApplication", @"NSPrincipalClass",
                             nil];
    switch ( role ) {
    case NoneRole:
        [infoDict setObject: @"None" forKey: @"NSRole"];
        break;
    case ViewerRole:
        [infoDict setObject: @"Viewer" forKey: @"NSRole"];
        break;
    case EditorRole:
        [infoDict setObject: @"Editor" forKey: @"NSRole"];
        break;
    }
    NSArray *authorArray = [self arrayFromCommaSeparatedString: [self authors]];
    if ( authorArray ) {
        [infoDict setObject: authorArray forKey: @"Authors"];
    }
    // types
    int typeCount = [types count];
    if ( typeCount ) {
        NSMutableArray *typeArray = [NSMutableArray arrayWithCapacity: typeCount];
        for ( i=0; i<typeCount; i++ ) {
            Type *type = [types objectAtIndex: i];
            if (! [type isFilter] && ! [type isScheme]) {
                NSString *iconFile = [NSString stringWithFormat: @"FileType_%03d.tiff", i];
                NSMutableDictionary *typeDict = [NSMutableDictionary dictionaryWithCapacity: 4];
                [typeDict setObject: iconFile forKey: @"NSIcon"];
                NSArray *extensions = [self arrayFromCommaSeparatedString: [type extensions]];
                if ( extensions ) {
                    [typeDict setObject: extensions forKey: @"NSUnixExtensions"];
                }
                [typeDict setObject: [type name] forKey: @"NSName"];
                [typeArray addObject: typeDict];
            }
        }
        [infoDict setObject: typeArray forKey: @"NSTypes"];
    }

    // services
    NSMutableArray *serviceArray = [NSMutableArray array];
    NSMutableArray* slist = [NSMutableArray array];
    int serviceCount = [services count];
    if ( serviceCount ) {
        for ( i=0; i<serviceCount; i++ ) {
            Service *service = [services objectAtIndex: i];
            NSString* ud = [NSString stringWithFormat:@"Service_%03d", i];
            NSMutableDictionary *serviceDict = [NSMutableDictionary dictionaryWithCapacity: 6];

            [serviceDict setObject: @"executeService" forKey: @"NSMessage"];
            [serviceDict setObject: [name stringByDeletingPathExtension] forKey: @"NSPortName"];
            [serviceDict setObject: ud forKey: @"NSUserData"];
            [serviceDict setObject: [NSDictionary dictionaryWithObjectsAndKeys:[service name], @"default", nil] forKey: @"NSMenuItem"];

            NSString* sendType = [service sendType];
            if ([sendType length] > 0) {
                [serviceDict setObject: [NSArray arrayWithObject: sendType] forKey: @"NSSendTypes"];
            }

            NSString* returnType = [service returnType];
            if ([returnType length] > 0) {
                [serviceDict setObject: [NSArray arrayWithObject: returnType] forKey: @"NSReturnTypes"];
            }
            [serviceArray addObject: serviceDict];

            [slist addObject:
                [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSDictionary dictionaryWithObjectsAndKeys:
                        [service shell], @"Shell",
                        @"RunScript", @"Action",
                        returnType?returnType:@"", @"ReturnType",
                        sendType?sendType:@"", @"SendType",
                    nil],
                    ud,
                nil]
            ];
        }
    }

    //schemes
    NSMutableArray *schemesArray = [NSMutableArray array];
    for ( i=0; i<typeCount; i++ ) {
        Type *type = [types objectAtIndex: i];
         if ([type isScheme] && [[type extensions] length]) {
            NSMutableDictionary *schemeDict = [NSMutableDictionary dictionaryWithCapacity: 6];
            [schemeDict setObject: @"Open URL" forKey: @"CFBundleURLName"];
            [schemeDict setObject: [type schemes] forKey: @"CFBundleURLSchemes"];

            [schemesArray addObject: schemeDict];
         }
    }
    if ( [schemesArray count] > 0 ) {
        [infoDict setObject: schemesArray forKey: @"CFBundleURLTypes"];
    }

    //filters
    for ( i=0; i<typeCount; i++ ) {
        Type *type = [types objectAtIndex: i];
         if ([type isFilter] && [[type returnType] length]) {
            NSMutableDictionary *serviceDict = [NSMutableDictionary dictionaryWithCapacity: 6];
            [serviceDict setObject: @"executeFilter" forKey: @"NSFilter"];
            [serviceDict setObject: [name stringByDeletingPathExtension] forKey: @"NSPortName"];
           
            NSMutableArray *sx = [NSMutableArray array];
            [sx addObject: NSFilenamesPboardType];

            for (NSString *ext in [self arrayFromCommaSeparatedString: [type extensions]]) {
                NSString *xx = [NSString stringWithFormat:@"NSTypedFileContentsPboardType:%@", ext];
                [sx addObject: xx];

                xx = [NSString stringWithFormat:@"NSFilenamesPboardType:%@", ext];
                [sx addObject: xx];
            }

            [serviceDict setObject: sx forKey: @"NSSendTypes"];
            [serviceDict setObject: [NSArray arrayWithObject: [type returnType]] forKey: @"NSReturnTypes"];

            NSString *ud = [type returnType];
            [serviceDict setObject: ud forKey: @"NSUserData"];
            [serviceArray addObject: serviceDict];
        }
    }

    /*
    if ( [schemesArray count] > 0 ) {
        NSMutableDictionary *serviceDict = [NSMutableDictionary dictionaryWithCapacity: 6];
        [serviceDict setObject: [name stringByDeletingPathExtension] forKey: @"NSPortName"];
        [serviceDict setObject: @"openURL" forKey: @"NSMessage"];
        [serviceDict setObject: [NSArray arrayWithObjects:@"NSURLPboardType",@"NSStringPboardType",nil] forKey: @"NSSendTypes"];
        [serviceArray addObject: serviceDict];
    }
    */

    if ( [serviceArray count] > 0 ) {
        [infoDict setObject: serviceArray forKey: @"NSServices"];
    }

    data = [[infoDict description] dataUsingEncoding: NSNonLossyASCIIStringEncoding];
    NSFileWrapper *info = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
    [info setPreferredFilename: @"Info-gnustep.plist"];

    // GSWrapper.plist
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInt: 1], @"Version",
                         [NSDictionary dictionaryWithObjectsAndKeys:
                                       startScriptShell, @"Shell",
                                       [WrapperDocument scriptActionToString: startScriptAction], @"Action",
                                       nil], @"Start",
                         [NSDictionary dictionaryWithObjectsAndKeys:
                                       startOpenScriptShell, @"Shell",
                                       [WrapperDocument scriptActionToString: startOpenScriptAction], @"Action",
                                       nil], @"StartOpen",
                         [NSDictionary dictionaryWithObjectsAndKeys:
                                       openScriptShell, @"Shell",
                                       [WrapperDocument scriptActionToString: openScriptAction], @"Action",
                                       nil], @"Open",
                         [NSDictionary dictionaryWithObjectsAndKeys:
                                       activateScriptShell, @"Shell",
                                       [WrapperDocument scriptActionToString: activateScriptAction], @"Action",
                                       nil], @"Activate",
                         [NSDictionary dictionaryWithObjectsAndKeys:
                                       userInterfaceScriptShell, @"Shell",
                                       (userInterface?@"RunScript":@"Ignore"), @"Action",
                                       nil], @"UserInterface",
                         [NSDictionary dictionaryWithObjectsAndKeys:
                                       filterScriptShell, @"Shell",
                                       [WrapperDocument scriptActionToString: filterScriptAction], @"Action",
                                       nil], @"Filter",
                         nil];

    NSMutableDictionary* adict = [NSMutableDictionary dictionary];
    [adict addEntriesFromDictionary: dict];
    for (id val in slist) {
        [adict addEntriesFromDictionary: val];
    }

    data = [[adict description] dataUsingEncoding: NSNonLossyASCIIStringEncoding];
    NSFileWrapper *gsWrapper = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
    [gsWrapper setPreferredFilename: @"GSWrapper.plist"];

    NSFileWrapper *icon = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: [[appIcon imageForOriginalSizeCopy: NO] TIFFRepresentation]]);
    //NSFileWrapper *icon = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: [appIcon scaledTIFFRepresentation: iconSize]]);
    //NSLog(@"Icon: %@", [appIcon scaledTIFFRepresentation: iconSize]);
    [icon setPreferredFilename: @"AppIcon.tiff"];

    data = [startScript dataUsingEncoding: [NSString defaultCStringEncoding]];
    NSFileWrapper *start = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
    [start setPreferredFilename: @"Start"];

    data = [activateScript dataUsingEncoding: [NSString defaultCStringEncoding]];
    NSFileWrapper *activate = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
    [activate setPreferredFilename: @"Activate"];

    data = [startOpenScript dataUsingEncoding: [NSString defaultCStringEncoding]];
    NSFileWrapper *startOpen = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
    [startOpen setPreferredFilename: @"StartOpen"];

    data = [openScript dataUsingEncoding: [NSString defaultCStringEncoding]];
    NSFileWrapper *open = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
    [open setPreferredFilename: @"Open"];

    data = [userInterfaceScript dataUsingEncoding: [NSString defaultCStringEncoding]];
    NSFileWrapper *ui = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
    [ui setPreferredFilename: @"Launcher"];

    data = [filterScript dataUsingEncoding: [NSString defaultCStringEncoding]];
    NSFileWrapper *filter = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
    [filter setPreferredFilename: @"Filter"];


    NSFileWrapper *resources = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:
                                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                                                        info, [info preferredFilename],
                                                                        gsWrapper, [gsWrapper preferredFilename],
                                                                        icon, [icon preferredFilename],
                                                                        start, [start preferredFilename],
                                                                        activate, [activate preferredFilename],
                                                                        startOpen, [startOpen preferredFilename],
                                                                        open, [open preferredFilename],
                                                                        filter, [filter preferredFilename],
                                                                        ui, [ui preferredFilename],
                                                                        nil]];
    // file type icons
    for ( i=0; i<typeCount; i++ ) {
        Type *type = [types objectAtIndex: i];
        NSFileWrapper *typeIcon = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: [[[type icon] imageForOriginalSizeCopy: NO] TIFFRepresentation]]);
        //NSFileWrapper *typeIcon = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: [[type icon] scaledTIFFRepresentation: iconSize]]);
        [typeIcon setPreferredFilename: [NSString stringWithFormat: @"FileType_%03d.tiff", i]];
        [resources addFileWrapper: typeIcon];
    }

    for ( i=0; i<serviceCount; i++ ) {
        Service *service = [services objectAtIndex: i];
        NSData* data = [[service action] dataUsingEncoding: [NSString defaultCStringEncoding]];
        NSFileWrapper *serviceScript = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
        [serviceScript setPreferredFilename: [NSString stringWithFormat: @"Service_%03d", i]];
        [resources addFileWrapper: serviceScript];
    }

    if ( userInterfacePath ) {
        NSFileWrapper *nibFile = AUTORELEASE([[NSFileWrapper alloc] initWithPath: userInterfacePath]);
        [nibFile setPreferredFilename: @"Launcher.gorm"];
        [resources addFileWrapper: nibFile];
    }

    [resources setPreferredFilename: @"Resources"];
    AUTORELEASE(resources);

    NSData *exe = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource: launcherName
                                                                     ofType: (nil)]];
    AppFileWrapper *app = [[AppFileWrapper alloc] initDirectoryWithFileWrappers:
                                                      [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    resources, [resources preferredFilename],
                                                                    nil]];
    AUTORELEASE(app);
    [app setExecutable: exe];
    return app;
}

- (BOOL)loadFreedesktopApplication: (NSFileWrapper *)file
{
    if ( ![file isRegularFile] ) {
        NSLog(@"is not a regular file");
        return NO;
    }

    NSString *fdentry = [[NSString alloc] initWithData: [file regularFileContents] encoding: NSUTF8StringEncoding];
    AUTORELEASE(fdentry);
    NSArray *lines = [fdentry componentsSeparatedByString: @"\n"];

    int lineCount = [lines count];
    int i;
    NSString *exec = nil;
    NSString *path = nil;
    NSString *section = nil;
    for ( i=0; i<lineCount; i++ ) {
        NSString *l = (NSString *)[lines objectAtIndex: i];
        l = [l stringByTrimmingSpaces];

        if ( ([l length] <= 0) || ([l hasPrefix: @"#"]) ) {
            // comment/blank: skip$
            continue;
        }
        else if ( [l hasPrefix: @"["] ) {
            if ( ![l hasSuffix: @"]"] ) {
                NSLog(@"Invalid section header: ] expected");
                return NO;
            }
            section = [l substringWithRange: NSMakeRange(1, [l length]-2)];
            NSLog(@"Section: \"%@\"", section);
        }
        else {
            if ( !section ) {
                NSLog(@"No section");
                return NO;
            }
            NSRange split = [l rangeOfString: @"="];
            NSString *key = [[l substringToIndex: split.location] stringByTrimmingSpaces];
            NSString *value = [[l substringFromIndex: split.location+1] stringByTrimmingSpaces];
            if ( [key length] <= 0 ) {
                NSLog(@"No key: %@", l);
                return NO;
            }
            NSLog(@"Entry: %@=%@", key, value);

            if ( [section isEqualToString: @"Desktop Entry"] ) {
                if ( [key isEqualToString: @"Type"] ) {
                    // FIXME: Only apps?
                }
                else if ( [key isEqualToString: @"Name"] ) {
                    [self setName: value];
                }
                else if ( [key isEqualToString: @"Comment"] ) {
                    [self setDescription: value];
                }
                else if ( [key isEqualToString: @"Icon"] ) {
                    // FIXME: load the icon
                }
                else if ( [key isEqualToString: @"Exec"] ) {
                    NSLog(@"fjsaail");
                    exec = value;
                }
                else if ( [key isEqualToString: @"Path"] ) {
                    path = value;
                }
                else if ( [key isEqualToString: @"Terminal"] ) {
                    // FIXME: run in terminal -> Terminal.app?
                }
                else {
                    NSLog(@"Ignoring entry in section %@: %@=%@", section, key, value);
                }
            }
            else {
                NSLog(@"Ignoring entry in section %@: %@=%@", section, key, value);
            }
        }
    }
    if ( exec == nil ) {
        NSLog(@"No executable specified");
        return NO;
    }
    if ( path ) {
        path = [NSString stringWithFormat: @"cd \"%@\"\n", path];
    }
    else {
        path = @"";
    }
    // FIXME: actions
    [self setStartScript: [NSString stringWithFormat: @"%@exec \"%@\"\n", path, exec]];
    [self setStartOpenScript: [NSString stringWithFormat: @"%@exec \"%@\" \"$@\"\n", path, exec]];
    [self setOpenScript: @"exit 1\n"];
    return YES;
}

- (NSFileWrapper *)saveFreedesktopApplication
{
    NSLog(@"Saving freedesktop desktop entries not supported yet");
    return nil;
}

+ (ScriptAction)stringToScriptAction: (NSString *)str
{
    if ( [str isEqualToString: actionRunScript] ) {
        return RunScriptAction;
    }
    else if ( [str isEqualToString: actionFail] ) {
        return FailAction;
    }
    else if ( [str isEqualToString: actionIgnore] ) {
        return IgnoreAction;
    }
    else {
        NSLog(@"Invalid action string: %@; defaulting to %@", str, actionRunScript);
        return RunScriptAction;
    }
}

+ (NSString *)scriptActionToString: (ScriptAction)action
{
    switch ( action ) {
    case RunScriptAction:
        return actionRunScript;
    case FailAction:
        return actionFail;
    case IgnoreAction:
        return actionIgnore;
    default:
        NSLog(@"Invalid action constant: %d; defaulting to 0 (RunScript)", action);
        return actionRunScript;
    }
}

@end

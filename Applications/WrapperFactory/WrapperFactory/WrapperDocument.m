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
NSString * const WrapperChangedNotification = @"WrapperChangedNotification";
NSString * const WrapperChangedAttributeName = @"AttributeName";
NSString * const WrapperChangedAttributeValue = @"AttributeValue";

NSString * const WrapperAggregateChangedNotification = @"WrapperAggregateChangedNotification";
NSString * const WrapperAggregateChangedObject = @"Object";
NSString * const WrapperAggregateChangedAttributeName = @"AttributeName";
NSString * const WrapperAggregateChangedAttributeValue = @"AttributeValue";

static NSString *emptyString = @"";
static NSString *launcherName = @"GSWrapper_Launcher";
static NSString *FreedesktopApplicationType = @"Freedesktop Application";

static NSString *actionRunScript = @"RunScript";
static NSString *actionFail = @"Fail";
static NSString *actionIgnore = @"Ignore";



/*
 * AppFileWrapper
 */

@interface AppFileWrapper : NSFileWrapper
{
    BOOL flattened;
    NSData *script;
    NSData *executable;
    NSString *executablePath;
}

- (void)setFlattened: (BOOL)f;
- (BOOL)flattened;

- (void)setScript: (NSData *)s;
- (NSData *)script;

- (void)setExecutable: (NSData *)exe;
 - (NSData *)executable;

- (void)setExecutablePath: (NSString *)exep;
- (NSString *)executablePath;

- (BOOL)writeToFile: (NSString *)path
         atomically:(BOOL)atomicFlag
    updateFilenames:(BOOL)updateNamesFlag;

@end

@implementation AppFileWrapper

- (void)dealloc
{
    TEST_RELEASE(script);
    TEST_RELEASE(executable);
    TEST_RELEASE(executablePath);
}

- (void)setFlattened: (BOOL)f
{
    flattened = f;
}

- (BOOL)flattened
{
    return flattened;
}

- (void)setScript: (NSData *)s
{
    ASSIGN(script, s);
}

- (NSData *)script
{
    return script;
}

- (void)setExecutable: (NSData *)exe
{
    ASSIGN(executable, exe);
}

- (NSData *)executable
{
    return executable;
}

- (void)setExecutablePath: (NSString *)exep
{
    ASSIGN(executablePath, exep);
}

- (NSString *)executablePath
{
    return executablePath;
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
        if ( flattened ) {
            [executable writeToFile: p atomically: NO];
        }
        else {
            [script writeToFile: p atomically: NO];
        }
        NSFileManager *fm = [NSFileManager defaultManager];
        NSDictionary *attrs = [fm fileAttributesAtPath: p traverseLink: NO];
        NSNumber *perms = [attrs objectForKey: NSFilePosixPermissions];
        perms = [NSNumber numberWithInt: [perms intValue]|0111];
        attrs = [NSDictionary dictionaryWithObject: perms forKey: NSFilePosixPermissions];
        [fm changeFileAttributes: attrs atPath: p];
        if ( !flattened ) {
            NSString *exe = [path stringByAppendingPathComponent: [executablePath stringByAppendingPathComponent: basename]];
            [executable writeToFile: exe atomically: YES];
            [fm changeFileAttributes: attrs atPath: exe];
        }
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
        name = _(@"Untitled.app");
        version = @"1.0";
        fullVersion = @"1.0/1.0";
        description = _(@"A wrapped application");
        url = emptyString;
        authors = emptyString;
        role = NoneRole;

        startScript = emptyString;
        startScriptShell = @"/bin/sh";
        startScriptAction = RunScriptAction;
        startOpenScript = emptyString;
        startOpenScriptShell = startScriptShell;
        startOpenScriptAction = RunScriptAction;
        openScript = emptyString;
        openScriptShell = startScriptShell;
        openScriptAction = IgnoreAction;

        types = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    RELEASE(types);
}

- (BOOL)loadFileWrapperRepresentation: (NSFileWrapper *)file
                               ofType: (NSString *)type
{
    NSLog(@"Loading wrapper: %@", [file filename]);
    if ( [type isEqualToString: ApplicationType]  ) {
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


@end



/*
 * category Private
 */

@implementation WrapperDocument (Private)


- (void)attributeChangedName: (NSString *)n
                       value: (id)v;
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                           n, WrapperChangedAttributeName,
                                           v, WrapperChangedAttributeValue,
                                           nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: WrapperChangedNotification
                                          object: (self)
                                          userInfo: (userInfo)];
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
        // the use of stringByTrimmingCharactersInSet: is discouraged by apple and probably buggy in GNUstep, too
        // element = [element stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
#ifdef GNUSTEP
        element = [element stringByTrimmingSpaces];
#else
#error -stringByTrimmingSpaces: is only supported under GNUstep
#endif
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

    NSString *flattenedString = [[[NSProcessInfo processInfo] environment] objectForKey: @"GNUSTEP_FLATTENED"];
    BOOL flattened;
    if ( flattenedString == nil ) {
        NSLog(@"GNUSTEP_FLATTENED not set");
        flattened = NO;
    }
    else {
        flattened = [flattenedString isEqualToString: @"yes"];
    }

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
        [infoDict setObject: typeArray forKey: @"NSTypes"];
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
                         nil];
    data = [[dict description] dataUsingEncoding: NSNonLossyASCIIStringEncoding];
    NSFileWrapper *gsWrapper = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
    [gsWrapper setPreferredFilename: @"GSWrapper.plist"];

    NSFileWrapper *icon = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: [[appIcon imageForOriginalSizeCopy: NO] TIFFRepresentation]]);
    //NSFileWrapper *icon = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: [appIcon scaledTIFFRepresentation: iconSize]]);
    //NSLog(@"Icon: %@", [appIcon scaledTIFFRepresentation: iconSize]);
    [icon setPreferredFilename: @"AppIcon.tiff"];

    data = [startScript dataUsingEncoding: [NSString defaultCStringEncoding]];
    NSFileWrapper *start = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
    [start setPreferredFilename: @"Start"];

    data = [startOpenScript dataUsingEncoding: [NSString defaultCStringEncoding]];
    NSFileWrapper *startOpen = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
    [startOpen setPreferredFilename: @"StartOpen"];

    data = [openScript dataUsingEncoding: [NSString defaultCStringEncoding]];
    NSFileWrapper *open = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: data]);
    [open setPreferredFilename: @"Open"];

    NSFileWrapper *resources = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:
                                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                                                        info, [info preferredFilename],
                                                                        gsWrapper, [gsWrapper preferredFilename],
                                                                        icon, [icon preferredFilename],
                                                                        start, [start preferredFilename],
                                                                        startOpen, [startOpen preferredFilename],
                                                                        open, [open preferredFilename],
                                                                        nil]];
    // file type icons
    for ( i=0; i<typeCount; i++ ) {
        Type *type = [types objectAtIndex: i];
        NSFileWrapper *typeIcon = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: [[[type icon] imageForOriginalSizeCopy: NO] TIFFRepresentation]]);
        //NSFileWrapper *typeIcon = AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents: [[type icon] scaledTIFFRepresentation: iconSize]]);
        [typeIcon setPreferredFilename: [NSString stringWithFormat: @"FileType_%03d.tiff", i]];
        [resources addFileWrapper: typeIcon];
    }

    [resources setPreferredFilename: @"Resources"];
    AUTORELEASE(resources);

    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    NSArray *exePathComponents = [NSArray arrayWithObjects:
                                          [environment objectForKey: @"GNUSTEP_HOST_CPU"],
                                          [environment objectForKey: @"GNUSTEP_HOST_OS"],
                                          [environment objectForKey: @"LIBRARY_COMBO"],
                                          nil];

    NSData *script;
    if ( flattened ) {
        script = nil;
    }
    else {
        script = [NSData dataWithContentsOfFile: [NSString pathWithComponents:
                                                               [NSArray arrayWithObjects:
                                                                        [[NSBundle mainBundle] bundlePath],
                                                                        @"WrapperFactory",
                                                                        nil]]];
    }

    NSData *exe;
    if ( flattened ) {
        exe = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource: launcherName
                                                                     ofType: (nil)]];

    }
    else {
        NSString *path = [NSString pathWithComponents:
                                       [exePathComponents arrayByAddingObject:
                                                              launcherName]];
        exe = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource: path
                                                                     ofType: (nil)]];
    }

    NSFileWrapper *exedir = nil;
    for ( i=[exePathComponents count]-1; i>=0; i-- ) {
        //dir = [[NSFileWrapper alloc] initWithPath: ];app
        if ( exedir ) {
            exedir = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:
                                                [NSDictionary dictionaryWithObjectsAndKeys: exedir, [exedir preferredFilename], nil]];
        }
        else {
            exedir = [[NSFileWrapper alloc] initDirectoryWithFileWrappers: [NSDictionary dictionary]];
        }
        [exedir setPreferredFilename: [exePathComponents objectAtIndex: i]];
        AUTORELEASE(exedir);
    }

    AppFileWrapper *app = [[AppFileWrapper alloc] initDirectoryWithFileWrappers:
                                                      [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    exedir, [exedir preferredFilename],
                                                                    resources, [resources preferredFilename],
                                                                    nil]];
    AUTORELEASE(app);
    [app setFlattened: flattened];
    [app setScript: script];
    [app setExecutable: exe];
    [app setExecutablePath: [NSString pathWithComponents: exePathComponents]];
    return app;
}

- (BOOL)loadFreedesktopApplication: (NSFileWrapper *)file
{
    if ( ![file isRegularFile] ) {
        NSLog(@"%@ is not a regular file");
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
#ifdef GNUSTEP
        l = [l stringByTrimmingSpaces];
#else
#error -stringByTrimmingSpaces is only supported under GNUstep
#endif
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

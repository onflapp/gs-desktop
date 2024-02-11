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
 * $Id: WrapperDelegate.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/libGSWrapper/WrapperDelegate.m $
 */

#import <AppKit/AppKit.h>
#import "WrapperDelegate.h"
#import "NSApplication+AppName.h"
#import "NSMenu+Suppress.h"
#import "AppIconView.h"

@implementation WrapperDelegate

/*
 * application delegate
 */

- (id)init
{
    self = [super init];
    appDidFinishLaunching = NO;
    startupFiles = nil;

    return self;
}

- (void)dealloc
{
    RELEASE(wrappedApp);
    RELEASE(shellTask);
    RELEASE(shellDelegate);
    RELEASE(shellEnv);
    RELEASE(mainAction);
    [super dealloc];
}

- (void)startupUI
{
    NSString *path = [[NSBundle mainBundle] pathForResource: @"GSWrapper" ofType: @"plist"];

    properties = RETAIN([NSDictionary dictionaryWithContentsOfFile: path]);
    shellEnv = [[NSMutableDictionary alloc] init];

    NSDictionary *uiprops = [properties objectForKey:@"UserInterface"];
    NSString *uishell = [uiprops objectForKey:@"Shell"];
    NSString *uiaction = [uiprops objectForKey:@"Action"];

    NSLog(@"startup user interface %@ %@", uishell, uiaction);

    if ([uiaction isEqualToString:@"RunScript"]) {
      if ([uishell isEqualToString:@"stexec"]) {
      }
      else {
        NSString* script = [[NSBundle mainBundle] pathForResource: @"Launcher" ofType: @""];
        NSString* gorm = [[NSBundle mainBundle] pathForResource: @"Launcher" ofType: @"gorm"];

        shellTask = [[ShellUITask alloc]initWithScript:script];
        [shellTask setShellExec:uishell];

        [shellEnv setValue:gorm forKey:@"GSWRAPPER_UI_FILE"];

        shellDelegate = [[ShellUIProxy alloc]init];

        NSMutableDictionary* o = [NSMutableDictionary dictionary];
        [o setValue:shellDelegate forKey:@"NSOwner"];
        [NSBundle loadNibFile:gorm externalNameTable:o withZone:nil];

        NSView* vv = [shellDelegate iconView];
        if (vv) {
          AppIconView *mv = [[AppIconView alloc] initWithFrame:NSMakeRect(0, 0, 64, 64)];
          [[NSApp iconWindow] setContentView:mv];
          [mv addSubview:vv];
          [vv setFrame:NSMakeRect(8, 8, 48, 48)];
        }
      }
    }
}

- (void)applicationWillFinishLaunching: (NSNotification*)not
{
  [self startupUI];

  NSString* wapp = [properties objectForKey:@"WrappedAppClassName"];
  if ( wapp ) {
    menu = [NSApp mainMenu];
    [[menu window] setHidesOnDeactivate:NO];

    wrappedApp = [[WrappedApp alloc] initWithClassName:wapp];
    [wrappedApp setDelegate:self];
    [wrappedApp startObservingEvents];
  }
}

- (void)applicationDidBecomeActive: (NSNotification*)not
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reactivateApplication) object:nil];
  if ( mainAction && appDidFinishLaunching && !appIsTerminating ) {
    [self performSelector:@selector(reactivateApplication) withObject:nil afterDelay:0.1];
  }
}

- (void)applicationDidFinishLaunching: (NSNotification*)not
{
    if([NSApp isScriptingSupported]) {
      [NSApp initializeApplicationScripting];
    }

    NSLog(@"finish");
    appDidFinishLaunching = YES;
    NSRegisterServicesProvider(self, [[NSApp applicationName] stringByDeletingPathExtension]);

    if ( startupFiles ) {
        mainAction = [[self actionForMessage: @"StartOpen"] retain];
        [shellEnv setValue:[startupFiles componentsJoinedByString:@":"] forKey:@"GSWRAPPER_FILES"];
    }
    else {
        mainAction = [[self actionForMessage: @"Start"] retain];
    }

    [mainAction executeWithFiles: startupFiles];
    lastActionTime = [[NSDate date] timeIntervalSinceReferenceDate];
    [startupFiles release];
    startupFiles = nil;

    if ( shellDelegate ) {
      [shellTask setEnvironment:shellEnv];
      [shellDelegate handleActions:shellTask];
    }
    else {
      if ( !mainAction ) {
          [NSApp terminate: self];
          return;
      }
      if ( ![mainAction task] ) {
          if ( [properties objectForKey: @"Filter"] ) {
              NSLog(@"Service handler configured - continue running for 60s");
              [NSApp performSelector:@selector(terminate:) withObject: self afterDelay:60];
              return;
          }
          else {
              NSLog(@"Main action has no task assigned - exiting");
              [NSApp terminate: self];
              return;
          }
      }
    }

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(unixAppExited:)
                                                 name: (NSTaskDidTerminateNotification)
                                               object: [mainAction task]];
}

- (void) applicationDidResignActive:(NSNotification*) not
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reactivateApplication) object:nil];
}

- (BOOL)application: (NSApplication*)app
           openFile: (NSString*)file
{
    return [self application: app
                 openFiles: [NSArray arrayWithObject: file]];
}

- (void)openURL:(NSPasteboard *)pboard
       userData:(NSString *)userData
          error:(NSString **)error  {
  NSString *path = [[pboard stringForType:NSStringPboardType] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];

  if (path) {
    [self application:NSApp openFile:path];
  }
}

- (BOOL) application: (NSApplication*)theApp
	     openURL: (NSURL*)aURL
{
    return [self application:NSApp openFile:[aURL description]];
}

- (BOOL)application: (NSApplication*)app
          openFiles: (NSArray*)files
{
    NSLog(@"Open files: %@", files);
    if ( ! appDidFinishLaunching ) {
        startupFiles = RETAIN(files);
        return YES;
    }
    else {
        if ( !openAction ) {
            openAction = [self actionForMessage: @"Open"];
        }
        if ( !openAction ) {
            return NO;
        }

        BOOL retval = [openAction executeWithFiles: files];
        lastActionTime = [[NSDate date] timeIntervalSinceReferenceDate];

        NSTask *task = [openAction task];
        if ( !task ) {
            return retval;
        }
        else {
            [task waitUntilExit];
            if ( [task terminationStatus] ) {
                NSRunCriticalAlertPanel([NSApp applicationName],
                                        [NSString stringWithFormat: @"Script exited with exit code %d",
                                                  [task terminationStatus]],
                                        @"OK", nil, nil);
                return NO;
            }
            else {
                return YES;
            }
        }
    }
}

- (void)wrappedAppDidBecomeActive
{
  [NSApp setSuppressActivation:YES];
  [menu show];
  NSLog(@"ACTIVATE");
}

- (void)wrappedAppDidResignActive
{
  NSLog(@"RESIGN");
  [NSApp deactivate];
  [NSApp setSuppressActivation:NO];
}

- (void) reactivateApplication
{
    NSLog(@"Reactivate");
    NSTimeInterval td = ([[NSDate date] timeIntervalSinceReferenceDate] - lastActionTime);
    if (td < 1.0) return;

    RunScriptAction *activateAction = (RunScriptAction*)[self actionForMessage: @"Activate"];
    [activateAction executeWithFiles: nil];
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
    appIsTerminating = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reactivateApplication) object:nil];
    if ( mainAction ) {
        [[mainAction task] interrupt];

        NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
        [[NSRunLoop currentRunLoop] runUntilDate: limit];
    }
    return YES;
}

- (BOOL) supportsReturnType:(NSString *)rtype forSendType:(NSString *)stype
{
    NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
    NSArray* services = [info valueForKey:@"NSServices"];
    for (NSDictionary* it in services) {
      NSArray* rtypes = [it valueForKey:@"NSReturnTypes"];
      NSArray* stypes = [it valueForKey:@"NSSendTypes"];

      if ([rtypes containsObject:rtype] && [stypes containsObject:stype]) {
        return YES;
      }
    }
    return NO;
} 

- (void) executeFilter: (NSPasteboard *)pboard
              userData: (NSString *)userData
                 error: (NSString **)error
{
    NSString *outDataType = userData;
    NSLog(@"FILTER >>> %@", userData);

    @try {
        RunScriptAction *serviceAction = (RunScriptAction*)[self actionForMessage: @"Filter"];

        if ( !serviceAction ) {
            NSLog(@"no action for Filter");
            return;
        }

        if ( !outDataType ) {
            NSLog(@"no output type for Filter");
            return;
        }
        
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSString *ext = @"";
        NSInteger found = 0;

        if ( ![files count] ) {
            for (int i = 0; i < [[pboard types] count]; i++) {
                NSString* it = [[pboard types] objectAtIndex: i];
                if ([it hasPrefix:@"NSTypedFileContentsPboardType:"]) {
                    ext = [it substringFromIndex:30];
                    if ([self supportsReturnType:outDataType forSendType:it]) {
                      found = 1;
                      break;
                    }
                }
                else if ([it hasPrefix:@"NSFilenamesPboardType:"]) {
                    ext = [it substringFromIndex:22];
                    if ([self supportsReturnType:outDataType forSendType:it]) {
                      found = 2;
                      NSData *fdata = [pboard dataForType:it];
                      NSString *path = [[NSString alloc]initWithData:fdata encoding:NSUTF8StringEncoding];

                      if (path) {
                        files = [NSArray arrayWithObject:path];
                        [path release];
                      }
                      else {
                        found = 0;
                      }

                      break;
                    }
                }
            }

            if ( found == 0 ) {
                *error = @"no filter available for datatype";
                NSLog(@"no filter script for type %@ found", outDataType);
                return;
            }
            else if (found == 1) {
              NSString *tmpf = [NSString stringWithFormat:@"%@/filter.%lx.%@", NSTemporaryDirectory(), [self hash], ext];
              NSLog(@"creating temp file for %@ in %@", ext, tmpf);
              [pboard readFileContentsType:ext toFile:tmpf];
              files = [NSArray arrayWithObject:tmpf];
            }
        }

        if ( ![files count] ) {
            NSLog(@"no input %@", [pboard types]);
            *error = @"no input files specified";
            return;
        }

        NSDictionary *myenv = [[NSProcessInfo processInfo] environment];
        NSMutableDictionary *env = [NSMutableDictionary dictionaryWithDictionary: myenv];
        [env setObject:outDataType forKey:@"GSFILTER_RETURN_TYPE"];
        [env setObject:ext forKey:@"GSFILTER_SEND_FILE_EXT"];

        NSLog(@"input files %@", files);

        NSTask *task = [serviceAction createTaskWithFiles: files];
        if ( !task ) {
            *error = @"filter error";
            NSLog(@"exit with error");
            return;
        }
        else {
            NSPipe *outPipe = [NSPipe pipe];

            [task setStandardOutput:outPipe];
            [task setEnvironment:shellEnv];
            [task launch];

            NSFileHandle *inFh = [outPipe fileHandleForReading];
            NSData *outData = [inFh readDataToEndOfFile];
            [inFh closeFile];

            if ([task terminationStatus] == 0 && [outData length] > 0) {
                if ([outDataType isEqualToString:@"NSStringPboardType"]) {
                    NSLog(@"provide data as string");
                    NSString *str = [[NSString alloc] initWithData: outData encoding:NSUTF8StringEncoding];
                    [pboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: nil];
                    [pboard setString: str forType: NSStringPboardType];
                }
                else if ([outDataType length] > 0) {
                    NSLog(@"provide data as %@", outDataType);
                    [pboard declareTypes: [NSArray arrayWithObject: outDataType] owner: nil];
                    [pboard setData: outData forType: outDataType];
                }
                NSLog(@"filter done");
            }
            else {
                *error = @"filter did not provide any data";
                NSLog(@"exit with error %d", [task terminationStatus]);
                return;
            }
        }
    }
    @catch (NSException* ex) {
        *error = @"filter exception";
        NSLog(@"FILTER exception %@", ex);
        return;
    }
}


- (void) executeService: (NSPasteboard *)pboard
               userData: (NSString *)userData
                  error: (NSString **)error
{
    
    NSString *inDataType  = [[properties objectForKey: userData] objectForKey: @"SendType"];
    NSString *outDataType = [[properties objectForKey: userData] objectForKey: @"ReturnType"];

    NSLog(@"SERVICE >>> %@ %@ %@", userData, inDataType, outDataType);

    RunScriptAction *serviceAction = (RunScriptAction*)[self actionForMessage: userData];

    if ( !serviceAction ) {
        NSLog(@"no action for %@", userData);
        return;
    }
    
    NSArray *files = [NSArray array];
    NSData *inData = nil;
    if ([inDataType isEqualToString:@"NSStringPboardType"]) {
        NSLog(@"input string");
        inData = [pboard dataForType: NSStringPboardType];
    }
    else if ([inDataType isEqualToString:@"NSFilenamesPboardType"]) {
        files = [pboard propertyListForType:NSFilenamesPboardType];
        NSLog(@"input files %@", files);
    }

    NSTask *task = [serviceAction createTaskWithFiles: files];
    if ( !task ) {
        NSLog(@"exit with error");
        return;
    }
    else {
        NSPipe *outPipe = [NSPipe pipe];

        [task setStandardOutput:outPipe];

        if (inData) {
            NSPipe *inPipe = [NSPipe pipe];
            [task setStandardInput:inPipe];
            NSFileHandle *outFh = [inPipe fileHandleForWriting];
            [outFh writeData:inData];
            [outFh closeFile];
        }

        [task launch];

        NSFileHandle *inFh = [outPipe fileHandleForReading];
        NSData *outData = [inFh readDataToEndOfFile];
        [inFh closeFile];

        if (outData) {
            if ([outDataType isEqualToString:@"NSStringPboardType"]) {
                NSLog(@"provide data as string");
                NSString *str = [[NSString alloc] initWithData: outData encoding:NSUTF8StringEncoding];
                [pboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: nil];
                [pboard setString: str forType: NSStringPboardType];
            }
            else if ([outDataType length] > 0) {
                NSLog(@"provide data as %@", outDataType);
                [pboard declareTypes: [NSArray arrayWithObject: outDataType] owner: nil];
                [pboard setData: outData forType: outDataType];
            }
        }
        NSLog(@"service done");
    }
}

/*
 * task notification
 */

- (void)unixAppExited: (NSNotification*)not
{
    int status = [[not object] terminationStatus];
    NSLog(@"UNIX application %@ exited with code %d", [[not object] arguments], status);
    if ( status ) {
        NSRunCriticalAlertPanel([NSApp applicationName],
                                [NSString stringWithFormat: @"UNIX appliation exited with exit code %d",
                                          status],
                                @"OK", nil, nil);
    }
    if ( [properties objectForKey: @"Filter"] ) {
        //give the service a chance to be called
        [NSApp performSelector:@selector(terminate:) withObject: self afterDelay:1];
    }
    else {
        [NSApp terminate: self];
    }
}

- (void) performShellUISelector:(SEL) sel withObject:(id) val
{
  if ( shellDelegate ) {
    [shellDelegate performSelector:sel withObject:val];
  }
}

/*
 * initializing actions
 */

- (id<Action>)actionForMessage: (NSString *)msg
{
    NSDictionary *actionProps = [properties objectForKey: msg];
    if ( !actionProps ) {
        actionProps = AUTORELEASE([[NSDictionary alloc] init]);
    }
    NSString *actionName = [actionProps objectForKey: @"Action"];
    if ( ! actionName ) {
        NSLog(@"Warning: No type specified for message %@ - defaulting to RunScript", msg);
        actionName = @"RunScript";
    }
    if ( [actionName isEqualToString: @"RunScript"] ) {
        return [[RunScriptAction alloc] initWithActionName: msg properties: actionProps];
    }
    else if ( [actionName isEqualToString: @"Fail"] ) {
        return [[ErrorDialogAction alloc] initWithActionName: msg properties: actionProps];
    }
    else if ( [actionName isEqualToString: @"Ignore"] ) {
        return [[IgnoreAction alloc] initWithActionName: msg properties: actionProps];
    }
    else {
        NSRunCriticalAlertPanel([NSApp applicationName],
                                [NSString stringWithFormat: @"Unknown action %@ specified for message %@", actionName, msg],
                                @"OK", nil, nil);
        return nil;
    }
}

@end

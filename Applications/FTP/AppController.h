/* -*- mode: objc -*-

   Project: FTP

   Copyright (C) 2005-2016 Riccardo Mottola

   Author: Riccardo Mottola

   Created: 2005-03-30
   
   Application Controller

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
 
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
 
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#define connectionModeKey @"connectionMode" 

#import <AppKit/AppKit.h>
#import "ftpclient.h"
#import "localclient.h"
#import "fileTable.h"

#include <sys/time.h>

@interface AppController : NSObject
{
  IBOutlet NSMenu *mainMenu;

  IBOutlet NSWindow            *mainWin;
  IBOutlet NSTableView         *localView;
  IBOutlet NSTableView         *remoteView;
  IBOutlet NSPopUpButton       *localPath;
  IBOutlet NSPopUpButton       *remotePath;
  IBOutlet NSButton            *buttDownload;
  IBOutlet NSButton            *buttUpload;
  IBOutlet NSTextField         *infoMessage;
  IBOutlet NSTextField         *infoSpeed;
  IBOutlet NSTextField         *infoSize;
  IBOutlet NSProgressIndicator *progBar;
    
  IBOutlet NSWindow     *logWin;
  IBOutlet NSTextView   *logTextField;
    
  IBOutlet NSPanel      *connectPanel;
  IBOutlet NSBox        *connServerBox;
  IBOutlet NSBox        *connAccountBox;
  IBOutlet NSTextField  *connAddress;
  IBOutlet NSTextField  *connPort;
  IBOutlet NSTextField  *connUser;
  IBOutlet NSTextField  *connPass;
  IBOutlet NSButton     *connAnon;
  IBOutlet NSButton     *connCancelButt;
  IBOutlet NSButton     *connConnectButt;

  IBOutlet NSPanel     *prefPanel;
  IBOutlet NSMatrix    *portType;
  IBOutlet NSButton    *prefCancelButt;
  IBOutlet NSButton    *prefSaveButt;
    
  NSMutableDictionary  *textAttributes;
    
  FileTable   *localTableData;
  FileTable   *remoteTableData;
  FtpClient   *ftp;
  LocalClient *local;

  NSMutableArray *filesInProcess;
  @private connectionModes    connMode;
  @private NSTimeInterval     beginTimeVal;
  @private unsigned long long transferSize;
  @private BOOL               threadRunning;

  @private NSConnection   *doConnection;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotif;
- (NSApplicationTerminateReply)applicationShouldTerminate:(id)sender;
- (void)applicationWillTerminate:(NSNotification *)aNotif;
- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName;

- (void)readDirWith:(Client *)client toTable:(FileTable *)t andView:(NSTableView*)tv;
- (void)updatePath :(NSPopUpButton *)path :(NSArray *)pathArray;

- (IBAction)changePathFromMenu:(id)sender;
- (IBAction)listDoubleClick:(id)sender;
- (BOOL)dropValidate:(id)sender paths:(NSArray *)paths;
- (void)dropAction:(id)sender paths:(NSArray *)paths;
- (IBAction)downloadButton:(id)sender;
- (IBAction)uploadButton:(id)sender;
- (IBAction)localDelete:(id)sender;
- (IBAction)remoteDelete:(id)sender;
- (IBAction)localRename:(id)sender;
- (IBAction)remoteRename:(id)sender;
- (IBAction)localNewFolder:(id)sender;
- (IBAction)remoteNewFolder:(id)sender;
- (IBAction)localRefresh:(id)sender;
- (IBAction)remoteRefresh:(id)sender;

- (void)setThreadRunningState:(BOOL)flag;

- (oneway void)setTransferBegin:(in bycopy NSString *)name :(unsigned long long)size;
- (oneway void)setTransferProgress:(in bycopy NSNumber *)bytesTransferred;
- (oneway void)setTransferEnd:(in bycopy NSNumber *)bytesTransferred;

/** closes the open connections and quits the session with the remote server */
- (IBAction)disconnect:(id)sender;

- (IBAction)showPrefPanel:(id)sender;
- (IBAction)prefSave:(id)sender;
- (IBAction)prefCancel:(id)sender;

- (IBAction)showFtpLog:(id)sender;

/** Called by the server object to register itself */
- (void)setServer:(id)anObject;
- (oneway void)appendTextToLog:(NSString *)textChunk;

- (IBAction)showConnPanel:(id)sender;
- (IBAction)connectConn:(id)sender;
- (IBAction)cancelConn:(id)sender;
- (IBAction)anonymousConn:(id)sender;

- (void)showAlertDialog:(NSString*)message;

/* accessor */
- (connectionModes)connectionMode;

/* internal methods */
- (void)performRetrieveFile;
- (void)performStoreFile;

- (void)retrieveFiles;
- (oneway void)fileRetrieved:(BOOL)success;
- (void)storeFiles;
- (oneway void)fileStored:(BOOL)success;

@end

@interface fileTransmitParms : NSObject
{
    @public FileElement *file;
    @public LocalClient *localClient;
    @public int         depth;
}
@end

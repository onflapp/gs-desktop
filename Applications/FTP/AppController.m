/* 
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

#import "AppController.h"
#import "fileElement.h"
#import "GetNameController.h"

@implementation fileTransmitParms
@end

@implementation AppController



- (id)init
{
  NSFont *font;
    
  if ((self = [super init]))
    {
      connMode = defaultMode;
        
      threadRunning = NO;

      font = [NSFont userFixedPitchFontOfSize: 0];
      textAttributes = [NSMutableDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
      [textAttributes retain];        
    }
  return self;
}

- (void)dealloc
{
  [doConnection invalidate];

  [doConnection release];
  [textAttributes release];
  [super dealloc];
}

- (void)awakeFromNib
{
  NSMenu *menu;
  NSMenuItem *mi;
  
  /* connection panel */
  [connServerBox setTitle:NSLocalizedString(@"Server Address and Port", @"Server Address and Port")];
  [connAccountBox setTitle:NSLocalizedString(@"Account", @"Account")];
  [connectPanel setTitle:NSLocalizedString(@"Connect", @"Connect")];
  [connAnon setTitle:NSLocalizedString(@"Anonymous", @"Anonymous connection")];
  [connCancelButt setTitle:NSLocalizedString(@"Cancel", @"Cancel")];
  [connConnectButt setTitle:NSLocalizedString(@"Connect (action)", @"Connect (action)")];
  
  /* main window */
  [[localPath itemAtIndex:0] setTitle:NSLocalizedString(@"local view", @"local view")];
  [[remotePath itemAtIndex:0] setTitle:NSLocalizedString(@"remote view", @"remote view")];
  [[[localView tableColumnWithIdentifier:@"filename"] headerCell] setStringValue:NSLocalizedString(@"Name", @"filename table")];
  [[[remoteView tableColumnWithIdentifier:@"filename"] headerCell] setStringValue:NSLocalizedString(@"Name", @"filename table")];
  
  /* menus */
  mi = [mainMenu itemWithTitle:@"Local"];
  menu = [mi submenu];
  [menu setTitle:NSLocalizedString(@"Local", @"Local")];
  mi = [menu itemWithTag:1];
  [mi setTitle:NSLocalizedString(@"Rename...", @"Rename...")];
  mi = [menu itemWithTag:2];
  [mi setTitle:NSLocalizedString(@"New Folder...", @"New Folder....")];
  mi = [menu itemWithTag:3];
  [mi setTitle:NSLocalizedString(@"Delete", @"Delete")];
  mi = [menu itemWithTag:4];
  [mi setTitle:NSLocalizedString(@"Refresh", @"Refresh")];

  mi = [mainMenu itemWithTitle:@"Remote"];
  menu = [mi submenu];
  [menu setTitle:NSLocalizedString(@"Remote", @"Remote")];
  mi = [menu itemWithTag:1];
  [mi setTitle:NSLocalizedString(@"Rename...", @"Rename...")];
  mi = [menu itemWithTag:2];
  [mi setTitle:NSLocalizedString(@"New Folder...", @"New Folder....")];
  mi = [menu itemWithTag:3];
  [mi setTitle:NSLocalizedString(@"Delete", @"Delete")];
  mi = [menu itemWithTag:4];
  [mi setTitle:NSLocalizedString(@"Refresh", @"Refresh")];

  /* log */
  [logWin setTitle:NSLocalizedString(@"Connection Log", @"Connection Log")];

  [logTextField setSelectable:YES];
  [logTextField setEditable:NO];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotif
{
    NSArray        *dirList;
    NSUserDefaults *defaults;
    NSString       *readValue;
    NSPort         *port1;
    NSPort         *port2;
    NSArray        *portArray;
	
    /* read the user preferences */
    defaults = [NSUserDefaults standardUserDefaults];
    readValue = [defaults stringForKey:connectionModeKey];

    /* if no value was set for the key we set passive as mode */
    if ([readValue isEqualToString:@"default"])
        connMode = defaultMode;
    else if ([readValue isEqualToString:@"port"] )
        connMode = portMode;
    else if ([readValue isEqualToString:@"passive"] || readValue == nil)
        connMode = passiveMode;
    else
        NSLog(@"Unrecognized value in user preferences for %@: %@", connectionModeKey, readValue);
    
    /* set double actions for tables */
    [localView setTarget:self];
    [localView setDoubleAction:@selector(listDoubleClick:)];
    [remoteView setTarget:self];
    [remoteView setDoubleAction:@selector(listDoubleClick:)];
    
    /* initialize drag-n-drop code */
    [localView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [remoteView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];

    /* startup code */
    local = [[LocalClient alloc] init];
    [local setWorkingDir:[local homeDir]];
    dirList = [local dirContents];
    [progBar setDoubleValue:0.0];  // reset the progress bar
    
    /* we create a data source and set the tableviews */
    localTableData = [[FileTable alloc] init];
    [localTableData initData:dirList];
    [localTableData sortByIdent: @"filename"];
    [localView setDataSource:localTableData];
    
    remoteTableData = [[FileTable alloc] init];
    [remoteTableData sortByIdent: @"filename"];
    [remoteView setDataSource:remoteTableData];

    /* we update the path menu */
    [self updatePath :localPath :[local workDirSplit]];
    // #### and a release of this array ?!?
	
    // we set up distributed objects
    port1 = [NSPort port];
    port2 = [NSPort port];
    doConnection = [[NSConnection alloc] initWithReceivePort:port1
						     sendPort:port2];
    [doConnection setRootObject:self];
	
    /* Ports switched here. */
    portArray = [NSArray arrayWithObjects:port2, port1, nil];
    [NSThread detachNewThreadSelector: @selector(connectWithPorts:)
                             toTarget: [FtpClient class] 
                           withObject: portArray];

    /* show the connection panel */
    [connectPanel makeKeyAndOrderFront:self];
    return;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(id)sender
{
  return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotif
{
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName
{
    return NO;
}

/** update the pop-up menu with a new path */
- (void)updatePath :(NSPopUpButton *)path :(NSArray *)pathArray
{
  [path removeAllItems];
  [path addItemsWithTitles:pathArray];
}

/** reads directory contents and reads refreshes the table */
- (void)readDirWith:(Client *)client toTable:(FileTable *)t andView:(NSTableView*)tv
{
  NSArray    *dirList;

  if ((dirList = [client dirContents]) == nil)
    return;
  [t initData:dirList];
  [tv deselectAll:self];
  [tv reloadData];
}

/** performs the action of the path pull-down menu
   it navigates upwards the tree
   and works for both the local and remote path */
- (IBAction)changePathFromMenu:(id)sender
{
  Client      *theClient;
  NSTableView *theView;
  FileTable   *theTable;
  NSString    *thePath;
  NSArray     *items;
  int         selectedIndex;
  unsigned    i;

  if (sender == localPath)
    {
      theClient = local;
      theView = localView;
      theTable = localTableData;
    }
  else
    {
      theClient = ftp;
      theView = remoteView;
      theTable = remoteTableData;
    }
  thePath = [NSString string];
  selectedIndex = [sender indexOfItem:[sender selectedItem]];
  items = [sender itemTitles];
  for (i = [items count] - 1; i >= selectedIndex; i--)
    thePath = [thePath stringByAppendingPathComponent: [items objectAtIndex:i]];

  [theClient changeWorkingDir:thePath];
  [self readDirWith:theClient toTable:theTable andView:theView];
    
  [self updatePath :sender :[theClient workDirSplit]];
}

/* perform the action of a double click in a table element
   a directory should be opened, a file down or uploaded
   The same method works for local and remote, detecting them */
- (IBAction)listDoubleClick:(id)sender
{
    Client        *theClient;
    NSTableView   *theView;
    FileTable     *theTable;
    int           elementIndex;
    FileElement   *fileEl;
    NSString      *thePath;
    NSPopUpButton *thePathMenu;

    if (threadRunning)
    {
        NSLog(@"thread was still running");
        return;
    }
    
    theView = sender;
    if (theView == localView)
    {
        theClient = local;
        theTable = localTableData;
        thePathMenu = localPath;
    } else
    {
        theClient = ftp;
        theTable = remoteTableData;
        thePathMenu = remotePath;
    }

    elementIndex = [sender selectedRow];
    if (elementIndex < 0)
    {
        NSLog(@"error: double click with nothing selected");
        return;
    }
    fileEl = [theTable elementAtIndex:elementIndex];
    NSLog(@"element: %@ %d", [fileEl name], [fileEl isDir]);
    thePath = [NSString stringWithString:[theClient workingDir]];
    thePath = [thePath stringByAppendingPathComponent: [fileEl name]];
    if ([fileEl isDir])
      {
        [theClient changeWorkingDir:thePath];
        [self readDirWith:theClient toTable:theTable andView:theView];
        [self updatePath :thePathMenu :[theClient workDirSplit]];
      }
    else
      {
        if (theView == localView)
          {
            [self performStoreFile];
          }
        else
          {
            [self performRetrieveFile];
          }
    }
}

- (BOOL)dropValidate:(id)sender paths:(NSArray *)paths
{
  if (threadRunning)
    {
      NSLog(@"thread was still running");
      return NO;
    }

  if (sender == localTableData)
    {
      /* the local view opens the file or the directory, it can be just one */
      if ([paths count] != 1)
        return NO;
    }

  return YES;
}

- (void)dropAction:(id)sender paths:(NSArray *)paths
{
  NSUInteger i;
  NSFileManager *fm;
  NSMutableArray *arr;

  arr = [[NSMutableArray alloc] initWithCapacity:[paths count]];
  fm = [NSFileManager defaultManager];
  for (i = 0; i < [paths count]; i++)
    {
      NSDictionary *attr;
      NSString *path;
      FileElement *fEl;

      path = [paths objectAtIndex:i];
      attr = [fm fileAttributesAtPath:path traverseLink:YES];
      fEl = [[FileElement alloc] initWithPath:path andAttributes:attr];
      [arr addObject:fEl];
      [fEl release];
    }

  /* locally, we accept only a directory and change to it
     remotely, we store everything */
  if (sender == localTableData)
    {
      NSString      *fileOrPath;
      NSString      *thePath;
      NSFileManager *fm;
      BOOL          isDir;

      fileOrPath = [paths objectAtIndex:0];
      fm = [NSFileManager defaultManager];

      if ([fm fileExistsAtPath:fileOrPath isDirectory:&isDir] == NO)
        {
          [arr release];
          return;
        }

      if (!isDir)
        thePath = [fileOrPath stringByDeletingLastPathComponent];
      else
        thePath = fileOrPath;
      NSLog(@"trimmed path to: %@", thePath);
      [local changeWorkingDir:thePath];
      [self readDirWith:local toTable:localTableData andView:localView];
 
      [self updatePath :localPath :[local workDirSplit]];
    }
  else if (sender == remoteTableData)
    {
      NSLog(@"will upload: %@", arr);
      [self storeFiles];
    }
  [arr release];
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
  if (tableView == localView)
    {
      [localTableData sortByIdent: [tableColumn identifier]];
      [localView reloadData];
    }
  else
    {
      [remoteTableData sortByIdent: [tableColumn identifier]];
      [remoteView reloadData];
    }
}

- (void)setInterfaceEnabled:(BOOL)flag
{
    [localView setEnabled:flag];
    [remoteView setEnabled:flag];
    [localPath setEnabled:flag];
    [remotePath setEnabled:flag];
    [buttUpload setEnabled:flag];
    [buttDownload setEnabled:flag];
}

- (void)setThreadRunningState:(BOOL)flag
{
    threadRunning = flag;
    [self setInterfaceEnabled:!flag];
}

/** retrieves using selection, by constructing an array and calling retrieveFiles */
- (void)performRetrieveFile
{
  NSEnumerator   *elemEnum;
  FileElement    *fileEl;
  id             currEl;

  /* make a copy of the selection */
  [filesInProcess release];
  filesInProcess = [[NSMutableArray alloc] init];
  elemEnum = [remoteView selectedRowEnumerator];

  while ((currEl = [elemEnum nextObject]) != nil)
    {
      fileEl = [remoteTableData elementAtIndex:[currEl intValue]];
      [filesInProcess addObject:fileEl];
    }
    
  [self retrieveFiles];
}

/** stores using selection, by constructing an array and calling storeFiles */
- (void)performStoreFile
{
  NSEnumerator   *elemEnum;
  FileElement    *fileEl;
  id             currEl;
  
  /* make a copy of the selection */
  [filesInProcess release];
  filesInProcess = [[NSMutableArray alloc] init];
  elemEnum = [localView selectedRowEnumerator];
    
  while ((currEl = [elemEnum nextObject]) != nil)
    {
      fileEl = [localTableData elementAtIndex:[currEl intValue]];
      [filesInProcess addObject:fileEl];
    }
  [self storeFiles];
}

/** Retrieves Array of FileElements */
- (void)retrieveFiles
{
  if([filesInProcess count] > 0)
    {
      FileElement *fEl;

      [self setThreadRunningState:YES];
      fEl = [filesInProcess objectAtIndex:0];
      NSLog(@"should download (performRETRIEVE): %@", [fEl name]);
      [ftp retrieveFile:fEl to:local];
    }
}

/* called by the worker thread when the element got processed */
- (oneway void)fileRetrieved:(BOOL)success
{
  FileElement *fEl;

  fEl = [filesInProcess objectAtIndex:0];
  if (success)
    {
      if (![localTableData containsFileName:[fEl name]])
        {
          FileElement *fEl2;
              
          fEl2 = [[FileElement alloc] initWithPath:[[local workingDir] stringByAppendingPathComponent:[fEl name]] andAttributes:[fEl attributes]];
          [localTableData addObject:fEl2];
          [fEl2 release];
        }
    }
  [filesInProcess removeObjectAtIndex:0];
  if ([filesInProcess count] > 0)
    {
      [self retrieveFiles];
    }
  else
    {
      [localView deselectAll:self];
      [localView reloadData];
      [self setThreadRunningState:NO];
      [filesInProcess release];
      filesInProcess = nil;
    }
}

/** Stores Array of FileElements */
- (void)storeFiles
{
  if([filesInProcess count] > 0)
    {
      FileElement *fEl;

      [self setThreadRunningState:YES];
      fEl = [filesInProcess objectAtIndex:0];
      NSLog(@"should download (performStore): %@", [fEl name]);
      [ftp storeFile:fEl from:local];
    }
}

/* called by the worker thread when the element got processed */
- (oneway void)fileStored:(BOOL)success
{
  FileElement *fEl;

  fEl = [filesInProcess objectAtIndex:0];
  if (success)
    {
      if (![remoteTableData containsFileName:[fEl name]])
        {
          FileElement *fEl2;
              
          fEl2 = [[FileElement alloc] initWithPath:[[ftp workingDir] stringByAppendingPathComponent:[fEl name]] andAttributes:[fEl attributes]];
          [remoteTableData addObject:fEl2];
          [fEl2 release];
        }
    }
  [filesInProcess removeObjectAtIndex:0];
  if ([filesInProcess count] > 0)
    {
      [self storeFiles];
    }
  else
    {
      [remoteView deselectAll:self];
      [remoteView reloadData];
      [self setThreadRunningState:NO];
      [filesInProcess release];
      filesInProcess = nil;
    }
}


- (IBAction)downloadButton:(id)sender
{
  if (threadRunning)
    {
      NSLog(@"thread was still running");
      return;
    }
  
  [self performRetrieveFile];
}

- (IBAction)uploadButton:(id)sender
{
  if (threadRunning)
    {
      NSLog(@"thread was still running");
      return;
    }
  
  [self performStoreFile];
}

- (IBAction)localDelete:(id)sender
{
  NSEnumerator   *elemEnum;
  FileElement    *fileEl;
  id             currEl;
  NSMutableArray *selArray;
  NSUInteger     i;
  
  /* make a copy of the selection */
  selArray = [[NSMutableArray alloc] init];
  elemEnum = [localView selectedRowEnumerator];
  while ((currEl = [elemEnum nextObject]) != nil)
    {
      fileEl = [localTableData elementAtIndex:[currEl intValue]];
      [selArray addObject:fileEl];
    }
  
  /* perform deletes */
  for (i = 0; i < [selArray count]; i++)
    {
      fileEl = [selArray objectAtIndex:i];
      if([local deleteFile:fileEl beingAt:0])
	[localTableData removeObject:fileEl];
    }
  [localView deselectAll:self];
  [localView reloadData];
  [selArray release];
}

- (IBAction)remoteDelete:(id)sender
{
  NSEnumerator  *elemEnum;
  FileElement   *fileEl;
  id            currEl;    
  NSMutableArray *selArray;
  NSUInteger     i;
  
  /* make a copy of the selection */
  selArray = [[NSMutableArray alloc] init];
  elemEnum = [remoteView selectedRowEnumerator];
  while ((currEl = [elemEnum nextObject]) != nil)
    {
      fileEl = [remoteTableData elementAtIndex:[currEl intValue]];
      [selArray addObject:fileEl];
    }

  /* perform deletes */
  for (i = 0; i < [selArray count]; i++)
    {
      fileEl = [selArray objectAtIndex:i];
      if ([ftp deleteFile:fileEl beingAt:0])
	[remoteTableData removeObject:fileEl];
    }
  [remoteView deselectAll:self];
  [remoteView reloadData];
  [selArray release]; 
}

- (IBAction)localRename:(id)sender
{
  GetNameController *nameGetter;
  NSInteger         alertReturn;
  NSEnumerator      *elemEnum;
  FileElement       *fileEl;
  id                currEl; 

  elemEnum = [localView selectedRowEnumerator];

  while ((currEl = [elemEnum nextObject]) != nil)
    {
      fileEl = [localTableData elementAtIndex:[currEl intValue]];

      nameGetter = [[GetNameController alloc] init];
      [nameGetter setName:[fileEl name]];
      [nameGetter setTitle:@"Rename"];
      [nameGetter setMessage:@"Rename"];

      alertReturn = [nameGetter runAsModal];
      if (alertReturn == NSAlertDefaultReturn)
        {
          NSString *name;
          
          name = [nameGetter name];
          NSLog(@"New name: %@", name);
          [local renameFile:fileEl to:name];
        }
      [nameGetter release];
    }
  [localView reloadData];
}

- (IBAction)remoteRename:(id)sender
{
  GetNameController *nameGetter;
  NSInteger         alertReturn;
  NSEnumerator      *elemEnum;
  FileElement       *fileEl;
  id                currEl; 
  
  elemEnum = [remoteView selectedRowEnumerator];
  
  while ((currEl = [elemEnum nextObject]) != nil)
    {
      fileEl = [remoteTableData elementAtIndex:[currEl intValue]];
    
      nameGetter = [[GetNameController alloc] init];
      [nameGetter setName:[fileEl name]];
      [nameGetter setTitle:@"Rename"];
      [nameGetter setMessage:@"Rename"];
    
      alertReturn = [nameGetter runAsModal];
      if (alertReturn == NSAlertDefaultReturn)
	{
	  NSString *name;
      
	  name = [nameGetter name];
	  NSLog(@"New name: %@", name);
	  [ftp renameFile:fileEl to:name];
	}
      [nameGetter release];
    }
  [remoteView reloadData];
}

- (IBAction)localNewFolder:(id)sender
{
  GetNameController *nameGetter;
  NSInteger         alertReturn;
  
  nameGetter = [[GetNameController alloc] init];
  [nameGetter setName:@"New Folder"];
  [nameGetter setTitle:@"New Folder"];
  [nameGetter setMessage:@"New Folder"];
  
  alertReturn = [nameGetter runAsModal];
  if (alertReturn == NSAlertDefaultReturn)
    {
      NSString *name;
      NSString *fullPath;
      
      name = [nameGetter name];
      fullPath = [[local workingDir] stringByAppendingPathComponent:name];
      if ([local createNewDir:fullPath])
        {
          FileElement *fileEl;
          NSDictionary *attrs;

          attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                  NSFileTypeDirectory, NSFileType,
                                NULL];
          fileEl = [[FileElement alloc] initWithPath:fullPath andAttributes:attrs];
          [localTableData addObject:fileEl];
          [fileEl release];
          [localView reloadData];
        }
    }
  [nameGetter release];
}

- (IBAction)remoteNewFolder:(id)sender
{
  GetNameController *nameGetter;
  NSInteger         alertReturn;
  
  nameGetter = [[GetNameController alloc] init];
  [nameGetter setName:@"New Folder"];
  [nameGetter setTitle:@"New Folder"];
  [nameGetter setMessage:@"New Folder"];
  
  alertReturn = [nameGetter runAsModal];
  if (alertReturn == NSAlertDefaultReturn)
    {
      NSString *name;
      NSString *fullPath;
      
      name = [nameGetter name];
      fullPath = [[ftp workingDir] stringByAppendingPathComponent:name];
      if ([ftp createNewDir:fullPath])
        {
          FileElement *fileEl;
          NSDictionary *attrs;

          attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                  NSFileTypeDirectory, NSFileType,
                                NULL];
          fileEl = [[FileElement alloc] initWithPath:fullPath andAttributes:attrs];
          [remoteTableData addObject:fileEl];
          [fileEl release];
          [remoteView reloadData];
        }
    }
  [nameGetter release];
}

- (IBAction)localRefresh:(id)sender
{
  [self readDirWith:local toTable:localTableData andView:localView];
}

- (IBAction)remoteRefresh:(id)sender
{
  [self readDirWith:ftp toTable:remoteTableData andView:remoteView];
}

- (oneway void)setTransferBegin:(in bycopy NSString *)name :(unsigned long long)size
{
    [infoMessage setStringValue:name];
    [progBar setDoubleValue:0];
    beginTimeVal = [NSDate timeIntervalSinceReferenceDate];
    transferSize = size;
    NSLog(@"begin transfer size: %llu", transferSize);
    if (transferSize == 0)
      {
	[progBar setIndeterminate:YES];
	[progBar startAnimation:nil];
      }
    [mainWin displayIfNeeded];
}

- (oneway void)setTransferProgress:(in bycopy NSNumber *)bytesTransferred
{
  NSTimeInterval currTimeVal;
  float    speed;
  NSString *speedStr;
  NSString *sizeStr;
  double   percent;
  unsigned long long bytes;

  bytes = [bytesTransferred unsignedLongLongValue];
  currTimeVal = [NSDate timeIntervalSinceReferenceDate];
  speed = (float)((double)bytes / (double)(currTimeVal - beginTimeVal));

    if (transferSize > 0)
      {
	percent = ((double)bytes / (double)transferSize) * 100;
	[progBar setDoubleValue:percent];
      }

    speedStr = [NSString alloc];
    if (speed < 1024)
        speedStr = [speedStr initWithFormat:@"%3.2fB/s", speed];
    else if (speed < 1024*1024)
        speedStr = [speedStr initWithFormat:@"%3.2fKB/s", speed/1024];
    else
        speedStr = [speedStr initWithFormat:@"%3.2fMB/s", speed/(1024*1024)];
    [infoSpeed setStringValue:speedStr];
    [speedStr release];

    sizeStr = [NSString alloc];

    if (transferSize < 1024 && transferSize != 0) /* except 0, which means unknown */
        sizeStr = [sizeStr initWithFormat:@"%3.2f : %3.2f B", (float)bytes, (float)transferSize];
    else if (transferSize < 1024*1024)
        sizeStr = [sizeStr initWithFormat:@"%3.2f : %3.2f KB", (double)bytes/1024, (double)transferSize/1024];
    else
        sizeStr = [sizeStr initWithFormat:@"%3.2f : %3.2f MB", (double)bytes/(1024*1024), (double)transferSize/(1024*1024)];
    [infoSize setStringValue:sizeStr];
    [sizeStr release];
}

- (oneway void)setTransferEnd:(in bycopy NSNumber *)bytesTransferred
{
  NSTimeInterval currTimeVal;
  NSTimeInterval deltaT;
  float          speed;
  NSString       *speedStr;
  NSString       *sizeStr;
  double         percent;
  unsigned long long bytes;
	
  bytes = [bytesTransferred unsignedLongLongValue];
  currTimeVal = [NSDate timeIntervalSinceReferenceDate];
  deltaT = (currTimeVal - beginTimeVal);
    speed = (float)((double)bytes / deltaT);
    NSLog(@"Elapsed time: %f", (float)deltaT);
    percent = ((double)bytes / (double)transferSize) * 100;
    speedStr = [NSString alloc];
    if (speed < 1024)
        speedStr = [speedStr initWithFormat:@"%3.2fB/s", speed];
    else if (speed < 1024*1024)
        speedStr = [speedStr initWithFormat:@"%3.2fKB/s", speed/1024];
    else
        speedStr = [speedStr initWithFormat:@"%3.2fMB/s", speed/(1024*1024)];
    [infoSpeed setStringValue:speedStr];
    [speedStr release];

    sizeStr = [NSString alloc];
    if (transferSize < 1024)
        sizeStr = [sizeStr initWithFormat:@"%3.2f : %3.2f B", (float)bytes, (float)transferSize];
    else if (transferSize < 1024*1024)
        sizeStr = [sizeStr initWithFormat:@"%3.2f : %3.2f KB", (double)bytes/1024, (double)transferSize/1024];
    else
        sizeStr = [sizeStr initWithFormat:@"%3.2f : %3.2f MB", (double)bytes/(1024*1024), (double)transferSize/(1024*1024)];
    [infoSize setStringValue:sizeStr];
    [sizeStr release];
    
    if ([progBar isIndeterminate])
      {
	[progBar stopAnimation:nil];
	[progBar setIndeterminate:NO];
      }
    [progBar setDoubleValue:percent];
    [mainWin displayIfNeeded];
}

- (IBAction)disconnect:(id)sender
{
  [ftp disconnect];
  [mainWin setTitle:@"FTP"];
  [remotePath removeAllItems];
  [remotePath addItemWithTitle:@"Remote View"];
  [remoteTableData clear];
  [remoteView reloadData];
  [self setThreadRunningState:NO];
}

- (IBAction)showPrefPanel:(id)sender
{
    [prefPanel makeKeyAndOrderFront:self];
    switch (connMode)
    {
        case defaultMode:
            [portType selectCellWithTag:0];
            break;
        case portMode:
            [portType selectCellWithTag:1];
            break;
        case passiveMode:
            [portType selectCellWithTag:2];
            break;
        default:
            NSLog(@"Unexpected mode on pref pane setup.");
    }
}

- (IBAction)prefSave:(id)sender
{
    NSUserDefaults *defaults;

    defaults = [NSUserDefaults standardUserDefaults];
    

    switch ([[portType selectedCell] tag])
    {
        case 0:
            //default
            NSLog(@"default");
            connMode = defaultMode;
            [ftp setPortDefault];
            [defaults setObject:@"default" forKey:connectionModeKey];
            break;
        case 1:
            //port
            NSLog(@"port");
            connMode = portMode;
            [ftp setPortPort];
            [defaults setObject:@"port" forKey:connectionModeKey];
            break;
        case 2:
            // passive
            NSLog(@"passive");
            connMode = passiveMode;
            [ftp setPortPassive];
            [defaults setObject:@"passive" forKey:connectionModeKey];
            break;
        default:
            NSLog(@"unexpected selection");
    }
    [prefPanel performClose:nil];
}

- (IBAction)prefCancel:(id)sender
{
  [prefPanel performClose:nil];
}

- (IBAction)showFtpLog:(id)sender
{
  [logWin makeKeyAndOrderFront:self];
}

/**
 Called by the server object to register itself.
 */
- (void)setServer:(id)anObject
{
  ftp = (FtpClient*)[anObject retain];
}

- (oneway void)appendTextToLog:(NSString *)textChunk
{
  NSAttributedString *attrStr;
    
  attrStr = [[NSAttributedString alloc] initWithString: textChunk
					    attributes: textAttributes];

  /* add the textChunk to the NSTextView's backing store as an attributed string */
  [[logTextField textStorage] appendAttributedString: attrStr];

    
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
  [logTextField scrollRangeToVisible:NSMakeRange([[logTextField string] length], 0)];

  [attrStr autorelease];
}


/* --- connection panel methods --- */
- (IBAction)showConnPanel:(id)sender
{
    [connectPanel makeKeyAndOrderFront:self];
}

- (IBAction)connectConn:(id)sender
{
  NSArray *dirList;
  char tempStr[1024];
  NSString *u;
  NSString *p;
    
  [connectPanel performClose:nil];
  [mainWin makeKeyAndOrderFront:self];

  ftp = [ftp initWithController:self :connMode];
  [[connAddress stringValue] getCString:tempStr];
  if ([ftp connect:[connPort intValue] :tempStr] < 0)
    {
      NSRunAlertPanel(@"Error", @"Connection failed.\nCheck that you typed the host name correctly.", @"Ok", nil, nil);
      NSLog(@"connection failed in connectConn");
      return;
    }
  if ([connAnon state] == NSOnState)
    {
      u = @"anonymous";
      p = @"user@myhost.com";
    }
  else
    {
      u = [connUser stringValue];
      p = [connPass stringValue];
    }
  if ([ftp authenticate:u :p] < 0)
    {
      NSRunAlertPanel(@"Error", @"Authentication failed.\nCheck that your username and password are correct.", @"Ok", nil, nil);
      NSLog(@"authentication failed.");
      return;
    }
  else
    {
      [ftp setWorkingDir:[ftp homeDir]];
      if ((dirList = [ftp dirContents]) == nil)
        return;
      [remoteTableData initData:dirList];
      [remoteView reloadData];
      
      /* update the path menu */
      [self updatePath :remotePath :[ftp workDirSplit]];
      
      /* set the window title */
      [mainWin setTitle:[connAddress stringValue]];
    }
}

- (IBAction)cancelConn:(id)sender
{
  [connectPanel performClose:nil];
}

- (IBAction)anonymousConn:(id)sender
{
  if ([connAnon state] == NSOnState)
    {
      [connUser setEnabled:NO];
      [connPass setEnabled:NO];
    }
  else
    {
      [connUser setEnabled:YES];
      [connPass setEnabled:YES];
    }
}


- (void)showAlertDialog:(NSString *)message
{
  [message retain];
  NSRunAlertPanel(@"Attention", message, @"Ok", nil, nil);
  [message release];
}

- (connectionModes)connectionMode
{
  return connMode;
}

@end

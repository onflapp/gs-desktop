/*
**  CWLocalStore.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (c) 2017-2020 Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola <rm@gnu.org>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <Pantomime/CWLocalStore.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWLocalCacheManager.h>
#import <Pantomime/CWLocalFolder.h>
#import <Pantomime/CWLocalFolder+mbox.h>
#import <Pantomime/CWLocalMessage.h>
#import <Pantomime/NSFileManager+Extensions.h>
#import <Pantomime/NSString+Extensions.h>
#import <Pantomime/CWURLName.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSValue.h>

#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <stdlib.h> // rand()

//
// Private interface
//
@interface CWLocalStore (Private)
- (NSEnumerator *) _rebuildFolderEnumerator;
@end

//
//
//
@implementation CWLocalStore

- (void) dealloc
{
  RELEASE(_path);
  RELEASE(_openFolders);
  RELEASE(_folders);
  
  [super dealloc];
}

//
//
//
- (id) initWithPath: (NSString *) thePath
{
  self = [super init];
  if (self)
    {
      BOOL isDirectory;

      [self setPath: thePath];
  
      _openFolders = [[NSMutableDictionary alloc] init];
      _folders = [[NSMutableArray alloc] init];
      _secure = YES;

      if ([[NSFileManager defaultManager] fileExistsAtPath: thePath  isDirectory: &isDirectory])
	{
	  if (!isDirectory)
	    {
	      AUTORELEASE(self);
	      return nil;
	    }
	}
      else
	{
	  AUTORELEASE(self);
	  return nil;
	}
    }
  return self;
}

//
//
//
- (id) initWithURL: (CWURLName *) theURL
{
  return [self initWithPath: [theURL path]];
}

//
// This method will open automatically Inbox (case-insensitive).
// It may return nil if the opening failed or Inbox wasn't found.
//
- (id) defaultFolder
{
  return [self folderForName: @"Inbox"];
}

//
// This method is used to open the folder theName in the current
// directory of this local store.
//
- (id) folderForName: (NSString *) theName
{
  CWLocalFolder *cachedFolder;

  if (!theName) return nil;

  cachedFolder = [_openFolders objectForKey: theName];
  
  if (!cachedFolder)
    {
      NSEnumerator *anEnumerator;
      NSString *aString;
      
      anEnumerator = [self folderEnumerator];

      while ((aString = [anEnumerator nextObject]))
	{
	  if ([aString compare: theName] == NSOrderedSame)
	    {
	      CWLocalFolder *aFolder;

	      aFolder = [[CWLocalFolder alloc] initWithPath: [NSString stringWithFormat:@"%@/%@", _path, aString]];
	      
	      if (aFolder)
		{
		  [aFolder setStore: self];
		  [aFolder setName: theName];

		  // We now cache it and return it
		  [_openFolders setObject: aFolder  forKey: theName];

		  POST_NOTIFICATION(PantomimeFolderOpenCompleted, self, [NSDictionary dictionaryWithObject: aFolder  forKey: @"Folder"]);
		  PERFORM_SELECTOR_2(self, @selector(folderOpenCompleted:), PantomimeFolderOpenCompleted, aFolder, @"Folder");
                  
                  // tell the cache manager to read all messages
                  if (![aFolder cacheManager])
                    {
                      [aFolder setCacheManager: [[[CWLocalCacheManager alloc] initWithPath: [NSString stringWithFormat: @"%@.%@.cache", [[aFolder path] substringToIndex: ([[aFolder path] length] - [[[aFolder path] lastPathComponent] length])], [[aFolder path] lastPathComponent]]  folder: aFolder] autorelease]];
                      [(CWLocalCacheManager *)[aFolder cacheManager] readAllMessages];
                      [aFolder parse: NO];
                    }
		  RELEASE(aFolder);
		}
	      else
		{
		  POST_NOTIFICATION(PantomimeFolderOpenFailed, self, [NSDictionary dictionaryWithObject: theName  forKey: @"FolderName"]);
		  PERFORM_SELECTOR_2(self, @selector(folderOpenFailed:), PantomimeFolderOpenFailed, theName, @"FolderName");
		}

	      return aFolder;
	    }
	}
      
      return nil;
    }

  //NSLog(@"Returning cached folder!");
  return cachedFolder;
}

//
//
//
- (id) folderForURL: (NSString *) theURL;
{
  CWURLName *theURLName;
  id aFolder;

  theURLName = [[CWURLName alloc] initWithString: theURL];

  aFolder = [self folderForName: [theURLName foldername]];

  RELEASE(theURLName);
  
  return aFolder;
}

//
// This method returns the list of folders contained in 
// a specific directory. It'll currently ignore some things
// like Netscape Mail's summary files and Pantomime's local
// cache files.
//
- (NSEnumerator *) folderEnumerator
{
  if ([_folders count] > 0)
    {
      POST_NOTIFICATION(PantomimeFolderListCompleted, self, [NSDictionary dictionaryWithObject: [_folders objectEnumerator] forKey: @"NSEnumerator"]);
      PERFORM_SELECTOR_2(self, @selector(folderListCompleted:), PantomimeFolderListCompleted, [_folders objectEnumerator], @"NSEnumerator");
      return [_folders objectEnumerator];
    }

  return [self _rebuildFolderEnumerator];
}


//
//
//
- (NSEnumerator *) subscribedFolderEnumerator
{
  return [self folderEnumerator];
}


//
//
//
- (id) delegate
{
  return _delegate;
}

- (void) setDelegate: (id) theDelegate
{
  _delegate = theDelegate;
}

//
//
//
- (NSString *) path
{
  return _path;
}

//
//
//
- (void) setPath: (NSString *) thePath
{
  ASSIGN(_path, thePath);
}

//
//
//
- (void) setEnforceMode: (BOOL) theBOOL;
{
  _secure = theBOOL;
}

//
//
//
- (BOOL) isEnforcingMode
{
  return _secure;
}

//
//
//
- (void) close
{
  NSEnumerator *anEnumerator;
  CWLocalFolder *aFolder;

  anEnumerator = [self openFoldersEnumerator];
  
  while ((aFolder = [anEnumerator nextObject]))
    {
      [aFolder close];
    }
}


//
//
//
- (NSEnumerator *) openFoldersEnumerator
{
  return [_openFolders objectEnumerator];
}


//
//
//
- (void) removeFolderFromOpenFolders: (CWFolder *) theFolder
{
  [_openFolders removeObjectForKey: [(CWLocalFolder *)theFolder name]];
}


//
//
//
- (BOOL) folderForNameIsOpen: (NSString *) theName
{
  NSEnumerator *anEnumerator;
  CWLocalFolder *aFolder;
  
  anEnumerator = [self openFoldersEnumerator];

  while ((aFolder = [anEnumerator nextObject]))
    {
      if ([[aFolder name] compare: theName] == NSOrderedSame)
	{
	  return YES;
	}
    }

  return NO;
}


//
//
//
- (PantomimeFolderType) folderTypeForFolderName: (NSString *) theName
{
  NSString *aString;
  BOOL isDir;

  aString = [NSString stringWithFormat: @"%@/%@", _path, theName];
  
  [[NSFileManager defaultManager] fileExistsAtPath: aString
				  isDirectory: &isDir];
  
  if (isDir)
    {
      // This could be a maildir store. Check for maildir specific subfolders.
      aString = [NSString stringWithFormat: @"%@/%@/cur", _path, theName];
      
      if ( [[NSFileManager defaultManager] fileExistsAtPath: aString
					   isDirectory: &isDir] && isDir )
	{
	  return PantomimeHoldsMessages;
	}
      else
	{
	  return PantomimeHoldsFolders;
	}
    }

  return PantomimeHoldsMessages;
}


//
//
//
- (unichar) folderSeparator
{
  return '/';
}


//
//
//
- (void) createFolderWithName: (NSString *) theName 
			 type: (PantomimeFolderFormat) theType
		     contents: (NSData *) theContents
{
  NSString *aName, *pathToFile;
  NSFileManager *aFileManager;
  NSEnumerator *anEnumerator;
  BOOL b, is_dir;
  NSUInteger count;

  aFileManager = [NSFileManager defaultManager];
  anEnumerator = [self folderEnumerator];
  count = 0;

  pathToFile = [NSString stringWithFormat: @"%@/%@", _path, theName];
  pathToFile = [pathToFile substringToIndex: ([pathToFile length]-[[pathToFile lastPathComponent] length]-1)];
 

  // We verify if the folder with that name does already exist
  while ((aName = [anEnumerator nextObject]))
    {
      if ([aName compare: theName  options: NSCaseInsensitiveSearch] == NSOrderedSame)
	{
	  POST_NOTIFICATION(PantomimeFolderCreateFailed, self, [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]);
	  PERFORM_SELECTOR_2(self, @selector(folderCreateFailed:), PantomimeFolderCreateFailed, theName, @"Name");
	  return;
	}
    }
  
  // Ok, the folder doesn't already exist.
  // Check if we want to create a simple folder/directory.
  if (theType == PantomimeFormatFolder)
    {
      NSString *aString;

      aString = [NSString stringWithFormat: @"%@/%@", _path, theName];
      b = [aFileManager createDirectoryAtPath: aString  attributes: nil];
      
      if (b)
	{
	  NSDictionary *info;
	  
	  if (_secure) [[NSFileManager defaultManager] enforceMode: 0700  atPath: aString];
	  [self _rebuildFolderEnumerator];

	  info = [NSDictionary dictionaryWithObjectsAndKeys: theName, @"Name", [NSNumber numberWithUnsignedInt: 0], @"Count", nil];
	  POST_NOTIFICATION(PantomimeFolderCreateCompleted, self, info);
	  PERFORM_SELECTOR_3(self, @selector(folderCreateCompleted:), PantomimeFolderCreateCompleted, info);
	}
      else
	{
	  POST_NOTIFICATION(PantomimeFolderCreateFailed, self, [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]);
	  PERFORM_SELECTOR_2(self, @selector(folderCreateFailed:), PantomimeFolderCreateFailed, theName, @"Name");
	}
      
      return;
    }
  
  b = NO;

  // We want to create a mailbox store; check if it already exists.
  if ([aFileManager fileExistsAtPath: pathToFile  isDirectory: &is_dir])
    {
      int size;
      
      size = [[[aFileManager fileAttributesAtPath: pathToFile traverseLink: NO] objectForKey: NSFileSize] intValue];
      
      // If we got an empty file or simply a directory...
      if (size == 0 || is_dir)
	{
	  NSString *aString;
	  
	  // If the size is 0, that means we have an empty file. We first convert this
	  // file to a directory. We also remove the cache file.
	  if (size == 0)
	    {
	      [aFileManager removeFileAtPath:
			      [NSString stringWithFormat: @"%@/.%@.cache",
					[pathToFile substringToIndex: ([pathToFile length]-[[pathToFile lastPathComponent] length]-1)],
					[pathToFile lastPathComponent]]  handler: nil];
	      [aFileManager removeFileAtPath: pathToFile  handler: nil];
	      [aFileManager createDirectoryAtPath: pathToFile  attributes: nil];
	    }
	  
	  // We can now proceed with the creation of our store.
	  // Check the type of store we want to create
	  switch (theType)
	    {
	    case PantomimeFormatMaildir:
	      // Create the main maildir directory
	      aString = [NSString stringWithFormat: @"%@/%@", _path, theName];  
	      b = [aFileManager createDirectoryAtPath: aString  attributes: nil];
	      if (_secure) [[NSFileManager defaultManager] enforceMode: 0700  atPath: aString];
								    
	      // Now create the cur, new, and tmp sub-directories.
	      aString = [NSString stringWithFormat: @"%@/%@/cur", _path, theName];
	      b = b & [aFileManager createDirectoryAtPath: aString  attributes: nil];
	      if (_secure) [[NSFileManager defaultManager] enforceMode: 0700  atPath: aString];
	      
	      // new
	      aString = [NSString stringWithFormat: @"%@/%@/new", _path, theName];
	      b = b & [aFileManager createDirectoryAtPath: aString  attributes: nil];
	      if (_secure) [[NSFileManager defaultManager] enforceMode: 0700  atPath: aString];

	      // tmp
	      aString = [NSString stringWithFormat: @"%@/%@/tmp", _path, theName];
	      b = b & [aFileManager createDirectoryAtPath: aString  attributes: nil];
	      if (_secure) [[NSFileManager defaultManager] enforceMode: 0700  atPath: aString];
	      
	      // We create our fist message
	      if (theContents)
		{
		  aString = [NSString stringWithFormat: @"%@/%@/cur/%@:2,",
				_path,
				theName,
				[NSString stringWithFormat: @"%lld.%d%d.%@",
						(long long)time(NULL),
						getpid(),
						rand(),
						[[NSHost currentHost] name]]];
		  [theContents writeToFile: aString  atomically: YES];
		}
	      break;
	      
	    case PantomimeFormatMbox:
	    default:
	      b = [aFileManager createFileAtPath: [NSString stringWithFormat: @"%@/%@", _path, theName]
				contents: theContents
				attributes: nil];
	      
	      count = [CWLocalFolder numberOfMessagesFromData: theContents];
	      
	      // We now enforce the mode (0600) on this new mailbox
	      if (_secure) [[NSFileManager defaultManager] enforceMode: 0600
							   atPath: [NSString stringWithFormat: @"%@/%@", _path, theName]];
	      break;				  
	    }
	  
	  // rebuild the folder list
	  [self _rebuildFolderEnumerator];
	}
      else
	{
	  b = NO;
	}
    }
  
  if (b)
    {
      NSDictionary *info;

      info = [NSDictionary dictionaryWithObjectsAndKeys: theName, @"Name", [NSNumber numberWithUnsignedInt: (unsigned int)count], @"Count", nil];
      POST_NOTIFICATION(PantomimeFolderCreateCompleted, self, info);
      PERFORM_SELECTOR_3(self, @selector(folderCreateCompleted:), PantomimeFolderCreateCompleted, info);
    }
  else
    {
      POST_NOTIFICATION(PantomimeFolderCreateFailed, self, [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]);
      PERFORM_SELECTOR_2(self, @selector(folderCreateFailed:), PantomimeFolderCreateFailed, theName, @"Name");
    }
}


//
// theName must be the full path of the mailbox.
//
- (void) deleteFolderWithName: (NSString *) theName
{
  NSFileManager *aFileManager;
  BOOL aBOOL, is_dir;
  
  aFileManager = [NSFileManager defaultManager];
  aBOOL = NO;

  if ([aFileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@", _path, theName]
		    isDirectory: &is_dir])
    {
      if (is_dir)
	{
	  NSEnumerator *theEnumerator;
	  NSArray *theEntries;
	  
	  theEnumerator = [aFileManager enumeratorAtPath: [NSString stringWithFormat: @"%@/%@",
								    _path, theName]];
	  
	  // FIXME - Verify the Store's path.
	  // If it doesn't contain any mailboxes and it's actually not or Store's path, we remove it.
	  theEntries = [theEnumerator allObjects];
	  if ([theEntries count] == 0)
	    {
	      aBOOL = [aFileManager removeFileAtPath: [NSString stringWithFormat: @"%@/%@",
								_path, theName]
				    handler: nil];
	      
	      // Rebuild the folder tree
	      if (aBOOL)
		{
		  [self _rebuildFolderEnumerator];
		  POST_NOTIFICATION(PantomimeFolderDeleteCompleted, self, [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]);
		  PERFORM_SELECTOR_1(self, @selector(folderDeleteCompleted:), PantomimeFolderDeleteCompleted);
		}
	      else
		{
		  POST_NOTIFICATION(PantomimeFolderDeleteFailed, self, [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]);
		  PERFORM_SELECTOR_1(self, @selector(folderDeleteFailed:), PantomimeFolderDeleteFailed);
		}

	      return;
	    }
	  // We could also be trying to delete a maildir mailbox which
	  // has a directory structure with 3 sub-directories: cur, new, tmp
	  else if ([aFileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@/cur", _path, theName]
				 isDirectory: &is_dir])
	    {
	      // Make sure that these are the maildir directories and not something else.
	      if (![aFileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@/new", _path, theName]
				 isDirectory: &is_dir])
		{
		  POST_NOTIFICATION(PantomimeFolderDeleteFailed, self, [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]);
		  PERFORM_SELECTOR_1(self, @selector(folderDeleteFailed:), PantomimeFolderDeleteFailed);
		  return;
		}
	      if (![aFileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@/tmp", _path, theName]
				 isDirectory: &is_dir] )
		{
		  POST_NOTIFICATION(PantomimeFolderDeleteFailed, self, [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]);
		  PERFORM_SELECTOR_1(self, @selector(folderDeleteFailed:), PantomimeFolderDeleteFailed);
		  return;
		}
	    }
	  else
	    {
	      POST_NOTIFICATION(PantomimeFolderDeleteFailed, self, [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]);
	      PERFORM_SELECTOR_1(self, @selector(folderDeleteFailed:), PantomimeFolderDeleteFailed);
	      return;
	    }
	}

      // We remove the mbox or maildir store
      aBOOL = [aFileManager removeFileAtPath: [NSString stringWithFormat: @"%@/%@",
							_path, theName]
			    handler: nil];
      
      // We remove the cache, if the store deletion was successful
      if (aBOOL)
	{
	  NSString *aString;

	  aString = [theName lastPathComponent];
	  
	  [[NSFileManager defaultManager] removeFileAtPath: [NSString stringWithFormat: @"%@/%@.%@.cache",
								      _path,
								      [theName substringToIndex: ([theName length]-[aString length])],
								      aString]
					  handler: nil];
	}

      // Rebuild the folder tree
      [self _rebuildFolderEnumerator];
    }
  
  if (aBOOL)
    {
      POST_NOTIFICATION(PantomimeFolderDeleteCompleted, self, [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]);
      PERFORM_SELECTOR_1(self, @selector(folderDeleteCompleted:), PantomimeFolderDeleteCompleted);
    }
  else
    {
      POST_NOTIFICATION(PantomimeFolderDeleteFailed, self, [NSDictionary dictionaryWithObject: theName  forKey: @"Name"]);
      PERFORM_SELECTOR_1(self, @selector(folderDeleteFailed:), PantomimeFolderDeleteFailed);
    }
}


//
// theName and theNewName MUST be the full path of those mailboxes.
// If they begin with the folder separator (ie., '/'), the character is
// automatically stripped.
//
// This method supports renaming mailboxes that are open.
//
- (void) renameFolderWithName: (NSString *) theName
                       toName: (NSString *) theNewName
{
  NSFileManager *aFileManager;
  NSDictionary *info;
  BOOL aBOOL, is_dir;
  
  aFileManager = [NSFileManager defaultManager];
  aBOOL = NO;
  
  theName = [theName stringByDeletingFirstPathSeparator: [self folderSeparator]];
  theNewName = [theNewName stringByDeletingFirstPathSeparator: [self folderSeparator]]; 
  info = [NSDictionary dictionaryWithObjectsAndKeys: theName, @"Name", theNewName, @"NewName", nil];

  // We do basic verifications on the passed parameters. We also verify if the destination path exists.
  // If it does, we abort the rename operation since we don't want to overwrite the folder.
  if (!theName || !theNewName || 
      [[theName stringByTrimmingWhiteSpaces] length] == 0 ||
      [[theNewName stringByTrimmingWhiteSpaces] length] == 0 ||
      [aFileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@", _path, theNewName]])
    {
      POST_NOTIFICATION(PantomimeFolderRenameFailed, self, info);
      PERFORM_SELECTOR_3(self, @selector(folderRenameFailed:), PantomimeFolderRenameFailed, info);
      return;
    }

  // We verify if the source path is valid
  if ([aFileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@", _path, theName]
		    isDirectory: &is_dir])
    {
      CWLocalFolder *aFolder;

      if (is_dir)
	{
	  NSEnumerator *theEnumerator;
	  NSArray *theEntries;
	  
	  theEnumerator = [aFileManager enumeratorAtPath: [NSString stringWithFormat: @"%@/%@",
								    _path, theName]];
	  
	  // FIXME - Verify the Store's path.
	  // If it doesn't contain any mailboxes and it's actually not or Store's path, we rename it.
	  theEntries = [theEnumerator allObjects];
	  
	  if ([theEntries count] == 0)
	    {
	      aBOOL = [aFileManager movePath: [NSString stringWithFormat: @"%@/%@",_path, theName]
				    toPath: [NSString stringWithFormat: @"%@/%@",  _path, theNewName]
				    handler: nil];
	      if (aBOOL)
		{
		  POST_NOTIFICATION(PantomimeFolderRenameCompleted, self, info);
		  PERFORM_SELECTOR_3(self, @selector(folderRenameCompleted:), PantomimeFolderRenameCompleted, info);
		}
	      else
		{
		  POST_NOTIFICATION(PantomimeFolderRenameFailed, self, info);
		  PERFORM_SELECTOR_3(self, @selector(folderRenameFailed:), PantomimeFolderRenameFailed, info);
		}
	    }
	  // We could also be trying to delete a maildir mailbox which
	  // has a directory structure with 3 sub-directories: cur, new, tmp
	  else if ([aFileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@/cur", _path, theName]
				 isDirectory: &is_dir])
	    {
	      // Make sure that these are the maildir directories and not something else.
	      if (![aFileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@/new", _path, theName]
				 isDirectory: &is_dir])
		{
		  POST_NOTIFICATION(PantomimeFolderRenameFailed, self, info);
		  PERFORM_SELECTOR_3(self, @selector(folderRenameFailed:), PantomimeFolderRenameFailed, info);
		  return;
		}
	      if (![aFileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@/tmp", _path, theName]
				 isDirectory: &is_dir])
		{
		  POST_NOTIFICATION(PantomimeFolderRenameFailed, self, info);
		  PERFORM_SELECTOR_3(self, @selector(folderRenameFailed:), PantomimeFolderRenameFailed, info);
		  return;
		}
	  }
	  else
	    {
	      POST_NOTIFICATION(PantomimeFolderRenameFailed, self, info);
	      PERFORM_SELECTOR_3(self, @selector(folderRenameFailed:), PantomimeFolderRenameFailed, info);
	      return;
	    }
	}
      
      // If the mailbox is open, we "close" it first.
      aFolder = [_openFolders objectForKey: theName];

      if (aFolder)
	{
	  if ([aFolder type] == PantomimeFormatMbox)
	    {
	      [aFolder close_mbox];
	    }
	  [[aFolder cacheManager] synchronize];
	}
      

      // We rename the mailbox
      aBOOL = [aFileManager movePath: [NSString stringWithFormat: @"%@/%@", _path, theName]
			    toPath: [NSString stringWithFormat: @"%@/%@", _path, theNewName]
			    handler: nil];
      
      // We rename the cache, if the store rename was successful
      if (aBOOL)
	{
	  NSString *str1, *str2;
	  
	  str1 = [theName lastPathComponent];
	  str2 = [theNewName lastPathComponent];
	  
	  [[NSFileManager defaultManager] movePath: [NSString stringWithFormat: @"%@/%@.%@.cache",
							      _path,
							      [theName substringToIndex:
									 ([theName length] - [str1 length])],
							      str1]
					  toPath: [NSString stringWithFormat: @"%@/%@.%@.cache",
							    _path,
							    [theNewName substringToIndex:
									  ([theNewName length] - [str2 length])],
							    str2]
					  handler: nil];
	}
      
      // If the folder was open, we must re-open and re-lock the mbox file,
      // recache the folder, adjust some paths and more.
      if (aFolder)
	{
	  // We update its name and path
	  [aFolder setName: theNewName];
	  [aFolder setPath: [NSString stringWithFormat: @"%@/%@", _path, theNewName]];

	  [[aFolder cacheManager] setPath: [NSString stringWithFormat: @"%@/%@.%@.cache",
						     _path,
						     [theNewName substringToIndex: ([theNewName length] - [[theNewName lastPathComponent] length])],
						     [theNewName lastPathComponent]]];
	  // We recache the mailbox with its new name.
	  RETAIN(aFolder);
	  [_openFolders removeObjectForKey: theName];
	  [_openFolders setObject: aFolder  forKey: theNewName];
	  RELEASE(aFolder);

	  // We now open and lock the mbox file. If we use maildir, we must adjust the "mail filename"
	  // of every message in the maildir.
	  if ([aFolder type] == PantomimeFormatMbox)
	    {
	      [aFolder open_mbox];
	    }
	}

      // Rebuild the folder tree
      [self _rebuildFolderEnumerator];
    }
  
  if (aBOOL)
    {
      POST_NOTIFICATION(PantomimeFolderRenameCompleted, self, info);
      PERFORM_SELECTOR_3(self, @selector(folderRenameCompleted:), PantomimeFolderRenameCompleted, info);
    }
  else
    {
      POST_NOTIFICATION(PantomimeFolderRenameFailed, self, info);
      PERFORM_SELECTOR_3(self, @selector(folderRenameFailed:), PantomimeFolderRenameFailed, info);
    }
}

@end


//
// Private interface
//
@implementation CWLocalStore (Private)

- (NSEnumerator *) _rebuildFolderEnumerator
{
  NSString *aString, *lastPathComponent, *pathToFolder;	
  NSEnumerator *tmpEnumerator;
  NSArray *tmpArray;
  NSUInteger i;
  
  // Clear out our cached folder structure and refresh from the file system
  [_folders removeAllObjects];
  [_folders setArray: [[[NSFileManager defaultManager] enumeratorAtPath: _path] allObjects]];
  
  //
  // We iterate through our array. If mbox A and .A.summary (or .A.cache) exists, we
  // remove .A.summary (or .A.cache) from our mutable array.
  // We do this in two runs:
  // First run: remove maildir sub-directory structure so that is appears as a regular folder.
  // Second run: remove other stuff like *.cache, *.summary
  //
  for (i = 0; i < [_folders count]; i++)
    {
      BOOL bIsMailDir;
      
      aString = [_folders objectAtIndex: i];
      
      //
      // First run:
      // If this is a maildir directory, remove its sub-directory structure from the list,
      // so that the maildir store appears just like a regular mail store.
      //
      if ([[NSFileManager defaultManager] fileExistsAtPath:
			[NSString stringWithFormat: @"%@/%@/cur", _path, aString] 
					  isDirectory: &bIsMailDir] && bIsMailDir)
	{
	  NSArray *subpaths;
	
	  // Wust ensure 700 mode un cur/new/tmp folders and 600 on all files (ie., messages)
	  if (_secure) 
	    {
	      [[NSFileManager defaultManager] enforceMode: 0700
					      atPath: [NSString stringWithFormat: @"%@/%@/cur", _path, aString]];
	      
	      [[NSFileManager defaultManager] enforceMode: 0700
					      atPath: [NSString stringWithFormat: @"%@/%@/new", _path, aString]];
	      
	      [[NSFileManager defaultManager] enforceMode: 0700
					      atPath: [NSString stringWithFormat: @"%@/%@/tmp", _path, aString]];
	    }
	  
	  // Get all the children of this directory an remove them from our mutable array.
	  subpaths = [[NSFileManager defaultManager] subpathsAtPath:
			[NSString stringWithFormat: @"%@/%@", _path, aString]];
	  [_folders removeObjectsInRange: NSMakeRange(i+1,[subpaths count])];
	}
    }
  
  //
  // Second Run: Get rid of cache, summary and OS specific stuff
  //
  tmpArray = [[NSArray alloc] initWithArray: _folders];
  AUTORELEASE(tmpArray);
  tmpEnumerator = [tmpArray objectEnumerator];
  
  while ((aString = [tmpEnumerator nextObject]))
    {
      lastPathComponent = [aString lastPathComponent];
      pathToFolder = [aString substringToIndex: ([aString length] - [lastPathComponent length])];
      
      // We remove Netscape/Mozilla summary file.
      [_folders removeObject: [NSString stringWithFormat: @"%@.%@.summary", pathToFolder, lastPathComponent]];
      
      // We remove Pantomime's cache file. Before doing so, we ensure it's 600 mode.
      [_folders removeObject: [NSString stringWithFormat: @"%@.%@.cache", pathToFolder, lastPathComponent]];
  
      if (_secure) [[NSFileManager defaultManager] enforceMode: 0600
						   atPath: [NSString stringWithFormat: @"%@/%@.%@.cache", _path, pathToFolder, lastPathComponent]];
      
      // We also remove Apple Mac OS X .DS_Store directory
      [_folders removeObject: [NSString stringWithFormat: @"%@.DS_Store", pathToFolder]];
    }
  
  return [_folders objectEnumerator];
}

@end

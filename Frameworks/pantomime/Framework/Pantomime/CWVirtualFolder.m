/*
**  CWVirtualFolder.m
**
**  Copyright (c) 2003-2004 Ludovic Marcotte
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
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

#import <Pantomime/CWVirtualFolder.h>

#import <Pantomime/CWConstants.h>

//
//
//
@implementation CWVirtualFolder

- (id) initWithName: (NSString *) theName
{
  self = [super initWithName: theName];
  if (self)
    {
      _allFolders = [[NSMutableArray alloc] init];
    }
  return self;
}


//
//
//
- (void) dealloc
{
  RELEASE(_allFolders);
  [super dealloc];
}


//
// New, VitualFolder specific methods.
//
- (void) addFolder: (CWFolder *) theFolder
{
  NSMutableArray *aMutableArray;

  if (!theFolder) return;

  [_allFolders addObject: theFolder];

  aMutableArray = [[NSMutableArray alloc] initWithArray: self->allMessages];
  [aMutableArray addObjectsFromArray: theFolder->allMessages];
  [super setMessages: aMutableArray];
  RELEASE(aMutableArray);
}

- (void) removeFolder: (CWFolder *) theFolder
{
  if (!theFolder) return;

  [_allFolders removeObject: theFolder];
}


//
// Re-implementations of some methods
//
- (void) close
{
  [_allFolders makeObjectsPerformSelector: @selector(close)];
  [_allFolders removeAllObjects];
}


//
// When doing an expunge on a virtual folder, we must re-initialize
// the allMessages ivar since it's holding messages potentially removed
// from the real Folder objects.
//
#warning FIXME
- (void) expunge: (BOOL) returnDeletedMessages
{
#if 0
  NSMutableArray *aMutableArray;
  int i;

  aMutableArray = [[NSMutableArray alloc] init];
  [self->allMessages removeAllObjects];

  for (i = 0; i < [_allFolders count]; i++)
    {
      // We first expunge all messages
      [aMutableArray addObjectsFromArray: [[_allFolders objectAtIndex: i] expunge: returnDeletedMessages]];

      // We add back our messages...
      [self->allMessages addObjectsFromArray: ((Folder *)[_allFolders objectAtIndex: i])->allMessages];
    }

  [self updateCache];

  return AUTORELEASE(aMutableArray);
#endif
}


//
// When we search in a virtual folder, we search in all folders and
// we concatenate all the search results.
//
- (void) search: (NSString *) theString
	   mask: (PantomimeSearchMask) theMask
	options: (PantomimeSearchOption) theOptions
{
#warning FIXME
#if 0
  NSMutableArray *aMutableArray;
  int i;

  aMutableArray = [[NSMutableArray alloc] init];

  for (i = 0; i < [_allFolders count]; i++)
    {
      [aMutableArray addObjectsFromArray: [[_allFolders objectAtIndex: i] search: theString
									  mask: theMask
									  options: theOptions]];
    }

  AUTORELEASE(aMutableArray);
#endif
}


- (void) setDelegate: (id) theDelegate
{
  // Go through all IMAP folder and set it.
}

@end 

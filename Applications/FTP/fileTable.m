/*
 Project: FTP

 Copyright (C) 2005-2016 Riccardo Mottola

 Author: Riccardo Mottola

 Created: 2005-04-12

 Table class for file listing

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

#import "fileTable.h"
#import "fileElement.h"
#import "AppController.h"

/* The sortedArray is just an array of pointers to the original unsorted file elements */
NSComparisonResult compareFileStructs(id e1, id e2, void *context)
{

  NSString *s1;
  NSString *s2;
  NSComparisonResult r;
  enum sortOrderDef sortOrder;

  s1 = [(FileElement *)e1 name];
  s2 = [(FileElement *)e2 name];
  sortOrder = *(enum sortOrderDef *)context;

  r = [s1 compare: s2];
  if (sortOrder == descending)
    {
      if (r == NSOrderedAscending)
	r = NSOrderedDescending;
      else if (r == NSOrderedDescending)
	r = NSOrderedAscending;
    }
  return r;
}

@implementation FileTable

- (void)initData:(NSArray *)fnames
{
  sortByIdent = nil;
  
  if (fileStructs)
    {
      [fileStructs release];
      [sortedArray release];
    }
  fileStructs = [[NSMutableArray arrayWithArray:fnames] retain];
  sortedArray = [[NSMutableArray arrayWithCapacity: [fileStructs count]] retain];
  [self generateSortedArray];

  sortOrder = undefined;
}

- (void)dealloc
{
  [fileStructs release];
  [sortedArray release];
  [super dealloc];
}

- (void)clear
{
  [fileStructs release];
  fileStructs = nil;
  [sortedArray release];
  sortedArray = nil;
}

- (void)generateSortedArray
{
  NSUInteger i;

  [sortedArray removeAllObjects];
  for (i = 0; i < [fileStructs count]; i++)
    {
      FileElement *fe;

      fe = [fileStructs objectAtIndex: i];
      [sortedArray addObject: fe];
    }
}


- (void)addObject:(FileElement *)object
{
  /* add the file element to the storage */
  [fileStructs addObject:object];

  /* keep the sorting map array in sync */
  [sortedArray addObject:object];
  if (sortOrder != undefined)
    {
      [sortedArray sortUsingFunction:compareFileStructs context:&sortOrder];
    }
}


- (void)removeObject:(FileElement *)object
{
  NSUInteger index;

  index = [fileStructs indexOfObject:object];
  if (index == NSNotFound)
    {
      NSLog(@"Object not found, internal error");
      return;
    }

  /* remove object from storage */
  [fileStructs removeObject:object];
  index = [sortedArray indexOfObject:object];
  if (index != NSNotFound)
    [sortedArray removeObjectAtIndex:index];

  if (sortOrder != undefined)
    {
      [sortedArray sortUsingFunction:compareFileStructs context:&sortOrder];
    }
}

/** returns the object after resolving sorting */
- (FileElement *)elementAtIndex:(NSUInteger)index
{
  return [sortedArray objectAtIndex:index];
}

- (void)sortByIdent:(NSString *)idStr
{
  if ([idStr isEqualToString: sortByIdent])
    {
      if (sortOrder == ascending)
	sortOrder = descending;
      else
	sortOrder = ascending;
    }
  else
    {
      NSLog(@"Sort by: %@", idStr);
      sortOrder = ascending;
    }
  sortByIdent = idStr;
  [sortedArray sortUsingFunction:compareFileStructs context:&sortOrder];
}



/* methods implemented to follow the informal NSTableView protocol */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [sortedArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    id theElement;

    theElement = NULL;
    NSParameterAssert(rowIndex >= 0 && rowIndex < [sortedArray count]);
    if ([[aTableColumn identifier] isEqualToString:TAG_FILENAME])
        theElement = [[sortedArray objectAtIndex:rowIndex] name];
    else
        NSLog(@"unknown table column ident");
    return theElement;
}

/* --- drag and drop ---  */
- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
  NSPasteboard *pboard;


  pboard = [info draggingPasteboard];
  if ([[pboard types] containsObject:NSFilenamesPboardType])
    {
      NSArray *paths;

      paths = [pboard propertyListForType:NSFilenamesPboardType];
      if ([paths count] > 0)
        {
          if ([[aTableView target] dropValidate:self paths:paths])
            return NSDragOperationEvery;
        }
    }

  return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
  NSPasteboard *pboard;


  pboard = [info draggingPasteboard];
  if ([[pboard types] containsObject:NSFilenamesPboardType])
    {
      NSArray *paths;

      paths = [pboard propertyListForType:NSFilenamesPboardType];
      if ([paths count] > 0)
        {
          [[aTableView target] dropAction:self paths:paths];
        }
    }
  
  return NO;
}

- (BOOL)containsFileName:(NSString *)name
{
  BOOL found;
  unsigned i;
  
  found = NO;
  i = 0;
  while (!found && i < [fileStructs count])
    {
      FileElement *fe;
  
      fe = [fileStructs objectAtIndex:i];
      found = [[fe name] isEqualToString:name];
      i++;
    }
  return found;
}


@end


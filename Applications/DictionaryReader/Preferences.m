/*
 *  DictionaryReader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <Preferences.h>

#import <Foundation/Foundation.h>

#import <DictConnection.h>
#import <LocalDictionary.h>

@implementation Preferences

// Singleton
+(id)shared {
    static Preferences* sharedPreferences = nil;
    
    if (sharedPreferences == nil) {
        sharedPreferences = [[Preferences alloc] init];
    }
    
    return sharedPreferences;
}


-(void)setDictionaries: (NSMutableArray*) dicts
{
  NSParameterAssert(dicts != nil);
  NSAssert(_dictionaries == nil || _dictionaries == dicts,
           @"You can't set the dictionary handle array twice and to different"
           @" values for the preferences panel.");
  
  int i;
  for (i=0; i<[dicts count]; i++) {
      NSAssert2([[dicts objectAtIndex: i] isKindOfClass: [DictionaryHandle class]],
               @"'%@' is not a Dictionary Handle object but a %@ object!",
               [dicts objectAtIndex: i],
               [dicts class]
      );
  }
  
  ASSIGN(_dictionaries, dicts);
  
  [_tableView reloadData];
}

-(void)rescanDictionaries: (id)sender
{
  NSAssert(_dictionaries != nil,
           @"The preference panel must be given a dictionary handle list!");
  
  [self searchInUsualPlaces];
  
  // default remote dictionary: dict.org
  DictConnection* dict =
     [[DictConnection alloc] init];
  [self foundDictionary: dict];
  [dict release];
  
  NSLog(@"rescanned: %@", _dictionaries);
  
  [_tableView reloadData];
  //[_tableView setNeedsDisplay: YES];
}


-(void)show {
    [_prefPanel orderFront: self];
}

-(void)hide {
    [_prefPanel setReleasedWhenClosed: NO];
    [_prefPanel close];
}
@end



@implementation Preferences (SearchForDictionaries)

-(void) foundDictionary: (id)aDictionary
{
    if (aDictionary != nil && [_dictionaries containsObject: aDictionary] == NO) {
        [aDictionary setDefinitionWriter: [NSApp delegate]];
        [aDictionary setActive: YES];
        [_dictionaries addObject: aDictionary];
    }
}

-(void) searchInUsualPlaces
{
    NSArray* searchPaths = [NSArray arrayWithObjects:@"/usr/share/dict", @"/usr/share/dictd", nil];

    int i;
    for (i=0; i<[searchPaths count]; i++) {
        [self searchInDirectory:
            [searchPaths objectAtIndex: i]];
    }

    searchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);

    for (i=0; i<[searchPaths count]; i++) {
        [self searchInDirectory:
            [[searchPaths objectAtIndex: i] stringByAppendingPathComponent:@"DictionaryReader/Dictionaries"]];
    }
}

-(void) searchInDirectory: (NSString*) dirName;
{
    NSLog(@"search dir %@", dirName);
    NSFileManager* manager = [NSFileManager defaultManager];
    NSArray* files = [manager directoryContentsAtPath: dirName];
    
    if (files == nil)
        return; // directory not present
    
    if ([files count] == 0)
        return; // directory empty
    
    int i;
    for (i=0; i<[files count]; i++) {
        NSString* fileName = [files objectAtIndex: i];
        NSString* pathExtension = [fileName pathExtension];
        NSString* indexFileName;
        
        if ([pathExtension isEqualToString: @"dict"]
#ifdef GNUSTEP
            || [pathExtension isEqualToString: @"dz"]
#endif // GNUSTEP
           ) {
            // Find out the index file name by cutting all path extensions, then adding .index!
            indexFileName = fileName;
            do {
                indexFileName = [indexFileName stringByDeletingPathExtension];
            } while ([[indexFileName pathExtension] isEqualToString: @""] == NO);
            indexFileName = [indexFileName stringByAppendingPathExtension: @"index"];
            
            if ([files containsObject: indexFileName]) {
                indexFileName = [dirName stringByAppendingPathComponent: indexFileName];
                fileName      = [dirName stringByAppendingPathComponent: fileName];
                
                LocalDictionary* dict =
                  [LocalDictionary dictionaryWithIndexAtPath: indexFileName
                                            dictionaryAtPath: fileName];
                [dict setName:[fileName lastPathComponent]];
                
                [self foundDictionary: dict];
            }
        }
    }
}

@end



/**
 * Responding to TableView delegate messages
 */
@implementation Preferences (DictionarySelectionDataSource)

/**
 * Returns the number of rows in the dictionary selection table.
 */
- (int) numberOfRowsInTableView: (NSTableView *)aTableView
{
    return [_dictionaries count];
}

/**
 * This is called when the object value for a table cell changes.
 * This is where the dictionary selection gets changed.
 */
-(void) tableView: (NSTableView*) aTableView
   setObjectValue: (id) anObj
   forTableColumn: (NSTableColumn*) aTableColumn
	      row: (int) rowIndex
{
  if ([[aTableColumn identifier] isEqualToString: @"active"]) {
      [[_dictionaries objectAtIndex: rowIndex] setActive: [anObj intValue]];
      
      [[NSNotificationCenter defaultCenter] postNotificationName: DRActiveDictsChangedNotification
                                                          object: _dictionaries];
  }
  else if ([[aTableColumn identifier] isEqualToString: @"name"]) {
      [(DictionaryHandle*)[_dictionaries objectAtIndex: rowIndex] setName: anObj];
  }
  else if ([[aTableColumn identifier] isEqualToString: @"location"]) {
      [(DictionaryHandle*)[_dictionaries objectAtIndex: rowIndex] setLocation: anObj];
  }
}

/**
 * Returns the value of a table cell.
 */
- (id) tableView: (NSTableView *)aTableView
objectValueForTableColumn: (NSTableColumn *)aTableColumn
             row: (int)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString: @"active"]) {
      return [NSNumber numberWithBool: [[_dictionaries objectAtIndex: rowIndex] isActive]];

    } else if ([[aTableColumn identifier] isEqualToString: @"name"]) {
      return [[_dictionaries objectAtIndex: rowIndex] valueForKey:@"name"];

    } else if ([[aTableColumn identifier] isEqualToString: @"location"]) {
      return [[_dictionaries objectAtIndex: rowIndex] valueForKey:@"location"];

    } else {
      return @"unknown";

    }
}

- (void) removeDictionary:(id) sender
{
  NSInteger row = [_tableView selectedRow];
  if (row != -1 && row < [_dictionaries count]) {
    [_dictionaries removeObjectAtIndex:row];
    [_tableView reloadData];
  }
}

- (void) revealDictionaryLocation:(id) sender
{
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
  NSString* path = [[paths lastObject] stringByAppendingPathComponent:@"DictionaryReader/Dictionaries"];

  [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];

  [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
}

- (void) addDictionary:(id) sender
{
  DictConnection* dict = [[DictConnection alloc] init];
  [dict setName:@"New Dictionary"];
  [self foundDictionary: dict];
  [dict release];
  
  [_tableView reloadData];
}

- (void) awakeFromNib
{
    NSButtonCell* cell = [[_tableView tableColumnWithIdentifier: @"active"] dataCell];
    [cell setEditable: YES];
    [cell setEnabled: YES];
    [cell setSelectable: YES];
    [cell setTitle: @""];
    
    [cell setButtonType: NSSwitchButton];
}

@end


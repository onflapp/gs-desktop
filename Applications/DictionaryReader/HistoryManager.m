/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 3 as
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

#import "HistoryManager.h"



@implementation HistoryManager : NSObject

-(id)init {
  self = [super init];
  listenMode = YES;
  currentLocationIndex = -1;
  ASSIGN(history, [NSMutableArray arrayWithCapacity: 20]);
  return self;
}

-(void)setDelegate: (id<HistoryManagerDelegate>)aDelegate {
  ASSIGN( _delegate, aDelegate );
}

-(id<HistoryManagerDelegate>)delegate {
  return [[_delegate retain] autorelease];
}

-(void) browseBack {
  [self browseToIndex: currentLocationIndex-1];
}

-(void) browseForward {
  [self browseToIndex: currentLocationIndex+1];
}

-(void) browseToIndex: (unsigned) aNewIndex {
  if (listenMode == YES) {
    listenMode = NO;
    
    if ([self canBrowseTo: aNewIndex] &&
	[_delegate conformsToProtocol: @protocol(HistoryManagerDelegate)]) {
      // remember where we will go
      futureLocationIndex = aNewIndex;
      // try to browse there
      [_delegate
	historyManager: self
	needsBrowseTo: [history objectAtIndex: aNewIndex]];
    }
    listenMode = YES;
  } else { // listenMode == NO
    NSLog(@"Can't go back in go-back mode.");
  }
}


-(BOOL) canBrowseTo: (unsigned) aNewIndex {
  return ([history count] > aNewIndex &&
	  aNewIndex != -1) ? YES : NO;
}

-(BOOL) canBrowseBack {
  return [self canBrowseTo: currentLocationIndex-1];
}

-(BOOL) canBrowseForward {
  return [self canBrowseTo: currentLocationIndex+1];
}

-(void) browser: (id)aBrowser
    didBrowseTo: (id)aBrowsingLocation {
  // When not in listen mode, we probably sent this browsing
  // request ourselves.
  if (listenMode == NO) {
    // set the currentLocation to where we are supposed to go
    currentLocationIndex = futureLocationIndex;
    return;
  }
  
  [history
    removeObjectsInRange: NSMakeRange(currentLocationIndex+1,[history count])];
  [history addObject: aBrowsingLocation];
  
  currentLocationIndex++;
}

@end



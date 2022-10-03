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

#import <AppKit/AppKit.h>

// predeclaration
@class HistoryManager;

@protocol HistoryManagerDelegate <NSObject>
-(BOOL) historyManager: (HistoryManager*) aHistoryManager
	 needsBrowseTo: (id) aLocation;
@end

@interface HistoryManager : NSObject
{
@private
  id<HistoryManagerDelegate> _delegate;
  NSMutableArray* history;
  BOOL listenMode;
  unsigned currentLocationIndex;
  unsigned futureLocationIndex;
}

-(id)init;
-(void)setDelegate: (id<HistoryManagerDelegate>)aDelegate;
-(id<HistoryManagerDelegate>)delegate;

-(void) browseToIndex: (unsigned) aNewIndex;
-(void) browseBack;
-(void) browseForward;
-(BOOL) canBrowseTo: (unsigned) aNewIndex;
-(BOOL) canBrowseBack;
-(BOOL) canBrowseForward;

-(void) browser: (id)aBrowser
    didBrowseTo: (id)aBrowsingLocation;


@end



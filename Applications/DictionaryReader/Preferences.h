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
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


#ifdef ETOILE
#import <EtoileFoundation/UKNibOwner.h>
#else
#import "UKNibOwner.h"
#endif


/**
 * This notification is sent through the default notification center whenever the
 * selection of the active dictionaries changes. The notification object is an array
 * that contains the new active dictionaries.
 */
static NSString* DRActiveDictsChangedNotification = @"DRActiveDictsChangedNotification";



/**
 * This is the controller class for the preferences panel.
 */
@interface Preferences : UKNibOwner
{
    NSTableView* _tableView;
    NSPanel* _prefPanel;
    NSMutableArray* _dictionaries;
}

// Singleton
+(id)shared;

-(void)setDictionaries: (NSMutableArray*) dicts;
-(void)rescanDictionaries: (id)sender;

-(void)show;
-(void)hide;
@end


@interface Preferences (SearchForDictionaries)
-(void) foundDictionary: (id)aDictionary;
-(void) searchInUsualPlaces;
-(void) searchInDirectory: (NSString*) dirName;
@end


@interface Preferences (DictionarySelectionDataSource)
@end


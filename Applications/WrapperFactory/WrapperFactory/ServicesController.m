/* Copyright (C) 2003 Raffael Herzog
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
 * $Id: TypesController.m 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/TypesController.m $
 */

#include <AppKit/AppKit.h>

#include "ServicesController.h"


static NSString *NameColumnId = @"NameColumn";

@implementation ServicesController

/*
 * initialization
 */

- (id)init
{
    self = [super init];
    if ( self ) {
    }
    [[NSNotificationCenter defaultCenter] addObserver: (self)
                                          selector: @selector(documentAggregateDidChange:)
                                          name: (WrapperAggregateChangedNotification)
                                          object: (nil)];
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)awakeFromNib
{
    [self setupTable];
}

- (void)setupTable
{
    if ( ! tableView ) {
        return;
    }
    [tableView setAllowsColumnReordering: NO];
    [tableView setAllowsColumnResizing: YES];
    [tableView setAllowsMultipleSelection: NO];
    [tableView setAllowsEmptySelection: NO];
    [tableView setAllowsColumnSelection: NO];
    NSEnumerator *e = [[tableView tableColumns] objectEnumerator];
    NSTableColumn *c;
    while ( (c=[e nextObject]) ) {
        [tableView removeTableColumn: c];
    }

    // name column
    c = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: NameColumnId]);
    [c setResizable: YES];
    [[c headerCell] setStringValue: _(@"Type Name")];
    [tableView addTableColumn: c];

    [tableView setAutoresizesAllColumnsToFit: NO];
    [tableView deselectAll: self];
    [tableView reloadData];
}



/*
 * NSTableView delegate
 */

- (void)tableViewSelectionDidChange: (NSNotification *)not
{
    if ( [tableView numberOfSelectedRows] ) {
        [serviceController setService: [document serviceAtIndex: [tableView selectedRow]]];
    }
    else {
        [serviceController setService: nil];
    }
}


/*
 * WrapperDocument delegate
 */

- (void)documentAggregateDidChange: (NSNotification *)not
{
    if ( document ) {
        if ( [document indexOfService: [not object]] >= 0 ) {
            [tableView reloadData];
        }
    }
}


/*
 * UI Actions
 */

- (IBAction)newService: (id)sender
{
    if ( document && tableView ) {
        Service *service = AUTORELEASE([[Service alloc] init]);
        [document addService: service];
        [tableView reloadData];
        [tableView selectRow: [document serviceCount]-1
                   byExtendingSelection: (NO)];
    }
}

- (IBAction)deleteService: (id)sender
{
    if ( document && tableView ) {
        int index = [tableView selectedRow];
        if ( index >= 0 ) {
            Service *service = [document serviceAtIndex: index];
            [tableView deselectRow: index];
            [document removeService: service];
            [tableView reloadData];
        }
    }
}


/*
 * Outlets
 */

- (WrapperDocument *)document
{
    return document;
}
- (void)setDocument: (WrapperDocument *)doc
{

//     if ( document ) {
//         [[NSNotificationCenter defaultCenter] removeObserver: (self)
//                                               name: (WrapperAggregateChangedNotification)
//                                               object: (document)];
//     }
    ASSIGN(document, doc);
//     if ( document ) {
//         //NSLog(@"Setting observer: %@", document);
//         [[NSNotificationCenter defaultCenter] addObserver: (self)
//                                               selector: @selector(documentAggregateDidChange:)
//                                               name: (WrapperAggregateChangedNotification)
//                                               object: (document)];
//     }
}

- (NSTableView *)tableView
{
    return tableView;
}
- (void)setTableView: (NSTableView *)table
{
    ASSIGN(tableView, table);
}

- (ServiceController *)serviceController
{
    return serviceController;
}
- (void)setServiceController: (ServiceController *)servicec
{
    ASSIGN(serviceController, servicec);
}

/*
 * NSTableDataSource
 */

- (int)numberOfRowsInTableView: (NSTableView *)table;
{
    if ( document ) {
        return [document serviceCount];
    }
    else {
        return 0;
    }
}

- (id)tableView: (NSTableView *)table
objectValueForTableColumn: (NSTableColumn *)col
            row: (int)row
{
    if ( !document || (row>=[document serviceCount]) ) {
        return nil;
    }
    Service *service = [document serviceAtIndex: row];
    if ( [[col identifier] isEqualToString: NameColumnId] ) {
        return [service name];
    }
    else {
        return nil;
    }
}

- (void)tableView: (NSTableView *)table
sortDescriptorsDidChange: (NSArray *)sortDescriptors
{
}

@end

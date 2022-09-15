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

#include "TypesController.h"


static NSString *IconColumnId = @"IconColumn";
static NSString *NameColumnId = @"NameColumn";


@interface TypesController (Private)

- (void)showTypeEditor;
- (void)hideTypeEditor;

@end


@implementation TypesController

/*
 * initialization
 */

- (id)init
{
    self = [super init];
    if ( self ) {
        emptyBox = [[NSBox alloc] init];
        [emptyBox setBorderType: NSNoBorder];
        [emptyBox setTitlePosition: NSNoTitle];
    }
    [[NSNotificationCenter defaultCenter] addObserver: (self)
                                          selector: @selector(documentAggregateDidChange:)
                                          name: (WrapperAggregateChangedNotification)
                                          object: (nil)];
    return self;
}

- (void)dealloc
{
    TEST_RELEASE(emptyBox);
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

    // icon column
    c = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: IconColumnId]);
    [c setWidth: [tableView rowHeight]];
    [c setResizable: NO];
    [c setDataCell: AUTORELEASE([[NSImageCell alloc] init])];
    [tableView addTableColumn: c];
    // name column
    c = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: NameColumnId]);
    [c setResizable: YES];
    [[c headerCell] setStringValue: _(@"Type Name")];
    [tableView addTableColumn: c];

    [tableView setAutoresizesAllColumnsToFit: NO];
    [tableView deselectAll: self];
    [tableView reloadData];

    [self hideTypeEditor];
}



/*
 * NSTableView delegate
 */

- (void)tableViewSelectionDidChange: (NSNotification *)not
{
    if ( [tableView numberOfSelectedRows] ) {
        [typeController setType: [document typeAtIndex: [tableView selectedRow]]];
        [self showTypeEditor];
    }
    else {
        [self hideTypeEditor];
        [typeController setType: nil];
    }
}


/*
 * WrapperDocument delegate
 */

- (void)documentAggregateDidChange: (NSNotification *)not
{
    if ( document ) {
        if ( [document indexOfType: [not object]] >= 0 ) {
            [tableView reloadData];
        }
    }
}


/*
 * UI Actions
 */

- (IBAction)newType: (id)sender
{
    if ( document && tableView ) {
        Type *type = AUTORELEASE([[Type alloc] init]);
        [document addType: type];
        [tableView reloadData];
        [tableView selectRow: [document typeCount]-1
                   byExtendingSelection: (NO)];
    }
}

- (IBAction)deleteType: (id)sender
{
    if ( document && tableView ) {
        int index = [tableView selectedRow];
        if ( index >= 0 ) {
            Type *type = [document typeAtIndex: index];
            [tableView deselectRow: index];
            [document removeType: type];
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

- (TypeController *)typeController
{
    return typeController;
}
- (void)setTypeController: (TypeController *)typec
{
    ASSIGN(typeController, typec);
}

- (NSBox *)typeEditor
{
    return typeEditor;
}

- (void)setTypeEditor: (NSBox *)editor
{
    ASSIGN(typeEditor, editor);
}


/*
 * NSTableDataSource
 */

- (int)numberOfRowsInTableView: (NSTableView *)table;
{
    if ( document ) {
        return [document typeCount];
    }
    else {
        return 0;
    }
}

- (id)tableView: (NSTableView *)table
objectValueForTableColumn: (NSTableColumn *)col
            row: (int)row
{
    if ( !document || (row>=[document typeCount]) ) {
        return nil;
    }
    Type *type = [document typeAtIndex: row];
    if ( [[col identifier] isEqualToString: IconColumnId] ) {
        return [[type icon] imageCopy: NO];
    }
    else if ( [[col identifier] isEqualToString: NameColumnId] ) {
        return [type name];
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


@implementation TypesController (Private)

- (void)showTypeEditor
{
    if ( typeEditor && typeEditorContents ) {
        [typeEditor setContentView: typeEditorContents];
        [typeEditor setTitlePosition: typeEditorTitlePosition];
        [typeEditor setBorderType: typeEditorBorderType];
        ASSIGN(typeEditorContents, nil);
    }
}

- (void)hideTypeEditor
{
    if ( typeEditor && !typeEditorContents ) {
        ASSIGN(typeEditorContents, [typeEditor contentView]);
        [typeEditor setContentView: emptyBox];
        typeEditorTitlePosition = [typeEditor titlePosition];
        typeEditorBorderType = [typeEditor borderType];
        [typeEditor setTitlePosition: NSNoTitle];
        [typeEditor setBorderType: NSNoBorder];
    }
}

@end

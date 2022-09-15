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
 * $Id: TypesController.h 103 2004-08-09 16:30:51Z rherzog $
 * $HeadURL: file:///home/rherzog/Subversion/GNUstep/GSWrapper/tags/release-0.1.0/WrapperFactory/TypesController.h $
 */

#ifndef _GSWrapper_TypesController_H
#define _GSWrapper_TypesController_H

#include <AppKit/AppKit.h>

#include "WrapperDocument.h"
#include "Type.h"
#include "TypeController.h"


@interface TypesController : NSObject
{
    IBOutlet NSTableView *tableView;
    IBOutlet TypeController *typeController;
    IBOutlet WrapperDocument *document;
    IBOutlet NSBox *typeEditor;

    NSBox *emptyBox;
    NSView *typeEditorContents;
    NSBorderType typeEditorBorderType;
    NSTitlePosition typeEditorTitlePosition;
}

/*
 * initialization
 */

- (void)awakeFromNib;

- (void)setupTable;


/*
 * NSTableView delegate
 */

- (void)tableViewSelectionDidChange: (NSNotification *)not;


/*
 * UI Actions
 */

- (IBAction)newType: (id)sender;
- (IBAction)deleteType: (id)sender;


/*
 * Outlets
 */

- (WrapperDocument *)document;
- (void)setDocument: (WrapperDocument *)doc;

- (NSTableView *)tableView;
- (void)setTableView: (NSTableView *)table;

- (TypeController *)typeController;
- (void)setTypeController: (TypeController *)typec;

- (NSBox *)typeEditor;
- (void)setTypeEditor: (NSBox *)Editor;


/*
 * NSTableDataSource
 */

- (int)numberOfRowsInTableView: (NSTableView *)table;
- (id)tableView: (NSTableView *)table
objectValueForTableColumn: (NSTableColumn *)col
            row: (int)row;

// - (void)tableView: (NSTableView *)table
//    setObjectValue: (id)value
//    forTableColumn: (NSTableColumn *)col
//               row: (int)row;

- (void)tableView: (NSTableView *)table
sortDescriptorsDidChange: (NSArray *)sortDescriptors;


// - (BOOL)tableView: (NSTableView *)table
//        acceptDrop: (id<NSDraggingInfo>)info
//               row: (int)row
//     dropOperation: (NSTableViewDropOperation *)operation;
// - (NSDragOperation)tableView: (NSTableView *)table
//                 validateDrop: (id<NSDraggingInfo>)info
//                  proposedRow: (int)row
//        proposedDropOperation: (NSTableViewDropOperation)operation;
// - (BOOL)tableView: (NSTableView *)table
//         writeRows: (NSArray *)rows
//      toPasteboard: (NSPasteboard *)pboard;

@end


#endif

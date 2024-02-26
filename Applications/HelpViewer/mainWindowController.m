/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003      Nicolas Roard (nicolas@roard.com)
                  2020-2021 Riccardo Mottola <rm@gnu.org>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the
    Free Software Foundation, Inc.  
    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
*/

#ifdef GNUSTEP
#import <GNUstepBase/GNUstep.h>
#else
#import "GNUstep.h"
#endif

#import "mainWindowController.h"

@implementation MainWindowController

- (id) initWithTextView: (NSTextView*) _text andBrowserView:(NSBrowser*) browser {
  if ((self = [super init]))
    {
	resultTextView = [_text retain];
	resultOutlineView = [browser retain];

	[resultTextView setDelegate: self];
	[resultTextView setTextContainerInset: NSMakeSize (8,8)];
	
	[resultOutlineView setDelegate: self];
	[resultOutlineView setAllowsMultipleSelection: NO];
	[resultOutlineView setCellClass: [BrowserCell class]];
	[resultOutlineView setAction: @selector(browserClick:)];
	[resultOutlineView setTarget: self];
	//[resultOutlineView setDataSource: self];


	//handler = RETAIN ([XMLHandler new]);
	handler = [HandlerStructureXLP new];
	
	[handler setTextView: resultTextView];

	id TextFormatter = [[TextFormatterXLP alloc] init];
	[TextFormatter setTextView: resultTextView];
	[Section setTextFormatter: TextFormatter];
	[TextFormatter release];

	prevRow = 0;

        historyManager = [[HistoryManager alloc] init];
        [historyManager setDelegate: self];
    }
  return self;
}

- (void) print: (id) sender 
{
        [[NSPrintOperation printOperationWithView: resultTextView] runOperation];
}

- (void) back: (id) sender 
{
  if ([historyManager canBrowseBack])
    [historyManager browseBack];
}

- (void) forward: (id) sender 
{
  if ([historyManager canBrowseForward])
    [historyManager browseForward];
}

- (void) search: (id) sender
{
  NSButton* tmp = [[NSButton alloc] init];
  [tmp setTag:2];
  [resultTextView performFindPanelAction:tmp];
  [tmp release];
}

-(BOOL) historyManager: (HistoryManager*) aHistoryManager
	 needsBrowseTo: (id) aLocation
{
  [self loadFile: aLocation];
  return YES;
}

- (BOOL) loadFile: (NSString*) fileName 
{
    ASSIGN (handler, [HandlerStructureXLP new]);

    if ([[fileName pathExtension] isEqualToString:@"help"]) {
      NSBundle* Bundle = [NSBundle bundleWithPath: fileName];
      NSString* path = [Bundle pathForResource: @"main" ofType: @"xlp"];
      [Section setBundle: Bundle];
      [handler setPath: path];
      [handler parse];
      [historyManager browser:self didBrowseTo:path];
    }
    else if ([[fileName pathExtension] isEqualToString:@"xlp"]) {
      [handler setPath: fileName];
      [handler parse];
      [historyManager browser:self didBrowseTo:fileName];
    }
    else {
      NSLog(@"try to convert %@", fileName);

      NSPasteboard* pboard = [NSPasteboard pasteboardByFilteringFile:fileName];
      NSString* data = [pboard stringForType:NSStringPboardType];
      if (data) {
        NSString* tfile = [NSString stringWithFormat:@"%@/temp.%lx.xlp", NSTemporaryDirectory(), [data hash]];
        [data writeToFile:tfile atomically:NO];
        NSLog(@"tmp file %@", tfile);

        [handler setPath: tfile];
        [handler parse];
        [historyManager browser:self didBrowseTo:tfile];
      }
      else {
        NSLog(@"don't know how to handle %@", fileName);
        return NO;
      }
    }

/*
    string = [handler getPart: 0];
    Part* currentPage = [handler getPage: 0];

    if ([handler title] != nil)
    {
    	[window setTitle: [handler title]];
    }
    
    //NSLog (@"string : %@", string);
    //NSLog (@"currentPage : %@", currentPage);
    if ((string != nil) && (currentPage != nil))
    {
	[currentPage addSubviewsToView: resultTextView];
	[[resultTextView textStorage] setAttributedString: string];
	[resultOutlineView reloadData];
	ret = YES;
    }
    else 
    {
	NSLog (@"no parts !!!");
    }
 */
    NSLog (@"loadFile : %@", fileName);

    [window makeKeyAndOrderFront:nil];

    [resultTextView scrollRangeToVisible:NSMakeRange (0, 1)];
    [resultOutlineView reloadColumn: 0];
    [resultOutlineView selectRow:0 inColumn:0];
    [self browserClick: resultOutlineView];

    return YES;
}

- (void) setWindow: (id) win { window = win; }

/*
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
    BOOL ret = NO;
    //NSLog (@"shouldSelectRow : %d", rowIndex);
    if (handler != nil)
    {
	int nb = [[handler structuredText] count]; // nb of pages
	int i;
	int cur = 0;
	for (i=0; i<nb; i++)
	{
	    Part* page = [handler getPage: i];
	    int count = [[page sections] count];
	    if (cur == rowIndex) // Page 
	    {
		//ret = [[page title] string];
		NSAttributedString* string;
		string = [handler getPart: i];
		Part* currentPage = [handler getPage: prevRow];
		[currentPage removeSubviews];
		currentPage = [handler getPage: i];
		prevRow = i;
		[currentPage addSubviewsToView: resultTextView];

		[[resultTextView textStorage] setAttributedString: string];
		if ([[resultTextView textStorage] length] > 0)
		{
		    [resultTextView scrollRangeToVisible: 
			NSMakeRange (0, 1)];
		}
		//[aTableView reloadData];
		ret = YES;
		break;
	    }
	    if (cur + count >= rowIndex) // if rowIndex a section of the current page ...
	    {
		cur = rowIndex - cur - 1; // get the section's index

		//ret = [NSString stringWithFormat: @"    %@", [[[page sections] objectAtIndex: cur] header]];

		if (prevRow != i) // wrong page ... we must update
		{
		    NSAttributedString* string;
		    string = [handler getPart: i];
		    Part* currentPage = [handler getPage: prevRow];
		    [currentPage removeSubviews];
		    currentPage = [handler getPage: i];
		    prevRow = i;
		    [currentPage addSubviewsToView: resultTextView];

		    [[resultTextView textStorage] setAttributedString: string];
		}

		int length = [[resultTextView textStorage] length];
		if (length > 1)
		{
		    [resultTextView scrollRangeToVisible: 
			NSMakeRange (length - 1, 1)];
		}
			    
		[resultTextView scrollRangeToVisible: 
		    [[[page sections] objectAtIndex: cur] range]];

		ret = YES;
		break;
	    }
	    cur += count + 1;
	}

    }
    return ret;
}
*/

/*
- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSAttributedString* string;
    NSLog (@"didClickTableColumn (%@)", [tableColumn identifier]);
    if (handler != nil)
    {
	string = [handler getPart: [[tableColumn identifier] intValue]];
	[[[theWindow resultTextView] textStorage] setAttributedString: string];
	[tableView reloadData];
    }
}
*/

/*
-(void) tableView: (NSTableView *)tv willDisplayCell: (NSCell *)c forTableColumn: (NSTableColumn *)tc row: (int)rowIndex
{
    if (handler != nil)
    {
	int nb = [[handler structuredText] count]; // nb of pages
	int i;
	int cur = 0;
	for (i=0; i<nb; i++)
	{
	    Part* page = [handler getPage: i];
	    int count = [[page sections] count];
	    if (cur == rowIndex) // Page 
	    {
//		[c setFont: [NSFont boldSystemFontOfSize: 0]];
		break;
	    }
	    else
	    {
//		[c setFont: [NSFont systemFontOfSize: 0]];
	    }
	    cur += count + 1;
	}
    }
}


- (int) numberOfRowsInTableView: (NSTableView*) aTableView
{
    int ret = 0;
    if (handler != nil)
    {
	int nb = [[handler structuredText] count]; // nb of pages
	int i;
	for (i=0; i<nb; i++)
	{
	    Part* page = [handler getPage: i];
	    ret += [[page sections] count] + 1;
	}
    }
    return ret;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    //NSLog (@"tableView:objectValueForTableColumn:row:%d", rowIndex);
    id ret = nil; 
    
    if (handler != nil)
    {
	int nb = [[handler structuredText] count]; // nb of pages
	int i;
	int cur = 0;
	for (i=0; i<nb; i++)
	{
	    Part* page = [handler getPage: i];
	    int count = [[page sections] count];
	    if (cur == rowIndex) 
	    {
		//ret = [[page title] string];
		ret = [page title];
		break;
	    }
	    if (cur + count >= rowIndex) // if rowIndex a section of the current page ...
	    {
		cur = rowIndex - cur - 1; // get the section's index

		ret = [NSString stringWithFormat: @"    %@", [[[page sections] objectAtIndex: cur] header]];
		break;
	    }
	    cur += count + 1;
	}
	
	//NSLog (@"*** retour (%d) : %@", rowIndex, ret);
	[aTableColumn setIdentifier: [NSNumber numberWithInt: rowIndex]];
	//NSLog (@"identifieur mis");
    }
    return ret;
}
*/

- (void) openExternalLink:(NSURL*) url
{

  [[NSWorkspace sharedWorkspace] openURL: url];
}

- (BOOL) textView: (NSTextView *) textView
    clickedOnLink: (id) link
              atIndex: (unsigned) charIndex
{
    BOOL ret = NO;
    if (handler != nil)
    {
	NSLog (@"clickedonlink !!!");
	if ([link isKindOfClass: [NSURL class]])
	{
	    NSLog(@"Opening URL : <%@>", [link description]);
            [self performSelector:@selector(openExternalLink:)
                       withObject:link
                       afterDelay:0.1];
            ret = YES;
	}
	else if ([link isKindOfClass: [NSString class]])
	{
	    NSLog (@"opening reference : %@", link);
	    Label* label = [handler getLabelForReference: link];
	    if ((label != nil) && ([label isKindOfClass: [Label class]]))
	    {
		NSLog (@"scrolling ...");
		NSLog (@"range to scroll : %d -> %d", [label range].location, [label range].length);
		Part* currentPage = [handler getPage: prevRow];
		[currentPage removeSubviews];
		currentPage = [label page];
		[currentPage addSubviewsToView: resultTextView];
		[[resultTextView textStorage] setAttributedString: [currentPage getPage]];		
		
		[resultTextView scrollRangeToVisible: 
		    [label range]];
	    }
	}
	NSLog (@"link : %@", link);
    }

    return ret;
}

- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column
{
	//NSLog (@"delegate browser ");
	NSInteger ret = 0;

	//NSLog (@"browser:numberOfRowsInColumn:%d", column);


	if (column == 0) // First column
	{
		Section* section = (Section*)[handler sections];
		ret = [[section subs] count];
	}	
	else
	{
		id cell = [sender selectedCellInColumn: column -1];
		ret = [[[cell section] subs] count];
	}
	//NSLog (@"fin de browser:numberOfRowsInColumn:%d", column);
	return ret;
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column
{
	Section* sub = nil;
	[cell setLeaf: YES];

	//NSLog (@"browser:willDisplayCell:atRow:%dcolumn:%d",row,column);

	if (column == 0) // First column
	{
		Section* section = (Section*)[handler sections];
		sub = [[section subs] objectAtIndex: row];
	}
	else
	{
		id cell = [sender selectedCellInColumn: column -1];
		sub = [[[cell section] subs] objectAtIndex: row];
	}

	if (sub != nil)
	{
		id subs = [sub subs];
		if ((subs != nil) && ([subs count] > 0))
		{
			[cell setLeaf: NO];
		}
		[cell setSection: sub];
		[cell setStringValue: [sub header]];

		if ([sub loaded] == NO)
		{
			//NSLog (@"not loaded : %@", [sub header]);
			[cell setImage: [NSImage imageNamed: @"notloaded.tiff"]];
			//[cell setLeaf: NO];
			//[sub load];
		}
		else
		{
			if (([sub type] == SECTION_TYPE_PLAIN)
			 || ([sub type] == SECTION_TYPE_CHAPTER))
			{
				//NSLog (@"chapter : %@", [sub header]);
				[cell setImage: [NSImage imageNamed: @"chapter.tiff"]];
			}
			else if ([sub type] == SECTION_TYPE_PART)
			{
				//NSLog (@"chapter : %@", [sub header]);
				[cell setImage: [NSImage imageNamed: @"part.tiff"]];
			}
		}
		
		//NSLog (@"sub : %@", [sub header]);
	}
	else
	{
		//NSLog (@"sub == nil");
		[cell setStringValue: @"ERROR"];
	}
	//NSLog (@"fin de browser:willDisplayCell:atRow:%dcolumn:%d",row,column);
}

- (void) browserClick: (id) sender
{
	Section* sub = (Section*)[[sender selectedCell] section];
	if (sub != nil)
	{
		//NSLog (@"browserClick");
		if ([sub loaded] == NO)
		{
			[sub load];
    			[resultOutlineView reloadColumn: [resultOutlineView lastColumn]];
			[resultOutlineView selectRow: [resultOutlineView selectedRowInColumn: [resultOutlineView lastColumn]]
				inColumn: [resultOutlineView lastColumn]];
		}
			
		if (([sub type] == SECTION_TYPE_PLAIN)
		 || ([sub type] == SECTION_TYPE_CHAPTER))
		{
			// We have a "new" page, so we replace the entire text 
			// NSLog (@"on a une nouvelle page ...");
			id str = [sub contentWithLevel: 0];
			// NSLog (@"on a recu : %@ et on va le mettre dans le textview", str);
			[str retain];
			[[resultTextView textStorage] setAttributedString: str];
			[str release];
		}
		else if ([sub type] == SECTION_TYPE_NORMAL)
		{
			// We should select the right position in the textview
			// (ie, point the user to the right section)
		}
    		[resultOutlineView reloadColumn: [resultOutlineView lastColumn]];
	}
	//NSLog (@"FIN browserClick");
}
		   
- (void) dealloc
{
    NSLog (@"=== dealloc mainWindowController ===");
    RELEASE ((NSObject*)handler);
    RELEASE (resultTextView);
    RELEASE (resultOutlineView);
    RELEASE (historyManager);
    [super dealloc];
}

@end

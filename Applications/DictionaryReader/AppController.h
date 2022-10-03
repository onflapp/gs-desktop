/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
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

#import <AppKit/AppKit.h>
#import "DictConnection.h"
#import "DefinitionWriter.h"
#import "HistoryManager.h"

@interface AppController : NSObject
{
  @private
  NSTextField* searchStringControl;
  NSTextView* searchResultView;
  NSButton* browseBackButton;
  NSButton* browseForwardButton;
  NSWindow* dictionaryContentWindow;
  
  NSMutableArray* dictionaries;
  HistoryManager* historyManager;
}

-(id)init;


// Some methods called by the GUI
-(void) browseBackClicked: (id)sender;
-(void) browseForwardClicked: (id)sender;
-(void) orderFrontPreferencesPanel: (id)sender;


// TextView delegate stuff
-(BOOL) textView: (NSTextView*) textView
   clickedOnLink: (id) link
	 atIndex: (unsigned) charIndex;

-(void)updateGUI;



// The file to store the dictionary list to
-(NSString*) dictionaryStoreFile;



// Listen for actions...

// ...from the GUI
-(void) searchAction: (id)sender;

// ...from the Links in the text field
-(void) clickSearchNotification: (NSNotification*)aNotification;

// ..from the system
-(void) applicationWillTerminate: (NSNotification*) theNotification;
-(void) applicationDidFinishLaunching: (NSNotification*) theNotification;


-(void) defineWord: (NSString*)aWord;

@end


@interface AppController (DefinitionWriter) <DefinitionWriter> 

-(void) clearResults;
-(void) writeBigHeadline: (NSString*) aString;
-(void) writeHeadline: (NSString*) aString;
-(void) writeLine: (NSString*) aString;
-(void) writeString: (NSString*) aString
	       link: (id) aClickable;

// not part of the protocol
-(void) writeString: (NSString*) aString
	 attributes: (NSDictionary*) attributes;

@end

@interface AppController (HistoryManagerDelegate) <HistoryManagerDelegate>
-(BOOL) historyManager: (HistoryManager*) aHistoryManager
	 needsBrowseTo: (id) aLocation;
@end

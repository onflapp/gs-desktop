/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003 Nicolas Roard (nicolas@roard.com)

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

#ifndef __MAIN_WINDOW_CONTROLLER_H__
#define __MAIN_WINDOW_CONTROLLER_H__

#include "GNUstep.h"
#include "Label.h"
#include "Parser.h"
#include "HandlerStructure.h"
#include "HandlerStructureXLP.h"
#include "TextFormatterXLP.h"
#include "BrowserCell.h"
#include "HistoryManager.h"

@interface MainWindowController : NSObject <HistoryManagerDelegate>
{
	NSTextView* resultTextView;
	NSBrowser* resultOutlineView;
    
	//XMLHandler* handler;
	id <HandlerStructure> handler;
	int prevRow;
	id window;
  HistoryManager* historyManager;
}

- (id) initWithTextView: (NSTextView*) text andBrowserView: (NSBrowser*) browser;
- (void) dealloc;
- (BOOL) loadFile: (NSString*) fileName;
- (void) setWindow: (id) win;
- (void) browserClick: (id) sender;
- (void) print: (id) sender;
- (void) back: (id) sender;
- (void) forward: (id) sender;
- (void) search: (id) sender;

@end;

#endif

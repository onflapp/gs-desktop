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

#ifndef __CONTROLLER_H__
#define __CONTROLLER_H__

#include <AppKit/AppKit.h>
#include "mainWindowController.h"
#include "GNUstep.h"

@interface Controller : NSObject
{
  id query;
  id search;
  id index;
  id back;
  id forward;
  id bookshelf;
    
  id textview;
  id tocview;
  id window;
  
  id infoMenu;
  id helpMenu;
  id servicesMenu;

  id searchField;
  id statusField;
  
  MainWindowController* windowController;
}
- (void) openFile: (id) sender;
- (void) search: (id) sender;
- (void) index: (id) sender;
- (void) back: (id) sender;
- (void) forward: (id) sender;
- (void) bookshelf: (id) sender;
- (void) print: (id) sender;
- (void) initButtons;
@end

#endif

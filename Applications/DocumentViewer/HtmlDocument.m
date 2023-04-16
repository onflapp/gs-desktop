/*
   Project: DocViewer

   Copyright (C) 2023 Free Software Foundation

   Author: Parallels

   Created: 2023-04-16 13:13:18 +0200 by parallels

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "HtmlDocument.h"

@implementation HtmlDocument

- (id) init {
  self = [super init];
  [NSBundle loadNibNamed:@"HtmlDocument" owner:self];
  [window setFrameAutosaveName:@"htmldocument_window"];
    
  [self initNavigation];
  return self;
}

- (void) awakeFromNib {
	[htmlView setUIDelegate:self];
	[htmlView setFrameLoadDelegate:self];
}

- (void) dealloc {
  [super dealloc];
}

- (void) displayFile:(NSString*) path {
  NSURL* u = [NSURL fileURLWithPath:path];
  [[htmlView mainFrame] loadRequest:[NSURLRequest requestWithURL:u]];

  [window makeKeyAndOrderFront:self];
  [statusField setStringValue:@"loading html"];
  [self displayPage:1];
}

- (NSInteger) currentPage {
  return 1;
}

- (NSInteger) pageCount {
  return [[htmlView backForwardList] backListCount];
}

- (void) webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
  if(frame == [sender mainFrame]) {
    [window setTitle:title];
  }
}

- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
  [self displayNavigation];
}

@end

/*
    This file is part of HelpViewer (http://www.roard.com/helpviewer)
    Copyright (C) 2003 Nicolas Roard (nicolas@roard.com)
                  2020 Riccardo Mottola <rm@gnu.org>

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

#include "Page.h"

@implementation Part

- (id) init
{
  if ((self = [super init]))
    {
      sections = [[NSMutableArray alloc] init];
      subviews = [[NSMutableArray alloc] init];
      title = [[NSString alloc] initWithString: @""];
      text = [[NSMutableAttributedString alloc] initWithString: @"\n"];
    }
  return self;
}

- (void) dealloc
{
  RELEASE (sections);
  RELEASE (subviews);
  RELEASE (title);
  RELEASE (text);
  [super dealloc];
}

- (NSString*) title {
    return title;
}

- (void) setTitle: (NSString*) ptitle {
    ASSIGN (title, ptitle);
}

- (NSMutableAttributedString*) text {
    return text;
}

- (void) addSection: (Section*) section {
    [sections addObject: section];
}

- (void) addSubview: (NSView*) view {
    [subviews addObject: view];
}

- (void) addSubviewsToView: (NSView*) view {
    NSUInteger i;
    
    for (i=0; i < [subviews count]; i++) 
    {
	[view addSubview: [subviews objectAtIndex: i]];
    }
}

- (void) removeSubviews {
    NSUInteger i;

    for (i=0; i < [subviews count]; i++)
    {
	[[subviews objectAtIndex: i] removeFromSuperview];
    }
}

- (NSAttributedString*) getPage {
    NSUInteger i;
    NSMutableAttributedString* ret = [[NSMutableAttributedString alloc] initWithAttributedString: text];
    AUTORELEASE (ret);

    NSLog (@"sections count : %d", [sections count]);
    for (i=0; i < [sections count]; i++)
    {
	NSMutableAttributedString* current;
	current = [(Section*)[sections objectAtIndex: i] text];
	[[sections objectAtIndex: i] setRange: NSMakeRange ([ret length], [current length])];
	[ret appendAttributedString: AUTORELEASE([[NSMutableAttributedString alloc] initWithString: @"\n"])];
	[ret appendAttributedString: current];
    }

    NSLog (@"Page returned : %@", ret);
    
    return ret;	
}

- (NSArray*) sections {
    return sections;
}

@end
    

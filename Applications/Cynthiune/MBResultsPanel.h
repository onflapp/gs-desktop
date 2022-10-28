/* MBResultsPanel.h - this file is part of Cynthiune
 *
 * Copyright (C) 2005 Wolfgang Sourdeau
 *
 * Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>
 *
 * This file is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#ifndef MBRESULTSPANEL_H
#define MBRESULTSPANEL_H

#import <AppKit/NSPanel.h>

#if defined(__APPLE__) && (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4)
#ifndef NSUInteger
#define NSUInteger unsigned
#endif
#ifndef NSInteger
#define NSInteger int
#endif
#ifndef CGFloat
#define CGFloat float
#endif
#endif

@class NSArray;
@class NSScrollView;
@class NSTableView;
@class NSTextField;

@interface MBResultsPanel : NSPanel
{
  NSButton *okButton;
  NSButton *cancelButton;
  NSTableView *tableView;
  NSArray *trackInfos;
  id target;
  SEL actionSelector;
}

+ (MBResultsPanel *) resultsPanel;

- (void) showPanelForTrackInfos: (NSArray *) allTrackInfos
                    aboveWindow: (NSWindow *) window
                         target: (id) caller
                       selector: (SEL) action;

@end

@interface NSObject (MBResultsPanelDelegate)

- (void) resultsPanelDidEndWithTrackInfos: (NSDictionary *) trackInfo;

@end

#endif /* MBRESULTSPANEL_H */

/* -*- mode: objc -*- */
//
// This application is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation; either
// version 2 of the License, or (at your option) any later version.
//
// This application is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Library General Public License for more details.
//
// You should have received a copy of the GNU General Public
// License along with this library; if not, write to the Free
// Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
//

#include <AppKit/NSView.h>
#include "BatteryModel.h"

@interface BatteryView: NSView
{
  NSDictionary *stateStrAttributes;
  NSImage *iconBattery_full;
  NSImage *iconBattery_good;
  NSImage *iconBattery_low;
  NSImage *iconBattery_caution;
  NSImage *iconBattery_empty;

  NSImage *iconPlug;
  NSImage *iconPlugOut;

  NSImage* tileImage;
  BatteryModel *batModel;

  // Double-click target/action
  id		actionTarget;
  SEL		doubleAction;
}
- initWithFrame:(NSRect)aFrame batteryModel:(BatteryModel*) model;
- (void)setTarget:(id)target;
- (void)setDoubleAction:(SEL)sel;

@end


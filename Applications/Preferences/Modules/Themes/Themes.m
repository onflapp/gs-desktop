/* -*- mode: objc -*- */
//
// Project: Preferences
//
// Copyright (C) 2014-2019 onflapp
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

#import <AppKit/NSApplication.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSView.h>
#import <AppKit/NSBox.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSBrowser.h>
#import <AppKit/NSBrowserCell.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSSlider.h>

#import "AppController.h"
#import "Themes.h"

@implementation ThemesPrefs

- (id)init
{
  NSString *imagePath;
  
  self = [super init];
  
  bundle = [NSBundle bundleForClass:[self class]];
  imagePath = [bundle pathForResource:@"Themes" ofType:@"tiff"];
  image = [[NSImage alloc] initWithContentsOfFile:imagePath];
  
  return self;
}

- (void)dealloc
{
  NSLog(@"ThemesPrefs -dealloc");
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [image release];
  [selectedTheme release];

  if (view) [view release];
  
  [super dealloc];
}

- (void)awakeFromNib
{
  [view retain];
  [window release];
}

- (NSView *)view
{
  if (view == nil)
    {
      if (![NSBundle loadNibNamed:@"Themes" owner:self])
        {
          NSLog (@"Themes.preferences: Could not load NIB, aborting.");
          return nil;
        }
    }
  [self mainViewDidLoad];

  return view;
}

- (NSString *)buttonCaption
{
  return @"Themes Preferences";
}

- (NSImage *)buttonImage
{
  return image;
}

- (void)mainViewDidLoad
{
  NSButtonCell	*proto;

  proto = [[NSButtonCell alloc] init];
  [proto setBordered: NO];
  [proto setAlignment: NSCenterTextAlignment];
  [proto setImagePosition: NSImageAbove];
  [proto setSelectable: NO];
  [proto setEditable: NO];

  [matrix setPrototype: proto];
  [proto release];
  [matrix renewRows:1 columns:1];
  [matrix setAutosizesCells: NO];
  [matrix setCellSize: NSMakeSize(72,72)];
  [matrix setIntercellSpacing: NSMakeSize(8,8)];
  [matrix setAutoresizingMask: NSViewNotSizable];
  [matrix setMode: NSRadioModeMatrix];
  [matrix setAction: @selector(changeSelection:)];
  [matrix setTarget: self];

  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
 NSMutableDictionary* domain = [[defaults persistentDomainForName:NSGlobalDomain] mutableCopy];

  [scrollByPage setState:[[domain valueForKey:@"GSScrollerScrollsByPage"]boolValue]];

  [self loadThemes:self];
}

- (void) configWM: (id)sender
{
  NSWorkspace *ws = [NSWorkspace sharedWorkspace];
  [ws launchApplication:@"WPrefs.app"];
}

- (void) changeOption: (id)sender
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary* domain = [[defaults persistentDomainForName:NSGlobalDomain] mutableCopy];

  if (sender == scrollByPage) {
    [domain setValue:[NSNumber numberWithBool:[scrollByPage state]] forKey:@"GSScrollerScrollsByPage"];
  }

  [defaults setPersistentDomain:domain forName:@"NSGlobalDomain"];
  [defaults synchronize];
}

- (void) changeSelection: (id)sender
{
  NSButtonCell	*cell = [sender selectedCell];
  NSString	*name = [cell title];
  NSArray       *authors;
  NSString      *authorsString;
  NSString      *license;
  NSImage       *previewImage;
  NSString      *themeDetails;
  NSString	    *previewPath;
  NSString	    *bundlePath;

  [selectedTheme release];
  selectedTheme = [[GSTheme loadThemeNamed: name] retain];

  [nameField setStringValue: name];
  authors = [selectedTheme authors];

  authorsString = @"";
  if ([authors count] > 0)
    authorsString = [authors componentsJoinedByString: @"\n"];
  [versionField setStringValue: [selectedTheme versionString]];
  license = [selectedTheme license];
  if (license == nil)
    license = @"";
  [licenseField setStringValue:license];

  themeDetails = [[[selectedTheme bundle] infoDictionary] objectForKey:@"GSThemeDetails"];
  if (themeDetails == nil)
    themeDetails = @"";

  themeDetails = [NSString stringWithFormat:@"%@\nauthors:\n%@", themeDetails, authorsString];
  [detailsView setString:themeDetails];

  if (YES == [[selectedTheme name] isEqualToString: @"GNUstep"])
    {
      previewPath = [bundle pathForResource: @"gnustep_preview_128" ofType: @"tiff"];  
      bundlePath = nil;
    }
  else
    {
      previewPath = [[selectedTheme infoDictionary]
	objectForKey: @"GSThemePreview"];
      bundlePath = [[selectedTheme bundle] bundlePath];
      if (nil != previewPath)
	{
          previewPath = [[selectedTheme bundle]
	    pathForResource: previewPath ofType: nil];  
	}
    }
  if (previewPath == nil)
    {
      previewPath = [bundle pathForResource: @"no_preview" ofType: @"tiff"];  
    }
  previewImage = [[NSImage alloc] initWithContentsOfFile:previewPath];
  [previewImage autorelease];
  [previewView setImage: previewImage];
  [pathField setStringValue:bundlePath?bundlePath:@""];
}

- (IBAction)open: (id)sender
{
  NSString* bundlePath = [[selectedTheme bundle] bundlePath];
  if (bundlePath)
    {
      [[NSWorkspace sharedWorkspace] selectFile:bundlePath inFileViewerRootedAtPath:@"/"];
    }
}
- (IBAction)apply:(id)sender
{
  [GSTheme setTheme: [GSTheme loadThemeNamed: [nameField stringValue]]];
}

- (IBAction)save:(id)sender
{
  NSUserDefaults      *defaults;
  NSMutableDictionary *domain;
  NSString            *themeName;

  defaults = [NSUserDefaults standardUserDefaults];
  domain = [NSMutableDictionary dictionaryWithDictionary: [defaults persistentDomainForName: NSGlobalDomain]];
  themeName = [nameField stringValue];

  if ([themeName isEqualToString:@"GNUstep"] == YES)
    [domain removeObjectForKey:@"GSTheme"];
  else
    [domain setObject:themeName
               forKey: @"GSTheme"];
  [defaults setPersistentDomain: domain forName: NSGlobalDomain];
}


- (void) loadThemes: (id)sender
{
  NSArray		*array;
  GSTheme		*theme = [GSTheme loadThemeNamed: @"GNUstep.theme"];

  /* Avoid [NSMutableSet set] that confuses GCC 3.3.3.  It seems to confuse
   * this static +(id)set method with the instance -(void)set, so it would
   * refuse to compile saying
   * GSTheme.m:1565: error: void value not ignored as it ought to be
   */
  NSMutableSet		*set = AUTORELEASE([NSMutableSet new]);

  NSString		*selected = RETAIN([[matrix selectedCell] title]);
  unsigned		existing = [[matrix cells] count];
  NSFileManager		*mgr = [NSFileManager defaultManager];
  NSEnumerator		*enumerator;
  NSString		*path;
  NSString		*name;
  NSButtonCell		*cell;
  unsigned		count = 0;

  /* Ensure the first cell contains the default theme.
   */
  cell = [matrix cellAtRow: count++ column: 0];
  [cell setImage: [theme icon]];
  [cell setTitle: [theme name]];

  /* Go through all the themes in the standard locations and find their names.
   */
  enumerator = [NSSearchPathForDirectoriesInDomains
    (NSAllLibrariesDirectory, NSAllDomainsMask, YES) objectEnumerator];
  while ((path = [enumerator nextObject]) != nil)
    {
      NSEnumerator	*files;
      NSString		*file;

      path = [path stringByAppendingPathComponent: @"Themes"];
      files = [[mgr directoryContentsAtPath: path] objectEnumerator];
      while ((file = [files nextObject]) != nil)
        {
	  NSString	*ext = [file pathExtension];

	  name = [file stringByDeletingPathExtension];
	  if ([ext isEqualToString: @"theme"] == YES
	    && [name isEqualToString: @"GNUstep"] == NO
	    && [[name pathExtension] isEqual: @"backup"] == NO)
	    {
	      [set addObject: name];
	    }
	}
    }

  /* Sort theme names alphabetically, and add each theme to the matrix.
   */
  array = [[set allObjects] sortedArrayUsingSelector:
    @selector(caseInsensitiveCompare:)];
  enumerator = [array objectEnumerator];
  while ((name = [enumerator nextObject]) != nil)
    {
      GSTheme	*loaded;

      loaded = [GSTheme loadThemeNamed: name];
      if (loaded != nil)
	{
	  if (count >= existing)
	    {
	      [matrix addRow];
	      existing++;
	    }
	  cell = [matrix cellAtRow: count column: 0];
	  [cell setImage: [loaded icon]];
	  [cell setTitle: [loaded name]];
	  count++;
	}
    }

  /* Empty any unused cells.
   */
  while (count < existing)
    {
      cell = [matrix cellAtRow: count column: 0];
      [cell setImage: nil];
      [cell setTitle: @""];
      count++;
    }

  /* Restore the selected cell.
   */
  array = [matrix cells];
  count = [array count];
  while (count-- > 0)
    {
      cell = [matrix cellAtRow: count column: 0];
      if ([[cell title] isEqual: selected])
        {
	  [matrix selectCellAtRow: count column: 0];
	  break;
	}
    }
  RELEASE(selected);
  [matrix sizeToCells];
  [matrix setNeedsDisplay: YES];
}

@end

/* -*- mode: objc -*- */
//
// Project: Preferences
//
// Copyright (C) 2014-2019 Sergii Stoian
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

#import <DesktopKit/NXTDefaults.h>
#import <DesktopKit/NXTNumericField.h>

#import <SystemKit/OSEScreen.h>
#import <SystemKit/OSEDisplay.h>

#import "AppController.h"
#import "Display.h"

@implementation DisplayPrefs

- (id)init
{
  NSBundle *bundle;
  NSString *imagePath;
  
  self = [super init];
  
  bundle = [NSBundle bundleForClass:[self class]];
  imagePath = [bundle pathForResource:@"Monitor" ofType:@"tiff"];
  image = [[NSImage alloc] initWithContentsOfFile:imagePath];
  
  return self;
}

- (void)dealloc
{
  NSLog(@"DisplayPrefs -dealloc");
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [image release];

  if (view) [view release];
  if (systemScreen) [systemScreen release];
  if (saveConfigTimer) [saveConfigTimer release];
  
  [super dealloc];
}

- (void)awakeFromNib
{
  [view retain];
  [window release];

  systemScreen = [OSEScreen new];
  [systemScreen setUseAutosave:YES];

  NXTDefaults *defs = [NXTDefaults globalUserDefaults];

  // Setup NXNumericField float constraints
  [gammaField setMinimumValue:0.1];
  [gammaField setMaximumValue:2.0];
  [[gammaField formatter] setMinimumIntegerDigits:1];
  [[gammaField formatter] setMinimumFractionDigits:2];

  // Setup NXNumericField integer constraints
  [brightnessField setMinimumValue:0.5];
  [brightnessField setMaximumValue:100.0];
  
  [monitorsList loadColumnZero];
  [self selectFirstEnabledMonitor];
  
  [rotationBtn setEnabled:NO];
  [reflectionBtn setEnabled:NO];

  // Desktop background
  /*
  BOOL managedExternally = [[defs objectForKey:@"DoNotManageDesktopBackground"] boolValue];
  [managedBackgroundBtn setState:managedExternally];
  [colorBtn setEnabled:!managedExternally];

  CGFloat red, green, blue;
  if ([systemScreen backgroundColorRed:&red green:&green blue:&blue] == YES)
    {
      desktopBackground = [NSColor colorWithDeviceRed:red
                                                green:green
                                                 blue:blue
                                                alpha:1.0];
      [colorBtn setColor:desktopBackground];
      if (!managedExternally) {
        [systemScreen setBackgroundColorRed:red
                                      green:green
                                       blue:blue];
      }
    }
  */

  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(screenDidUpdate:)
           name:OSEScreenDidUpdateNotification
         object:systemScreen];

  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(screenDidUpdate:)
           name:OSEDisplayDidUpdateNotification
         object:nil];
}

- (NSView *)view
{
  if (view == nil)
    {
      if (![NSBundle loadNibNamed:@"Display" owner:self])
        {
          NSLog (@"Display.preferences: Could not load NIB, aborting.");
          return nil;
        }
    }

  return view;
}

- (NSString *)buttonCaption
{
  return @"Display Preferences";
}

- (NSImage *)buttonImage
{
  return image;
}

//
// Helper methods
//
- (void)fillRateButton
{
  NSString     *resBtnTitle = [resolutionBtn titleOfSelectedItem];
  NSArray      *m = [selectedDisplay allResolutions];
  NSString     *rateString;
  NSDictionary *res;
  NSString     *resTitle;
  NSSize       size;

  [rateBtn removeAllItems];
  NSInteger i;
  for (i = 0; i < [m count]; i++)
    {
      res = [m objectAtIndex:i];
      size = NSSizeFromString([res objectForKey:@"Size"]);
      resTitle = [NSString stringWithFormat:@"%.0fx%.0f",
                           size.width, size.height];
      if ([resTitle isEqualToString:resBtnTitle])
        {
          rateString = [NSString stringWithFormat:@"%.1f Hz",
                               [[res objectForKey:@"Rate"] floatValue]];
          [rateBtn addItemWithTitle:rateString];
          [[rateBtn itemWithTitle:rateString] setRepresentedObject:res];
        }
    }

  [rateBtn setEnabled:([[rateBtn itemArray] count] == 1) ? NO : YES];
}

- (void)setResolution
{
  // Set resolution only to active display.
  // Display activating implemented in 'Screen' Preferences' module.
  if ([selectedDisplay isActive])
    {
      [systemScreen setDisplay:selectedDisplay
                    resolution:[[rateBtn selectedCell] representedObject]];

      [self performSelector:@selector(saveLayoutConfig) 
                 withObject:nil
                 afterDelay:3.0];
    }
}

- (void)selectFirstEnabledMonitor
{
  NSArray *cells = [[monitorsList matrixInColumn:0] cells];

  int i;
  for (i = 0; i < [cells count]; i++)
    {
      if ([[cells objectAtIndex:i] isEnabled] == YES)
        {
          [monitorsList selectRow:i inColumn:0];
          break;
        }
    }
  
  [self monitorsListClicked:monitorsList];
}

- (void)saveDisplayConfig
{
  NSLog(@"Display: save current Display.confg");
  [systemScreen saveCurrentDisplayLayout];

  NXTDefaults *defs = [NXTDefaults globalUserDefaults];
  if ([selectedDisplay isDisplayBrightnessSupported]) 
    {
      [defs setObject:[NSNumber numberWithInt:[brightnessField intValue]] forKey:OSEDisplayBrightnessKey];
    }
  else
    {
      [defs removeObjectForKey:OSEDisplayBrightnessKey];
    }
}

- (void)saveLayoutConfig
{
  NSString* initrc = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"apply_config"];
  NSLog(@"Exec apply_config %@ layout", initrc);
  [NSTask launchedTaskWithLaunchPath:initrc arguments:[NSArray arrayWithObject:@"layout"]];
}

//
// Action methods
//
- (IBAction)monitorsListClicked:(id)sender
{
  NSArray      *m;
  NSSize       size;
  NSString     *resolution;
  NSDictionary *r;
  NSTimeInterval d = [[NSDate date] timeIntervalSinceReferenceDate] - lastChange;

  selectedDisplay = [[sender selectedCell] representedObject];
  m = [selectedDisplay allResolutions];
  // NSLog(@"Display.preferences: selected monitor with title: %@", mName);

  // Resolution
  [resolutionBtn removeAllItems];
  for (NSDictionary *res in m)
    {
      size = NSSizeFromString([res objectForKey:@"Size"]);
      resolution = [NSString stringWithFormat:@"%.0fx%.0f",
                             size.width, size.height];
      [resolutionBtn addItemWithTitle:resolution];
    }
  r = [selectedDisplay activeResolution];
  size = NSSizeFromString([r objectForKey:@"Size"]);
  resolution = [NSString stringWithFormat:@"%.0fx%.0f",
                         size.width, size.height];
  [resolutionBtn selectItemWithTitle:resolution];
  // Rate button filled here. Items tagged with resolution description
  // object in [NSDisplay allModes] array
  [self fillRateButton];

  if ([selectedDisplay isGammaSupported] == YES)
    {
      [gammaSlider setEnabled:YES];
      [gammaField setEnabled:YES];
      [brightnessSlider setEnabled:YES];
      [brightnessField setEnabled:YES];
      // Contrast
      NSString *gammaString = [NSString stringWithFormat:@"%.2f",
                                        [selectedDisplay gamma]];
      [gammaSlider setFloatValue:[gammaString floatValue]];
      [gammaField setStringValue:gammaString];

      if ([selectedDisplay isDisplayBrightnessSupported] == NO)
        { 
          // Brightness
          CGFloat brightness = [selectedDisplay gammaBrightness];
          [brightnessSlider setFloatValue:brightness * 100];
          [brightnessField
            setStringValue:[NSString stringWithFormat:@"%.0f", brightness * 100]];
        }
    }
  else
    {
      [gammaSlider setEnabled:NO];
      [gammaField setEnabled:NO];
      [brightnessSlider setEnabled:NO];
      [brightnessField setEnabled:NO];
    }

  if ([selectedDisplay isDisplayBrightnessSupported] == YES && d > 0.5) 
    {
      // Display Brightness
      CGFloat brightness = [selectedDisplay displayBrightness];
      [brightnessSlider setFloatValue:floor(brightness)];
      [brightnessField
        setStringValue:[NSString stringWithFormat:@"%.0f", floor(brightness)]];
    }
}

- (IBAction)resolutionClicked:(id)sender
{
  [self fillRateButton];
  NSLog(@"resolutionClicked: Selected resolution: %@",
        [[rateBtn selectedCell] representedObject]);
  
  [self performSelector:@selector(setResolution)
             withObject:nil
             afterDelay:0.1];
}

- (IBAction)rateClicked:(id)sender
{
  [self performSelector:@selector(setResolution)
             withObject:nil
             afterDelay:0.1];

  NSLog(@"rateClicked: Selected resolution: %@",
        [[rateBtn selectedCell] representedObject]);
}

- (IBAction)sliderMoved:(id)sender
{
  CGFloat value = [sender floatValue];

  if (saveConfigTimer && [saveConfigTimer isValid])
    [saveConfigTimer invalidate];

  saveConfigTimer = [NSTimer
                      scheduledTimerWithTimeInterval:2
                                              target:self
                                            selector:@selector(saveDisplayConfig)
                                            userInfo:nil
                                             repeats:NO];
  [saveConfigTimer retain];
  
  if (sender == gammaSlider) 
    {
      // NSLog(@"Gamma slider moved");
      [gammaField setStringValue:[NSString stringWithFormat:@"%.2f", value]];
      [selectedDisplay setGamma:value];
    }
  else if (sender == brightnessSlider)
    {
      // NSLog(@"Brightness slider moved %f", value);
      if (value > 100) 
        value = 100;

      [brightnessField setIntValue:[sender intValue]];

      [NSObject cancelPreviousPerformRequestsWithTarget:self];
      [self performSelector:@selector(__updateDisplayBrigthness:)
                 withObject:[NSNumber numberWithFloat:value]
                 afterDelay:0.2];
    }
  else 
    {
      NSLog(@"Unknown slider moved");
    }
}

- (IBAction)managedBackgroundChanged:(id)sender
{
  BOOL managedExternally = [sender state];
  [colorBtn setEnabled:!managedExternally];
  NXTDefaults *defs = [NXTDefaults globalUserDefaults];
  [defs setObject:[NSNumber numberWithBool:managedExternally] forKey:@"DoNotManageDesktopBackground"];
}

- (IBAction)backgroundChanged:(id)sender
{
  NSColor *color = [sender color];
  NSColor *rgbColor = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    
  // NSLog(@"Display: backgroundChanged: %@", [sender className]);
  /*
  if ([systemScreen setBackgroundColorRed:[rgbColor redComponent]
                                    green:[rgbColor greenComponent]
                                     blue:[rgbColor blueComponent]] == YES) {
    NXTDefaults   *defs = [NXTDefaults globalUserDefaults];
    NSDictionary *dBack;

    dBack = [NSDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithFloat:[color redComponent]],@"Red",
              [NSNumber numberWithFloat:[color greenComponent]],@"Green",
              [NSNumber numberWithFloat:[color blueComponent]],@"Blue",
              [NSNumber numberWithFloat:1.0],@"Alpha",nil];
    [defs setObject:dBack forKey:OSEDesktopBackgroundColor];
  }
  */
}

//
// Browser (list of monitors) delegate methods
//
- (NSString *)browser:(NSBrowser *)sender titleOfColumn:(NSInteger)column
{
  if (column > 0)
    return @"";

  return @"Monitors";
}

- (void)     browser:(NSBrowser *)sender
 createRowsForColumn:(NSInteger)column
            inMatrix:(NSMatrix *)matrix
{
  NSBrowserCell *bc;

  if (column > 0)
    return;

  for (OSEDisplay *d in [systemScreen connectedDisplays])
    {
      [matrix addRow];
      bc = [matrix cellAtRow:[matrix numberOfRows]-1 column:0];
      [bc setTitle:[d outputName]];
      [bc setRepresentedObject:d];
      [bc setLeaf:YES];
      [bc setRefusesFirstResponder:YES];
      [bc setEnabled:[d isActive]];
    }
}

//
// TextField Delegate methods
//
- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
  id      tf = [aNotification object];
  CGFloat value = [tf floatValue];

  NSLog(@"Display set gamma: %f", value);

  if (tf == gammaField)
    {
      [gammaSlider setFloatValue:value];
      [selectedDisplay setGamma:value];
      [tf setFloatValue:value];
    }
  else if (tf == brightnessField)
    {
      if ([selectedDisplay isDisplayBrightnessSupported]) 
        {
          [selectedDisplay setDisplayBrightness:value];
          value = [selectedDisplay displayBrightness];
          [brightnessSlider setFloatValue:value];
          [tf setFloatValue:value];
        }
      else
        {
          [selectedDisplay setGammaBrightness:value/100];
          value = [selectedDisplay gammaBrightness]*100;
          [brightnessSlider setFloatValue:value];
          [tf setFloatValue:value];
        }
    }

  // Changes to gamma is not generate XRRScreenChangeNotify event.
  // That's why saving display configuration is here.
  if (saveConfigTimer && [saveConfigTimer isValid])
    [saveConfigTimer invalidate];

  saveConfigTimer = [NSTimer
                      scheduledTimerWithTimeInterval:2
                                              target:self
                                            selector:@selector(saveDisplayConfig)
                                            userInfo:nil
                                             repeats:NO];
  [saveConfigTimer retain];
}

// Notifications
- (void)screenDidUpdate:(NSNotification *)aNotif
{
  NSLog(@"Display: XRandR screen resources was updated, refreshing...");
  [monitorsList reloadColumn:0];
  [self selectFirstEnabledMonitor];
}

//
// Utility methods
//

- (void)__updateDisplayBrigthness:(NSNumber *)value
{
  lastChange = [[NSDate date] timeIntervalSinceReferenceDate];
  if ([selectedDisplay isDisplayBrightnessSupported])
    {
      [selectedDisplay setDisplayBrightness:[value floatValue]];
    }
  else
    {
      [selectedDisplay setGammaBrightness:[value floatValue]/100];
    }

}

@end

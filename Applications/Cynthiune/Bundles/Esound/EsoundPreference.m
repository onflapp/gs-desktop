/* EsoundPreference.m - this file is part of Cynthiune
 *
 * Copyright (C) 2004 Wolfgang Sourdeau
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

#import <AppKit/NSBox.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSDictionary.h>

#import <Cynthiune/CynthiuneBundle.h>
#import <Cynthiune/Output.h>
#import <Cynthiune/Preference.h>
#import <Cynthiune/utils.h>

#import "Esound.h"
#import "EsoundPreference.h"

#define LOCALIZED(X) _b ([Esound class], X)

@implementation EsoundPreference : NSObject

// Preference protocol
+ (id) instance
{
  static EsoundPreference *singleton = nil;

  if (!singleton)
    singleton = [[self alloc] _init];

  return singleton;
}

- (EsoundPreference *) _init
{
  NSDictionary *tmpDict;

  if ((self = [super init]))
    {
      tmpDict = [[NSUserDefaults standardUserDefaults]
                  dictionaryForKey: @"Esound"];
      preference = [NSMutableDictionary dictionaryWithDictionary: tmpDict];
      [preference retain];
    }

  return self;
}

- (NSView *) preferenceSheet
{
  NSView *aView;

  [NSBundle loadNibNamed: @"EsoundPreferences"
            owner: self];
  aView = [prefsWindow contentView];
  [aView retain];
  [aView removeFromSuperview];
  [prefsWindow release];
  [aView autorelease];

  return aView;
}

- (void) _initDefaults
{
  NSString *socketType, *tcpHost, *tcpPort;
  static BOOL initted = NO;

  if (!initted)
    {
      socketType = [preference objectForKey: @"socketType"];
      if (!socketType)
        {
          socketType = @"UNIX";
          [preference setObject: socketType
                      forKey: @"socketType"];
        }

      tcpHost = [preference objectForKey: @"tcpHostname"];
      if (!tcpHost)
        {
          tcpHost = @"localhost";
          [preference setObject: tcpHost
                  forKey: @"tcpHostname"];
        }
      tcpPort = [preference objectForKey: @"tcpPort"];
      if (!tcpPort)
        {
          tcpPort = @"16001";
          [preference setObject: tcpPort
                      forKey: @"tcpPort"];
        }
      initted = YES;
    }
}

- (void) awakeFromNib
{
  [self _initDefaults];

  [connectionTypeBox setTitle: LOCALIZED (@"Connection type")];
  [tcpOptionsBox setTitle: LOCALIZED (@"TCP options")];
  [unixBtn setTitle: LOCALIZED (@"UNIX socket")];
  [tcpBtn setTitle: LOCALIZED (@"TCP socket")];
  [hostLabel setStringValue: LOCALIZED (@"Hostname (or IP)")];
  [portLabel setStringValue: LOCALIZED (@"Port")];

  if ([[preference objectForKey: @"socketType"] isEqualToString: @"UNIX"])
    [self selectUnixBtn: self];
  else    
    [self selectTcpBtn: self];

  [hostField setStringValue: [preference objectForKey: @"tcpHostname"]];
  [portField setStringValue: [preference objectForKey: @"tcpPort"]];
}

- (NSString *) preferenceTitle
{
  return @"Esound"; 
}

- (void) save
{
  NSUserDefaults *defaults;

  defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject: preference
            forKey: @"Esound"];
  [defaults synchronize];
}

- (BOOL) socketIsTCP
{
  NSString *socketType;

  [self _initDefaults];

  socketType = [preference objectForKey: @"socketType"];
  return [socketType isEqualToString: @"TCP"];
}

- (NSString *) tcpHostConnectString
{
  [self _initDefaults];

  return [NSString stringWithFormat: @"%@:%@",
                   [preference objectForKey: @"tcpHostname"],
                   [preference objectForKey: @"tcpPort"]];
}

- (void) selectUnixBtn: (id) sender
{
  NSColor *disabledColor;

  disabledColor = [NSColor controlBackgroundColor];
  [unixBtn setState: 1];
  [tcpBtn setState: 0];
  [hostField setEditable: NO];
  [portField setEditable: NO];
  [hostField setBackgroundColor: disabledColor];
  [portField setBackgroundColor: disabledColor];
  [portField display];
  [hostField display];

  [preference setObject: @"UNIX" forKey: @"socketType"];
}

- (void) selectTcpBtn: (id) sender
{
  NSColor *enabledColor;

  enabledColor = [NSColor textBackgroundColor];
  [unixBtn setState: 0];
  [tcpBtn setState: 1];
  [hostField setEditable: YES];
  [portField setEditable: YES];
  [hostField setBackgroundColor: enabledColor];
  [portField setBackgroundColor: enabledColor];
  [portField display];
  [hostField display];

  [preference setObject: @"TCP"
              forKey: @"socketType"];
}

- (void) controlTextDidEndEditing: (NSNotification *) notification
{
  id object;
  NSString *prefKey;

  object = [notification object];
  if (object == hostField)
    prefKey = @"tcpHostname";
  else if (object == portField)
    prefKey = @"tcpPort";
  else
    prefKey = @"";

  [preference setObject: [object stringValue]
              forKey: prefKey];
}

@end

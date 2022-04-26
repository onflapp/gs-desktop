/*
**  CWSendmail.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <Pantomime/CWSendmail.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWMessage.h>
#import <Pantomime/NSFileManager+Extensions.h>
#import <Pantomime/NSString+Extensions.h>

#import <Foundation/NSFileHandle.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSTask.h>

#include <stdio.h>


//
// Sendmail's private interface
//
@interface CWSendmail (Private)

- (void) _fail;
- (void) _taskDidTerminate: (NSNotification *) theNotification;

@end


//
//
//
@implementation CWSendmail

- (id) initWithPath: (NSString *) thePath;
{
  self = [super init];
  if (self)
    {
      [self setPath: thePath];
  
      _delegate = nil;
    }
  
  return self;
}

- (void) dealloc
{
  RELEASE(_message);
  RELEASE(_data);
  RELEASE(_recipients);
  RELEASE(_path);  

  [super dealloc];
}



//
// access / mutation methods
//
- (void) setDelegate: (id) theDelegate
{
  _delegate = theDelegate;
}

- (id) delegate
{
  return _delegate;
}


//
//
//
- (void) setPath: (NSString *) thePath
{
  ASSIGN(_path, [thePath stringByTrimmingWhiteSpaces]);
}

- (NSString *) path
{
  return _path;
}



//
//
//
- (void) setMessage: (CWMessage *) theMessage
{
  ASSIGN(_message, theMessage);
}

- (CWMessage *) message
{
  return _message;
}


//
//
//
- (void) setMessageData: (NSData *) theData
{
  ASSIGN(_data, theData);
}

- (NSData *) messageData
{
  return _data;
}


//
// That does nothing but we keep it if a developer wanna
// use that ivar.
//
- (void) setRecipients: (NSArray *) theRecipients
{
  ASSIGN(_recipients, [NSMutableArray arrayWithArray: theRecipients]);
}

- (NSArray *) recipients
{
  return _recipients;
}


//
//
//
- (void) sendMessage
{
  NSString *aString, *aFilename;
  NSFileHandle *aFileHandle;
  NSRange aRange; 
  NSTask *aTask;
 
  if ((!_message && !_data) || !_path)
    {
      [self _fail];
      return;
    }

  if (!_data && _message)
    {
      [self setMessageData: [_message dataValue]];
    }

  // We verify if _pathToSendmail is a valid one (ie., readable and executable)
  aRange = [_path rangeOfString: @" "];
  aString = _path;
  
  if (aRange.location != NSNotFound)
    {
      aString = [_path substringToIndex: aRange.location];
    }

  if (![[NSFileManager defaultManager] isExecutableFileAtPath: aString])
    {
      [self _fail];
      return;
    }

  // We now create our task and send the message
  aFilename = [NSString stringWithFormat: @"%@/%d_%@", NSTemporaryDirectory(), 
			[[NSProcessInfo processInfo] processIdentifier],
			NSUserName()];
  
  if (![_data writeToFile: aFilename  atomically: YES])
    {
      [self _fail];
      return;
    }
  
  [[NSFileManager defaultManager] enforceMode: 0600  atPath: aFilename];
  aFileHandle = [NSFileHandle fileHandleForReadingAtPath: aFilename];
  aTask = [[NSTask alloc] init];
  
  // We register for our notification
  [[NSNotificationCenter defaultCenter] 
    addObserver: self
    selector: @selector(_taskDidTerminate:)
    name: NSTaskDidTerminateNotification
    object: aTask];

  // We build our right string
  aString = [_path stringByTrimmingWhiteSpaces];
      
  // We verify if our program to launch has any arguments
  aRange = [aString rangeOfString: @" "];
  
  if (aRange.length)
    {
      [aTask setLaunchPath: [aString substringToIndex: aRange.location]];      
      [aTask setArguments: [[aString substringFromIndex: (aRange.location + 1)] 
			     componentsSeparatedByString: @" "]];
    }
  else
    {
      [aTask setLaunchPath: aString];
    }
  
  [aTask setStandardInput: aFileHandle];
  
  // We launch our task
  [aTask launch];
  
  [aFileHandle closeFile];
  
  [[NSFileManager defaultManager] removeFileAtPath: aFilename
				  handler: nil];
}

@end


//
//
//
@implementation CWSendmail (Private)

- (void) _fail
{
  if (_message)
    POST_NOTIFICATION(PantomimeMessageNotSent, self,
		[NSDictionary dictionaryWithObject: _message  forKey: @"Message"]);
  else
    POST_NOTIFICATION(PantomimeMessageNotSent, self,
		[NSDictionary dictionaryWithObject: AUTORELEASE([CWMessage new])  forKey: @"Message"]);
  PERFORM_SELECTOR_1(_delegate, @selector(messageNotSent:), PantomimeMessageNotSent);
}

- (void) _taskDidTerminate: (NSNotification *) theNotification
{
  // We first unregister ourself for the notification
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  if ([[theNotification object] terminationStatus] == 0)
    {
      POST_NOTIFICATION(PantomimeMessageSent, self,
	[NSDictionary dictionaryWithObject: _message  forKey: @"Message"]);
      PERFORM_SELECTOR_2(_delegate,
	@selector(messageSent:), PantomimeMessageSent, _message, @"Message");
    }
  else
    {
      [self _fail];
    }
}

@end

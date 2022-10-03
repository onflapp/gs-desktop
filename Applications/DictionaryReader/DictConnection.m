/* -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "DictConnection.h"
#import "GNUstep.h"

#import "NSString+Clickable.h"
#import "NSString+DictLineParsing.h"

// easier logging
#define LOG(format, args...) \
	[self log: [NSString stringWithFormat: format, ##args]];


@implementation DictConnection


/**
 * Initialises the DictionaryHandle from the property list aPropertyList.
 */
-(id) initFromPropertyList: (NSDictionary*) aPropertyList
{
    NSAssert1([aPropertyList objectForKey: @"host"] != nil,
              @"No entry for 'host' key in NSDictionary %@", aPropertyList);
    NSAssert1([aPropertyList objectForKey: @"port"] != nil,
              @"No entry for 'host' key in NSDictionary %@", aPropertyList);
    
    if ((self = [super initFromPropertyList: aPropertyList]) != nil) {
        self = [self initWithHost: [aPropertyList objectForKey: @"host"]
                             port: [[aPropertyList objectForKey: @"port"] intValue]];
    }
    
    return self;
}

-(id)initWithHost: (NSHost*) aHost
	     port: (int) aPort
{
  if (self = [super init]) {
    if (aHost == nil) {
        [self release];
        return nil;
    }
    
    ASSIGN(host, aHost);
    port = aPort;
    
    reader = nil;
    writer = nil;
    inputStream = nil;
    outputStream = nil;
    defWriter = nil;
  }
  
  return self;
}

-(id)initWithHost: (NSHost*) aHost
{
  return [self initWithHost: aHost
	       port: 2628];
}

-(id)init
{
  NSString
    *hostname = nil;
  
  hostname = [[NSUserDefaults standardUserDefaults] objectForKey: @"Dict Server"];
  
  if (hostname == nil)
    hostname = @"dict.org";
  
  return [self initWithHost: [NSHost hostWithName: hostname]];
}

-(void)dealloc
{
  // first close connection, if open
  [self close];
  
  [reader release];
  [writer release];
  [inputStream release];
  [outputStream release];
  [host release];
  
  [super dealloc];
}

-(void) sendClientString: (NSString*) clientName
{
  LOG(@"Sending client String: %@", clientName);
  
  [writer writeLine:
	    [NSString stringWithFormat: @"client \"%@\"\r\n",
		      clientName]];
  
  NSString* answer = [reader readLineAndRetry];
  
  if (![answer hasPrefix: @"250"]) {
    LOG(@"Answer not accepted?: %@", answer);
  }
}

-(void) handleDescription
{
  [self showError: @"Retrieval of server descriptions not implemented yet."];
}
  
-(void) descriptionForDatabase: (NSString*) aDatabase
{
  [self showError: @"Database description retrieval not implemented yet."];
}

-(void) definitionFor: (NSString*) aWord
         inDictionary: (NSString*) aDict
{
  NSMutableString* result = [NSMutableString stringWithCapacity: 100];
  
  [writer writeLine:
	    [NSString stringWithFormat: @"define %@ \"%@\"\r\n",
		      aDict, aWord]];
  
  
  NSString* answer = [reader readLineAndRetry];
  
  if ([answer hasPrefix: @"552"]) { // word not found
    [defWriter writeHeadline:
		 [NSString stringWithFormat: @"No results from %@", self]];
  } else if ([answer hasPrefix: @"550"]) {
    [self
      showError: [NSString stringWithFormat: @"Invalid database: %@", aDict]];
  } else if ([answer hasPrefix: @"150"]) { // got results
    BOOL lastDefinition = NO;
    do {
      answer = [reader readLineAndRetry];
      if ([answer hasPrefix: @"151"]) {
	[defWriter writeHeadline:
		     [NSString stringWithFormat: @"From %@:",
			       [answer dictLineComponent: 3]]
	 ];
	
	// TODO: Extract database information here!
	//[defWriter writeHeadline: [answer substringFromIndex: 4]];
	
	BOOL lastLine = NO;
	do {
	  answer = [reader readLineAndRetry];
	  if ([answer isEqualToString: @"."]) {
	    lastLine = YES;
	  } else { // wow, actual text! ^^
	    [defWriter writeLine: answer];
	  }
	} while (lastLine == NO);
      } else {
	lastDefinition = YES;
	if (![answer hasPrefix: @"250"]) {
	  [self showError: answer];
	}
      }
    } while (lastDefinition == NO);
  }
}

-(void) definitionFor: (NSString*) aWord
{
  return [self definitionFor: aWord
	       inDictionary: @"*"];
}

-(void)open
{
  [NSStream getStreamsToHost: host
	    port: port
	    inputStream: &inputStream
	    outputStream: &outputStream];
  
  if (inputStream == nil || outputStream == nil) {
    [self log: @"open failed: cannot create input and output stream"];
    return;
  }
  
  [inputStream open];
  [outputStream open];
  
  reader = [[StreamLineReader alloc] initWithInputStream: inputStream];
  writer = [[StreamLineWriter alloc] initWithOutputStream: outputStream];
  
  if (reader == nil || writer == nil) {
    [self log: @"open failed: cannot create reader and writer"];
    return;
  }
  
  // fetch server banner
  NSString* banner = [reader readLineAndRetry];
  
  
  // interprete server banner
  if ([banner hasPrefix: @"220"]) {
    LOG(@"Server banner: %@", banner);
  } else {
    if ([banner hasPrefix: @"530"]) {
      [self showError: @"Access to server denied."];
    } else if ([banner hasPrefix: @"420"]) {
      [self showError: @"Temporarily unavailable."];
    } else if ([banner hasPrefix: @"421"]) {
      [self showError: @"Server shutting down at operator request."];
    } else {
      LOG(@"Bad banner: %@", banner);
    }
  } 
}

#warning FIXME: Crashes sometimes?
-(void)close
{
  [inputStream close];
  RELEASE(inputStream); inputStream = nil;
  
  [outputStream close];
  RELEASE(outputStream); outputStream = nil;
  
  RELEASE(reader); reader = nil;
  RELEASE(writer); writer = nil;
}

-(void) log: (NSString*) aLogMsg
{
  NSLog(@"%@", aLogMsg);
}

-(void) showError: (NSString*) aString
{
  [defWriter writeBigHeadline: [NSString stringWithFormat: @"%@ Error", self]];
  [defWriter writeLine: aString];
}

-(void) setDefinitionWriter: (id<DefinitionWriter>) aDefinitionWriter
{
  ASSIGN(defWriter, aDefinitionWriter);
}

-(NSDictionary*) shortPropertyList
{
    NSMutableDictionary* result = [super shortPropertyList];
    
    [result setObject: host forKey: @"host"];
    [result setObject: [NSNumber numberWithBool: port] forKey: @"port"];
    
    return result;
}

-(NSString*) description
{
  return [NSString stringWithFormat: @"Dictionary at %@", host];
}

@end


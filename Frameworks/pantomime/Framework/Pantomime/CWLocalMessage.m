/*
**  CWLocalMessage.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**                2018      Riccardo Mottola
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

#import <Pantomime/CWLocalMessage.h>

#import <Pantomime/io.h>
#import <Pantomime/CWConstants.h>
#import <Pantomime/CWLocalFolder.h>
#import <Pantomime/CWLocalStore.h>
#import <Pantomime/CWMIMEUtility.h>
#import <Pantomime/NSData+Extensions.h>
#import <Pantomime/CWParser.h>
#import <Pantomime/CWFlags.h>

#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>

#include <fcntl.h>  // O_RDONLY
#include <stdlib.h> // free() and malloc()
#include <unistd.h> // lseek() and close()

#ifdef __MINGW32__
#include <io.h>
#endif

static int currentLocalMessageVersion = 1;

//
//
//
@implementation CWLocalMessage

+ (void) initialize
{
  [CWLocalMessage setVersion: currentLocalMessageVersion];
}

- (id) init
{
  self = [super init];
  if (self)
    {
      _mailFilename = nil;
      _file_position = 0;
    }
  return self;
}

- (id) initWithCacheRecord: (cache_record) cr
{
  self = [super init];
    {
      _mailFilename = nil;
      
      [self flags]->flags = cr.flags;
      [self setReceivedDate: [NSCalendarDate dateWithTimeIntervalSince1970: (NSTimeInterval)cr.date]];
      _file_position = cr.position;
      _size = (unsigned long) cr.size;
      
      [CWParser parseFrom: cr.from  inMessage: self  quick: YES];
      [CWParser parseInReplyTo: cr.in_reply_to  inMessage: self  quick: YES];
      [CWParser parseMessageID: cr.message_id  inMessage: self  quick: YES];
      [CWParser parseReferences: cr.references  inMessage: self  quick: YES];
      [CWParser parseSubject: cr.subject inMessage: self  quick: YES];
      [CWParser parseDestination: cr.to
                         forType: PantomimeToRecipient
                       inMessage: self
                           quick: YES];
      [CWParser parseDestination: cr.cc
                         forType: PantomimeCcRecipient
                       inMessage: self
                           quick: YES];
    }
  return self;
}



//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder *) theCoder
{
  [super encodeWithCoder: theCoder];

  [theCoder encodeObject: [NSNumber numberWithLong: _file_position]];

  // Store the name of the file; we need it for local.
  [theCoder encodeObject: _mailFilename];

  // Store the message type; useful to have.
  [theCoder encodeObject: [NSNumber numberWithInt: _type]];
}


//
//
//
- (id) initWithCoder: (NSCoder *) theCoder
{
  self = [super initWithCoder: theCoder];

  if (self)
    {
      _file_position = [[theCoder decodeObject] longValue];

      // Retrieve the mail file name which we need for local storage.
      [self setMailFilename: [theCoder decodeObject]];
  
      // Retrieve the message type
      _type = (PantomimeFolderFormat)[[theCoder decodeObject] intValue];
    }
  return self;
}


//
// access / mutation methods
//
- (long int) filePosition
{
  return _file_position;
}

- (void) setFilePosition: (long int) theFilePosition
{
  _file_position = theFilePosition;
}

//
//
//
- (PantomimeFolderFormat) type
{
  return _type;
}

- (void) setType: (PantomimeFolderFormat) theType
{
  _type = theType;
}


//
//
//
- (NSString *) mailFilename
{
  return _mailFilename;
}

- (void) setMailFilename: (NSString *) theFilename
{	
  ASSIGN(_mailFilename, theFilename);
}


//
//
//
- (void) dealloc
{
  TEST_RELEASE(_mailFilename);
  [super dealloc];
}


//
//
//
- (NSData *) rawSource
{
  NSData *aData;
  char *buf;
  int fd;

  // If we are reading from a mbox file, the file is already open
  if ([(CWLocalFolder *)[self folder] type] == PantomimeFormatMbox)
    {
      fd = [(CWLocalFolder *)[self folder] fd];
    }
  // For maildir, we need to open the specific file
  else
    {
#ifdef __MINGW32__
      fd = _open([[NSString stringWithFormat: @"%@/cur/%@", [(CWLocalFolder *)[self folder] path], _mailFilename] UTF8String], O_RDONLY);
#else
      fd = open([[NSString stringWithFormat: @"%@/cur/%@", [(CWLocalFolder *)[self folder] path], _mailFilename] UTF8String], O_RDONLY);
#endif
    }

  if (fd < 0)
    {
      NSLog(@"Unable to get the file descriptor");
      return nil;
    }
  
  //NSLog(@"Seeking to %d", [self filePosition]);

#ifdef __MINGW32__
  if (_lseek(fd, [self filePosition], SEEK_SET) < 0)
#else  
  if (lseek(fd, [self filePosition], SEEK_SET) < 0)
#endif
    {
      NSLog(@"CWLocalMessage rawSource: Unable to seek to %li", [self filePosition]);
      return nil;
    }
  
  buf = (char *)malloc(_size*sizeof(char));

  if (buf != NULL && read_block(fd, buf, _size) >= 0)
    {
      aData = [NSData dataWithBytesNoCopy: buf  length: _size  freeWhenDone: YES];
    }
  else
    {
      free(buf);
      aData = nil;
    }
  
  // If we are operating on a local file, close it.
  if ([(CWLocalFolder *)[self folder] type] == PantomimeFormatMaildir)
    {
      safe_close(fd);
    }
  
  //NSLog(@"READ |%@|", [aData asciiString]);

  return aData;
}


//
// This method is called to initialize the message if it wasn't.
// If we set it to NO and we HAD a content, we release the content;
//
- (void) setInitialized: (BOOL) aBOOL
{
  [super setInitialized: aBOOL];

  if (aBOOL)
    {
      NSData *aData;

      aData = [self rawSource];

      if (aData)
	{
	  NSRange aRange;

	  aRange = [aData rangeOfCString: "\n\n"];
	  
	  if (aRange.length == 0)
	    {
	      [super setInitialized: NO];
	      return;
	    }

	  [self setHeadersFromData: [aData subdataWithRange: NSMakeRange(0,aRange.location)]];
	  [CWMIMEUtility setContentFromRawSource:
			   [aData subdataWithRange:
				    NSMakeRange(aRange.location + 2, [aData length]-(aRange.location+2))]
			 inPart: self];
	}
      else
	{
	  [super setInitialized: NO];
	  return;
	}
    }
  else
    {
      DESTROY(_content);
    } 
}

@end

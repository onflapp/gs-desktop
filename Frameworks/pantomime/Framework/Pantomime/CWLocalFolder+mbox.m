/*
**  CWLocalFolder+mbox.m
**
**  Copyright (c) 2004-2007 Ludovic Marcotte
**  Copyright (C) 2014-2020 Riccardo Mottola, Sebastian Reitenbach
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola
**          Sebastian Reitenbach
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

#import <Foundation/Foundation.h>

#import <Pantomime/CWLocalFolder+mbox.h>

#import <Pantomime/CWFlags.h>
#import <Pantomime/CWCacheManager.h>
#import <Pantomime/CWLocalCacheManager.h>
#import <Pantomime/CWLocalMessage.h>
#import <Pantomime/CWLocalStore.h>
#import <Pantomime/NSData+Extensions.h>
#import <Pantomime/NSString+Extensions.h>
#import <Pantomime/CWParser.h>


#ifdef __MINGW32__
#include <io.h>
#endif

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <unistd.h>

//
//
//
@implementation CWLocalFolder (mbox)

- (void) close_mbox
{
#ifndef __MINGW32__
  struct flock lock;

#ifdef __linux__
  if (flock(fd, LOCK_UN) == -1)
    {
      NSLog(@"CWLocalFolder+mbox: Could not remove advisory file lock for: %@. Rationale: %s", _path, strerror(errno));
    }
#endif

  // We remove the mandatory lock
  lock.l_type = F_UNLCK;
  lock.l_whence = SEEK_SET;
  lock.l_start = lock.l_len = 0;
  lock.l_pid = getpid();

  if (fcntl(fd, F_SETLK, &lock) == -1)
    {
      NSLog(@"CWLocalFolder+mbox: Could not remove mandatory file lock for: %@. Rationale: %s", _path, strerror(errno));
     }
#endif

  //
  // We close the stream. This will also close our file descriptor.
  //
  // fopen(3) says:
  //
  // The file descriptor is not dup'ed, and will be closed when the
  // stream created  by fdopen is closed. 
  //
  fclose(stream);
  
  stream = NULL;
  fd = -1;
}


//
//
//
- (void) expunge_mbox
{
  FILE *theInputStream, *theOutputStream;

  NSMutableArray *aMutableArray;
  CWLocalMessage *aMessage;
  CWFlags *theFlags;
  
  BOOL writeWasSuccessful, seenStatus, seenXStatus, doneWritingHeaders;
  NSString *pathToMailbox;
  
  NSUInteger i, count;
  unsigned int messageNumber;
  char aLine[1024];

  aMutableArray = AUTORELEASE([[NSMutableArray alloc] init]);

  pathToMailbox = [[_store path] stringByAppendingPathComponent: _name];
  
  // The stream is used to store (temporarily) the new local folder
#ifdef __MINGW32__
  theOutputStream = fopen([[pathToMailbox stringByAppendingPathExtension:@"tmp"] UTF8String], "ab");
#else
  theOutputStream = fopen([[pathToMailbox stringByAppendingPathExtension:@"tmp"] UTF8String], "a");
#endif
  theInputStream = [self stream];

  // We assume that our write operation was successful and we initialize our messageNumber to 1
  writeWasSuccessful = YES;
  messageNumber = 1;
  
  // We verify it the creation failed
  if (!theOutputStream)
    {
      POST_NOTIFICATION(PantomimeFolderExpungeFailed, self, nil);
      PERFORM_SELECTOR_2([[self store] delegate], @selector(folderExpungeFailed:), PantomimeFolderExpungeFailed, self, @"Folder");
      return;
    }
  
  count = [allMessages count];

  for (i = 0; i < count; i++)
    {
      aMessage = [allMessages objectAtIndex: i];
      theFlags = [aMessage flags];

      doneWritingHeaders = seenStatus = seenXStatus = NO;    
      
      if ([theFlags contain: PantomimeDeleted])
	{
	  //[(CWLocalCacheManager *)_cacheManager removeObject: aMessage];
	  [aMutableArray addObject: aMessage];
	}
      else
	{
          unsigned long size;
	  long delta, position;
	  long headers_length;
	  
	  // We get our position and headers_length
	  position = ftell(theOutputStream);
	  
	  // We seek to the beginning of the message
	  fseek(theInputStream, [aMessage filePosition], SEEK_SET);
	 
	  size = [aMessage size];
	  memset(aLine, 0, 1024);
	  
	  while (fgets(aLine, 1024, theInputStream) != NULL &&
		 (ftell(theInputStream) < ([aMessage filePosition] + (long)size)))
	    {
	      // We verify if we aren't finished reading our headers
	      if (!doneWritingHeaders)
		{
		  // We check for the "null line" (ie., end of headers)
		  if (strlen(aLine) == 1 && strcmp("\n", aLine) == 0)
		    {
		      doneWritingHeaders = YES;
		      headers_length = ftell(theOutputStream);

		      if (!seenStatus) 
			{
			  fputs([[NSString stringWithFormat: @"Status: %@\n",
					   [theFlags statusString]] cString], theOutputStream);
			}
		      
		      if (!seenXStatus) 
			{
			  fputs([[NSString stringWithFormat: @"X-Status: %@\n",
					   [theFlags xstatusString]] cString], theOutputStream);
			}

		      delta =  ftell(theOutputStream)-headers_length;

		      // Since we are done writing our headers, we update the headers_length variable
		      //headers_length = ftell(theOutputStream) - position;

		      // We adjust the size of the message since headers might have been rewritten (Status/X-Status).
		      // We need the trailing -1 to actually remove the header/content separator (a single \n).
		      //delta = headers_length - ([aMessage bodyFilePosition] - [aMessage filePosition] - 1);
		      
		      if (delta > 0)
			{
			  //NSLog(@"delta = %d", delta);
			  [aMessage setSize: (size+(unsigned long)delta)];
			}
		    }
		  
		  // If we read the Status header, we replace it with the current Status header
#warning we might need to adjust the size here too!
		  if (strncasecmp(aLine,"Status:", 7) == 0) 
		    {
		      seenStatus = YES;
		      memset(aLine, 0, 1024);
		      sprintf(aLine, "Status: %s\n", [[theFlags statusString] cString]); 
		    }
		  else if (strncasecmp(aLine,"X-Status:", 9) == 0)
		    {
		      seenXStatus = YES;
		      memset(aLine, 0, 1024);
		      sprintf(aLine, "X-Status: %s\n", [[theFlags xstatusString] cString]); 
		    }
		}
	      
	      // We write our line to our new stream
	      if (fputs(aLine, theOutputStream) < 0)
		{
		  writeWasSuccessful = NO;
		  break;
		}
	      
	      memset(aLine, 0, 1024);
	    } // while (...)
	  
	  // We add our message separator
	  if (fputs("\n", theOutputStream) < 0)
	    {
	      writeWasSuccessful = NO;
	      break;
	    }
	    
	  // We update our message's ivars
	  [aMessage setFilePosition: position];
	  //[aMessage setBodyFilePosition: (position+headers_length+1)];
	  [aMessage setMessageNumber: messageNumber];
	  
	  // We increment our messageNumber local variable
	  messageNumber++;
	}

    } // for (i = 0; i < count; i++)
  
  

  // We close our output stream
  if (fclose(theOutputStream) != 0)
    {
      writeWasSuccessful = NO;
    }
  
  //
  // We verify if the last write was successful, if yes, we remove our original mailbox
  // and we replace it by our temporary mailbox.
  //
  if (writeWasSuccessful)
    {
      // We close the current folder
      [self close_mbox];
      
      // Now that everything is alright, replace <folder name> by <folder name>.tmp
      [[NSFileManager defaultManager] removeFileAtPath: pathToMailbox
				      handler: nil];
      [[NSFileManager defaultManager] movePath: [pathToMailbox stringByAppendingPathExtension:@"tmp"]
				      toPath: pathToMailbox
				      handler: nil];
      
      // We sync our cache
      if (_cacheManager) [_cacheManager expunge];
      
      // Now we re-open our folder and update the 'allMessages' ivar in the Folder superclass
      [self open_mbox];

      [allMessages removeObjectsInArray: aMutableArray];
      //[self setMessages: [_cacheManager cache]];
    }
  
  //
  // The last write failed, let's remove our temporary file and keep the original mbox which, might
  // contains non-updated status flags or messages that have been transferred/deleted.
  //
  else
    {
      NSLog(@"Writing to %@ failed. We keep the original mailbox.", pathToMailbox);
      NSLog(@"This can be due to the fact that your partition containing this mailbox is full or that you don't have write permission in the directory where this mailbox is.");
      [[NSFileManager defaultManager] removeFileAtPath: [NSString stringWithFormat: @"%@.tmp", pathToMailbox]
				      handler: nil];
      POST_NOTIFICATION(PantomimeFolderExpungeFailed, self, nil);
      PERFORM_SELECTOR_2([[self store] delegate], @selector(folderExpungeFailed:), PantomimeFolderExpungeFailed, self, @"Folder");
      return;
    }
  
#warning also return when invoking the delegate
  POST_NOTIFICATION(PantomimeFolderExpungeCompleted, self, nil);
  PERFORM_SELECTOR_2([[self store] delegate], @selector(folderExpungeCompleted:), PantomimeFolderExpungeCompleted, self, @"Folder");
}



//
// We use fcntl(2) for locking the local mbox file.  This provides a
// mandatory, kernel-enforced lock that should work over NFS.
// However, on Linux, fcntl(2) and flock(2) are implemented as to ignore
// each other and if the local delivery agent uses flock(2), we won't
// block appropriately.  So, if we are on Linux, we lock the mbox file
// with both fcntl(2) and flock(2).
//
- (FILE *) open_mbox
{
#ifndef __MINGW32__
  struct flock lock;
#endif
  FILE *aStream;
  
  if (!_path)
    {
      NSLog(@"Invalid path to the mailbox file.");
      return NULL;
    }

#ifdef __MINGW32__
  fd = _open([_path UTF8String], _O_BINARY|_O_RDWR);
#else
  fd = open([_path UTF8String], O_RDWR);
#endif 
 
  if (fd < 0)
    {
      NSLog(@"LocalFolder: Unable to get folder descriptor at path %@.", _path);
      return NULL;
    }

  //NSLog(@"In open_mbox, fd = %d", fd);

#ifndef __MINGW32__
  lock.l_type = F_WRLCK;
  lock.l_whence = SEEK_SET;
  lock.l_start = 0;
  lock.l_len = 0;
  lock.l_pid = getpid();
 
  if (fcntl(fd, F_SETLK, &lock) == -1)
    {
      NSLog(@"CWLocalFolder+mbox: Unable to obtain the mandatory lock on the folder descriptor at path %@.", _path);
    }
  
#ifdef __linux__
  if (flock(fd, LOCK_EX|LOCK_NB) < 0) 
    {
      NSLog(@"CWLocalFolder+mbox: Unable to obtain the advisory lock on the folder descriptor at path %@.", _path);
      close(fd);
      return NULL;
    }
  else 
    {
      flock(fd, LOCK_UN);
    }
#endif
#endif
  
#ifdef __MINGW32__  
  aStream = _fdopen(fd, "r+");
#else
  aStream = fdopen(fd, "r+");
#endif

  [self setStream: aStream];
  
  if (aStream == NULL)
    {
      NSLog(@"LocalFolder: Unable to open the specified mailbox at path %@.", _path);
      return NULL;
    }
  
#ifdef __linux__
  flock(fd, LOCK_EX|LOCK_NB);
#endif  

  return aStream;
}


//
//
//
- (void) parse_mbox: (NSString *) theFile
	     stream: (FILE *) theStream
	      flags: (CWFlags *) theFlags
		all: (BOOL) theBOOL
{
  CWLocalMessage *aMessage;
  unsigned long size;
  long begin, end;
  cache_record record;
  char aLine[1024];
  
  // We initialize our variables
  aMessage = [[CWLocalMessage alloc] init];
  CLEAR_CACHE_RECORD(record);

  begin = 0L;

  if (_type == PantomimeFormatMbox)
    {
      begin = ftell(theStream);
    }

  while (fgets(aLine, 1024, theStream) != NULL)
    {
      switch (tolower((int)(unsigned char)aLine[0]))
	{	
	case 'b':
	  if (theBOOL && strncasecmp(aLine, "Bcc", 2) == 0)
	    {
	      [CWParser parseDestination: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
			forType: PantomimeBccRecipient
			inMessage: aMessage
			quick: NO];
	    }
	  break;
	  
	case 'c':
	  if (strncasecmp(aLine, "Cc", 2) == 0)
	    {
	      record.cc = [CWParser parseDestination: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
				    forType: PantomimeCcRecipient
				    inMessage: aMessage
				    quick: NO];
	    }
	  else if (theBOOL && strncasecmp(aLine, "Content-Type", 12) == 0)
	    {
	      [CWParser parseContentType: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
			inPart: aMessage];
	    }
	  break;
	  
	case 'd':
	  if (strncasecmp(aLine, "Date", 4) == 0)
	    {
	      [CWParser parseDate: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
			inMessage: aMessage];

	      if ([aMessage receivedDate])
		{
		  record.date = (uint32_t)round([[aMessage receivedDate] timeIntervalSince1970]);
		}
	    }
	  break;
	  
	case 'f':
	  if (strncasecmp(aLine, "From ", 5) == 0)
	    {
	      // do nothing, it's our message separator
	    }
	  else if (strncasecmp(aLine, "From", 4) == 0)
	    {
	      record.from = [CWParser parseFrom: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
				      inMessage: aMessage
				      quick: NO];
	    }
	  break;
	  
	case 'i':
	  if (strncasecmp(aLine, "In-Reply-To", 11) == 0)
	    {
	      record.in_reply_to = [CWParser parseInReplyTo: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
					     inMessage: aMessage
					     quick: NO];
	    }
	  break;

	case 'm':
	  if (strncasecmp(aLine, "Message-ID", 10) == 0)
	    {
	      record.message_id = [CWParser parseMessageID: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
					    inMessage: aMessage
					    quick: NO];
	    }
	  else if (strncasecmp(aLine, "MIME-Version", 12) == 0)
	    {
	      [CWParser parseMIMEVersion: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
			inMessage: aMessage];
	    }
	  break;
	  
	case 'o':
	  if (theBOOL && strncasecmp(aLine, "Organization", 12) == 0)
	    {
	      [CWParser parseOrganization: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
			inMessage: aMessage];
	    }
	  break;
	
	case 'r':
	  if (strncasecmp(aLine, "References", 10) == 0)
	    {
	      record.references = [CWParser parseReferences: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
					    inMessage: aMessage
					    quick: NO];
	    }
	  else if (theBOOL && strncasecmp(aLine, "Reply-To", 8) == 0)
	    {
	      [CWParser parseReplyTo: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
			inMessage: aMessage];
	    }
	  else if (theBOOL && strncasecmp(aLine, "Resent-From", 11) == 0)
	    {
	      [CWParser parseResentFrom: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
			inMessage: aMessage];
	    }
	  break;
	  
	case 's':
	  if (strncasecmp(aLine, "Status", 6) == 0)
	    {
	      [CWParser parseStatus: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
			inMessage: aMessage];
	    }
	  else if (strncasecmp(aLine, "Subject", 7) == 0)
	    {
	      record.subject = [CWParser parseSubject: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
					inMessage: aMessage
					quick: NO];
	    }
	  break;
	  
	case 't':
	  if (strncasecmp(aLine, "To", 2) == 0)
	    {
	      record.to = [CWParser parseDestination: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
				    forType: PantomimeToRecipient
				    inMessage: aMessage
				    quick: NO];
	    }
	  break;
	  
	case 'x':
	  if (strncasecmp(aLine, "X-Status", 8) == 0)
	    {
	      [CWParser parseXStatus: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
			inMessage: aMessage];
	    }
	  break;
	  
	case '\n':
	  [aMessage setFilePosition: begin];
	  //[aMessage setBodyFilePosition: ftell(theStream)];
	  
	  // We must set this in case the last message of our mbox is
	  // an "empty message", i.e, a message with all the headers but
	  // with an empty content.
	  end = ftell(theStream);
	  
	  while (fgets(aLine, 1024, theStream) != NULL)
	    {
	      if (strncmp(aLine, "From ", 5) == 0 && _type == PantomimeFormatMbox) break;
	      else end = ftell(theStream);
	    }
	  
	  fseek(theStream, end, SEEK_SET);
	  size = end-begin;
	  
	  // We set the properties of our message object and we add it to our folder.
	  [aMessage setSize: (NSUInteger)size];
	  [aMessage setMessageNumber: [allMessages count]+1];
	  [aMessage setFolder: self];
	  [aMessage setType: _type];
	  [self appendMessage: aMessage];
	      
	  record.filename = (char *)[[theFile lastPathComponent] UTF8String];
	  record.flags = (theFlags ? theFlags->flags : [aMessage flags]->flags);
	  record.position = begin;
	  record.size = (unsigned int)size;
	  [(CWLocalCacheManager *)_cacheManager writeRecord: &record];
	  CLEAR_CACHE_RECORD(record);
	  //
	  
	  // if we are reading a maildir message, check for flag information in the file name
	  if (_type == PantomimeFormatMaildir)
	    {
	      NSString *info;
	      NSUInteger indexOfPatternSeparator;
	      
	      [aMessage setMailFilename: [theFile lastPathComponent]];

	      // The name of file will be unique_pattern:info with the status flags in the info field
	      indexOfPatternSeparator = [theFile indexOfCharacter: ':'];
	      
	      if (indexOfPatternSeparator != NSNotFound && indexOfPatternSeparator > 1)
		{
		  info = [theFile substringFromIndex: indexOfPatternSeparator];
		}
	      else
		{
		  info = @"";
		}
	      
	      // We remove all the flags and rebuild
	      [[aMessage flags] removeAll];
	      [[aMessage flags] addFlagsFromData: [info dataUsingEncoding: NSASCIIStringEncoding]
				format: PantomimeFormatMaildir];
	    }		
	  

	  RELEASE(aMessage);	  
	  begin = ftell(theStream);
	  
	  // We re-init our message and our mutable string for the next message we're gonna read
	  aMessage = [[CWLocalMessage alloc] init];
	  break;
	  
	default:
	  if (theBOOL)
	    {
	      [CWParser parseUnknownHeader: [self unfoldLinesStartingWith: aLine  fileStream: theStream]
			inMessage: aMessage];
	    }
	  break;
	}
    }
    
  //
  // We sync our cache if's an mbox file since we are done parsing. For
  // maildir, we synchronize it in -parse_maildir:
  //
  if (_type == PantomimeFormatMbox)
    {
      //NSLog(@"Sync cache.");
      [_cacheManager synchronize];
    }

  RELEASE(aMessage);
}


//
// This method is used to unfold the lines that have been folded
// by starting with the first line.
//
- (NSData *) unfoldLinesStartingWith: (char *) firstLine 
			  fileStream: (FILE*) theStream
{
  NSMutableData *aMutableData;
  char aLine[1024], buf[1024];
  char space;
  long mark;
  
  // We initialize our buffers
  memset(aLine, 0, 1024);
  memset(buf, 0, 1024);
  space = ' ';
    
  mark = ftell(theStream);
  if (fgets(aLine, 1024, theStream) == NULL)
    {
      return [NSData dataWithBytes: firstLine  length: strlen(firstLine)];
    }

  // We create our mutable data
  aMutableData = [[NSMutableData alloc] initWithCapacity: strlen(firstLine)];

  // We remove the trailing \n and we append our first line to our mutable data
  strncpy(buf, firstLine, strlen(firstLine) - 1);
  [aMutableData appendBytes: buf length: strlen(firstLine) - 1];
  [aMutableData appendBytes: &space length: 1];
  
  // We loop as long as we have a space or tab character as the first character 
  // of the line that we just read
  while (aLine[0] == 9 || aLine[0] == 32)
    {
      char *ptr;

      // We skip the first char
      ptr = aLine;
      ptr++;
      
      // We init our buffer and we copy the data into it by trimming the trailing \n
      memset(buf, 0, 1024);
      strncpy(buf, ptr, strlen(ptr)-1);
      [aMutableData appendBytes: buf length: strlen(ptr)-1];
      [aMutableData appendBytes: &space length: 1];
      
      // We set our mark and get the next folded line (if there's one)
      mark = ftell(theStream);
      memset(aLine, 0, 1024);
      if (fgets(aLine, 1024, theStream) == NULL)
        {
	  RELEASE(aMutableData);
          return nil;
        }
    }

  // We reset our file pointer position
  if (fseek(theStream, mark, SEEK_SET) == -1)
    {
      NSLog(@"Failed to fseek()");
    }
  
  // We trim our last " " that we added to our data
  [aMutableData setLength: [aMutableData length]-1];
  return AUTORELEASE(aMutableData);
}

//
//
//
+ (NSUInteger) numberOfMessagesFromData: (NSData *) theData
{
  NSRange aRange;
  NSUInteger count, len;

  if (!theData || (len = [theData length]) == 0)
    {
      return 0;
    }

  aRange = NSMakeRange(0,0);
  count = 0;

  do
    {
      aRange = [theData rangeOfCString: "\nFrom "  options: 0  range: NSMakeRange(NSMaxRange(aRange), len-NSMaxRange(aRange))];
      count++;
    } while (aRange.location != NSNotFound);

  return count;
}


//
//
//
- (NSArray *) messagesFromMailSpoolFile
{
  NSMutableArray *aMutableArray;
  char aLine[1024];
  long begin, end;

  if (_type == PantomimeFormatMbox || _type == PantomimeFormatMaildir)
    {
      return nil;
    }

  
  begin = 0;
  memset(aLine, 0, 1024);

  if (fseek(stream, begin, SEEK_SET) == -1)
    {
      NSLog(@"failed to fseek()");
      return nil;
    }

  aMutableArray = [[NSMutableArray alloc] init];

  while (fgets(aLine, 1024, stream) != NULL)
    {
      if (strncasecmp(aLine, "From ", 5) == 0)
	{
	  NSData *aData;
	  
	  unsigned long length;
	  char *buf;
	  
	  // We always 'skip' the "From " line
	  begin = ftell(stream);
	  end = ftell(stream);
	  
	  // We read until we reach an other "From " or, the end of the stream
	  while (fgets(aLine, 1024, stream) != NULL)
	    {
	      if (strncmp(aLine, "From ", 5) == 0) break;
	      else end = ftell(stream);
	    }
	  
	  // We get the length of our message
	  length = end - begin - 1;
	  
	  // We allocate our buffer for the message
	  buf = (char *)malloc(length * sizeof(char));
	  memset(buf, 0, length);
	  
	  // We move our fp to the beginning of the message
          if (fseek(stream, begin, SEEK_SET) == -1)
            {
              NSLog(@"failed to fseek() 2");
              free(buf);
			  [aMutableArray release];
              return nil;
            }

          if (fread(buf, sizeof(char), length, stream) != length)
            {
              NSLog(@"failed to fread()");
              free(buf);
			  [aMutableArray release];
              return nil;
            }
	  
	  aData = [[NSData alloc] initWithBytesNoCopy: buf  length: length];
	  [aMutableArray addObject: aData];
	  RELEASE(aData);
	  
	  // We reset our fp to the right position (end of previous message)
	  if (fseek(stream, end, SEEK_SET) == -1)
            {
              NSLog(@"failed to fseek() 3");
            }
	  memset(aLine, 0, 1024);
	}
    }
  
  // We now truncate our file to a length of 0.
  if (ftruncate(fd, 0) == -1)
    {
      NSLog(@"CWLocalFolder+mbox: Could not truncate file: %@", _path);
    }

  return  AUTORELEASE(aMutableArray);
}

@end

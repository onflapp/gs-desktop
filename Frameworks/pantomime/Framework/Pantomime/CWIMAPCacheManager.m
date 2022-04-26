/*
**  CWIMAPCacheManager.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2013-2018 Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola <rm@gnu.org>
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

#import <Pantomime/CWIMAPCacheManager.h>

#import <Pantomime/io.h>
#import <Pantomime/CWConstants.h>
#import <Pantomime/CWFlags.h>
#import <Pantomime/CWFolder.h>
#import <Pantomime/CWIMAPMessage.h>

#import <Foundation/NSArchiver.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSValue.h>

#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <netinet/in.h>
#include <errno.h>
#include <unistd.h>

static unsigned short version = 1;

//
//
//
@implementation CWIMAPCacheManager

- (id) initWithPath: (NSString *) thePath  folder: (CWFolder *) theFolder
{
  NSDictionary *attributes;
  unsigned short int v;

  self = [super initWithPath: thePath];
  if (self)
    {
      uint32_t count;
      
      _table = NSCreateMapTable(NSIntMapKeyCallBacks, NSObjectMapValueCallBacks, 128);
      _count = _UIDValidity = 0;
      _folder = theFolder;


      if ((_fd = open([thePath UTF8String], O_RDWR|O_CREAT, S_IRUSR|S_IWUSR)) < 0) 
	{
	  NSLog(@"CANNOT CREATE OR OPEN THE CACHE!)");
	  abort();
	}

      if (lseek(_fd, 0L, SEEK_SET) < 0)
	{
	  close(_fd);
	  NSLog(@"UNABLE TO LSEEK INITIAL");
	  abort();
	}

      attributes = [[NSFileManager defaultManager] fileAttributesAtPath: thePath  traverseLink: NO];

      // If the cache exists, lets parse it.
      if ([[attributes objectForKey: NSFileSize] intValue])
	{
	  v = read_uint16(_fd);

	  if (v != version)
	    {
	      if (ftruncate(_fd, 0) == -1)
		{

		  if (errno == EACCES || errno == EROFS)
		    NSLog(@"UNABLE TO TRUNCATE CACHE FILE WITH OLD VERSION, NOT WRITABLE");
		  else
		    NSLog(@"UNABLE TO TRUNCATE CACHE FILE WITH OLD VERSION");
		  close(_fd);
		  abort();
		}
	      [self synchronize];
	      return self;
	    }

	  if (read_uint32(_fd, &count) <= 0)
            {
              NSLog(@"CWIMAPCacheManger initWithPath: Failed to read count");
              abort();
            }
          _count = (NSUInteger)count;
	  if (read_uint32(_fd, &_UIDValidity) <= 0)
            {
              NSLog(@"CWIMAPCacheManger initWithPath: Failed to read UIDValidity");
              abort();
            }
	}
      else
	{
	  [self synchronize];
	}
    }
  return self;
}


//
//
//
- (void) dealloc
{
  //NSLog(@"CWIMAPCacheManager: -dealloc");
  
  NSFreeMapTable(_table);
  if (_fd >= 0) close(_fd);

  [super dealloc];
}

//
//
//
- (void) readAllMessages
{
  [self readMessagesInRange:NSMakeRange(0, NSUIntegerMax)];
}

//
//
//
- (void) readMessagesInRange: (NSRange) theRange
{
  NSAutoreleasePool *pool;
  CWIMAPMessage *aMessage;
  unsigned int tot;
  NSUInteger begin, end, i;
  unsigned char *r;

  if (lseek(_fd, 10L, SEEK_SET) < 0)
    {
      NSLog(@"lseek failed in initInRange:");
      abort();
    }

  begin = theRange.location;
  end = (NSMaxRange(theRange) <= _count ? NSMaxRange(theRange) : _count);
  
  //NSLog(@"init from %d to %d, count = %d, size of char %d  UID validity = %d", begin, end, _count, sizeof(char), _UIDValidity);

  pool = [[NSAutoreleasePool alloc] init];

  // We MUST skip the last few bytes...
  for (i = begin; i < end ; i++)
    {
      uint16_t len;
      cache_record cr;
      unsigned int record_length;

      // We parse the record length, date, flags, position in file and the size.
      if (read_uint32(_fd, &record_length) <= 0)
        {
          NSLog(@"CWIMAPCacheManager readMessagesInRange (%lu/%lu)", (unsigned long)i, (unsigned long)end);
          break;
        }
      //NSLog(@"i = %d, len = %d", i, record_length);

      r = (unsigned char *)malloc(record_length-4);

      if (r == NULL)	// may be in case len was 4
	{
	  continue;
	}
      
      if (read(_fd, r, record_length-4) < 0) { NSLog(@"read failed"); abort(); }
      
      cr.flags = read_uint32_memory(r);  // FASTER and _RIGHT_ since we can't call -setFlags: on CWIMAPMessage
      cr.date = read_uint32_memory(r+4);
      cr.imap_uid = read_uint32_memory(r+8);
      cr.size = read_uint32_memory(r+12);
      tot = 16;

      
      cr.from = read_data_memory(r+tot, &len);
      tot += len+2;
     
      cr.in_reply_to = read_data_memory(r+tot, &len);
      tot += len+2;
      
      cr.message_id = read_data_memory(r+tot, &len);
      tot += len+2;

      cr.references = read_data_memory(r+tot, &len);
      tot += len+2;

      cr.subject = read_data_memory(r+tot, &len);
      tot += len+2;
      
      cr.to = read_data_memory(r+tot, &len);
      tot += len+2;

      cr.cc = read_data_memory(r+tot, &len);

      // zero unused fields
      cr.position = 0;
      cr.filename = NULL;
      cr.pop3_uid = NULL;
      
      aMessage = [[CWIMAPMessage alloc] initWithCacheRecord:cr];
      [aMessage setMessageNumber: (unsigned int)i+1];

      [((CWFolder *)_folder)->allMessages addObject: aMessage];
      NSMapInsert(_table, (void *)[aMessage UID], aMessage);
      //[self addObject: aMessage]; // MOVE TO CWFIMAPOLDER
      //[((CWFolder *)_folder)->allMessages replaceObjectAtIndex: i  withObject: aMessage];
      RELEASE(aMessage);

      free(r);
    }

  RELEASE(pool);
}

//
//
//
- (void) removeMessageWithUID: (NSUInteger) theUID
{
  NSMapRemove(_table, (void *)theUID);
}

//
//
//
- (CWIMAPMessage *) messageWithUID: (NSUInteger) theUID
{
  return NSMapGet(_table, (void *)theUID);
}

//
//
//
- (unsigned int) UIDValidity
{
  return _UIDValidity;
}

//
//
//
- (void) setUIDValidity: (unsigned int) theUIDValidity
{
  _UIDValidity = theUIDValidity;
}


//
//
//
- (void) invalidate
{
  NSDebugLog(@"IMAPCacheManager - INVALIDATING the cache...");
  [super invalidate];
  _UIDValidity = 0;
  [self synchronize];
}


//
//
//
- (BOOL) synchronize
{
  unsigned int len, flags;
  NSUInteger i;

  _count = [_folder->allMessages count];
  
  //NSLog(@"CWIMAPCacheManager: -synchronize with folder count = %d", _count);

  if (lseek(_fd, 0L, SEEK_SET) < 0)
    {
      NSLog(@"fseek failed");
      abort();
    }
  
  // We write our cache version, count and UID validity.
  write_uint16(_fd, version);
  write_uint32(_fd, (uint32_t)_count);
  write_uint32(_fd, _UIDValidity);
  
  //NSLog(@"Synching flags");
  for (i = 0; i < _count; i++)
    {
      read_uint32(_fd, &len);
      flags = ((CWFlags *)[[_folder->allMessages objectAtIndex: i] flags])->flags;
      write_uint32(_fd, flags);
      lseek(_fd, (len-8), SEEK_CUR);
    }
  //NSLog(@"Done!");
 
  return (fsync(_fd) == 0);
}


//
//
//
- (void) writeRecord: (cache_record *) theRecord  message: (id) theMessage
{
  unsigned int len;

  if (lseek(_fd, 0L, SEEK_END) < 0)
    {
      NSLog(@"COULD NOT LSEEK TO END OF FILE");
      abort();
    }
  
  // We calculate the length of this record (including the
  // first five fields, which is 20 bytes long and is added
  // at the very end)
  len = 0;
  len += (unsigned int)[theRecord->from length]+2;
  len += (unsigned int)[theRecord->in_reply_to length]+2;
  len += (unsigned int)[theRecord->message_id length]+2;
  len += (unsigned int)[theRecord->references length]+2;
  len += (unsigned int)[theRecord->subject length]+2;
  len += (unsigned int)[theRecord->to length]+2;
  len += (unsigned int)[theRecord->cc length]+22;
  write_uint32(_fd, len);
  
  // We write the flags, date, position and the size of the message.
  write_uint32(_fd, theRecord->flags); 
  write_uint32(_fd, theRecord->date);
  write_uint32(_fd, theRecord->imap_uid);
  write_uint32(_fd, theRecord->size);

  // We write the read of our cached headers (From, In-Reply-To, Message-ID, References, 
  // Subject, To and Cc)
  write_data(_fd, theRecord->from);
  write_data(_fd, theRecord->in_reply_to);
  write_data(_fd, theRecord->message_id);
  write_data(_fd, theRecord->references);
  write_data(_fd, theRecord->subject);
  write_data(_fd, theRecord->to);
  write_data(_fd, theRecord->cc);
  
  NSMapInsert(_table, (void *)theRecord->imap_uid, theMessage);
  _count++;
}


//
//
//
- (void) expunge
{
  NSDictionary *attributes;

  off_t size;
  NSUInteger i;
  unsigned total_length;
  unsigned char *buf;

  //NSLog(@"expunge: rewriting cache");

  if (lseek(_fd, 10L, SEEK_SET) < 0)
    {
      NSLog(@"fseek failed");
      if (errno == EBADF)
        NSLog(@"Bad file descriptor");
      else if (errno == EINVAL)
        NSLog(@"Seek invalid");
      else if (errno == EOVERFLOW)
        NSLog(@"Seek overflow");
      abort();
    }
  
  attributes = [[NSFileManager defaultManager]
		fileAttributesAtPath: [self path]  traverseLink: NO];
  
  buf = (unsigned char *)malloc([[attributes objectForKey: NSFileSize]
								unsignedLongValue]);
  if (buf == NULL)	// nothing to do for us here
    return;
  total_length = 0;

  for (i = 0; i < _count; i++)
    {
      uint32_t len;
      uint32_t v;
      
      //NSLog(@"===========");
      if (read_uint32(_fd, &len) <= 0)
        {
          NSLog(@"CWIMAPCacheManager expunge: error reading record length (%lu/%lu)", (unsigned long)i, (unsigned long)_count);
          continue;
        }
      if (len <= 4)	// sanity check, we read len-4 bytes later on
	continue;

      //NSLog(@"i = %d  len = %d", i, len);
      v = htonl(len);
      memcpy((buf+total_length), (char *)&v, 4);
      
      // We write the rest of the record into the memory
      if (read(_fd, (buf+total_length+4), len-4) < 0)
	{
	  NSLog(@"read failed");
	  abort();
	}
      
      unsigned int uid = read_uint32_memory(buf+total_length+12);

      if ([self messageWithUID: uid])
	{
	  total_length += len;
	}
      else
	{
	  //NSLog(@"Message not found! uid = %d  table count = %d",
	  //					uid, NSCountMapTable(_table));
	}
    }

  if (lseek(_fd, 0L, SEEK_SET) < 0)
    {
      NSLog(@"fseek failed");
      abort();
    }

  // We write our cache version, count, modification date our new size
  _count = [_folder->allMessages count];
  size = total_length+10;

  write_uint16(_fd, version);
  write_uint32(_fd, (uint32_t)_count);
  write_uint32(_fd, _UIDValidity);

  // We write our memory cache
  if (write(_fd, buf, total_length) != (ssize_t) total_length)
    {
      if (errno == EAGAIN)
        {
          // Perhaps we could handle this more gracefully?
          NSLog(@"EXPUNGE CACHE: WRITE OUT ERROR, EAGAIN");
        }
      else
        {
          NSLog(@"EXPUNGE CACHE: WRITE OUT INCOMPLETE");
        }
      abort();
    }

  if (ftruncate(_fd, size) == -1)
    {
      
      if (errno == EACCES || errno == EROFS)
        NSLog(@"UNABLE TO EXPUNGE CACHE, NOT WRITABLE");
      else if (errno == EFBIG)
        NSLog(@"UNABLE TO EXPUNGE CACHE, EFBIG");
      else
        NSLog(@"UNABLE TO EXPUNGE CACHE");
      abort();
    }
  free(buf);

  //NSLog(@"Done! New size = %d", size);
}
@end

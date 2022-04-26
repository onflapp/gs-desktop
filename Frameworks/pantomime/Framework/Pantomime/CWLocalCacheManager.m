/*
**  CWLocalCacheManager.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2013-2020 Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola <rm@gnu.org>
**          Sebastian Reitenbach
**
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

#import <Pantomime/CWLocalCacheManager.h>

#import <Pantomime/io.h>
#import <Pantomime/CWConstants.h>
#import <Pantomime/CWFlags.h>
#import <Pantomime/CWLocalFolder.h>
#import <Pantomime/CWLocalMessage.h>
#import <Pantomime/CWParser.h>
#import <Pantomime/NSData+Extensions.h>

#import <Foundation/NSArchiver.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSValue.h>

#include <stdlib.h>
#include <string.h>
#include <sys/types.h>  // For open() and friends.
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>     // For lseek()
#include <netinet/in.h> // For ntohl()

static unsigned short version = 1;

//
// Cache structure:
//
// Start   length Description
// 
// 0       2      Cache version
// 2       4      Number of cache entries
// 6       4      Modification date of the underlying mbox file
//                Modification of the underlying cur/ directory for maildir
// [10]    4      File size of the underlying mbox file. This entry does NOT exist for maildir cache.
// 14+/10+        Beginning of the first cache entry
// 
// 0       4      Record length, including this field. The record consist of cached message headers / attributes.
// 4       4      Flags
// 8       4      Date
// 12      4+     Position for mbox / Filename for maildir
// 16+     4      Size
//
//
@implementation CWLocalCacheManager

//
//
//
- (id) initWithPath: (NSString *) thePath  folder: (id) theFolder
{
  NSDictionary *attributes;
  NSUInteger d, s, c;
  unsigned short int v;
  BOOL broken;

  self = [super initWithPath: thePath];
  if (self)
    {
  // We get the attributes of the mailbox
  if ([theFolder type] == PantomimeFormatMbox)
    {
      attributes = [[NSFileManager defaultManager] fileAttributesAtPath: [theFolder path]  traverseLink: NO];
    }
  else
    {
      attributes = [[NSFileManager defaultManager] fileAttributesAtPath: [NSString stringWithFormat: @"%@/cur", [theFolder path]]
						   traverseLink: NO];
    }

  d = (NSUInteger)[[attributes objectForKey: NSFileModificationDate] timeIntervalSince1970];
  s = (NSUInteger)[[attributes objectForKey: NSFileSize] unsignedLongValue];
  broken = NO;

  // We get the attribtes of the cache
  attributes = [[NSFileManager defaultManager] fileAttributesAtPath: thePath  traverseLink: NO];

  _folder = theFolder;
  _count = _modification_date = 0;

  if ((_fd = open([thePath UTF8String], O_RDWR|O_CREAT, S_IRUSR|S_IWUSR)) < 0) 
    {
      AUTORELEASE(self);
      return nil;
    }

  if (lseek(_fd, 0L, SEEK_SET) < 0)
    {
      AUTORELEASE(self);
      return nil;
    }
  
  // If the cache exists, lets parse it.
  if ([[attributes objectForKey: NSFileSize] intValue])
    {
      v = read_uint16(_fd);

      // HACK: We IGNORE all the previous cache.
      if (v != version)
	{
	  //NSLog(@"Ignoring the old cache format.");
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

      if (read_uint32(_fd, (uint32_t *)&_count) <= 0)
        {
          NSLog(@"CWLocalCacheManager initWithPath, error reading _count");
          broken = YES;
        }
      read_uint32(_fd, &_modification_date);

      if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
	{
	  if (read_uint32(_fd, (uint32_t*)&_size) <= 0)
            {
              NSLog(@"CWLocalCacheManager initWithPath: failed to read size");
              broken = YES;
            }
	  
	  if (s != _size || d != _modification_date) broken = YES;
	}
      else
	{
	  //NSLog(@"Asking enumerator...");
	  c = [[[[NSFileManager defaultManager] enumeratorAtPath: [NSString stringWithFormat: @"%@/cur/", [theFolder path]]] allObjects] count];
	  //NSLog(@"Done! count = %d", c);
	  
	  if (c != _count || d != _modification_date) broken = YES;
	}
 
      if (broken)
	{
	  NSDebugLog(@"Broken cache, we must invalidate.");
	  _count = _size = 0;
          if (ftruncate(_fd, 0) == -1)
            {

              if (errno == EACCES || errno == EROFS)
                NSLog(@"UNABLE TO TRUNCATE BROKEN CACHE FILE, NOT WRITABLE");
              else
                NSLog(@"UNABLE TO TRUNCATE BROKEN CACHE FILE");
              close(_fd);
              abort();
            }
	  [self synchronize];
	  return self;
	}
      
      //NSLog(@"Version = %i  date  = %d  size = %d count = %d", v, d, _size, _count);
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
  //NSLog(@"CWLocalCacheManager: -dealloc");
  
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
// If this method is invoked on already initialized messages, we use
// the file position or filename field in order to determine if we already
// initialized or not the message.
//
- (void) readMessagesInRange: (NSRange) theRange
{
  CWLocalMessage *aMessage;
  
  unsigned short int tot;
  unsigned char *r;
  NSUInteger begin, end, i;

  begin = theRange.location;
  end = (NSMaxRange(theRange) <= _count ? NSMaxRange(theRange) : _count);

  if (lseek(_fd, ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox) ? 14L : 10L, SEEK_SET) < 0)
    {
      NSLog(@"CWLocalCacheManager readMessagesInRange: lseek failed");
      abort();
    }
  
  //NSLog(@"init from %d to %d, count = %d, size of char %d", begin, end, _count, sizeof(char));

  // We MUST skip the last few bytes...
  for (i = begin; i < end ; i++)
    {
      uint16_t len;
      cache_record cr;
      unsigned int record_length;
      NSString *mailFilename;
    

      // We parse the record length, date, flags, position in file and the size.
      if (read_uint32(_fd, &record_length) <= 0)
        {
          NSLog(@"CWLocalCacheManager readMessagesInRange: failed to read record length (%lu/%lu)", (unsigned long)i, (unsigned long)end);
          break;
        }
      
      r = (unsigned char *)malloc(record_length-4);
      
      if (read(_fd, r, record_length-4) < 0) { NSLog(@"read failed"); abort(); }

      tot = 0;
      
      cr.flags = read_uint32_memory(r);
      tot += 4;
      
      cr.date = read_uint32_memory(r+4);
      tot += 4;

      mailFilename= nil;
      cr.position = 0;
      if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
	{
	  cr.position = (long)read_uint32_memory(r+tot);
	  tot += 4;
	}
      else
	{
	  mailFilename = read_string_memory(r+tot, &len);
	  tot += len+2;
	}

      cr.size = read_uint32_memory(r+tot);
      tot += 4;
      
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
      cr.imap_uid = 0;
      cr.filename = NULL;
      cr.pop3_uid = NULL;
      
      aMessage = [[CWLocalMessage alloc] initWithCacheRecord:cr];
      [aMessage setFolder: _folder];
 
      if ([aMessage filename] != nil)
	[aMessage setMailFilename: mailFilename];
  
      [aMessage setMessageNumber: i+1];
      [((CWFolder *)_folder)->allMessages addObject: aMessage];
      RELEASE(aMessage);
      
      free(r);
    }
}

//
// access/mutation methods
//
- (NSDate *) modificationDate
{
  return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) _modification_date];
}

- (void) setModificationDate: (NSDate *) theDate
{
  _modification_date = (unsigned int)[theDate timeIntervalSince1970];
}

//
//
//
- (NSUInteger) fileSize
{
  return _size;
}

- (void) setFileSize: (unsigned int) theSize
{
  _size = theSize;
}

//
//
//
- (BOOL) synchronize
{
  NSDictionary *attributes; 
  CWLocalMessage *aMessage;
  unsigned int len, flags;
  NSUInteger i;

  if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
    {
      attributes = [[NSFileManager defaultManager] fileAttributesAtPath: [(CWLocalFolder *)_folder path]
						   traverseLink: NO];
    }
  else
    {
      attributes = [[NSFileManager defaultManager] fileAttributesAtPath: [NSString stringWithFormat: @"%@/cur", [(CWLocalFolder *)_folder path]]
						   traverseLink: NO];
    }
  
  _modification_date = (unsigned int)[[attributes objectForKey: NSFileModificationDate] timeIntervalSince1970];
  _count = [_folder->allMessages count];

  if (lseek(_fd, 0L, SEEK_SET) < 0)
    {
      NSLog(@"fseek failed");
    }
  
  // We write our cache version, count, modification date and size.
  write_uint16(_fd, version);
  write_uint32(_fd, (uint32_t)_count);
  write_uint32(_fd, _modification_date);

  if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
    {
      _size = [attributes fileSize];
      write_uint32(_fd, _size);
    }

  // We now update the message flags
  //NSLog(@"Synching flags for mailbox %@, count = %d", [(CWLocalFolder *)_folder path], _count);
  for (i = 0; i < _count; i++)
    {
      if (read_uint32(_fd, &len) <= 0)
        {
          NSLog(@"CSWLocalCacheManger synchronize (%lu/%lu)", (unsigned long)i, (unsigned long)_count);
          break;
        }
      //NSLog(@"len = %d", len);

      if ((NSNull *)(aMessage = [_folder->allMessages objectAtIndex: i]) != [NSNull null])
	{
	  flags = ((CWFlags *)[aMessage flags])->flags;
	  write_uint32(_fd, flags);
	  lseek(_fd, (len-8), SEEK_CUR);
	  //NSLog(@"wrote = %d", flags);
	}
      else
	{
	  lseek(_fd, (len-4), SEEK_CUR);
	}
    }
  //NSLog(@"Done!");
 
  return (fsync(_fd) == 0);
}


//
//
//
- (NSUInteger) count
{
  return _count;
}

//
//
//
- (void) writeRecord: (cache_record *) theRecord
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
  len += (unsigned int)[theRecord->cc length]+2;
  
  if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
    {
      len += 20;
    }
  else
    {
      len += strlen(theRecord->filename)+2;
      len += 16;
    }

  // We write the length of our entry
  write_uint32(_fd, len);

  // We write the flags, date, position and the size of the message.
  write_uint32(_fd, theRecord->flags);
  write_uint32(_fd, theRecord->date);

  if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
    {
      write_uint32(_fd, (uint32_t)theRecord->position);
    }
  else
    {
      write_string(_fd, (unsigned char *)theRecord->filename, (uint16_t)strlen(theRecord->filename));
    }
  
  write_uint32(_fd, theRecord->size);
  
  // We write the read of our cached headers (From, In-Reply-To, Message-ID, References, Subject and To)
  write_data(_fd, theRecord->from);
  write_data(_fd, theRecord->in_reply_to);
  write_data(_fd, theRecord->message_id);
  write_data(_fd, theRecord->references);
  write_data(_fd, theRecord->subject);
  write_data(_fd, theRecord->to);
  write_data(_fd, theRecord->cc);

  _count++;
}


//
// For mbox-based and maildir-base cache:
//
// This method MUST be called after writing the new mbox
// on disk but BEFORE we actually removed the deleted
// messages from the allMessages ivar.
//
//
- (void) expunge
{
  NSDictionary *attributes;
  CWLocalMessage *aMessage;
  off_t cache_size;
  NSUInteger i;
  unsigned int flags, len, total_deleted, total_length, type, v;
  short delta;
  char *buf;

  //NSLog(@"rewriting cache");

  // We get the current cache size
  cache_size = lseek(_fd, 0L, SEEK_END);

  if (lseek(_fd, ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox) ? 14L : 10L, SEEK_SET) < 0)
    {
      NSLog(@"fseek failed");
      abort();
    }

  total_deleted = total_length = 0;  
  type = [(CWLocalFolder *)_folder type];
  
  //
  // We alloc a little bit more memory that we really need in
  // case we have to rewrite the filename for a maildir cache
  // and the filename length is greater than the previous one.
  //
  buf = (char *)malloc(cache_size+[_folder count]*10);
  _count = [_folder->allMessages count];

  for (i = 0; i < _count; i++)
    {
      if (read_uint32(_fd, &len) <= 0)
        {
          NSLog(@"CWLocalCacheManager expunge: record length read error (%lu/%lu)", (unsigned long)i, (unsigned long)_count);
          break;
        }
      aMessage = [_folder->allMessages objectAtIndex: i];
      flags = ((CWFlags *)[aMessage flags])->flags;
      delta = 0;

      if ((flags&PantomimeDeleted) == PantomimeDeleted)
	{
	  // We skip over that record
	  lseek(_fd, len-4, SEEK_CUR);
	  total_deleted++;
	  //NSLog(@"Skip %d bytes, index %d!", len, i);
	}
      else
	{	  
	  //
	  // For mbox-based caches, we must update the file position of
	  // our cache entries and also the size of the message in the cache.
	  //
	  if (type == PantomimeFormatMbox)
	    {
	      // We write the rest of the record into the memory
	      if (read(_fd, (buf+total_length+4), len-4) < 0) { NSLog(@"read failed"); abort(); }

	      // We update the position in the mailbox file by
	      // overwriting the current value in memory
	      v = htonl([aMessage filePosition]);
	      memcpy((buf+total_length+12), (char *)&v, 4);
	      //NSLog(@"Wrote file position %d", ntohl(v));
	      
	      // We update the size of the message by overwriting
	      // the current value in memory
	      v = htonl([aMessage size]);
	      memcpy((buf+total_length+16), (char *)&v, 4);
	      //NSLog(@"Wrote message size %d", ntohl(v));
	    }
	  //
	  // For maildir-based caches, we must update the filename of our
	  // cache entries in case flags were flushed to the disk.
	  //
	  else
	    {
	      unsigned short c0, c1, old_len, r;
	      char *filename;
	      size_t s_len;

	      // We read our Flags, Date, and the first two bytes
	      // of our filename into memory.
	      if (read(_fd, (buf+total_length+4), 10) < 0) { NSLog(@"read failed"); abort(); }

	      // We read the length of our previous string
	      c0 = *(buf+total_length+12);
	      c1 = *(buf+total_length+13);
	      old_len = ntohs((c1<<8)|c0);

	      //NSLog(@"Previous length = %d  Filename = |%@|", old_len, [aMessage mailFilename]);
	      filename = (char *)[[aMessage mailFilename] UTF8String];
	      s_len = strlen(filename);
	      delta = s_len-old_len;
	      
	      //if (delta != 0) NSLog(@"i = %d  delta = %d |%@| s_len = %d", i, delta, [aMessage mailFilename], s_len);
	      
	      // We write back our filename
	      r = htons(s_len);
	      memcpy((buf+total_length+12), (char *)&r, 2);
	      memcpy((buf+total_length+14), filename, s_len);

	      // We read the rest in our memory. We first skip or old filename string.
	      if (lseek(_fd, old_len, SEEK_CUR) < 0) { NSLog(@"lseek failed"); abort(); }
	      //NSLog(@"must read back into memory %d bytes", len-old_len-14);
	      if (read(_fd, (buf+total_length+s_len+14), len-old_len-14) < 0) { NSLog(@"read failed"); abort(); }
	      //NSLog(@"current file pos after full read %d", lseek(_fd, 0L, SEEK_CUR));
	    }

	  // We write back our record length, adjusting its size if we need
	  // to, in the case we are handling a maildir-based cache.
	  len += (unsigned int)delta;
	  v = htonl(len);
	  memcpy((buf+total_length), (char *)&v, 4);

	  total_length += len;
	  //NSLog(@"_size = %d  total_length = %d", _size, total_length);
	}
    }

  if (lseek(_fd, 0L, SEEK_SET) < 0)
    {
      NSLog(@"fseek failed");
    }

  // We write our cache version, count, modification date our new size
  cache_size = total_length+([(CWLocalFolder *)_folder type] == PantomimeFormatMbox ? 14 : 10);
  _count -= total_deleted;

  write_uint16(_fd, version);
  write_uint32(_fd, (uint32_t)_count);

  if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
      {
	attributes = [[NSFileManager defaultManager] fileAttributesAtPath: [(CWLocalFolder *)_folder path]
						     traverseLink: NO];
	
	_modification_date = (unsigned int)[[attributes fileModificationDate] timeIntervalSince1970];
	_size = (NSUInteger)[attributes fileSize];
	write_uint32(_fd, _modification_date);
	write_uint32(_fd, _size);
      }
  else
    {
      attributes = [[NSFileManager defaultManager] fileAttributesAtPath: [NSString stringWithFormat: @"%@/cur", [(CWLocalFolder *)_folder path]]
						   traverseLink: NO];
      _modification_date = (unsigned int)[[attributes fileModificationDate] timeIntervalSince1970];
      _size = 0;
      write_uint32(_fd, _modification_date);
    }
  
  // We write our memory cache
    if (write(_fd, buf, total_length) != (ssize_t)total_length)
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

  //ftruncate(_fd, _size);
  if (ftruncate(_fd, cache_size) == -1)
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

  //NSLog(@"Done!");
}
@end

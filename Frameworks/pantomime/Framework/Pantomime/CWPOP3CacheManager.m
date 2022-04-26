/*
**  CWPOP3CacheManager.m
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2014-2020 Riccardo Mottola
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

#import <Pantomime/CWPOP3CacheManager.h>

#import <Pantomime/io.h>
#import <Pantomime/CWConstants.h>
#import <Pantomime/CWPOP3CacheObject.h>

#import <Foundation/NSArchiver.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>

#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <netinet/in.h>

static unsigned short version = 1;

//
//
//
@implementation CWPOP3CacheManager

- (id) initWithPath: (NSString *) thePath
{
  NSDictionary *attributes;
  unsigned short int v;

  self = [super initWithPath: thePath];
  if (self)
    {
  
  _table = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 128);
  _count = 0;
  
  if ((_fd = open([thePath UTF8String], O_RDWR|O_CREAT, S_IRUSR|S_IWUSR)) < 0) 
    {
      NSLog(@"CANNOT CREATE OR OPEN THE CACHE!)");
      abort();
    }
  
  if (lseek(_fd, 0L, SEEK_SET) < 0)
    {
      NSLog(@"UNABLE TO LSEEK INITIAL");
      abort();
    }
  
  attributes = [[NSFileManager defaultManager] fileAttributesAtPath: thePath  traverseLink: NO];

  // If the cache exists, lets parse it.
  if ([[attributes objectForKey: NSFileSize] intValue])
    {
      NSString *aUID;
      NSDate *aDate;

      unsigned short len;
      char *s;
      NSUInteger i;

      v = read_uint16(_fd);

      // Version mismatch. We ignore the cache for now.
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

      if(read_uint32(_fd, &_count) <= 0)
        {
          NSLog(@"CWPOP3CacheManager initWithPath: error reading count");
        }

      //NSLog(@"Init with count = %d  version = %d", _count, v);
  
      s = (char *)malloc(4096);
    
      for (i = 0; i < _count; i++)
	{
          unsigned int dateInt;

          read_uint32(_fd, &dateInt);
	  aDate = [NSCalendarDate dateWithTimeIntervalSince1970: dateInt];
	  if (read_string(_fd, s, &len) < 0)
            {
              NSLog(@"CWPOP3CacheManager initWithPath: error reading data (%lu/%lu)", (unsigned long)i, (unsigned long)_count);
              break;
            }
          // FIXME, this could use read_data
	  aUID = AUTORELEASE([[NSString alloc] initWithData: [NSData dataWithBytes: s  length: len]
                                                   encoding: NSASCIIStringEncoding]);
	  NSMapInsert(_table, aUID, aDate);
	}
      
      free(s);
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
  //NSLog(@"CWPOP3CacheManager: -dealloc, _fd was = %d", _fd);
  
  NSFreeMapTable(_table);
  if (_fd >= 0) close(_fd);
  [super dealloc];
}

//
//
//
- (NSCalendarDate *) dateForUID: (NSString *) theUID
{
  return NSMapGet(_table, theUID);
}

//
//
//
- (BOOL) synchronize
{
  if (lseek(_fd, 0L, SEEK_SET) < 0)
    {
      NSLog(@"fseek failed");
      abort();
      return NO;
    }
  
  // We write our cache version, count and UID validity.
  write_uint16(_fd, version);
  write_uint32(_fd, _count);
 
  return (fsync(_fd) == 0);
}

//
//
//
- (void) expunge
{
  NSLog(@"Warning! POP3 Cache has no expunge implementation");
}

//
//
//
- (void) writeRecord: (cache_record *) theRecord
{
  NSData *aData;

  // We do NOT write a record we already have in our cache.
  // Some POP3 servers, like popa3d, might return the same UID
  // for messages at different index but with the same content.
  // If that happens, we just don't write that value in our cache.
  if (NSMapGet(_table, theRecord->pop3_uid))
    {
     return;
   }

  if (lseek(_fd, 0L, SEEK_END) < 0)
    {
      NSLog(@"COULD NOT LSEEK TO END OF FILE");
      abort();
    }

  write_uint32(_fd, theRecord->date);

  aData = [theRecord->pop3_uid dataUsingEncoding: NSASCIIStringEncoding];
  write_data(_fd, aData);
  
  
  NSMapInsert(_table, theRecord->pop3_uid, [NSCalendarDate dateWithTimeIntervalSince1970: theRecord->date]);
  _count++;
}

@end

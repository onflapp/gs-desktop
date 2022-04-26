/*
**  io.m
**
**  Copyright (c) 2004-2007 Ludovic Marcotte
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

#import <Pantomime/io.h>

#import <Foundation/NSData.h>
#import <Foundation/NSString.h>

#include <errno.h>
#ifdef __MINGW32__
#include <io.h> 	// For _read(), _write() and _close() on MinGW
#include <winsock2.h>	// For recv() on MinGW
#else
#include <sys/ioctl.h>
#include <sys/socket.h>
#endif

#include <stdlib.h>	// For abort()
#include <stdio.h>
#include <string.h>     // For memset()
#include <netinet/in.h> // For ntohs() and friends. 

#include <unistd.h>	// For read(), write() and close()

#ifdef MACOSX
#include <sys/uio.h>	// For read() and write() on OS X
#endif

#if !defined(FIONBIO) && !defined(__MINGW32__)
#include <sys/filio.h>  // For FIONBIO on Solaris
#endif

//
//
//
ssize_t read_block(int fd, void *buf, size_t count)
{
  size_t tot;
  ssize_t bytes;
  
  tot = 0;

  while (tot < count)
    {
#ifdef __MINGW32__ 
      if ((bytes = _read(fd, buf+tot, count-tot)) == -1)
#else
      if ((bytes = read(fd, buf+tot, count-tot)) == -1)
#endif
        {
	  if (errno != EINTR)
	    {
	      return -1;
	    }
	}
      else
	{
	  tot += (size_t)bytes;
	}
    }
  
  return (ssize_t)tot;
}


//
//
//
int safe_close(int fd)
{
  int value;
#ifdef __MINGW32__
  while (value = _close(fd), value == -1 && errno == EINTR);
#else
  while (value = close(fd), value == -1 && errno == EINTR);
#endif
  return value;
}

//
//
//
ssize_t safe_read(int fd, void *buf, size_t count)
{
  ssize_t value;
#ifdef __MINGW32__
  while (value = _read(fd, buf, count), value == -1 && errno == EINTR);
#else
  while (value = read(fd, buf, count), value == -1 && errno == EINTR);
#endif
  return value;
}

//
//
//
ssize_t safe_recv(int fd, void *buf, size_t count, int flags)
{
  ssize_t value;
  while (value = recv(fd, buf, count, flags), value == -1 && errno == EINTR);
  return value;
}

//
// 
//
NSString *read_string_memory(unsigned char *m, uint16_t *count)
{
  uint16_t c0, c1, r;

  c0 = *m;
  c1 = *(m+1);

  *count = r = (c0<<8)|c1;
  m += 2;

  return [[[NSString alloc] initWithBytes:m length:r encoding: NSUTF8StringEncoding] autorelease];
}

//
//
//
NSData *read_data_memory(unsigned char *m, uint16_t *count)
{
  uint16_t c0, c1, r;
  
  c0 = *m;
  c1 = *(m+1);
  
  *count = r = (c0<<8)|c1;
  m += 2;
  
  // when used on a file buffer, it should outlive the NSData object itself
  return [NSData dataWithBytesNoCopy: m  length: r freeWhenDone:NO];  
}


//
//
//
uint32_t read_uint32_memory(unsigned char *m)
{
  uint32_t c0, c1, c2, c3, r;

  c0 = *m;
  c1 = *(m+1);
  c2 = *(m+2);
  c3 = *(m+3);

  r = ((c0<<24)|(c1<<16)|(c2<<8)|c3);
  
  return r;
}

//
//
//
uint16_t read_uint16(int fd)
{
  uint16_t v;
  
  if (read(fd, &v, 2) != 2) abort();

  return ntohs(v);
}

//
//
//
void write_uint16(int fd, uint16_t value)
{
  uint16_t v;
  
  v = htons(value);
  
  if (write(fd, &v, 2) != 2)
    {
      //printf("Error writing cache, aborting.");
      abort();
    }
} 

//
//
//
ssize_t read_string(int fd, char *buf, uint16_t *count)
{
  *count = read_uint16(fd);
  
  if (*count)
    {
      ssize_t nbytes;
      nbytes = read(fd, buf, *count);
      if (nbytes == (ssize_t)*count)
        return nbytes;
      if (nbytes == 0)
        {
          printf("read_string: EOF\n");
        }
      else if (nbytes == -1)
        {
          printf("read_string: error\n");
        }
      printf("read_string: read less bytes than expected\n");
      return nbytes;
    }
  return 0; // FIXME this might be a legitimate 0 or an issue with read_uint16 failed
}

//
//
//
void write_string(int fd, unsigned char *s, size_t len)
{
  if (s && len > 0)
    { 
      write_uint16(fd, len);
      if (write(fd, s, len) != (ssize_t)len)
	{
	  //NSLog(@"FAILED TO WRITE BYTES, ABORT");
	  abort();
	}
    }
  else
    {
      write_uint16(fd, 0);
    }
}

void write_data(int fd, NSData *d)
{
  write_string (fd, (unsigned char *)[d bytes], [d length]);
}

//
//
//
int read_uint32(int fd, uint32_t *val)
{
  uint32_t v;
  int c;
  
  if ((c = (int)read(fd, &v, 4)) != 4)
    {
      if (c == 0)
        printf("read_unsinged_int: EOF\n");
      else 
        printf("read_unisnged_int unexpected :read = %d\n", c);
    }

  *val = htonl(v);
  return c;
}

//
//
//
void write_uint32(int fd, uint32_t value)
{
  uint32_t v;
  ssize_t r;
  
  v = htonl(value);

  //printf("b|%d| a|%d|", value, v);

  r = write(fd, &v, 4);
  if (r < 0)
    {
      if (errno == EFBIG)
        printf("ERROR WRITING CACHE: file too big");
      else if (errno == EACCES)
        printf("ERROR WRITING CACHE: permission denied");
      else
        printf("ERROR WRITING CACHE: %d", errno);
      abort();
    }
  else if (r != 4)
    {
      printf("ERROR WRITING CACHE: Wrote %ld out of 4", (long)r);
      abort();
    }
}

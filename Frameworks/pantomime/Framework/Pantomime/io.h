/*
**  io.h
**
**  Copyright (c) 2004-2016 Ludovic Marcotte
**  Copyright (C) 2019-2020 Riccardo Mottola
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

#ifndef _Pantomime_H_io
#define _Pantomime_H_io

#include <sys/types.h>
#include <stdint.h>
#include <arpa/inet.h>

@class NSData;
@class NSString;

/*!
  @function read_block
  @discussion This function is used to read <i>count</i> bytes
              from <i>fd</i> and store them in <i>buf</i>. This
	      method blocks until it read all bytes or if
	      an error different from EINTR occurs.
  @param fd The file descriptor to read bytes from.
  @param buf The buffer where to store the read bytes.
  @param count The number of bytes to read.
  @result The number of bytes that have been read.
*/
ssize_t read_block(int fd, void *buf, size_t count);

/*!
  @function safe_close
  @discussion This function is used to safely close a file descriptor.
              This function will block until the file descriptor
	      is close, or if the error is different from EINTR.
  @param fd The file descriptor to close.
  @result Returns 0 on success, -1 if an error occurs.
*/
int safe_close(int fd);

/*!
  @function safe_read
  @discussion This function is used to read <i>count</i> bytes
              from <i>fd</i> and store them in <i>buf</i>. This
	      method might not block when reading if there are
	      no bytes available to be read.
  @param fd The file descriptor to read bytes from.
  @param buf The buffer where to store the read bytes.
  @param count The number of bytes to read.
  @result The number of bytes that have been read.
*/
ssize_t safe_read(int fd, void *buf, size_t count);

/*!
  @function safe_recv
  @discussion This function is used to read <i>count</i> bytes
              from <i>fd</i> and store them in <i>buf</i>. This
	      method might not block when reading if there are
	      no bytes available to be read. Options can be
	      passed through <i>flags</i>.
  @param fd The file descriptor to read bytes from.
  @param buf The buffer where to store the read bytes.
  @param count The number of bytes to read.
  @param flags The flags to use.
  @result The number of bytes that have been read.
*/
ssize_t safe_recv(int fd, void *buf, size_t count, int flags);

/*!
 @function read_data_memory
 @discussion This function is used to read a string from <i>m</i>
             and return it as a NSData objectand adjust the <i>count</i> on how
             long the read data is. The data must NOT be longer than 65535 bytes.
 @param m The buffer to read from.
 @param count The lenght of the data returned
 @result The read NSData* (autoreleased)
 */

NSData *read_data_memory(unsigned char *m, uint16_t *count);

/*!
  @function read_string_memory
  @discussion This function is used to read a string from <i>m</i>
              and adjust the <i>count</i> on how long the string is.
              The string must NOT be longer than 65535 bytes.
  @param m The buffer to read from.
  @param count The lenght of the string stored in <i>buf</i>
  @result The allocated string (autoreleased)
*/
NSString *read_string_memory(unsigned char *m, uint16_t *count);

/*!
  @function read_uint32_memory
  @discussion This function is used to read an unsigned int from
              the memory in network byte-order.
  @param m The buffer to read from.
  @result The unsigned integer read from memory.
*/
uint32_t read_uint32_memory(unsigned char *m);

/*!
  @function read_uint16
  @discussion This function is used to read an uint16 from
              the file descriptor in network byte-order.
  @param fd The file descriptor to read from.
  @result The unsigned short read from the file descriptor.
*/
uint16_t read_uint16(int fd);

/*!
  @function write_uint16
  @discussion This function is used to write the specified
              uint16 <i>value</i> to the file descriptor
	      </i>fd</i>. The written value is in network byte-order.
  @param fd The file descriptor to write to.
  @param value The unsigned value to write.
*/
void write_uint16(int fd, uint16_t value);

/*!
  @function read_string
  @discussion This function is used to read a string from a
              file descriptor, store it into a buffer and adjust
	      the number of bytes that has been read.
  @param fd The file descriptor to read from.
  @param buf The buf to write to.
  @param count The number of bytes that have been declared as string length.
  @result actual bytes of string read
*/
ssize_t read_string(int fd, char *buf, uint16_t *count);

/*!
  @function write_string
  @discussion This function is used to string a string to a
              file descriptor.
  @param fd The file descriptor to write to.
  @param buf The buf that needs to be written.
  @param count The number of bytes that we have to write.
*/
void write_string(int fd, unsigned char *s, size_t len);

/*!
 @function write_string
 @discussion This function is used to write NSData as a string to a
 file descriptor. The whole length is written
 @param fd The file descriptor to write to.
 @param d The NSData that needs to be written.
 */
void write_data(int fd, NSData *d);

/*!
  @function read_uint32
  @discussion This function is used to read an uint32 from
              the file descriptor in network byte-order.
  @param fd The file descriptor to read from.
  @result The unsigned int read from the file descriptor.
*/
int read_uint32(int fd, uint32_t *val);

/*!
  @function write_uint32
  @discussion This function is used to write the specified
              uint32 <i>value</i> to the file descriptor
	      </i>fd</i>. The written value is in network byte-order.
  @param fd The file descriptor to write to.
  @param value The unsigned value to write.
*/
void write_uint32(int fd, uint32_t value);

#endif //  _Pantomime_H_io

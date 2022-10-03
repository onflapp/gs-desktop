/*
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

#import "StreamLineReader.h"
#import "GNUstep.h"

@implementation StreamLineReader

-(id)init
{
  RELEASE(self);
  return nil;
}

-(id)initWithInputStream: (NSInputStream*) anInputStream
{
  return [self initWithInputStream: anInputStream
	       andDelimiter: @"\r\n"];
}

-(id)initWithInputStream: (NSInputStream*) anInputStream
            andDelimiter: (NSString*) aDelimiter
{
  ASSIGN(inputStream, anInputStream);
  NSData* delimData;
  
  delimData = [aDelimiter dataUsingEncoding: NSUTF8StringEncoding];
  delimSize = [delimData length];
  delim = malloc(delimSize);
  
  if (delim != NULL)
    memcpy(delim, [delimData bytes], delimSize);
  
  strBufSize = 0x1000;
  strBufPos = 0;
  strBuf = malloc(strBufSize);
  
  if (strBuf == NULL || delim == NULL) {
    [self dealloc];
    return nil;
  }
  
  return self;
}

-(void)dealloc
{
  NSLog(@"%@ dealloc start", self);
  free(delim);
  free(strBuf);
  RELEASE(inputStream);
  NSLog(@"%@ dealloc end", self);
  [super dealloc];
}

-(NSString*)readLineAndRetry
{
  NSString* result = nil;
  while (result == nil) {
    result = [self readLine];
  }
  return result;
}

-(NSString*)readLine
{
  BOOL canProceed = YES;
  while([self canExtractNextLine] == NO && canProceed) {
    //NSLog(@"getting more, bufSize=%d bufPos=%d", strBufSize, strBufPos);
    canProceed = [self getMoreCharacters];
  }
  
  if ([self canExtractNextLine] == YES)
    return [self extractNextLine];
  else
    return nil;
}

-(BOOL) getMoreCharacters
{
  //NSLog(@"getMoreChars opened (stream status = %d)",
  //      [inputStream streamStatus]);
  
  // cancel if nothing in queue
  if ([inputStream hasBytesAvailable] == NO) {
    NSLog(@"stream says nothing available (GNUstep impl b0rken?)");
    //return NO;
  }
  
  if ([inputStream streamStatus] == NSStreamStatusClosed) {
    NSLog(@"Stream is closed (by server?)");
    return NO;
  }
  
  
  // make buffer bigger if needed
  if (strBufPos > (strBufSize>>1)) {
    strBufSize = strBufSize<<1;
    strBuf = realloc(strBuf, strBufSize);
  }
  
  NSAssert(strBufPos < strBufSize, @"strBufPos >= strBufSize");
  
  //NSLog(@"getMoreChars: now reading from %@", inputStream);
  
  // read bytes
  int numBytesRead = [inputStream read: (strBuf+strBufPos)
				  maxLength: (strBufSize-strBufPos)];
  
  
  //NSLog(@"getMoreChars closed with %d bytes read", numBytesRead);
  
  if (numBytesRead > 0) {
    strBufPos += numBytesRead;
    return YES;
  } else {
    return NO;
  }
}

-(NSString*) extractNextLine
{
  NSString* result;
  int resultLength;
  
  resultLength = [self delimPosInBuffer];
  
  //NSLog(@"buf@0x%08x, resLen=%d, delSize=%d, strBufPos=%d",
  //      strBuf, resultLength, delimSize, strBufPos);
  NSAssert(resultLength < strBufPos, @"resultLength >= strBufPos");
  NSAssert(resultLength >= 0, @"resultLength < 0");
  
  if (resultLength < 0)
    return nil;
  
  result = [[NSString alloc] initWithBytes: strBuf
			     length: resultLength
			     encoding: NSUTF8StringEncoding];
  AUTORELEASE(result);
  
  memmove(strBuf, strBuf+resultLength+delimSize, 
	  strBufPos-(resultLength+delimSize));
  strBufPos -= (resultLength+delimSize);
  
  return result;
}

-(int) delimPosInBuffer
{
  if (delimSize > strBufPos)
    return -1;
  
  int pos = 0;
  while (pos < strBufPos - delimSize + 1) {
    if (memcmp(strBuf+pos, delim, delimSize) == 0)
      return pos;
    
    pos++;
  }
  
  return -1;
}

-(BOOL) canExtractNextLine
{
  return ([self delimPosInBuffer] == -1) ? NO : YES;
}


@end

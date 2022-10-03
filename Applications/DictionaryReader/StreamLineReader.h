/*  -*-objc-*-
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

#ifndef _STREAMLINEREADER_H_
#define _STREAMLINEREADER_H_

#import <Foundation/Foundation.h>

@interface StreamLineReader : NSObject
{
  // Instance variables
  NSInputStream* inputStream;
  uint8_t* delim;
  unsigned delimSize;
  
  uint8_t* strBuf;
  unsigned strBufPos;
  unsigned strBufSize;
}

// Class methods



// Instance methods

-(id)init;
-(id)initWithInputStream: (NSInputStream*) anInputStream;
-(id)initWithInputStream: (NSInputStream*) anInputStream
            andDelimiter: (NSString*) aDelimiter;

-(void)dealloc;

-(NSString*)readLineAndRetry;
-(NSString*)readLine;

-(BOOL) getMoreCharacters;
-(NSString*) extractNextLine;
-(int) delimPosInBuffer;
-(BOOL) canExtractNextLine;


@end

#endif // _STREAMLINEREADER_H_

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

#import "StreamLineWriter.h"
#import "GNUstep.h"

@implementation StreamLineWriter

// Won't work, we need an output Stream here!
-(id)init {
    RELEASE(self);
    return nil;
}

-(id)initWithOutputStream: (NSOutputStream*) anOutputStream {
    ASSIGN( outputStream, anOutputStream );
    return self;
}

-(void)dealloc {
  NSLog(@"%@ dealloc start", self);
  RELEASE(outputStream);
  NSLog(@"%@ dealloc end", self);
  [super dealloc];
}

// ---------------------------------------

-(BOOL)writeLine: (NSString*) aString
{
  NSData* UTF8data = [aString dataUsingEncoding: NSUTF8StringEncoding];
  
  if (UTF8data == nil)
    return NO;
  
  unsigned int length = [UTF8data length];
  uint8_t* bytes = (uint8_t*) [UTF8data bytes];
  unsigned int position = 0;
  
  while (/* [outputStream hasSpaceAvailable] && */ position < length) {
    unsigned int written =
      [outputStream write: (bytes+position)
		    maxLength: length-position];
    
    position += written;
  }
  
  if (position == length)
    return YES;
  
  return NO;
}


@end

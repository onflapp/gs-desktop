/*
**  CWSendmail.h
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
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

#ifndef _Pantomime_H_CWSendmail
#define _Pantomime_H_CWSendmail

#include <Pantomime/CWTransport.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

@class NSTask;

/*!
  @class CWSendmail
  @discussion This class, which implements the CWTransport protocol, is used
              to provide an interface to the "sendmail" command found on
	      most UNIX system in order to submit messages directly
	      instead of using SMTP.
*/
@interface CWSendmail : NSObject <CWTransport>
{    
  @private
    NSMutableArray *_recipients;
    CWMessage *_message;
    NSData *_data;

    NSString *_path;
    id _delegate;
}

/*!
  @method initWithPath:
  @discussion This is the designated initializer for the CWSendmail class.
  @param thePath The complete path to the "sendmail" binary.
  @result An instance of Sendmail, nil on error.
*/
- (id) initWithPath: (NSString *) thePath;

/*!
  @method setDelegate:
  @discussion This method is used to set the CWSendmail instance's delegate.
              The delegate will not be retained. The CWSendmail class
	      (and its subclasses) will invoke methods on the delegate
	      based on actions performed.
  @param theDelegate The delegate, which implements various callback methods.
*/
- (void) setDelegate: (id) theDelegate;

/*!
  @method delegate
  @discussion This method is used to obtain the delegate of the CWSendmail's instance.
  @result The delegate, nil if none was previously set.
*/
- (id) delegate;

/*!
  @method setPath:
  @discussion This method is used to set the path to the "sendmail" binary.
  @param thePath The full path to the binary.
*/
- (void) setPath: (NSString *) thePath;

/*!
  @method path
  @discussion This method is used to get the path to the "sendmail" binary
              previously set by calling -setPath:.
  @result The path to the "sendmail" binary.
*/
- (NSString *) path;

@end

#endif // _Pantomime_H_CWSendmail

/*
**  CWTransport.h
**
**  Copyright (c) 2001-2006 Ludovic Marcotte
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

#ifndef _Pantomime_H_CWTransport
#define _Pantomime_H_CWTransport

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSNotification.h>

/*!
  @const PantomimeMessageSent
*/
extern NSString* PantomimeMessageSent;

/*!
  @const PantomimeMessageNotSent
*/
extern NSString* PantomimeMessageNotSent;


@class CWMessage;

/*!
  @category NSObject (TransportClient)
  @discussion This informal protocol defines methods that can implemented in
              CWTransport's delegate (CWSMTP or CWSendmail instances) to control 
	      the behavior of the class or to obtain status information.
*/
@interface NSObject (TransportClient)
/*!
  @method messageSent:
  @discussion This method is automatically invoked on the delegate
              after the SMTP DATA command has completed. The userInfo's
	      part of the notification contains the message that has
	      been sent. The key to obtain it is "Message".
	      A PantomimeMessageSent notification is also posted.
  @param theNotification The notification holding the information.
*/
- (void) messageSent: (NSNotification *) theNotification;

/*!
  @method messageNotSent:
  @discussion This method is automatically invoked on the delegate
              if any error occurs when trying to send a message
	      (like if a SMTP server won't relay our mails). The userInfo's
	      part of the notification contains the message that has
	      not been sent. The key to obtain it is "Message".
	      A PantomimeMessageNotSent notification is also posted.
  @param theNotification The notification holding the information.
*/
- (void) messageNotSent: (NSNotification *) theNotification;
@end

/*!
  @protocol CWTransport
  @discussion This protocol defines a generic interface for sending messages.
              The CWSMTP and CWSendmail classes fully implement this protocol.
*/
@protocol CWTransport

/*!
  @method sendMessage
  @discussion This method sends the message previously set with -setMessage:
              or -setMessageData:. It posts a PantomimeTransportMessageNotSent
	      notification (and calls -messageNotSent: on the delegate, if any)
	      if the message could not be sent. It ports a PantomimeTransportMessageSent
	      notification (and calls -messageSent: on the delegate, if any)
	      if the message has been successfully sent. This method is
	      fully asynchronous.
*/
- (void) sendMessage;

/*!
  @method setMessage:
  @discussion This method is used to set the message (instance of the CWMessage class)
              that the transport class will eventually send (by calling -sendMessage).
  @param theMessage The message to send.
*/
- (void) setMessage: (CWMessage *) theMessage;

/*!
  @method message
  @discussion This method is used to obtain the Message instance
              previously set by calling -setMessage:
  @result The CWMessage instance.
*/
- (CWMessage *) message;

/*!
  @method setMessageData:
  @discussion This method is used to set the message (as raw source) that the transport
              class will eventually send (by calling -sendMessage).
  @param theMessage The message to send.
*/
- (void) setMessageData: (NSData *) theData;

/*!
  @method messageData
  @discussion This method is used to obtain the message (its raw representation)
              previously set by calling -setMessageData:
  @result The message's raw representation.
*/
- (NSData *) messageData;

/*!
  @method setRecipients:
  @discussion This method is used to specify the recipients of the
              message.
  @param theRecipients An NSArray instance which contains CWInternetAddress
                       instances for all recipients.
*/
- (void) setRecipients: (NSArray *) theRecipients;

/*!
  @method recipients
  @discussion This method is used to obtain the recipients set when
              calling -setRecipients:.
  @result The array of recipients.
*/
- (NSArray *) recipients;

@end

#endif // _Pantomime_H_CWTransport

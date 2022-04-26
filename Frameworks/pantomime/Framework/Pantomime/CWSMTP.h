/*
**  CWSMTP.h
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

#ifndef _Pantomime_H_CWSMTP
#define _Pantomime_H_CWSMTP

#include <Pantomime/CWService.h>
#include <Pantomime/CWTransport.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

/*!
  @const PantomimeTransactionInitiationCompleted
*/
extern NSString* PantomimeTransactionInitiationCompleted;

/*!
  @const PantomimeTransactionInitiationFailed
*/
extern NSString* PantomimeTransactionInitiationFailed;

/*!
  @const PantomimeRecipientIdentificationCompleted
*/
extern NSString* PantomimeRecipientIdentificationCompleted;

/*!
  @const PantomimeRecipientIdentificationFailed
*/
extern NSString* PantomimeRecipientIdentificationFailed;

/*!
  @const PantomimeTransactionResetCompleted
*/
extern NSString* PantomimeTransactionResetCompleted;

/*!
  @const PantomimeTransactionResetFailed
*/
extern NSString* PantomimeTransactionResetFailed;


@class CWMessage;

/*!
  @category NSObject (SMTPClient)
  @discussion This informal protocol defines methods that can implemented in
              SMTP's delegate to control the behavior of the class 
	      or to obtain status information.
*/
@interface NSObject (SMTPClient)

/*!
  @method transactionInitiationCompleted:
  @discussion This method is automatically invoked on the delegate
              after the SMTP MAIL FROM command has completed. The userInfo's
	      part of the notification contains the message that has
	      been sent. The key to obtain it is "Message".
	      A PantomimeTransactionInitiationCompleted notification is also posted.
  @param theNotification The notification holding the information.
*/
- (void) transactionInitiationCompleted: (NSNotification *) theNotification;

/*!
  @method transactionInitiationFailed:
  @discussion This method is automatically invoked on the delegate
              after the SMTP MAIL FROM command has failed. The userInfo's
	      part of the notification contains the message that has
	      not been sent. The key to obtain it is "Message".
	      A PantomimeTransactionInitiatioFailed notification is also posted.
  @param theNotification The notification holding the information.
*/
- (void) transactionInitiationFailed: (NSNotification *) theNotification;

/*!
  @method recipientIdentificationCompleted:
  @discussion This method is automatically invoked on the delegate
              after the SMTP RCPT TO command has completed. The userInfo's
	      part of the notification contains the recipients (CWInternetAddress
	      instances) that were sucessfully sent. The key to obtain it is "Recipients".
	      A PantomimeRecipientIdentificationCompleted notification is also posted.
 @param theNotification The notification holding the information.
*/
- (void) recipientIdentificationCompleted: (NSNotification *) theNotification;

/*!
  @method recipientIdentificationFailed:
  @discussion This method is automatically invoked on the delegate
              after the SMTP RCPT TO command has failed. The userInfo's
	      part of the notification contains the recipient (CWInternetAddress
	      instance) that was not sucessfully sent. The key to obtain it is "Recipient".
	      A PantomimeRecipientIdentificationFailed notification is also posted.
 @param theNotification The notification holding the information.
*/
- (void) recipientIdentificationFailed: (NSNotification *) theNotification;

/*!
  @method transactionResetCompleted:
  @discussion This method is automatically invoked on the delegate
              after the SMTP RSET command has completed.
	      A PantomimeTransactionResetCompleted notification is
	      also posted.
  @param theNotification The notification holding the information.
*/
- (void) transactionResetCompleted: (NSNotification *) theNotification;

/*!
  @method transactionResetFailed:
  @discussion This method is automatically invoked on the delegate
              after the SMTP RSET command has completed and failed.
	      This should never really happen but this method could
	      be invoked, if the SMTP server isnt RFC-strict.
	      A PantomimeTransactionResetFailed notification is
	      also posted.
  @param theNotification The notification holding the information.
*/
- (void) transactionResetFailed: (NSNotification *) theNotification;

@end

/*!
  @typedef SMTPCommand
  @abstract Supported SMTP commands.
  @discussion This enum lists the supported SMTP commands available
              in Pantomime's SMTP client code.
  @constant SMTP_AUTH_CRAM_MD5 CRAM-MD5 authentication.
  @constant SMTP_AUTH_LOGIN LOGIN authentication.
  @constant SMTP_AUTH_LOGIN_CHALLENGE Challenge during the LOGIN authentication.
  @constant SMTP_AUTH_PLAIN PLAIN authentication.
  @constant SMTP_DATA The DATA SMTP command - see 4.1.1.4 DATA (DATA) of RFC 2821.
  @constant SMTP_EHLO The EHLO SMTP command - see 4.1.1.1  Extended HELLO (EHLO) or HELLO (HELO) of RFC 2821.
  @constant SMTP_HELO The HELO SMTP command - see 4.1.1.1  Extended HELLO (EHLO) or HELLO (HELO) of RFC 2821.
  @constant SMTP_MAIL The MAIL SMTP command - see 4.1.1.2 MAIL (MAIL) of RFC 2821.
  @constant SMTP_NOOP The NOOP SMTP command - see 4.1.1.9 NOOP (NOOP) of RFC 2821.
  @constant SMTP_QUIT The QUIT SMTP command - see 4.1.1.10 QUIT (QUIT) of RFC 2821.
  @constant SMTP_RCPT The RCPT SMTP command - see 4.1.1.3 RECIPIENT (RCPT) of RFC 2821.
  @constant SMTP_RSET The RSET SMTP command - see 4.1.1.5 RESET (RSET) of RFC 2821.
  @constant SMTP_STARTTLS The STARTTLS SMTP command - see RFC2487.
  @constant SMTP_AUTHORIZATION Special command to know we are in the autorization state.
  @constant SMTP_EMPTY_QUEUE Special command to empty the command queue.
*/
typedef enum {
  SMTP_AUTH_CRAM_MD5 = 0x1000,
  SMTP_AUTH_LOGIN,
  SMTP_AUTH_LOGIN_CHALLENGE,
  SMTP_AUTH_PLAIN,
  SMTP_DATA,
  SMTP_EHLO,
  SMTP_HELO,
  SMTP_MAIL,
  SMTP_NOOP,
  SMTP_QUIT,
  SMTP_RCPT,
  SMTP_RSET,
  SMTP_STARTTLS,
  SMTP_AUTHORIZATION,
  SMTP_EMPTY_QUEUE,
} SMTPCommand;

/*!
  @class CWSMTP
  @abstract Pantomime SMTP client code.
  @discussion This class, which extends the CWService class and implements
              the CWTransport protocol, is Pantomime's SMTP client code.
*/
@interface CWSMTP : CWService <CWTransport>
{
  @private
    NSMutableArray *_sent_recipients;
    NSMutableArray *_recipients;
    CWMessage *_message;
    NSData *_data;
    
    unsigned int _max_size;
    BOOL _redirected;
}

/*!
  @method lastResponse
  @discussion This method is used to obtain the last response
              received from the SMTP server. If the server
	      sent a multi-line response, only the last line
	      will be returned.
  @result The last response in its complete form, nil if no
          response was read.
*/
- (NSData *) lastResponse;

/*!
  @method lastResponseCode
  @discussion This method is used to obtain the last response code
              received from the SMTP server. If the server
	      sent a multi-line response, only the code of the
	      last line will be returned.
  @result The last response code in its complete form, 0 if
          no response was read.         
*/
- (int) lastResponseCode;

/*!
  @method reset
  @discussion This method is used to send the RSET SMTP command.
              See 4.1.1.5 RESET (RSET) of RFC 2821 for a full description
	      of this command. It will NOT reset to nil the previously
	      used recipients, message or message data. If you wish
	      to change either of them, call the corresponding
	      accessor method between your -sendMessage calls.
*/
- (void) reset;

/*!
  @method sendCommand: arguments: ...
  @discussion This method is used to send commands to the SMTP server.
              Normally, you should not call this method directly.
  @param theCommand The SMTP command to send.
  @param theFormat The format defining the variable arguments list.
*/
- (void) sendCommand: (SMTPCommand) theCommand  arguments: (NSString *) theFormat, ...;

@end

#endif // _Pantomime_H_CWSMTP

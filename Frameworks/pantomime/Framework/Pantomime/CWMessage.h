/*
**  CWMessage.h
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2017 2018 Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola
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

#ifndef _Pantomime_H_CWMessage
#define _Pantomime_H_CWMessage

#import <Pantomime/CWConstants.h>
#import <Pantomime/CWCacheManager.h>
#import <Pantomime/CWPart.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSCalendarDate.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSObject.h>

/*!
  @const PantomimeMessageFetchCompleted
*/
extern NSString* PantomimeMessageFetchCompleted;

/*!
  @const PantomimeMessageFetchFailed
*/
extern NSString* PantomimeMessageFetchFailed;

/*!
  @const PantomimeMessagePrefetchCompleted
*/
extern NSString* PantomimeMessagePrefetchCompleted;

/*!
  @const PantomimeMessagePrefetchFailed
*/
extern NSString* PantomimeMessagePrefetchFailed;

/*!
  @const PantomimeMessageChanged
  @discussion This notification is posted when message flags have changed
              but the called didn't ask for flag changes. 
*/
extern NSString* PantomimeMessageChanged;

/*!
  @const PantomimeMessageExpunged
  @discussion This notification is posted when a message is expunged
              but the called didn't expunge the mailbox.
*/
extern NSString* PantomimeMessageExpunged;


@class CWFlags;
@class CWFolder;
@class CWInternetAddress;

/*!
  @class CWMessage
  @discussion This class is used to describe Internet messages. This class
              extends the CWPart class and inherit all its methods.
*/
@interface CWMessage : CWPart <NSCoding>
{
  @protected
    NSData *_rawSource;

  @private
    NSMutableDictionary *_properties;
    NSMutableArray *_recipients;  
 
    NSArray *_references;
    CWFolder *_folder;
    CWFlags *_flags;

    unsigned int _message_number;
    BOOL _initialized;    
}

/*!
  @method initWithHeaders:
  @discussion This method is used to initialize the receiver with
              a predefined set of headers. The headers are specified
	      in a NSDictionary instance where the keys are the header
	      names (for example, "Content-Type") and the values are
	      the respective values of for each keys. This method class
	      -setHeaders:.
  @param theHeaders The NSDictionary instance holding all headers / values.
  @result A Message instance, nil on error.
*/
- (id) initWithHeaders: (NSDictionary *) theHeaders;

/*!
  @method initWithHeadersFromData:
  @discussion This method is used to initialize the receiver with
              a predefined set of headers in their raw representation.
              This method calls -setHeadersFromData:.
  @param theHeaders The headers in their raw represnetation.
  @result A Message instance, nil on error.
*/
- (id) initWithHeadersFromData: (NSData *) theHeaders;

/*!
  @method from
  @discussion This method is used to obtain the value of the
              "From" header.
  @result The value of the "From" header, as an CWInternetAddress instance.
*/
- (CWInternetAddress *) from;

/*!
  @method setFrom:
  @discussion This method is used to set the value of the "From:" header.
  @param theInternetAddress The CWInternetAddress instance.
*/
- (void) setFrom: (CWInternetAddress *) theInternetAddress;

/*!
  @method messageNumber
  @discussion This method is used to obtain the message sequence number (MSN)
              of the receiver. MSN have a special meaning for IMAP
	      messages (see 2.3.1.2. of RFC3501 for details).
  @result The MSN, 0 if none was previously set.
*/
- (unsigned int) messageNumber;

/*!
  @method setMessageNumber:
  @discussion This method is used to set the message number value
              of the receiver.
  @param theMessageNumber The value.
*/
- (void) setMessageNumber: (unsigned int) theMessageNumber;

/*!
  @method messageID
  @discussion This method is used to obtain the value of
              the "Message-ID" header.
  @result The value of the "Message-ID" header.
*/
- (NSString *) messageID;

/*!
  @method setMessageID:
  @discussion This method is used to set the value of
              the "Message-ID" header.
  @param theMessageID The value of the "Message-ID" header.
*/
- (void) setMessageID: (NSString *) theMessageID;

/*!
  @method inReplyTo
  @discussion This method is used to obtain the value of
              the "In-Reply-To" header.
  @result The value of the "In-Reply-To" header.
*/
- (NSString *) inReplyTo;

/*!
  @method setInReplyTo:
  @discussion This method is used to set the value of
              the "In-Reply-To" header.
  @param theInReplyTo The value of the "In-Reply-To" header.
*/
- (void) setInReplyTo: (NSString *) theInReplyTo;

/*!
  @method receivedDate
  @discussion This method is used to obtain the value of
              the "Date" header.
  @result The value of the "Date" header, as a NSCalendarDate instance.
*/
- (NSCalendarDate *) receivedDate;

/*!
  @method setReceivedDate:
  @discussion This method is used to set the value of
              the "Date" header.
  @param theDate The NSCalendarDate instance.
*/
- (void) setReceivedDate: (NSCalendarDate *) theDate;

/*!
  @method addRecipient:
  @discussion This method is used to add a recipient to the
              list of all recipients for the receiver. The
	      recipient type is determined by calling the
	      -type method on the CWInternetAddress's instance.
  @param theAddress The CWInternetAddress instance holding the
                    recipient to add to the list.
*/
- (void) addRecipient: (CWInternetAddress *) theAddress;

/*!
  @method removeRecipient:
  @discussion This method is used to remove the specified
              recipient from the receiver's list of recipients.
  @param theAddress The recipient to remove.
*/
- (void) removeRecipient: (CWInternetAddress *) theAddress;

/*!
  @method recipients
  @discussion This method is used to obtain the list of recipients
              of the receiver. All recipient types are returned.
  @result The array of recipients which are all CWInternetAddress instances.
*/
- (NSArray *) recipients;

/*!
  @method setRecipients:
  @discussion This method is used to add <i>theRecipients</i> to the
              list of the receiver's recipients.
  @param theRecipients The array of CWInternetAddress instances to add
                       to the receiver's list of recipients.
*/
- (void) setRecipients: (NSArray *) theRecipients;

/*!
  @method recipientsCount
  @discussion This method is used to obtain the number of recipients
              the receiver has.
  @result The count.
*/
- (NSUInteger) recipientsCount;

/*!
  @method removeAllRecipients:
  @discussion This method is used to remove all recipients from
              the receiver.
*/
- (void) removeAllRecipients;

/*!
  @method replyTo
  @discussion This method is used to obtain the value of the "Reply-To" header.
  @result The value of the "Reply-To" header, as an array of CWInternetAddress instances.
          If there are none, nil is returned.
*/
- (NSArray *) replyTo;

/*!
  @method setReplyTo:
  @discussion This method is used to set the value of the "Reply-To:" header.
  @param theAddressList An array of CWInternetAddress instances.
*/
- (void) setReplyTo: (NSArray *) theAddressList;

/*!
  @method subject
  @discussion This method is used to obtain the value of the
              "Subject" header.
  @result The value of the "Subject" header.
*/
- (NSString *) subject;

/*!
  @method setSubject:
  @discussion This method is used to set the value of the "Subject" header.
  @param theSubject The value to set.
*/
- (void) setSubject: (NSString *) theSubject;

/*!
  @method baseSubject
  @discussion This method is used to obtain the base subject. The base
              subject is basically the value of the "Subject" header
	      but without the "re" or "fwd" (or whatever) prefix.
  @result The base subject.
*/
- (NSString *) baseSubject;

/*!
  @method setBaseSubject:
  @discussion This method is used to set the base subject of
              the receiver.
  @param theBaseSubject The base subject to set.
*/
- (void) setBaseSubject: (NSString *) theBaseSubject;

/*!
  @method isInitialized
  @discussion This method is used to verify if a message has been
              initialized or not. An inititalized message is a message
	      for which all parts have been initilized. A message
	      for which only the headers are set is not an
	      initialized message.
  @result YES if the message is initialized, NO otherwise.
*/
- (BOOL) isInitialized;

/*!
  @method setInitialized:
  @discussion This method is used to initialize the message or
              free the resources taken by its content. Subclasses
	      of CWMessage sometimes overwrite this method.
  @param theBOOL YES if we want to load the content of the message
                 and initialize the receiver with it. NO if we
		 want to free the resources taken by the decoded content.
*/
- (void) setInitialized: (BOOL) theBOOL;

/*!
  @method flags
  @discussion This method is used to obtain the flags associated to
              the receiver.
  @result The CWFlags instance of the receiver.
*/
- (CWFlags *) flags;

/*!
  @method setFlags:
  @discussion This method is used to set the flags of the receiver,
              replacing any previous values set. Subclasses of
	      CWMessage sometimes overwrite this method.
  @param theFlags The new flags for the receiver.
*/
- (void) setFlags: (CWFlags *) theFlags;

/*!
  @method MIMEVersion
  @discussion This method is used to obtain the value of the
              "MIME-Version" header.
  @result The value of the header, nil if none was set.
*/
- (NSString *) MIMEVersion;

/*!
  @method setMIMEVersion:
  @discussion This method is used to set the value of the
              "MIME-Version" header, replacing any values
	      previously set.
  @param theMIMEVersion The new value for the header.
*/
- (void) setMIMEVersion: (NSString *) theMIMEVersion;

/*!
  @method reply:
  @discussion This method is used to contruct a new CWMessage
              instance to be used when replying to a
	      message. The returned message will always
	      use the UTF-8 charset. The message will NOT have a
	      content other than the plain text one(s).
  @param theMode The type of reply operation to do.
                 The default mode is PantomimeNormalReplyMode.
  @result A CWMessage instance used for replying.
*/
- (CWMessage *) reply: (PantomimeReplyMode) theMode;

/*!
  @method forward
  @discussion This method is used to contruct a new CWMessage
              instance to be used when forward a message.
	      The returned message will always use
	      the UTF-8 charset.
  @param theMode The type of forward operation to do.
  @result A CWMessage instance used for forwarding.
*/
- (CWMessage *) forward: (PantomimeForwardMode) theMode;

/*!
  @method addHeader: withValue:
  @discussion This method is used to add an extra header to the list of headers
              of the message.
  @param theName The header name, which should normally begin with an "X-".
  @param theValue The header value.
*/
- (void) addHeader: (NSString *) theName
         withValue: (NSString *) theValue;

/*!
  @method folder
  @discussion This method is used to get the associated
              receiver's folder.
  @result The CWFolder instance in which the message is
          stored, nil if no folder holds the receiver.
*/
- (CWFolder *) folder;

/*!
  @method setFolder:
  @discussion This method is used to set the associated folder
              to the message.
  @param theFolder The folder which holds the receiver.
*/
- (void) setFolder: (CWFolder *) theFolder;

/*!
  @method rawSource
  @discussion This method is used to obtain the raw
              representation of the receiver. Subclasses
	      will overwrite this method so it's not
	      blocking (see the documentation of this
	      method for CWIMAPMessage, for example).
  @result The raw representation, or nil if it has not
          been loaded.
*/
- (NSData *) rawSource;

/*!
  @method setRawSource:
  @discussion This method is used to set the raw representation
              of the receiver. No specific actions are taken
	      when invoking this method.
  @param theRawSource The raw source of the message.
*/
- (void) setRawSource: (NSData *) theRawSource;

/*!
  @method organization
  @discussion This method is used to obtain the value of the
              "Organization" header.
  @result The value of the "Organization" header.
*/
- (NSString *) organization;

/*!
  @method setOrganization:
  @discussion This method is used to set the value of the
              "Organization" header.
  @param theOrganization The new value of the header.
*/
- (void) setOrganization: (NSString *) theOrganization;

/*!
  @method propertyForKey:
  @discussion This method is used to get an extra property for the
               specified key.
  @result The property for the specified key, nil if key isn't found.
*/
- (id) propertyForKey: (id) theKey;

/*!
  @method setProperty: forKey:
  @discussion This method is used to set an extra property for the
              specified key on this folder. If nil is passed for
	      theProperty parameter, the value will actually be
	      REMOVED for theKey.
  @param theProperty The value of the property.
  @param theKey The key of the property.
*/
- (void) setProperty: (id) theProperty
              forKey: (id) theKey;

/*!
  @method resentDate
  @discussion This method is used to obtain the value of the
              "Resent-Date" header.
  @result The value of the "Resent-Date" header.
*/
- (NSCalendarDate *) resentDate;

/*!
  @method setResentDate:
  @discussion This method is used to set the value of the
              "Resent-Date" header.
  @param theResentDate The new value of the header.
*/
- (void) setResentDate: (NSCalendarDate *) theResentDate;

/*!
  @method resentFrom
  @discussion This method is used to obtain the value of the
              "Resent-From" header.
  @result The value of the "Resent-From" header.
*/
- (CWInternetAddress *) resentFrom;

/*!
  @method setResentFrom:
  @discussion This method is used to set the value of the
              "Resent-From" header.
  @param theInternetAddress The new value of the header.
*/
- (void) setResentFrom: (CWInternetAddress *) theInternetAddress;

/*!
  @method resentMessageID
  @discussion This method is used to obtain the value of the
              "Resent-Message-ID" header.
  @result The value of the "Resent-Message-ID" header.
*/
- (NSString *) resentMessageID;

/*!
  @method setResentMessageID:
  @discussion This method is used to set the value of the
              "Resent-Message-ID" header.
  @param theResentMessageID The new value of the header.
*/
- (void) setResentMessageID: (NSString *) theResentMessageID;

/*!
  @method resentSubject
  @discussion This method is used to obtain the value of the
              "Resent-Subject" header.
  @result The value of the "Resent-Subject" header.
*/
- (NSString *) resentSubject;

/*!
  @method setResentSubject:
  @discussion This method is used to set the value of the
              "Resent-Subject" header.
  @param theResentSubject The new value of the header.
*/
- (void) setResentSubject: (NSString *) theResentSubject;

/*!
  @method allReferences
  @discussion This method is used to obtain the value of the
              "References" header. The values are particularly
	      useful for message threading.
  @result The value of the "References" header. This corresponds
          to a NSArray of NSString instances. Each instance is normally
	  a Message-ID.
*/
- (NSArray *) allReferences;

/*!
  @method setReferences:
  @discussion This method is used to the value of the "References"
              header, replacing any previously defined value.
  @param theReferences The array of references.
*/
- (void) setReferences: (NSArray *) theReferences;

/*!
  @method addHeadersFromData:record:
  @discussion This method is used to add addionnal headers
              from their raw representation. It will not erase the
	      currently defined headers. It also updates
	      the cache record <i>theRecord</i> with the decoded
	      information.
  @param The additional headers, in their raw representation.
  @param theRecord The cache_record to update.
*/
- (void) addHeadersFromData: (NSData *) theHeaders  record: (cache_record *) theRecord;

/*!
  @method setHeadersFromData:record:
  @discussion This method initalize all the headers of a message
              from the raw data source. It replaces previously 
	      defined values of headers found in <i>theHeaders</i>.
	      It also updates the cache record <i>theRecord</i> with
	      the decoded information.
  @param theHeaders The bytes to use.
*/
- (void) setHeadersFromData: (NSData *) theHeaders record: (cache_record *) theRecord;
@end


//
// Message's comparison category
//
@interface CWMessage (Comparing)

- (NSComparisonResult) compareAccordingToNumber: (CWMessage *) aMessage;
- (NSComparisonResult) reverseCompareAccordingToNumber: (CWMessage *) aMessage;
- (NSComparisonResult) compareAccordingToDate: (CWMessage *) aMessage;
- (NSComparisonResult) reverseCompareAccordingToDate: (CWMessage *) aMessage;
- (NSComparisonResult) compareAccordingToSender: (CWMessage *) aMessage;
- (NSComparisonResult) reverseCompareAccordingToSender: (CWMessage *) aMessage;
- (NSComparisonResult) compareAccordingToSize: (CWMessage *) aMessage;
- (NSComparisonResult) reverseCompareAccordingToSize: (CWMessage *) aMessage;

@end

#endif // _Pantomime_H_CWMessage




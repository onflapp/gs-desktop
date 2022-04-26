/*
**  CWConstants.h
**
**  Copyright (c) 2001-2007 Ludovic Marcotte
**  Copyright (C) 2013-2017 The GNUstep team
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

#ifndef _Pantomime_H_CWConstants
#define _Pantomime_H_CWConstants

#ifdef GNUSTEP
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#endif

//
// The current version of Pantomime.
//
#define PANTOMIME_VERSION @"1.3.0"

//
// Useful macros that we must define ourself on OS X.
//
#ifdef MACOSX 
#define RETAIN(object)          [object retain]
#define RELEASE(object)         [object release]
#define AUTORELEASE(object)     [object autorelease]
#define TEST_RELEASE(object)    ({ if (object) [object release]; })
#define ASSIGN(object,value)    ({\
id __value = (id)(value); \
id __object = (id)(object); \
if (__value != __object) \
  { \
    if (__value != nil) \
      { \
        [__value retain]; \
      } \
    object = __value; \
    if (__object != nil) \
      { \
        [__object release]; \
      } \
  } \
})
#define DESTROY(object) ({ \
  if (object) \
    { \
      id __o = object; \
      object = nil; \
      [__o release]; \
    } \
})

#define NSLocalizedString(key, comment) \
  [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

#define _(X) NSLocalizedString (X, @"")
#endif

//
// We must define NSObject: -subclassResponsibility: on OS X.
//
#ifdef MACOSX
#import <Pantomime/CWMacOSXGlue.h>
#endif


//
// Only for older Mac versions
//
#if defined(__APPLE__) && (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4)
#ifndef NSUInteger
#define NSUInteger unsigned int
#endif
#ifndef NSInteger
#define NSInteger int
#endif
#endif


#ifndef NSDebugLog
#ifdef DEBUG
#define NSDebugLog(format, args...) \
do { NSLog(format, ##args); } while(0)
#else
#define NSDebugLog(format, args...)
#endif
#endif

//
// Some macros, to minimize the code.
//
#define PERFORM_SELECTOR_1(del, sel, name) ({ \
\
BOOL zBOOL; \
\
zBOOL = NO; \
\
if (del && [del respondsToSelector: sel]) \
{ \
  [del performSelector: sel \
       withObject: [NSNotification notificationWithName: name \
			    	   object: self]]; \
  zBOOL = YES; \
} \
\
zBOOL; \
})

#define PERFORM_SELECTOR_2(del, sel, name, obj, key) \
if (del && [del respondsToSelector: sel]) \
{ \
  [del performSelector: sel \
       withObject: [NSNotification notificationWithName: name \
			   	   object: self \
				   userInfo: [NSDictionary dictionaryWithObject: obj forKey: key]]]; \
}

#define PERFORM_SELECTOR_3(del, sel, name, info) \
if (del && [del respondsToSelector: sel]) \
{ \
  [del performSelector: sel \
       withObject: [NSNotification notificationWithName: name \
				   object: self \
				   userInfo: info]]; \
}

#define AUTHENTICATION_COMPLETED(del, s) \
POST_NOTIFICATION(PantomimeAuthenticationCompleted, self, [NSDictionary dictionaryWithObject: ((id)s?(id)s:(id)@"")  forKey:  @"Mechanism"]); \
PERFORM_SELECTOR_2(del, @selector(authenticationCompleted:), PantomimeAuthenticationCompleted, ((id)s?(id)s:(id)@""), @"Mechanism");


#define AUTHENTICATION_FAILED(del, s) \
NSLog(@"AUTHENTICATION_FAILED: |%@|", s); \
POST_NOTIFICATION(PantomimeAuthenticationFailed, self, [NSDictionary dictionaryWithObject: ((id)s?(id)s:(id)@"")  forKey:  @"Mechanism"]); \
PERFORM_SELECTOR_2(del, @selector(authenticationFailed:), PantomimeAuthenticationFailed, ((id)s?(id)s:(id)@""), @"Mechanism");

#define POST_NOTIFICATION(name, obj, info) \
[[NSNotificationCenter defaultCenter] postNotificationName: name \
  object: obj \
  userInfo: info]

/*!
  @typedef PantomimeEncoding
  @abstract Supported encodings.
  @discussion This enum lists the supported Content-Transfer-Encoding
              values. See RFC 2045 - 6. Content-Transfer-Encoding Header Field
	      (all all sub-sections) for a detailed description of the
	      possible values.
  @constant PantomimeEncodingNone No encoding.
  @constant PantomimeEncoding7bit No encoding, same value as PantomimeEncodingNone.
  @constant PantomimeEncodingQuotedPrintable The quoted-printable encoding.
  @constant PantomimeEncodingBase64 The base64 encoding.
  @constant PantomimeEncoding8bit Identity encoding.
  @constant PantomimeEncodingBinary Identity encoding.
*/
typedef enum
{
  PantomimeEncodingNone = 0,
  PantomimeEncoding7bit = 0,
  PantomimeEncodingQuotedPrintable = 1,
  PantomimeEncodingBase64 = 2,
  PantomimeEncoding8bit = 3,
  PantomimeEncodingBinary = 4
} PantomimeEncoding;


/*!
  @typedef PantomimeFolderFormat
  @abstract The supported folder formats.
  @discussion Pantomime supports various local folder formats. Currently,
              the mbox and maildir formats are supported. Also, a custom
	      format is defined to represent folder which holds folders
	      (ie., not messages).
  @constant PantomimeFormatMbox The mbox format.
  @constant PantomimeFormatMaildir The maildir format.
  @constant PantomimeFormatMailSpoolFile The mail spool file, in mbox format but without cache synchronization.
  @constant PantomimeFormatFolder Custom format.
*/
typedef enum {
  PantomimeFormatMbox = 0,
  PantomimeFormatMaildir = 1,
  PantomimeFormatMailSpoolFile = 2,
  PantomimeFormatFolder = 3
} PantomimeFolderFormat;


/*!
  @typedef PantomimeMessageFormat
  @abstract The format of a message.
  @discussion Pantomime supports two formats when encoding
              plain/text parts. The formats are described in RFC 2646.
  @constant PantomimeFormatUnknown Unknown format.
  @constant PantomimeFormatFlowed The "format=flowed" is used.
*/
typedef enum
{
  PantomimeFormatUnknown = 0,
  PantomimeFormatFlowed = 1
} PantomimeMessageFormat;


/*!
  @typedef PantomimeFlag
  @abstract Valid message flags.
  @discussion This enum lists valid message flags. Flags can be combined
              using a bitwise OR.
  @constant PantomimeAnswered The message has been answered.
  @constant PantomimeDraft The message is an unsent, draft message.
  @constant PantomimeFlagged The message is flagged.
  @constant PantomimeRecent The message has been recently received.
  @constant PantomimeSeen The message has been read.
  @constant PantomimeDeleted The message is marked as deleted.
*/
typedef enum
{
  PantomimeAnswered = 1,
  PantomimeDraft = 2,
  PantomimeFlagged = 4,
  PantomimeRecent = 8,
  PantomimeSeen = 16,
  PantomimeDeleted = 32
} PantomimeFlag;


/*!
  @typedef PantomimeFolderType
  @abstract Flags/name attributes for mailboxes/folders.
  @discussion This enum lists the potential mailbox / folder
              flags which some IMAP servers can enforce.
	      Those flags have few meaning for POP3 and
	      Local mailboxes. Flags can be combined using
	      a bitwise OR.
  @constant PantomimeHoldsFolders The folder holds folders.
  @constant PantomimeHoldsMessages The folder holds messages.
  @constant PantomimeNoInferiors The folder has no sub-folders.
  @constant PantomimeNoSelect The folder can't be opened.
  @constant PantomimeMarked The folder is marked as "interesting".
  @constant PantomimeUnmarked The folder does not contain any new
                              messages since the last time it has been open.
*/
typedef enum
{
  PantomimeHoldsFolders = 1,
  PantomimeHoldsMessages = 2,
  PantomimeNoInferiors = 4,
  PantomimeNoSelect = 8,
  PantomimeMarked = 16,
  PantomimeUnmarked = 32
} PantomimeFolderType;


/*!
  @typedef PantomimeSearchMask
  @abstract Mask for Folder: -search: mask: options:
  @discussion This enum lists the possible values of the
              search mask. Values can be combined using
	      a bitwise OR.
  @constant PantomimeFrom Search in the "From:" header value.
  @constant PantomimeTo Search in the "To:" header value.
  @constant PantomimeSubject Search in the "Subject:" header value.
  @constant PantomimeContent Search in the message content.
*/
typedef enum
{
  PantomimeFrom = 1,
  PantomimeTo = 2,
  PantomimeSubject = 4,
  PantomimeContent = 8
} PantomimeSearchMask;


/*!
  @typedef PantomimSearchOption
  @abstract Options for Folder: -search: mask: options:
  @discussion This enum lists the possible options when
              performing a search.
  @constant PantomimeCaseInsensitiveSearch Don't consider the case when performing a search operation.
  @constant PantomimeRegularExpression The search criteria represents a regular expression.
*/
typedef enum
{
  PantomimeCaseInsensitiveSearch = 1,
  PantomimeRegularExpression = 2
} PantomimeSearchOption;


/*!
  @typedef PantomimeFolderMode
  @abstract Valid modes for folder.
  @discussion This enum lists the valid mode to be used when
              opening a folder.
  @constant PantomimeUnknownMode Unknown mode.
  @constant PantomimeReadOnlyMode The folder will be open in read-only.
  @constant PantomimeReadWriteMode The folder will be open in read-write.
*/
typedef enum
{
  PantomimeUnknownMode = 1,
  PantomimeReadOnlyMode = 2,
  PantomimeReadWriteMode = 3
} PantomimeFolderMode;

/*!
  @typedef PantomimeForwardMode
  @abstract Valid modes when forwarding a message.
  @discussion This enum lists the valid mode to be
              used when forwarding a message.
  @constant PantomimeAttachmentForwardMode The message will be attached.
  @constant PantomimeInlineForwardMode The text parts of the message will be
                                       extracted and included inline in the
				       forwarded response.
*/
typedef enum
{
  PantomimeAttachmentForwardMode = 1,
  PantomimeInlineForwardMode = 2
} PantomimeForwardMode;


/*!
  @typedef PantomimeContentDisposition
  @abstract Valid modes when setting a Content-Disposition.
  @discussion This enum lists the valid Content-Disposition
              as stated in the RFC2183 standard.
  @constant PantomimeAttachmentDisposition The part is separated from the mail body.
  @constant PantomimeInlineDisposition The part is part of the mail body.
*/
typedef enum
{
  PantomimeAttachmentDisposition = 1,
  PantomimeInlineDisposition = 2
} PantomimeContentDisposition;

/*!
  @typedef PantomimeReplyMode
  @abstract Valid modes when replying to a message.
  @discussion This enum lists the valid modes to be
              used when replying to a message. Those
	      modes are to be used with CWMessage: -reply:
	      PantomimeSimpleReplyMode and PantomimeNormalReplyMode
	      can NOT be combined but can be individually combined
	      with PantomimeReplyAllMode.
  @constant PantomimeSimpleReplyMode Reply to the sender, without a message content
  @constant PantomimeNormalReplyMode Reply to the sender, with a properly build message content.
  @constant PantomimeReplyAllMode Reply to all recipients.
*/
typedef enum
{
  PantomimeSimpleReplyMode = 1,
  PantomimeNormalReplyMode = 2,
  PantomimeReplyAllMode = 4
} PantomimeReplyMode;


/*!
  @typedef PantomimeRecipientType
  @abstract Valid recipient types.
  @discussion This enum lists the valid kind of recipients
              a message can have.
  @constant PantomimeToRecipient Recipient which will appear in the "To:" header value.
  @constant PantomimeCcRecipient Recipient which will appear in the "Cc:" header value.
  @constant PantomimeBccRecipient Recipient which will obtain a black carbon copy of the message.
  @constant PantomimeResentToRecipient Recipient which will appear in the "Resent-To:" header value.
  @constant PantomimeResentCcRecipient Recipient which will appear in the "Resent-Cc:" header value.
  @constant PantomimeResentBccRecipient Recipient which will obtain a black carbon copy of the message
                                        being redirected.
*/
typedef enum
{
  PantomimeToRecipient = 1,
  PantomimeCcRecipient = 2,
  PantomimeBccRecipient = 3,
  PantomimeResentToRecipient = 4,
  PantomimeResentCcRecipient = 5,
  PantomimeResentBccRecipient = 6
} PantomimeRecipientType;

#endif // _Pantomime_H_CWConstants

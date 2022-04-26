/*
**  CWConstants.m
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

#import <Foundation/NSString.h>

// CWDNSManager notifications
NSString* PantomimeDNSResolutionCompleted = @"PantomimeDNSResolutionCompleted";
NSString* PantomimeDNSResolutionFailed = @"PantomimeDNSResolutionFailed";

// CWFolder notifications
NSString* PantomimeFolderAppendCompleted = @"PantomimeFolderAppendCompleted";
NSString* PantomimeFolderAppendFailed = @"PantomimeFolderCloseFailed";
NSString* PantomimeFolderCloseCompleted = @"PantomimeFolderCloseCompleted";
NSString* PantomimeFolderCloseFailed = @"PantomimeFolderAppendFailed";
NSString* PantomimeFolderExpungeCompleted = @"PantomimeFolderExpungeCompleted";
NSString* PantomimeFolderExpungeFailed = @"PantomimeFolderExpungeFailed";
NSString* PantomimeFolderListCompleted = @"PantomimeFolderListCompleted";
NSString* PantomimeFolderListFailed = @"PantomimeFolderListFailed";
NSString* PantomimeFolderListSubscribedCompleted = @"PantomimeFolderListSubscribedCompleted";
NSString* PantomimeFolderListSubscribedFailed = @"PantomimeFolderListSubscribedFailed";
NSString* PantomimeFolderOpenCompleted = @"PantomimeFolderOpenCompleted";
NSString* PantomimeFolderOpenFailed = @"PantomimeFolderOpenFailed";
NSString* PantomimeFolderPrefetchCompleted = @"PantomimeFolderPrefetchCompleted";
NSString* PantomimeFolderPrefetchFailed = @"PantomimeFolderPrefetchFailed";
NSString* PantomimeFolderSearchCompleted = @"PantomimeFolderSearchCompleted";
NSString* PantomimeFolderSearchFailed = @"PantomimeFolderSearchFailed";

// CWIMAPFolder notifications
NSString* PantomimeMessagesCopyCompleted = @"PantomimeMessagesCopyCompleted";
NSString* PantomimeMessagesCopyFailed = @"PantomimeMessagesCopyFailed";
NSString* PantomimeMessageStoreCompleted = @"PantomimeMessageStoreCompleted";
NSString* PantomimeMessageStoreFailed = @"PantomimeMessageStoreFailed";

// CWIMAPStore notifications
NSString* PantomimeFolderStatusCompleted = @"PantomimeFolderStatusCompleted";
NSString* PantomimeFolderStatusFailed = @"PantomimeFolderStatusFailed";
NSString* PantomimeFolderSubscribeCompleted = @"PantomimeFolderSubscribeCompleted";
NSString* PantomimeFolderSubscribeFailed = @"PantomimeFolderSubscribeFailed";
NSString* PantomimeFolderUnsubscribeCompleted = @"PantomimeFolderUnsubscribeCompleted";
NSString* PantomimeFolderUnsubscribeFailed = @"PantomimeFolderUnsubscribeFailed";

// CWMessage notifications
NSString* PantomimeMessageChanged = @"PantomimeMessageChanged";
NSString* PantomimeMessageExpunged = @"PantomimeMessageExpunged";
NSString* PantomimeMessageFetchCompleted = @"PantomimeMessageFetchCompleted";
NSString* PantomimeMessageFetchFailed = @"PantomimeMessageFetchFailed";
NSString* PantomimeMessagePrefetchCompleted = @"PantomimeMessagePrefetchCompleted";
NSString* PantomimeMessagePrefetchFailed = @"PantomimeMessagePrefetchFailed";

// CWService notifications
NSString* PantomimeProtocolException = @"PantomimeProtocolException";
NSString* PantomimeAuthenticationCompleted = @"PantomimeAuthenticationCompleted";
NSString* PantomimeAuthenticationFailed = @"PantomimeAuthenticationCompleted";
NSString* PantomimeConnectionEstablished = @"PantomimeConnectionEstablished";
NSString* PantomimeConnectionLost = @"PantomimeConnectionLost";
NSString* PantomimeConnectionTerminated = @"PantomimeConnectionTerminated";
NSString* PantomimeConnectionTimedOut = @"PantomimeConnectionTimedOut";
NSString* PantomimeRequestCancelled = @"PantomimeRequestCancelled";
NSString* PantomimeServiceInitialized = @"PantomimeServiceInitialized";
NSString* PantomimeServiceReconnected = @"PantomimeServiceReconnected";

// CWSMTP notifications
NSString* PantomimeRecipientIdentificationCompleted = @"PantomimeRecipientIdentificationCompleted";
NSString* PantomimeRecipientIdentificationFailed = @"PantomimeRecipientIdentificationFailed";
NSString* PantomimeTransactionInitiationCompleted = @"PantomimeTransactionInitiationCompleted";
NSString* PantomimeTransactionInitiationFailed = @"PantomimeTransactionInitiationFailed";
NSString* PantomimeTransactionResetCompleted = @"PantomimeTransactionResetCompleted";
NSString* PantomimeTransactionResetFailed = @"PantomimeTransactionResetFailed";

// CWStore notifications
NSString* PantomimeFolderCreateCompleted = @"PantomimeFolderCreateCompleted";
NSString* PantomimeFolderCreateFailed = @"PantomimeFolderCreateFailed";
NSString* PantomimeFolderDeleteCompleted = @"PantomimeFolderDeleteCompleted";
NSString* PantomimeFolderDeleteFailed = @"PantomimeFolderDeleteFailed";
NSString* PantomimeFolderRenameCompleted = @"PantomimeFolderRenameCompleted";
NSString* PantomimeFolderRenameFailed = @"PantomimeFolderRenameFailed";

// CWTransport notifications
NSString* PantomimeMessageNotSent = @"PantomimeMessageNotSent";
NSString* PantomimeMessageSent = @"PantomimeMessageSent";


/***************************************************************************
                                IRCObject.h
                          -------------------
    begin                : Thu May 30 22:06:25 UTC 2002
    copyright            : (C) 2005 by Andrew Ruder
                         : (C) 2013 The GNUstep Application Project
    email                : aeruder@ksu.edu
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU Lesser General Public License as        *
 *   published by the Free Software Foundation; either version 2.1 of the  *
 *   License or (at your option) any later version.                        *
 *                                                                         *
 ***************************************************************************/

@class IRCObject, DCCObject, DCCReceiveObject, DCCSendObject;

#ifndef IRC_OBJECT_H
#define IRC_OBJECT_H

#import "LineObject.h"
#import "NetTCP.h"
#import <Foundation/NSObject.h>

extern NSString *IRCException;

/**
 * Additions of NSString that are used to upper/lower case strings taking
 * into account that on many servers {}|^ are lowercase forms of []\~.
 * Try not to depend on this fact, some servers nowadays are drifting away
 * from this idea and will treat them as different characters entirely.
 */
@interface NSString (IRCAddition)
/**
 * Returns an uppercased string (and converts any of {}|^ characters found
 * to []\~ respectively).
 */
- (NSString *)uppercaseIRCString;
/**
 * Returns a lowercased string (and converts any of []\~ characters found 
 * to {}|^ respectively).
 */
- (NSString *)lowercaseIRCString;
/**
 * Returns a uppercased string (and converts any of {}| characters found
 * to []\ respectively).  The original RFC 1459 forgot to include these
 * and thus this method is included.
 */
- (NSString *)uppercaseStrictRFC1459IRCString;
/**
 * Returns a lowercased string (and converts any of []\ characters found
 * to {}| respectively).  The original RFC 1459 forgot to include these
 * and thus this method is included.
 */
- (NSString *)lowercaseStrictRFC1459IRCString;
@end

/* When one of the callbacks ends with from: (NSString *), that last 
 * argument is where the callback originated from.  It is usually in a slightly
 * different format: nick!host.  So if you want the nick you use
 * ExtractIRCNick, if you want the host you use ExtractIRCHost, and if you
 * want both, you can use SeparateIRCNickAndHost(which stores nick then host
 * in that order)
 * 
 * If, for example, the message originates from a server, it will not be in
 * this format, in this case, ExtractIRCNick will return the original string
 * and ExtractIRCHost will return nil, and SeparateIRCNickAndHost will return
 * an array with just one object.
 * 
 * So, if you are using a callback, and the last argument has a from: before
 * it, odds are you may want to look into using these functions.
 */

/**
 * Returns the nickname portion of a prefix.  On any argument after
 * from: in the class reference, the name could be in the format of
 * nickname!host.  Will always return a valid string.
 */
NSString *ExtractIRCNick(NSString *prefix);
/**
 * Returns the host portion of a prefix.  On any argument after
 * from: in the class reference, the name could be in the format
 * nickname!host.  Returns nil if the prefix is not in the correct
 * format.
 */
NSString *ExtractIRCHost(NSString *prefix);
/**
 * Returns an array of the nickname/host of a prefix.  In the case that
 * the array has only one object, it will be the nickname.  In the case that
 * it has two, it will be [nickname, host].  The object will always be at
 * least one object long and never more than two.
 */
NSArray *SeparateIRCNickAndHost(NSString *prefix);

/**
 * <p>
 * IRCObject handles all aspects of an IRC connection.  In almost all
 * cases, you will want to override this class and implement just the
 * callback methods specified in [IRCObject(Callbacks)] to handle 
 * everything.
 * </p>
 * <p>
 * A lot of arguments may not contain spaces.  The general procedure on 
 * processing these arguments is that the method will cut the string
 * off at the first space and use the part of the string before the space
 * and fail only if that string is still invalid.  Try to avoid
 * passing strings with spaces as the arguments to the methods 
 * that warn not to.
 * </p>
 */
@interface IRCObject : LineObject
	{
		NSString *nick;
		BOOL connected;
		
		NSString *userName;
		NSString *realName;
		NSString *password;

		NSString *errorString;
		
		NSStringEncoding defaultEncoding;
		NSMapTable *targetToEncoding;
		NSMutableDictionary *targetToOriginalTarget;

		SEL lowercasingSelector;
	}
/**
 * <init />
 * Initializes the IRCObject and retains the arguments for the next connection.
 * Uses -setNick:, -setUserName:, -setRealName:, and -setPassword: to save the
 * arguments.
 */
- initWithNickname: (NSString *)aNickname
   withUserName: (NSString *)aUser withRealName: (NSString *)aRealName
   withPassword: (NSString *)aPassword;

/**
 * Set the lowercasing selector.  This is the selector that is called
 * on a NSString to get the lowercase form.  Used to determine if two
 * nicknames are equivalent.  Generally <var>aSelector</var> would be
 * either @selector(lowercaseString) or @selector(lowercaseIRCString).
 * By default, this is lowercaseIRCString but will be autodetected
 * from the server if possible.  It will be reset to lowercaseIRCString
 * upon reconnection.
 */
- setLowercasingSelector: (SEL)aSelector;

/**
 * Return the lowercasing selector.  See -setLowercasingSelector: for
 * more information on the use of this lowercasing selector.
 */
- (SEL)lowercasingSelector;

/**
 * Use the lowercasingSelector to compare two strings.  Returns a 
 * NSComparisonResult ( NSOrderedAscending, NSOrderedSame or 
 * NSOrderedDescending )
 */
- (NSComparisonResult)caseInsensitiveCompare: (NSString *)aString1
   to: (NSString *)aString2;

/**
 * Sets the nickname that this object will attempt to use upon a connection.
 * Do not use this to change the nickname once the object is connected, this
 * is only used when it is actually connecting.  This method returns nil if
 * <var>aNickname</var> is invalid and will set the error string accordingly.
 * <var>aNickname</var> is invalid if it contains a space or is zero-length.
 */
- setNick: (NSString *)aNickname;
/**
 * Returns the nickname that this object will use on connecting next time.
 */
- (NSString *)nick;

/**
 * Sets the user name that this object will give to the server upon the
 * next connection.  If <var>aUser</var> is invalid, it will use the user name
 * of "netclasses".  <var>aUser</var> should not contain spaces.
 * This method will always succeed.
 */
- setUserName: (NSString *)aUser;
/**
 * Returns the user name that will be used upon the next connection.
 */
- (NSString *)userName;

/**
 * Sets the real name that will be passed to the IRC server on the next
 * connection.  If <var>aRealName</var> is nil or zero-length, the name
 * "John Doe" shall be used.  This method will always succeed.
 */
- setRealName: (NSString *)aRealName;
/**
 * Returns the real name that will be used upon the next connection.
 */
- (NSString *)realName;

/**
 * Sets the password that will be used upon connecting to the IRC server.
 * <var>aPass</var> can be nil or zero-length, in which case no password
 * shall be used. <var>aPass</var> may not contain a space.  Will return 
 * nil and set the error string if this fails. 
 */
- setPassword: (NSString *)aPass;
/** 
 * Returns the password that will be used upon the next connection to a 
 * IRC server.
 */
- (NSString *)password;

/**
 * Returns a string that describes the last error that happened.
 */
- (NSString *)errorString;

/** 
 * Returns YES when the IRC object is fully connected and registered with
 * the IRC server.  Returns NO if the connection has not made or this 
 * connection has not fully registered with the server.
 */
- (BOOL)connected;

/**
 * Sets the encoding that will be used for incoming as well as outgoing
 * messages.  <var>aEncoding</var> should be an 8-bit encoding for a typical
 * IRC server.  Uses the system default by default.
 */
- setEncoding: (NSStringEncoding)aEncoding;

/**
 * Sets the encoding that will be used for incoming as well as outgoing
 * messages to a specific target.  <var>aEncoding</var> should be an 8-bit
 * encoding for a typical IRC server.  Uses the encoding set with 
 * setEncoding: by default.
 */
- setEncoding: (NSStringEncoding)aEncoding forTarget: (NSString *)aTarget;

/**
 * Returns the encoding currently being used by the connection.
 */
- (NSStringEncoding)encoding;

/**
 * Return the encoding for <var>aTarget</var>.
 */
- (NSStringEncoding)encodingForTarget: (NSString *)aTarget;

/**
 * Remove the encoding for <var>aTarget</var>.
 */
- (void)removeEncodingForTarget: (NSString *)aTarget;

/**
 * Return all targets with a specific encoding.
 */
- (NSArray *)targetsWithEncodings;

// IRC Operations
/**
 * Sets the nickname to the <var>aNick</var>.  This method is quite similar
 * to -setNick: but this will also actually send the nick change request to
 * the server if connected, and will only affect the nickname stored by the 
 * object (which is returned with -nick) if the the name change was successful
 * or the object is not yet registered/connected.  Please see RFC 1459 for
 * more information on the NICK command.
 */
- (id)changeNick: (NSString *)aNick;

/** 
 * Quits IRC with an optional message.  <var>aMessage</var> can have 
 * spaces.  If <var>aMessage</var> is nil or zero-length, the server
 * will often provide its own message.  Please see RFC 1459 for more
 * information on the QUIT command.
 */
- (id)quitWithMessage: (NSString *)aMessage;

/**
 * Leaves the channel <var>aChannel</var> with the optional message
 * <var>aMessage</var>.  <var>aMessage</var> may contain spaces, and
 * <var>aChannel</var> may not.  <var>aChannel</var> may also be a 
 * comma separated list of channels.  Please see RFC 1459 for more 
 * information on the PART command.
 */
- (id)partChannel: (NSString *)aChannel withMessage: (NSString *)aMessage;

/**
 * Joins the channel <var>aChannel</var> with an optional password of
 * <var>aPassword</var>.  Neither may contain spaces, and both may be
 * comma separated for multiple channels/passwords.  If there is one
 * or more passwords, it should match the number of channels specified
 * by <var>aChannel</var>.  Please see RFC 1459 for more information on
 * the JOIN command.
 */
- (id)joinChannel: (NSString *)aChannel withPassword: (NSString *)aPassword;

/**
 * Sends a CTCP <var>aCTCP</var> reply to <var>aPerson</var> with the 
 * argument <var>args</var>.  <var>args</var> may contain spaces and is
 * optional while the rest may not.  This method should be used to 
 * respond to a CTCP message sent by another client. See
 * -sendCTCPRequest:withArgument:to:
 */
- (id)sendCTCPReply: (NSString *)aCTCP withArgument: (NSString *)args
   to: (NSString *)aPerson;

/**
 * Sends a CTCP <var>aCTCP</var> request to <var>aPerson</var> with an
 * optional argument <var>args</var>.  <var>args</var> may contain a space
 * while the rest may not.  This should be used to request CTCP information
 * from another client and never for responding.  See 
 * -sendCTCPReply:withArgument:to:
 */
- (id)sendCTCPRequest: (NSString *)aCTCP withArgument: (NSString *)args
   to: (NSString *)aPerson;

/**
 * Sends a message <var>aMessage</var> to <var>aReceiver</var>.
 * <var>aReceiver</var> may be a nickname or a channel name.  
 * <var>aMessage</var> may contain spaces.  This is used to carry 
 * out the basic communication over IRC.  Please see RFC 1459 for more
 * information on the PRIVMSG message.
 */
- (id)sendMessage: (NSString *)aMessage to: (NSString *)aReceiver;

/**
 * Sends a notice <var>aNotice</var> to <var>aReceiver</var>.  
 * <var>aReceiver</var> may not contain a space.  This is generally
 * not used except for system messages and should rarely be used by
 * a regular client.  Please see RFC 1459 for more information on the
 * NOTICE command.
 */
- (id)sendNotice: (NSString *)aNotice to: (NSString *)aReceiver;

/**
 * Sends an action <var>anAction</var> to the receiver <var>aReceiver</var>.
 * This is similar to a message but will often be displayed such as:<br /><br />
 * &lt;nick&gt; &lt;anAction&gt;<br /><br /> and can be used effectively to display things
 * that you are <em>doing</em> rather than saying.  <var>anAction</var>
 * may contain spaces.
 */
- (id)sendAction: (NSString *)anAction to: (NSString *)aReceiver;

/**
 * This method attempts to become an IRC operator with name <var>aName</var>
 * and password <var>aPassword</var>.  Neither may contain spaces.  This is
 * a totally different concept than channel operators since it refers to 
 * operators of the server as a whole.  Please see RFC 1459 for more information
 * on the OPER command.
 */
- (id)becomeOperatorWithName: (NSString *)aName withPassword: (NSString *)aPassword;

/**
 * Requests the names on a channel <var>aChannel</var>.  If <var>aChannel</var>
 * is not specified, all users in all channels will be returned.  The information
 * will be returned via a <var>RPL_NAMREPLY</var> numeric message.  See the
 * RFC 1459 for more information on the NAMES command.
 */
- (id)requestNamesOnChannel: (NSString *)aChannel;

/**
 * Requests the Message-Of-The-Day from server <var>aServer</var>.  <var>aServer</var>
 * is optional and may not contain spaces if present.  The message of the day
 * is returned through the <var>RPL_MOTD</var> numeric command.
 */
- (id)requestMOTDOnServer: (NSString *)aServer;

/**
 * Requests size information from an optional <var>aServer</var> and
 * optionally forwards it to <var>anotherServer</var>.  See RFC 1459 for
 * more information on the LUSERS command
 */
- (id)requestSizeInformationFromServer: (NSString *)aServer
                      andForwardTo: (NSString *)anotherServer;

/**
 * Queries the version of optional <var>aServer</var>.  Please see 
 * RFC 1459 for more information on the VERSION command.
 */
- (id)requestVersionOfServer: (NSString *)aServer;

/**
 * Returns a series of statistics from <var>aServer</var>.  Specific 
 * queries can be made with the optional <var>query</var> argument.  
 * Neither may contain spaces and both are optional.  See RFC 1459 for
 * more information on the STATS message
 */
- (id)requestServerStats: (NSString *)aServer for: (NSString *)query;

/** 
 * Used to list servers connected to optional <var>aServer</var> with
 * an optional mask <var>aLink</var>.  Neither may contain spaces.
 * See the RFC 1459 for more information on the LINKS command.
 */
- (id)requestServerLink: (NSString *)aLink from: (NSString *)aServer;

/**
 * Requests the local time from the optional server <var>aServer</var>.  
 * <var>aServer</var> may not contain spaces.  See RFC 1459 for more 
 * information on the TIME command.
 */
- (id)requestTimeOnServer: (NSString *)aServer;

/**
 * Requests that <var>aServer</var> connects to <var>connectServer</var> on
 * port <var>aPort</var>.  <var>aServer</var> and <var>aPort</var> are optional
 * and none may contain spaces.  See RFC 1459 for more information on the 
 * CONNECT command.
 */
- (id)requestServerToConnect: (NSString *)aServer to: (NSString *)connectServer
                  onPort: (NSString *)aPort;

/**
 * This message will request the route to a specific server from a client.
 * <var>aServer</var> is optional and may not contain spaces; please see
 * RFC 1459 for more information on the TRACE command.
 */
- (id)requestTraceOnServer: (NSString *)aServer;

/**
 * Request the name of the administrator on the optional server
 * <var>aServer</var>.  <var>aServer</var> may not contain spaces.  Please
 * see RFC 1459 for more information on the ADMIN command.
 */
- (id)requestAdministratorOnServer: (NSString *)aServer;

/**
 * Requests information on a server <var>aServer</var>.  <var>aServer</var>
 * is optional and may not contain spaces.  Please see RFC 1459 for more 
 * information on the INFO command.
 */
- (id)requestInfoOnServer: (NSString *)aServer;

/**
 * Used to request that the current server reread its configuration files.
 * Please see RFC 1459 for more information on the REHASH command.
 */
- (id)requestServerRehash;

/**
 * Used to request a shutdown of a server.  Please see RFC 1459 for additional
 * information on the DIE command.
 */
- (id)requestServerShutdown;

/**
 * Requests a restart of a server.  Please see RFC 1459 for additional 
 * information on the RESTART command.
 */
- (id)requestServerRestart;

/** 
 * Requests a list of users logged into <var>aServer</var>.  
 * <var>aServer</var> is optional and may contain spaces.  Please see 
 * RFC 1459 for additional information on the USERS message.
 */
- (id)requestUserInfoOnServer: (NSString *)aServer;

/**
 * Requests information on the precense of certain nicknames listed in 
 * <var>userList</var> on the network.  <var>userList</var> is a space 
 * separated list of users.  For each user that is present, its name will
 * be added to the reply through the numeric message <var>RPL_ISON</var>.
 * See RFC 1459 for more information on the ISON message.
 */
- (id)areUsersOn: (NSString *)userList;

/**
 * Sends a message to all operators currently online.  The actual implementation
 * may vary from server to server in regards to who can send and receive it.
 * <var>aMessage</var> is the message to be sent and may contain spaces. 
 * Please see RFC 1459 for more information regarding the WALLOPS command.
 */
- (id)sendWallops: (NSString *)aMessage;

/**
 * Requests a list of users with a matching mask <var>aMask</var> against 
 * their username and/or host.  This can optionally be done just against 
 * the IRC operators. The mask <var>aMask</var> is optional and may not 
 * contain spaces.  Please see RFC 1459 for more information regarding the
 * WHO message.
 */
- (id)listWho: (NSString *)aMask onlyOperators: (BOOL)operators;

/**
 * Requests information on a user <var>aPerson</var>.  <var>aPerson</var>
 * may also be a comma separated list for additional users.  <var>aServer</var>
 * is optional and neither argument may contain spaces.  Refer to RFC 1459 for
 * additional information on the WHOIS command.
 */
- (id)whois: (NSString *)aPerson onServer: (NSString *)aServer;

/** 
 * Requests information on a user <var>aPerson</var> that is no longer 
 * connected to the server <var>aServer</var>.  A possible maximum number
 * of entries <var>aNumber</var> may be displayed.  All arguments may not
 * contain spaces and <var>aServer</var> and <var>aNumber</var> are optional.
 * Please refer to RFC 1459 for more information regarding the WHOWAS message.
 */
- (id)whowas: (NSString *)aPerson onServer: (NSString *)aServer
                     withNumberEntries: (NSString *)aNumber;

/**
 * Used to kill the connection to <var>aPerson</var> with a possible comment
 * <var>aComment</var>.  This is often used by servers when duplicate nicknames
 * are found and may be available to the IRC operators.  <var>aComment</var>
 * is optional and <var>aPerson</var> may not contain spaces.  Please see 
 * RFC 1459 for additional information on the KILL command.
 */
- (id)kill: (NSString *)aPerson withComment: (NSString *)aComment;

/**
 * Sets the topic for channel <var>aChannel</var> to <var>aTopic</var>.
 * If the <var>aTopic</var> is omitted, the topic for <var>aChannel</var>
 * will be returned through the <var>RPL_TOPIC</var> numeric message.  
 * <var>aChannel</var> may not contain spaces.  Please refer to the 
 * TOPIC command in RFC 1459 for more information.
 */
- (id)setTopicForChannel: (NSString *)aChannel to: (NSString *)aTopic;

/** 
 * Used to query or set the mode on <var>anObject</var> to the mode specified
 * by <var>aMode</var>.  Flags can be added by adding a '+' to the <var>aMode</var>
 * string or removed by adding a '-' to the <var>aMode</var> string.  These flags
 * may optionally have arguments specified in <var>aList</var> and may be applied
 * to the object specified by <var>anObject</var>.  Examples:
 * <example>
 * aMode: @"+i" anObject: @"#gnustep" withParams: nil
 *   sets the channel "#gnustep" to invite only.
 * aMode: @"+o" anObject: @"#gnustep" withParams: (@"aeruder")
 *   makes aeruder a channel operator of #gnustep
 * </example>
 * Many servers have differing implementations of these modes and may have various
 * modes available to users.  None of the arguments may contain spaces.  Please
 * refer to RFC 1459 for additional information on the MODE message.
 */
- (id)setMode: (NSString *)aMode on: (NSString *)anObject 
                     withParams: (NSArray *)aList;
					 
/**
 * Lists channel information about the channel specified by <var>aChannel</var>
 * on the server <var>aServer</var>.  <var>aChannel</var> may be a comma separated
 * list and may not contain spaces.  <var>aServer</var> is optional.  If <var>aChannel</var>
 * is omitted, then all channels on the server will be listed.  Please refer
 * to RFC 1459 for additional information on the LIST command.
 */
- (id)listChannel: (NSString *)aChannel onServer: (NSString *)aServer;

/**
 * This message will invite <var>aPerson</var> to the channel specified by
 * <var>aChannel</var>.  Neither may contain spaces and both are required.
 * Please refer to RFC 1459 concerning the INVITE command for additional 
 * information.
 */
- (id)invite: (NSString *)aPerson to: (NSString *)aChannel;

/**
 * Kicks the user <var>aPerson</var> off of the channel <var>aChannel</var>
 * for the reason specified in <var>aReason</var>.  <var>aReason</var> may 
 * contain spaces and is optional.  If omitted the server will most likely
 * supply a default message.  <var>aPerson</var> and <var>aChannel</var> 
 * are required and may not contain spaces.  Please see the KICK command for
 * additional information in RFC 1459.
 */
- (id)kick: (NSString *)aPerson offOf: (NSString *)aChannel for: (NSString *)aReason;

/**
 * Sets status to away with the message <var>aMessage</var>.  While away, if
 * a user should send you a message, <var>aMessage</var> will be returned to
 * them to explain your absence.  <var>aMessage</var> may contain spaces.  If
 * omitted, the user is marked as being present.  Please refer to the AWAY 
 * command in RFC 1459 for additional information.
 */
- (id)setAwayWithMessage: (NSString *)aMessage;

/**
 * Requests a PONG message from the server.  The argument <var>aString</var>
 * is essential but may contain spaces.  The server will respond immediately
 * with a PONG message with the same argument.  This commnd is rarely needed
 * by a client, but is sent out often by servers to ensure connectivity of 
 * clients.  Please see RFC 1459 for more information on the PING command.
 */
- (id)sendPingWithArgument: (NSString *)aString;

/**
 * Used to respond to a PING message.  The argument sent with the PING message
 * should be the argument specified by <var>aString</var>.  <var>aString</var>
 * is required and may contain spaces.  See RFC 1459 for more informtion
 * regarding the PONG command.
 */
- (id)sendPongWithArgument: (NSString *)aString;
@end

/**
 * This category represents all the callback methods in IRCObject.  You can
 * override these with a subclass.  All of them do not do anything especially
 * important by default, so feel free to not call the default implementation.
 * 
 * On any method ending with an argument like 'from: (NSString *)aString',
 * <var>aString</var> could be in the format of nickname!host.  Please see
 * the documentation for ExtractIRCNick(), ExtractIRCHost(), and 
 * SeparateIRCNickAndHost() for more information.
 */
@interface IRCObject (Callbacks)
/**
 * This method will be called when the connection is fully registered with
 * the server.  At this point it is safe to start joining channels and carrying
 * out other typical IRC functions. 
 */
- (id)registeredWithServer;

/**
 * This method will be called if a connection cannot register for whatever reason.
 * This reason will be outlined in <var>aReason</var>, but the best way to track
 * the reason is to watch the numeric commands being received in the 
 * -numericCommandReceived:withParams:from: method.
 */
- (id)couldNotRegister: (NSString *)aReason;

/**
 * Called when a CTCP request has been received.  The CTCP request type is
 * stored in <var>aCTCP</var>(could be such things as DCC, PING, VERSION, etc.)
 * and the argument is stored in <var>anArgument</var>.  The actual location
 * that the CTCP request is sent is stored in <var>aReceiver</var> and the 
 * person who sent it is stored in <var>aPerson</var>.
 */
- (id)CTCPRequestReceived: (NSString *)aCTCP 
   withArgument: (NSString *)anArgument to: (NSString *)aReceiver
   from: (NSString *)aPerson;

/**
 * Called when a CTCP reply has been received.  The CTCP reply type is
 * stored in <var>aCTCP</var> with its argument in <var>anArgument</var>.
 * The actual location that the CTCP reply was sent is stored in <var>aReceiver</var>
 * and the person who sent it is stored in <var>aPerson</var>.
 */
- (id)CTCPReplyReceived: (NSString *)aCTCP
   withArgument: (NSString *)anArgument to: (NSString *)aReceiver
   from: (NSString *)aPerson;

/**
 * Called when an IRC error has occurred.  This is a message sent by the server
 * and its argument is stored in <var>anError</var>.  Typically you will be 
 * disconnected after receiving one of these.
 */
- (id)errorReceived: (NSString *)anError;

/**
 * Called when a Wallops has been received.  The message is stored in 
 * <var>aMessage</var> and the person who sent it is stored in 
 * <var>aSender</var>.
 */
- (id)wallopsReceived: (NSString *)aMessage from: (NSString *)aSender;

/**
 * Called when a user has been kicked out of a channel.  The person's nickname
 * is stored in <var>aPerson</var> and the channel he/she was kicked out of is
 * in <var>aChannel</var>.  <var>aReason</var> is the kicker-supplied reason for
 * the removal.  <var>aKicker</var> is the person who did the kicking.  This will
 * not be accompanied by a -channelParted:withMessage:from: message, so it is safe
 * to assume they are no longer part of the channel after receiving this method.
 */
- (id)userKicked: (NSString *)aPerson outOf: (NSString *)aChannel 
         for: (NSString *)aReason from: (NSString *)aKicker;
		 
/**
 * Called when the client has been invited to another channel <var>aChannel</var>
 * by <var>anInviter</var>.
 */
- (id)invitedTo: (NSString *)aChannel from: (NSString *)anInviter;

/**
 * Called when the mode has been changed on <var>anObject</var>.  The actual
 * mode change is stored in <var>aMode</var> and the parameters are stored in
 * <var>paramList</var>.  The person who changed the mode is stored in 
 * <var>aPerson</var>.  Consult RFC 1459 for further information.
 */
- (id)modeChanged: (NSString *)aMode on: (NSString *)anObject 
   withParams: (NSArray *)paramList from: (NSString *)aPerson;
   
/**
 * Called when a numeric command has been received.  These are 3 digit numerical
 * messages stored in <var>aCommand</var> with a number of parameters stored
 * in <var>paramList</var>.  The sender, almost always the server, is stored
 * in <var>aSender</var>.  These are often used for replies to requests such
 * as user lists and channel lists and other times they are used for errors.
 */
- (id)numericCommandReceived: (NSString *)aCommand withParams: (NSArray *)paramList 
                      from: (NSString *)aSender;

/**
 * Called when someone changes his/her nickname.  The new nickname is stored in
 * <var>newName</var> and the old name will be stored in <var>aPerson</var>.
 */
- (id)nickChangedTo: (NSString *)newName from: (NSString *)aPerson;

/**
 * Called when someone joins a channel.  The channel is stored in <var>aChannel</var>
 * and the person who joined is stored in <var>aJoiner</var>.
 */
- (id)channelJoined: (NSString *)aChannel from: (NSString *)aJoiner;

/**
 * Called when someone leaves a channel.  The channel is stored in <var>aChannel</var>
 * and the person who left is stored in <var>aParter</var>.  The parting message will
 * be stored in <var>aMessage</var>.
 */
- (id)channelParted: (NSString *)aChannel withMessage: (NSString *)aMessage
             from: (NSString *)aParter;

/**
 * Called when someone quits IRC.  Their parting message will be stored in
 * <var>aMessage</var> and the person who quit will be stored in 
 * <var>aQuitter</var>.
 */
- (id)quitIRCWithMessage: (NSString *)aMessage from: (NSString *)aQuitter;

/**
 * Called when the topic is changed in a channel <var>aChannel</var> to
 * <var>aTopic</var> by <var>aPerson</var>.
 */
- (id)topicChangedTo: (NSString *)aTopic in: (NSString *)aChannel
              from: (NSString *)aPerson;

/**
 * Called when a message <var>aMessage</var> is received from <var>aSender</var>.
 * The person or channel that the message is addressed to is stored in <var>aReceiver</var>.
 */
- (id)messageReceived: (NSString *)aMessage to: (NSString *)aReceiver
               from: (NSString *)aSender;

/**
 * Called when a notice <var>aNotice</var> is received from <var>aSender</var>.
 * The person or channel that the notice is addressed to is stored in <var>aReceiver</var>.
 */
- (id)noticeReceived: (NSString *)aNotice to: (NSString *)aReceiver
              from: (NSString *)aSender;

/**
 * Called when an action has been received.  The action is stored in <var>anAction</var>
 * and the sender is stored in <var>aSender</var>.  The person or channel that
 * the action is addressed to is stored in <var>aReceiver</var>.
 */
- (id)actionReceived: (NSString *)anAction to: (NSString *)aReceiver
              from: (NSString *)aSender;

/** 
 * Called when a ping is received.  These pings are generally sent by the
 * server.  The correct method of handling these would be to respond to them
 * with -sendPongWithArgument: using <var>anArgument</var> as the argument.
 * The server that sent the ping is stored in <var>aSender</var>.
 */
- (id)pingReceivedWithArgument: (NSString *)anArgument from: (NSString *)aSender;

/**
 * Called when a pong is received.  These are generally in answer to a 
 * ping sent with -sendPingWithArgument:  The argument <var>anArgument</var>
 * is generally the same as the argument sent with the ping.  <var>aSender</var>
 * is the server that sent out the pong.
 */
- (id)pongReceivedWithArgument: (NSString *)anArgument from: (NSString *)aSender;

/**
 * Called when a new nickname was needed while registering because the other
 * one was either invalid or already taken.  Without overriding this, this
 * method will simply try adding a underscore onto it until it gets in. 
 * This method can be overridden to do other nickname-changing schemes.  The
 * new nickname should be directly set with -changeNick:
 */
- (id)newNickNeededWhileRegistering;
@end

/**
 * This is the lowlevel interface to IRCObject.
 * One method is a callback for when the object receives
 * a raw message from the connection, the other is a method
 * used to write raw messages across the connection
 */
@interface IRCObject (LowLevel)
/**
 * Handles an incoming line of text from the IRC server by 
 * parsing it and doing the appropriate actions as well as 
 * calling any needed callbacks.
 * See [LineObject-lineReceived:] for more information.
 */
- (id)lineReceived: (NSData *)aLine;
/**
 * Writes a formatted string to the connection.  This string
 * will not pass through any of the callbacks.
 */
- (id)writeString: (NSString *)format, ...;
@end

/* Below is all the numeric commands that you can receive as listed
 * in the RFC
 */

/**
 *  001 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_WELCOME;
/**
 *  002 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_YOURHOST;
/**
 *  003 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_CREATED;
/**
 *  004 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_MYINFO;
/**
 *  005 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_BOUNCE;
/**
 *  005 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ISUPPORT;
/**
 *  302 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_USERHOST;
/**
 *  303 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ISON;
/**
 *  301 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_AWAY;
/**
 *  305 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_UNAWAY;
/**
 *  306 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_NOWAWAY;
/**
 *  311 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_WHOISUSER;
/**
 *  312 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_WHOISSERVER;
/**
 *  313 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_WHOISOPERATOR;
/**
 *  317 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_WHOISIDLE;
/**
 *  318 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFWHOIS;
/**
 *  319 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_WHOISCHANNELS;
/**
 *  314 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_WHOWASUSER;
/**
 *  369 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFWHOWAS;
/**
 *  321 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_LISTSTART;
/**
 *  322 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_LIST;
/**
 *  323 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_LISTEND;
/**
 *  325 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_UNIQOPIS;
/**
 *  324 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_CHANNELMODEIS;
/**
 *  331 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_NOTOPIC;
/**
 *  332 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TOPIC;
/**
 *  341 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_INVITING;
/**
 *  342 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_SUMMONING;
/**
 *  346 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_INVITELIST;
/**
 *  347 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFINVITELIST;
/**
 *  348 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_EXCEPTLIST;
/**
 *  349 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFEXCEPTLIST;
/**
 *  351 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_VERSION;
/**
 *  352 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_WHOREPLY;
/**
 *  315 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFWHO;
/**
 *  353 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_NAMREPLY;
/**
 *  366 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFNAMES;
/**
 *  364 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_LINKS;
/**
 *  365 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFLINKS;
/**
 *  367 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_BANLIST;
/**
 *  368 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFBANLIST;
/**
 *  371 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_INFO;
/**
 *  374 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFINFO;
/**
 *  375 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_MOTDSTART;
/**
 *  372 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_MOTD;
/**
 *  376 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFMOTD;
/**
 *  381 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_YOUREOPER;
/**
 *  382 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_REHASHING;
/**
 *  383 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_YOURESERVICE;
/**
 *  391 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TIME;
/**
 *  392 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_USERSSTART;
/**
 *  393 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_USERS;
/**
 *  394 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFUSERS;
/**
 *  395 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_NOUSERS;
/**
 *  200 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACELINK;
/**
 *  201 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACECONNECTING;
/**
 *  202 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACEHANDSHAKE;
/**
 *  203 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACEUNKNOWN;
/**
 *  204 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACEOPERATOR;
/**
 *  205 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACEUSER;
/**
 *  206 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACESERVER;
/**
 *  207 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACESERVICE;
/**
 *  208 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACENEWTYPE;
/**
 *  209 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACECLASS;
/**
 *  210 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACERECONNECT;
/**
 *  261 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACELOG;
/**
 *  262 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRACEEND;
/**
 *  211 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSLINKINFO;
/**
 *  212 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSCOMMANDS;
/**
 *  219 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFSTATS;
/**
 *  242 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSUPTIME;
/**
 *  243 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSOLINE;
/**
 *  221 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_UMODEIS;
/**
 *  234 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_SERVLIST;
/**
 *  235 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_SERVLISTEND;
/**
 *  251 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_LUSERCLIENT;
/**
 *  252 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_LUSEROP;
/**
 *  253 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_LUSERUNKNOWN;
/**
 *  254 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_LUSERCHANNELS;
/**
 *  255 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_LUSERME;
/**
 *  256 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ADMINME;
/**
 *  257 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ADMINLOC1;
/**
 *  258 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ADMINLOC2;
/**
 *  259 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ADMINEMAIL;
/**
 *  263 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_TRYAGAIN;
/**
 *  401 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOSUCHNICK;
/**
 *  402 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOSUCHSERVER;
/**
 *  403 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOSUCHCHANNEL;
/**
 *  404 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_CANNOTSENDTOCHAN;
/**
 *  405 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_TOOMANYCHANNELS;
/**
 *  406 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_WASNOSUCHNICK;
/**
 *  407 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_TOOMANYTARGETS;
/**
 *  408 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOSUCHSERVICE;
/**
 *  409 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOORIGIN;
/**
 *  411 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NORECIPIENT;
/**
 *  412 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOTEXTTOSEND;
/**
 *  413 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOTOPLEVEL;
/**
 *  414 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_WILDTOPLEVEL;
/**
 *  415 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_BADMASK;
/**
 *  421 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_UNKNOWNCOMMAND;
/**
 *  422 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOMOTD;
/**
 *  423 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOADMININFO;
/**
 *  424 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_FILEERROR;
/**
 *  431 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NONICKNAMEGIVEN;
/**
 *  432 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_ERRONEUSNICKNAME;
/**
 *  433 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NICKNAMEINUSE;
/**
 *  436 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NICKCOLLISION;
/**
 *  437 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_UNAVAILRESOURCE;
/**
 *  441 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_USERNOTINCHANNEL;
/**
 *  442 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOTONCHANNEL;
/**
 *  443 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_USERONCHANNEL;
/**
 *  444 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOLOGIN;
/**
 *  445 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_SUMMONDISABLED;
/**
 *  446 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_USERSDISABLED;
/**
 *  451 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOTREGISTERED;
/**
 *  461 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NEEDMOREPARAMS;
/**
 *  462 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_ALREADYREGISTRED;
/**
 *  463 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOPERMFORHOST;
/**
 *  464 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_PASSWDMISMATCH;
/**
 *  465 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_YOUREBANNEDCREEP;
/**
 *  466 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_YOUWILLBEBANNED;
/**
 *  467 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_KEYSET;
/**
 *  471 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_CHANNELISFULL;
/**
 *  472 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_UNKNOWNMODE;
/**
 *  473 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_INVITEONLYCHAN;
/**
 *  474 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_BANNEDFROMCHAN;
/**
 *  475 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_BADCHANNELKEY;
/**
 *  476 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_BADCHANMASK;
/**
 *  477 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOCHANMODES;
/**
 *  478 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_BANLISTFULL;
/**
 *  481 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOPRIVILEGES;
/**
 *  482 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_CHANOPRIVSNEEDED;
/**
 *  483 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_CANTKILLSERVER;
/**
 *  484 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_RESTRICTED;
/**
 *  485 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_UNIQOPPRIVSNEEDED;
/**
 *  491 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOOPERHOST;
/**
 *  501 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_UMODEUNKNOWNFLAG;
/**
 *  502 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_USERSDONTMATCH;
/**
 *  231 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_SERVICEINFO;
/**
 *  232 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_ENDOFSERVICES;
/**
 *  233 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_SERVICE;
/**
 *  300 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_NONE;
/**
 *  316 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_WHOISCHANOP;
/**
 *  361 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_KILLDONE;
/**
 *  262 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_CLOSING;
/**
 *  363 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_CLOSEEND;
/**
 *  373 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_INFOSTART;
/**
 *  384 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_MYPORTIS;
/**
 *  213 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSCLINE;
/**
 *  214 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSNLINE;
/**
 *  215 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSILINE;
/**
 *  216 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSKLINE;
/**
 *  217 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSQLINE;
/**
 *  218 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSYLINE;
/**
 *  240 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSVLINE;
/**
 *  241 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSLLINE;
/**
 *  244 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSHLINE;
/**
 *  245 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSSLINE;
/**
 *  246 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSPING;
/**
 *  247 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSBLINE;
/**
 *  250 - Please see RFC 1459 for additional information.
 */
extern NSString *RPL_STATSDLINE;
/**
 *  492 - Please see RFC 1459 for additional information.
 */
extern NSString *ERR_NOSERVICEHOST;

#endif

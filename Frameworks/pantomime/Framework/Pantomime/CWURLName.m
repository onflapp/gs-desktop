/*
**  CWURLName.m
**
**  Copyright (c) 2001-2004 Ludovic Marcotte
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

#import <Pantomime/CWURLName.h>

#import <Pantomime/CWConstants.h>
#import <Foundation/NSPathUtilities.h>

//
// Private methods
//
@interface CWURLName (Private)

- (void) _decodeIMAP: (NSString *) theString;
- (void) _decodeLocal: (NSString *) theString;
- (void) _decodePOP3: (NSString *) theString;
- (void) _decodeURL: (NSString *) theString;

@end


//
//
//
@implementation CWURLName

- (id) initWithString: (NSString *) theString
{
  return [self initWithString: theString  path: nil];
}


//
//
//
- (id) initWithString: (NSString *) theString
		 path: (NSString *) thePath
{
  self = [super init];
  if (self)
    {
      // We initialize our ivars
      _protocol = nil;
      _foldername = nil;
      _host = nil;
      _port = 0;
      _username = nil;
      _password = nil;
      
      _path = thePath;
  
      if (_path)
	{
	  RETAIN(_path);
	}
      
      // We now decode our URL
      [self _decodeURL: theString];
    }
  return self;
}


//
//
//
- (void) dealloc
{
  TEST_RELEASE(_protocol);
  TEST_RELEASE(_foldername);
  TEST_RELEASE(_path);
  TEST_RELEASE(_host);
  TEST_RELEASE(_username);
  TEST_RELEASE(_password);
  
  [super dealloc];
}


//
// access/mutation methods
//
- (NSString *) protocol
{
  return _protocol;
}

- (NSString *) foldername
{
  return _foldername;
}

- (NSString *) path
{
  return _path;
}

- (NSString *) host;
{
  return _host;
}

- (unsigned int) port
{
  return _port;
}

- (NSString *) username
{
  return _username;
}

- (NSString *) password
{
  return _password;
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"protocol = (%@), foldername = (%@), path = (%@), host = (%@), port = (%d), username = (%@), password = (%@)",
		   _protocol, _foldername, _path, _host, _port, _username, _password];
}

- (NSString *) stringValue
{
  if ([_protocol caseInsensitiveCompare: @"LOCAL"] == NSOrderedSame)
    {
      return [NSString stringWithFormat: @"local://%@/%@", _path, _foldername];
    }
  else if ([_protocol caseInsensitiveCompare: @"IMAP"] == NSOrderedSame)
    {
      return [NSString stringWithFormat: @"imap://%@@%@/%@", _username, _host, _foldername];
    }
  else
    {
      return [NSString stringWithFormat: @"pop3://%@@%@", _username, _host];
    }
}

@end


//
// Private methods
//
@implementation CWURLName (Private)

//// FIXME (finish!)
// imap://<iserver>/<foldername>
//
// Examples: imap://minbari.org/gray-council;UIDVALIDITY=385759045/;UID=20
//           imap://michael@minbari.org/users.*;type=list
//           imap://psicorp.org/~peter/%E6%97%A5%E6%9C%AC%E8%AA%9E/
//           imap://;AUTH=KERBEROS_V4@minbari.org/gray-council/;uid=20/;section=1.2
//           imap://;AUTH=*@minbari.org/gray%20council?SUBJECT%20shadows
//
// Note: The imap:// part isn't present in the received string as parameter.
//
- (void) _decodeIMAP: (NSString *) theString
{
  NSRange r1, r2;

  // We decode the username
  r1 = [theString rangeOfString: @"@"
		  options: NSBackwardsSearch];
  
  if (r1.length)
    {
      _username = [theString substringToIndex: r1.location];
      RETAIN(_username);
    }
  else
    {
      r1.location = 0;
    }
  
  r2 = [theString rangeOfString: @"/"
		  options: 0
		  range: NSMakeRange(r1.location, [theString length] - r1.location)];
  
  if (r1.length)
    {
      _host = [theString substringWithRange: NSMakeRange(r1.location + 1, r2.location - r1.location - 1)];
    }
  else
    {
      _host = [theString substringWithRange: NSMakeRange(r1.location, r2.location - r1.location)];
    }
  
  RETAIN(_host);

  _foldername = [theString substringFromIndex: (r2.location + 1)];
  RETAIN(_foldername);
}


//
// local://<path>/<foldername> (full path)
//
// Note: The local:// part isn't present in the received string as parameter.
//
- (void) _decodeLocal: (NSString *) theString
{
  // If localMailDirectoryPath is nil, we return the last path component
  // of the URL as the foldername.
  if (!_path)
    {
      _foldername = [theString lastPathComponent];
      RETAIN(_foldername);
      
      _path = [theString substringToIndex: ([theString length] - [_foldername length])];
      RETAIN(_path);
    }
  else
    {
      _foldername = [theString substringFromIndex: ([_path length] + 1)];
      RETAIN(_foldername);
    }
}


//
// FIXME (finish!)
// pop://<user>;auth=<auth>@<host>:<port>
//
// Examples: pop://rg@mailsrv.qualcomm.com
//           pop://rg;AUTH=+APOP@mail.eudora.com:8110
//           pop://baz;AUTH=SCRAM-MD5@foo.bar
//
// Note: The pop:// part isn't present in the received string as parameter.
//
- (void) _decodePOP3: (NSString *) theString
{
  NSRange aRange;

  _foldername = [[NSString alloc] initWithString: @"INBOX"];
  
  aRange = [theString rangeOfString: @"@"];
  
  _username = [theString substringToIndex: aRange.location];
  RETAIN(_username);

  _host = [theString substringFromIndex: (aRange.location + 1)];
  RETAIN(_host);
}


//
//
//
- (void) _decodeURL: (NSString *) theString
{
  NSRange aRange;

  // We first decode our protocol.
  aRange = [theString rangeOfString: @"://"];
  
  if (aRange.length)
    {
      NSString *aString;

      _protocol = [theString substringToIndex: aRange.location];
      RETAIN(_protocol);
      
      aString = [theString substringFromIndex: (aRange.location + aRange.length)];

      if ([_protocol caseInsensitiveCompare: @"LOCAL"] == NSOrderedSame)
	{
	  [self _decodeLocal: aString];
	}
      else if ([_protocol caseInsensitiveCompare: @"POP3"] == NSOrderedSame)
	{
	  [self _decodePOP3: aString];
	}
      else if ([_protocol caseInsensitiveCompare: @"IMAP"] == NSOrderedSame)
	{
	  [self _decodeIMAP: aString];
	}
    }
}

@end

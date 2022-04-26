/*
**  CWDNSManager.m
**
**  Copyright (c) 2004-2007 Ludovic Marcotte
**  Copyright (C) 2012-2018 Riccardo Mottola
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**          Riccardo Mottola <rm@gnu.org>
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

#import <Pantomime/CWDNSManager.h>

#import <Pantomime/CWConstants.h>
#import <Pantomime/NSData+Extensions.h>

#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSScanner.h>

#ifdef __MINGW32__
#include <winsock2.h>

#elif defined (__NetBSD__)
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/nameser.h>
#include <resolv.h>
//#include <res_update.h>
#include <arpa/inet.h>
#include <netdb.h>
#if __NetBSD_Version__ >= 300000000
#define HAS_RES_NINIT 1
#endif

#else
#include <sys/types.h>      // For u_char on Mac OS X
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <resolv.h>
#endif

#include <unistd.h>

#define MAX_PACKET_SIZE 512
#define MAX_TIMEOUT 2



static CWDNSManager *singleInstance = nil;

typedef struct _dns_packet_header
{
  unsigned short packet_id;
  unsigned short flags;
  unsigned short qdcount;
  unsigned short ancount;
  unsigned short nscount;
  unsigned short arcount;
} dns_packet_header;

typedef struct _dns_packet_question
{
  unsigned short qtype;
  unsigned short qclass;
} dns_packet_question;

typedef struct _dns_resource_record
{
  unsigned short type;
  unsigned short class;
  unsigned int ttl;
  unsigned short rdlength;
} dns_resource_record;

#ifdef MACOSX
void dns_socket_callback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void* data, void* info);

void dns_socket_callback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void* data, void* info)
{
  if (type&kCFSocketReadCallBack)
    {
      [(CWDNSManager *)info receivedEvent: (void*)CFSocketGetNative(s)
		       type: ET_RDESC
		       extra: 0
		       forMode: nil];
    }
}
#endif

//
//
//
@interface CWDNSRequest : NSObject
{
  @public
    NSMutableArray *servers;
    NSData *name;
    unsigned short packet_id, count;
}

- (id) initWithName: (NSString *) theName;

@end

@implementation CWDNSRequest

- (id) initWithName: (NSString *) theName
{
  self = [super init];
  if (self)
    {
      servers = [[NSMutableArray alloc] init];
      name = RETAIN([theName dataUsingEncoding: NSASCIIStringEncoding]);
      count = 0;
    }
  return self;
}

- (void) dealloc
{
  RELEASE(servers);
  RELEASE(name);
  [super dealloc];
}

@end

//
//
//
@interface CWDNSManager (Private)

- (void) _parseHostsFile;
- (void) _parseResolvFile;
- (void) _processResponse;
- (void) _sendRequest: (CWDNSRequest *) theRequest;
- (void) _tick: (id) sender;

@end

//
//
//
@implementation CWDNSManager

- (id) init
{
  self = [super init];
  if (self)
    {
      _cache = [[NSMutableDictionary alloc] init];
      _servers = [[NSMutableArray alloc] init];
      _queue = [[NSMutableArray alloc] init];
      _is_asynchronous = NO;

#ifdef MACOSX
  _runLoopSource = nil;
  _context = nil;
  _cf_socket = nil;
#endif

  [self _parseResolvFile];
  [self _parseHostsFile];

  if ([_servers count] && (_socket = socket(PF_INET, SOCK_DGRAM, 0)) >= 0)
    {
      _is_asynchronous = YES;
      _packet_id = 1;
      
#ifdef MACOSX
      _context = (CFSocketContext *)malloc(sizeof(CFSocketContext));
      memset(_context, 0, sizeof(CFSocketContext));
      _context->info = self;
      
      _cf_socket = CFSocketCreateWithNative(NULL, _socket, kCFSocketReadCallBack|kCFSocketWriteCallBack, dns_socket_callback, _context);
      CFSocketDisableCallBacks(_cf_socket, kCFSocketReadCallBack|kCFSocketWriteCallBack);
      
      if (!_cf_socket)
	{
	  _is_asynchronous = NO;
	  return self;
	}
      
      _runLoopSource = CFSocketCreateRunLoopSource(NULL, _cf_socket, 1);
      
      if (!_runLoopSource)
	{
	  CFSocketInvalidate(_cf_socket);
	  _is_asynchronous = NO;
	  return self;
	}
      
      CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopCommonModes);
#else
      [[NSRunLoop currentRunLoop] addEvent: (void *)_socket
#ifdef __MINGW32__
				  type: ET_HANDLE
#else
				  type: ET_RDESC
#endif
				  watcher: self
				  forMode: NSDefaultRunLoopMode];
#endif

      _timer = [NSTimer scheduledTimerWithTimeInterval: 1.0
			target: self
			selector: @selector(_tick:)
			userInfo: nil
			repeats: YES];
      RETAIN(_timer);
      [_timer fire];
    }
    }
  return self;
}

//
//
//
- (void) dealloc
{
  [_timer invalidate];
  RELEASE(_timer);

#ifdef MACOSX
  if (CFRunLoopSourceIsValid(_runLoopSource))
    {
      CFRunLoopSourceInvalidate(_runLoopSource);
      CFRelease(_runLoopSource);
    }

  if (CFSocketIsValid(_cf_socket))
    {
      CFSocketInvalidate(_cf_socket);
    }

  CFRelease(_cf_socket);
  free(_context);
#endif

  RELEASE(_cache);
  RELEASE(_servers);
  RELEASE(_queue);
  [super dealloc];
}

//
//
//
- (NSArray *) addressesForName: (NSString *) theName  background: (BOOL) theBOOL
{
  id o;

  NSDebugLog(@"DNSManager - Looking up address: %@, background? %u", theName, theBOOL);
  o = [_cache objectForKey: theName];
  
  if (theBOOL)
    {      
      if (o)
	{
	  POST_NOTIFICATION(PantomimeDNSResolutionCompleted, self, ([NSDictionary dictionaryWithObjectsAndKeys: theName, @"Name", [o objectAtIndex: 0], @"Address", nil]));
	}
      else
	{
	  CWDNSRequest *aRequest;
	  aRequest = AUTORELEASE([[CWDNSRequest alloc] initWithName: theName]);
	  aRequest->packet_id = _packet_id++;
	  aRequest->servers = [[NSMutableArray alloc] initWithArray: _servers];
	  aRequest->count = 0;

	  if ([_servers count])
	    {
	      [self _sendRequest: aRequest];
	    }
	}

      return nil;
    }

  if (!o)
    {
      struct hostent *host_info;

      //
      // We don't compare with _servers as it might have more
      // magic to obtain IP addresses from DNS names.
      //
      host_info = gethostbyname([theName cString]);
      
      if (host_info)
	{
	  unsigned i;

	  o = [NSMutableArray array];
          i = 0;
	  while (host_info->h_addr_list[i] != NULL)
	    {
              uint8_t c0, c1, c2, c3;
              char *buf;
              uint32_t r;
		  
              buf = host_info->h_addr_list[i];
              c0 = (uint8_t)*(buf);
              c1 = (uint8_t)*(buf+1);
              c2 = (uint8_t)*(buf+2);
              c3 = (uint8_t)*(buf+3);
		  
              r = ntohl((uint32_t)((c0<<24)|(c1<<16)|(c2<<8)|c3));

              [o addObject: [NSNumber numberWithUnsignedInt: r]];

              i++;
	    }
	  
	  // We only cache if we have at least one address for the DNS name.
	  if ([o count])
	    {
	      [_cache setObject: o  forKey: theName];
	    }
	}
      else
	{
	  o = nil;
	}
    }
  
  return o;
}

//
//
//
- (void) receivedEvent: (void *) theData
                  type: (RunLoopEventType) theType
                 extra: (void *) theExtra
               forMode: (NSString *) theMode
{
  switch (theType)
    {
#ifdef __MINGW32__
    case ET_HANDLE:
    case ET_TRIGGER:
#else
    case ET_RDESC:
#endif
      [self _processResponse];
      break;

    default:
      break;
    }
}

//
//
//
+ (id) singleInstance
{
  if (!singleInstance)
    {
      singleInstance = [[CWDNSManager alloc] init];
    }

  return singleInstance;
}

@end

@implementation CWDNSManager (Private)

//
// See man 5 hosts for all details
// on the format of the /etc/hosts file.
//
- (void) _parseHostsFile
{
  NSData *aData;

  aData = [NSData dataWithContentsOfFile: @"/etc/hosts"];
  
  if (aData)
    {
      NSArray *allLines;
      NSString *aString;
      BOOL b;
      NSUInteger i;
      
      allLines = [aData componentsSeparatedByCString: "\n"];
      
      for (i = 0; i < [allLines count]; i++)
	{
	  aData = [allLines objectAtIndex: i];

	  if ([aData hasCPrefix: "#"]) continue;
      
	  aString = [[NSString alloc] initWithData: aData  encoding: NSASCIIStringEncoding];
	  b = YES;

	  if (aString)
	    {
	      NSString *aWord;
	      NSString *theIP;
	      NSScanner *aScanner;

	      aScanner = [NSScanner scannerWithString: aString];
	      theIP = nil;
	      
	      [aScanner scanCharactersFromSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]  intoString: NULL];
	      
	      while ([aScanner scanUpToCharactersFromSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]  intoString: &aWord] == YES)
		{
		  if (b)
		    {
		      theIP = aWord;
		      b = NO;
		      continue;
		    }

		  [_cache setObject: [NSArray arrayWithObject: [NSNumber numberWithUnsignedInt: inet_addr([theIP UTF8String])]]  forKey: aWord];
		  [aScanner scanCharactersFromSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]  intoString: NULL];

		}

	      RELEASE(aString);
	    }
	}
    }
}

//
// See man 5 resolv.conf for all details
// on the format of the /etc/resolv.conf  file.
//
- (void) _parseResolvFile
{
  int i;
#ifdef HAS_RES_NINIT
  struct __res_state cw_res;
#else
#define cw_res _res
#endif

#ifdef HAS_RES_NINIT
  memset(&cw_res, 0, sizeof(cw_res));

  if (res_ninit(&cw_res) == -1)
      return;
#else
  if (res_init() == -1)
      return; 
#endif

  if ((cw_res.options & RES_INIT) == 0)
    return;

  for (i = 0 ; i < cw_res.nscount; i++ )
  {
    [_servers addObject: [NSNumber numberWithUnsignedInt: cw_res.nsaddr_list[i].sin_addr.s_addr]];
  }

#ifdef HAS_RES_NINIT
  res_ndestroy(&cw_res);
#endif
}


//
//
//
- (void) _processResponse
{
  CWDNSRequest *aRequest;
  NSString *aString;
  NSNumber *aNumber;

  dns_resource_record *resource_record;
  dns_packet_header *header;

  char *buf, qr, ra, rcode, *start;
  unsigned short flags, i, type;
  uint8_t c0, c1, c2, c3;
  uint32_t r;

  start = buf = (char *)malloc(MAX_PACKET_SIZE);

  if (recvfrom(_socket, buf, MAX_PACKET_SIZE, 0, NULL, NULL) == -1)
    {
      free(buf);
      return;
    }

  // We build our packet header. We should get (~118 bytes in total):
  //
  // - packet identifier
  // - flags (0x8180)
  // - qdcount
  // - ancount
  // - nscount
  // - arcount
  header = (dns_packet_header *)buf;  

  // We get the right DNSRequest object from the queue
  // based on our packet ID.
  aRequest = nil;

  for (i = 0; i < [_queue count]; i++)
    {
      aRequest = [_queue objectAtIndex: i];
      if (aRequest->packet_id == ntohs(header->packet_id)) break;
    }

  if (!aRequest)
    {
      free(buf);
      return;
    }

  flags = ntohs(header->flags);  
  
  qr = (char)((flags & 0x8000) >> 15);
  
  // We check if we got a response from the server. If not,
  // we try the next server, if any.
  if (!qr) return;

  ra = (char)((flags & 0x0080) >> 7);

  // We check if recursive queries are supported by
  // the server. If not, we try the next server, if any.
  if (!ra) return;

  rcode = (char)((flags & 0x000F) >> 0);

  // We check if we got any errors...
  // 2 - server failure
  // 3 - domain does not exist
  // 5 - the server refused to serve our query
  if (rcode)
    {
      return;
    }
  
  // We check if we got a response from the server. If not,
  // we try the next server, if any.
  if (!htons(header->ancount)) return;

  buf += sizeof(dns_packet_header);

  //
  // We skip over the Question section.
  //
  while (*buf)
    {
      buf += (int)(*buf)+1;
    }

  buf += sizeof(dns_packet_question)+1;
  

  //
  // We now read the Answer section of our packet
  //
  //                                  1  1  1  1  1  1
  //    0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  //  |                                               |
  //  /                                               /
  //  /                      NAME                     /
  //  |                                               |
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  //  |                      TYPE                     |
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  //  |                     CLASS                     |
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  //  |                      TTL                      |
  //  |                                               |
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  //  |                   RDLENGTH                    |
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
  //  /                     RDATA                     /
  //  /                                               /
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  type = 0;

  while (type != 1)
    {
      if (!((*buf) & 0xC0))
	{      
	  while (*buf)  
	    {
	      buf+=(int)(*buf)+1;
	    }
	  
	  buf-=1;
	}
      
      resource_record = (dns_resource_record *)(buf+=2); 
      type = ntohs(resource_record->type);
      buf += (sizeof(dns_resource_record)-2)+ntohs(resource_record->rdlength);
    }
  
  buf -= ntohs(resource_record->rdlength);
  c0 = (uint8_t)*(buf);
  c1 = (uint8_t)*(buf+1);
  c2 = (uint8_t)*(buf+2);
  c3 = (uint8_t)*(buf+3);
  
  r = ntohl((uint32_t)((c0<<24)|(c1<<16)|(c2<<8)|c3));

  aString = AUTORELEASE([[NSString alloc] initWithData: aRequest->name  encoding: NSASCIIStringEncoding]);
  aNumber = [NSNumber numberWithUnsignedInt: r];

  POST_NOTIFICATION(PantomimeDNSResolutionCompleted, self, ([NSDictionary dictionaryWithObjectsAndKeys: aString, @"Name", aNumber, @"Address", nil]));

  [_cache setObject: [NSArray arrayWithObject: aNumber]  forKey: aString];

  // We remove our request from the queue
  [_queue removeObject: aRequest];

  free(start);
}

//
//
//
- (void) _sendRequest: (CWDNSRequest *) theRequest
{
  NSArray *subdomains;

  struct sockaddr_in peer_address;
  dns_packet_question *question;
  dns_packet_header *header;
  unsigned i;
  size_t len;
  char *packet, *start;

  peer_address.sin_family = PF_INET;
  peer_address.sin_port = htons(53);

  peer_address.sin_addr.s_addr = [[theRequest->servers objectAtIndex: 0] unsignedIntValue];
  start = packet = (char *)malloc(MAX_PACKET_SIZE);

  // We build our packet header. We have to set:
  //  
  // - packet identifier
  // - flags, we have something like this to fill:
  //   |QR|   Opcode  |AA|TC|RD|RA|   Z    |   RCODE   |
  //    0      0000    0  0  1  0     000      0000
  // - qdcount: 1 entry in the question section.
  // - ancount: 0 resource record in the answer section
  // - nscount: 0 name server resource record in the authority records section
  // - arcount: 0 resource record in the additional records section
  //
  //NSLog(@"(0x0100:\t%d to %d\n1:\t\t%d to %d\n", 0x0100, htons(0x0100), 1, htons(1));
  header = (dns_packet_header *)packet;
  header->packet_id = htons(theRequest->packet_id);
  header->flags = htons(0x0100);    
  header->qdcount = htons(1);
  header->ancount = header->nscount = header->arcount = 0;

  // We build our packet question.
  packet += sizeof(dns_packet_header);

  // QNAME
  // a domain name represented as a sequence of labels, where
  // each label consists of a length octet followed by that
  // number of octets.  The domain name terminates with the
  // zero length octet for the null label of the root.  Note
  // that this field may be an odd number of octets; no
  // padding is used.
  //
  subdomains = [theRequest->name componentsSeparatedByCString: "."];
  
  for (i = 0; i < [subdomains count]; i++)
    {
      *packet = len = [[subdomains objectAtIndex: i] length];
      memcpy(++packet, [[subdomains objectAtIndex: i] bytes], len);
      packet += len;
    }

  *(packet++) = '\0'; 
  question = (dns_packet_question *)packet;
  question->qtype = htons(1);  // Type A: 1 a host address
  question->qclass = htons(1); // IN: 1 the Internet
  packet += sizeof(dns_packet_question);
  
  len = packet-(char *)header;

  // We queue our DNS request
  if (![_queue containsObject: theRequest]) [_queue addObject: theRequest];
  
  // We send our packet. If we failed to send it, we don't care since
  // we'll try to send it to an other server shortly after.
  sendto(_socket, start, len, 0, (struct sockaddr *)&peer_address, sizeof(struct sockaddr));
  
  free(start);
}

//
//
//
- (void) _tick: (id) sender
{
  NSUInteger c;

  if ((c = [_queue count]))
    {
      CWDNSRequest *aRequest;

      while (c--)
	{
	  aRequest = [_queue objectAtIndex: c];
	  
	  if (aRequest->count == MAX_TIMEOUT)
	    {
	      if ([aRequest->servers count] > 1)
		{
		  [aRequest->servers removeObjectAtIndex: 0];
		  aRequest->count = 0;
		  
		  [self _sendRequest: aRequest];
		}
	      else
		{
		  NSDictionary *aDictionary;

		  aDictionary = [NSDictionary dictionaryWithObject: AUTORELEASE([[NSString alloc] initWithData: aRequest->name  encoding: NSASCIIStringEncoding])
					      forKey: @"Name"];
		  POST_NOTIFICATION(PantomimeDNSResolutionFailed, self, aDictionary);

		  [_queue removeObject: aRequest];
		}
	    }

	  aRequest->count++;
	}
    }
}

@end


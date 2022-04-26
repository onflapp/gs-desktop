// addressserver.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Dedicated Address Book Server for GNUstep
// 
// $Author: buzzdee $
// $Locker:  $
// $Revision: 1.5 $
// $Date: 2013/10/19 15:25:22 $

/* system includes */
#include <Addresses/Addresses.h>
#include <netinet/in.h>

/* my includes */
/* (none) */

extern char **environ;

char *hello = "Hello\n";
char *error = "Error\n";
char *ok = "OK\n";

@interface FileHandleAuth: NSObject
{
  BOOL _readOK, _writeOK;
  NSFileHandle *_handle;
}

- initWithFileHandle: (NSFileHandle*) handle;
- (NSFileHandle*) fileHandle;
- (BOOL) isReadOK;
- (BOOL) isWriteOK;
- (void) setReadOK: (BOOL) read writeOK: (BOOL) write;
@end

@implementation FileHandleAuth
- initWithFileHandle: (NSFileHandle*) handle
{
  _handle = handle;
  [_handle retain];
  _readOK = NO; _writeOK = NO;
  return self;
}
- (void) dealloc
{
  [_handle release];
  [super dealloc];
}
- (NSFileHandle*) fileHandle
{
  return _handle;
}
- (BOOL) isReadOK
{
  return _readOK;
}
- (BOOL) isWriteOK
{
  return _writeOK;
}
- (void) setReadOK: (BOOL) read writeOK: (BOOL) write
{
  _readOK = read; _writeOK = write;
}
@end  

@interface AddressBookServer: NSObject<ADSimpleAddressBookServing>
{
  ADAddressBook *_book;
  NSString *_roPwd, *_rwPwd;
  NSFileHandle *_handle;
  NSMutableArray *_connections;
}
- initWithAddressBook: (ADAddressBook*)book
     readOnlyPassword: (NSString*) roPwd
    readWritePassword: (NSString*) rwPwd
   socketServerAtPort: (int) port;
- (ADAddressBook*) addressBookForReadOnlyAccessWithAuth: (id) auth;
- (ADAddressBook*) addressBookForReadWriteAccessWithAuth: (id) auth;

- (void) acceptConnection: (NSNotification*) note;
- (void) handleDataOnConnection: (NSNotification*) note;

- (void) handleInput: (NSString*) input
	    withAuth: (FileHandleAuth*) auth;
@end

@implementation AddressBookServer
- initWithAddressBook: (ADAddressBook*)book
     readOnlyPassword: (NSString*) roPwd
    readWritePassword: (NSString*) rwPwd
   socketServerAtPort: (int) port
{
  _book = [book retain];
  _roPwd = [roPwd copy];
  _rwPwd = [rwPwd copy];

  _connections = [[NSMutableArray alloc] initWithCapacity: 5];

  if(port != -1)
    {
      int sock, reuse = 1;
      struct sockaddr_in sockaddr;

      memset(&sockaddr, 0, sizeof(struct sockaddr_in));
      sockaddr.sin_addr.s_addr = GSSwapHostI32ToBig(INADDR_ANY);
      sockaddr.sin_port = GSSwapHostI16ToBig(port);

      if((sock = socket(AF_INET, SOCK_STREAM, PF_UNSPEC)) == -1)
	NSLog(@"Unable to create socket - %s\n", strerror(errno));
      else if(setsockopt(sock, SOL_SOCKET, SO_REUSEADDR,
			 (char*)&reuse, sizeof(int)) == -1) 
	NSLog(@"Couldn't set reuse on socket - %s\n", strerror(errno));
      else if(bind(sock, (struct sockaddr*)&sockaddr, sizeof(sockaddr)))
	NSLog(@"Couldn't bind to port %d - %s\n", port, strerror(errno));
      else if(listen(sock, 5) == -1)
	NSLog(@"Couldn't listen on port %d - %s\n", port, strerror(errno));
      else
	{
	  _handle = [[NSFileHandle alloc] initWithFileDescriptor: sock
					  closeOnDealloc: YES];
	  [_handle acceptConnectionInBackgroundAndNotify];

	  [[NSNotificationCenter defaultCenter]
	    addObserver: self
	    selector: @selector(acceptConnection:)
	    name: NSFileHandleConnectionAcceptedNotification
	    object: nil];
	  [[NSNotificationCenter defaultCenter]
	    addObserver: self
	    selector: @selector(handleDataOnConnection:)
	    name: NSFileHandleDataAvailableNotification
	    object: nil];
	}
    }
  return self;
}

- (void) dealloc
{
  [_book autorelease];
  [_roPwd autorelease];
  [_rwPwd autorelease];
  [_handle autorelease];
  [_connections autorelease];
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [super dealloc];
}

- (ADAddressBook*) addressBookForReadOnlyAccessWithAuth: (id) auth
{
  if(![_roPwd isEqualToString: auth]) return nil;
  return [[[ADPublicAddressBook alloc]
	    initWithAddressBook: _book readOnly: YES]
	   autorelease];
}

- (ADAddressBook*) addressBookForReadWriteAccessWithAuth: (id) auth
{
  if(![_rwPwd isEqualToString: auth]) return nil;
  return [[[ADPublicAddressBook alloc]
	    initWithAddressBook: _book readOnly: NO]
	   autorelease];
}

- (void) acceptConnection: (NSNotification*) note
{
  NSFileHandle *handle;
  FileHandleAuth *auth;
  
  handle = [[note userInfo]
	     objectForKey: NSFileHandleNotificationFileHandleItem];
  auth = [[[FileHandleAuth alloc] initWithFileHandle: handle] autorelease];
  [_connections addObject: auth];

  [handle writeData: [NSData dataWithBytes: hello length: strlen(hello)]]; 

  [handle waitForDataInBackgroundAndNotify];
  [_handle acceptConnectionInBackgroundAndNotify];
}

- (void) handleDataOnConnection: (NSNotification*) note
{
  NSFileHandle *handle;
  FileHandleAuth *auth;
  int i;
  NSData *data; NSString *str; char *buf;

  handle = [note object];

  auth = nil;
  for(i=0; i<[_connections count]; i++)
    if([[_connections objectAtIndex: i] fileHandle] == handle)
      {
	auth = [_connections objectAtIndex: i];
	break;
      }

  if(!auth)
    {
      NSLog(@"Huh?! Couldn't find auth object\n");
      return;
    }

  data = [handle availableData];
  if(![data length])
    {
      [_connections removeObject: auth];
      return;
    }
  
  buf = (char *)malloc([data length]+1);
  memset(buf, 0, [data length]+1);
  memcpy(buf, [data bytes], [data length]);

  str = [NSString stringWithCString: buf];
  str = [str stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [self handleInput: str withAuth: auth];

  [handle waitForDataInBackgroundAndNotify];
}

- (void) handleInput: (NSString*) input
	    withAuth: (FileHandleAuth*) auth
{
  NSArray *arr;
  NSString *cmd;

#define ERROR \
 do {                  \
    [[auth fileHandle] \
      writeData: [NSData dataWithBytes: error length: strlen(error)]]; \
    return;            \
  } while(0);
#define OK \
 do {                  \
    [[auth fileHandle] \
      writeData: [NSData dataWithBytes: ok length: strlen(ok)]]; \
    return;            \
  } while(0);
  
  arr = [input componentsSeparatedByString: @" "];
  if(![arr count])
    ERROR;
  
  cmd = [arr objectAtIndex: 0];

  if([cmd isEqualToString: @"auth"])
    {
      NSString *type, *pwd;
      if([arr count] != 3) ERROR;
      
      type = [arr objectAtIndex: 1];
      pwd = [arr objectAtIndex: 2];
      if([type isEqualToString: @"ro"])
	{
	  if([_roPwd isEqualToString: pwd])
	    {
	      [auth setReadOK: YES writeOK: NO];
	      OK;
	    }
	  ERROR;
	}
      
      else if([type isEqualToString: @"rw"])
	{
	  if([_rwPwd isEqualToString: pwd])
	    {
	      [auth setReadOK: YES writeOK: YES];
	      OK;
	    }
	  ERROR;
	}

      else ERROR;
    }

  else if([cmd isEqualToString: @"quit"])
    [_connections removeObject: auth];
  else
    ERROR;
}

@end

void DiePrintingMessage(NSString *msg, int exitVal)
{
  fprintf(stderr, "%s", [msg cString]);
  exit(exitVal);
}

void DiePrintingUsage(int exitval)
{
  NSString *progname, *msg;
  
  progname = [[[NSProcessInfo processInfo] arguments] objectAtIndex: 0];
  msg = [NSString
	  stringWithFormat:
	    @"Usage: %@\n"
	  @"       [--ab LOC] [--ro PWD] [--rw PWD] [--conf CFILE]\n"
	  @"       [--rp PORT] [--sp port]\n"
	  @"Options:\n"
	  @"\t--ab LOC     Serve address book at the given location\n"
	  @"\t--ro PWD     Use PASS as read-only access password\n"
	  @"\t--rw PWD     Use PASS as read-write access password\n"
	  @"\t--rp PORT    Use PORT as receive port number\n"
	  @"\t--sp PORT    Use PORT as send port number\n"
	  @"\t--sock PORT  Use PORT as socket port number (default: 5000)\n"
	  @"\t--conf CFILE Read values for AddressBookLocation, \n"
	  @"\t             ReadOnlyPassword, ReadWritePassword,\n"
	  @"\t             SendPort, ReceivePort from CONFIGFILE\n"
	  @"\t             (proplist dictionary). Values given on\n"
	  @"\t             the command line override these.\n",
	  progname];
  return DiePrintingMessage(msg, exitval);
}

int main(int argc, char **argv)
{
  NSString *abLocation = nil, *roPassword = nil, *rwPassword = nil,
    *configFile = nil;
  int rport = -1, sport = -1, sock = 5000;
  NSAutoreleasePool *pool;
  NSEnumerator *e; NSString *arg; id config;

  NSConnection *conn; NSSocketPort *receivePort, *sendPort;

  ADLocalAddressBook *lbook; AddressBookServer *srv;

  pool = [[NSAutoreleasePool alloc] init];

  [NSProcessInfo initializeWithArguments: argv
		 count: argc
		 environment: environ];

  e = [[[NSProcessInfo processInfo] arguments] objectEnumerator];
  [e nextObject]; // skip argv[0];

  while((arg = [e nextObject]))
    {
      if([arg isEqualToString: @"--ab"])
	{
	  arg = [e nextObject];
	  if(!arg) DiePrintingUsage(-1);
	  abLocation = arg;
	}
      else if([arg isEqualToString: @"--ro"])
	{
	  arg = [e nextObject];
	  if(!arg) DiePrintingUsage(-1);
	  roPassword = arg;
	}
      else if([arg isEqualToString: @"--rw"])
	{
	  arg = [e nextObject];
	  if(!arg) DiePrintingUsage(-1);
	  rwPassword = arg;
	}
      else if([arg isEqualToString: @"--rp"])
	{
	  arg = [e nextObject];
	  if(!arg) DiePrintingUsage(-1);
	  rport = [arg intValue];
	}
      else if([arg isEqualToString: @"--sp"])
	{
	  arg = [e nextObject];
	  if(!arg) DiePrintingUsage(-1);
	  sport = [arg intValue];
	}
      else if([arg isEqualToString: @"--sock"])
	{
	  arg = [e nextObject];
	  if(!arg) DiePrintingUsage(-1);
	  sock = [arg intValue];
	}
      else if([arg isEqualToString: @"--conf"])
	{
	  arg = [e nextObject];
	  if(!arg) DiePrintingUsage(-1);
	  configFile = arg;
	}
      else
	DiePrintingUsage(-1);
    }

  if(configFile)
    {
      config = [[NSString stringWithContentsOfFile: configFile] propertyList];
      if(!config || ![config isKindOfClass: [NSDictionary class]])
	{
	  fprintf(stderr,
		  "Error: %s could not be read or doesn't contain"
		  "a valid dictionary!\n",
		  [configFile cString]);
	  exit(-1);
	}

      if(!abLocation)
	abLocation = [config objectForKey: @"AddressBookLocation"];
      if(!roPassword)
	roPassword = [config objectForKey: @"ReadOnlyPassword"];
      if(!rwPassword)
	rwPassword = [config objectForKey: @"ReadWritePassword"];
      if(rport == -1 && [config objectForKey: @"ReceivePort"])
	rport = [[config objectForKey: @"ReceivePort"] intValue];
      if(sport == -1 && [config objectForKey: @"SendPort"])
	sport = [[config objectForKey: @"SendPort"] intValue];
    }

  if(!abLocation)
    DiePrintingMessage(@"Error: No value for AddressBookLocation\n", -1);
  if(!roPassword)
    DiePrintingMessage(@"Error: No value for ReadOnlyPassword\n", -1);
  if(!rwPassword)
    DiePrintingMessage(@"Error: No value for ReadWritePassword\n", -1);
  if(rport == -1)
    DiePrintingMessage(@"Error: Receive port is invalid\n", -1);
  if(sport == -1)
    DiePrintingMessage(@"Error: Send port is invalid\n", -1);

  lbook = [[ADLocalAddressBook alloc] initWithLocation: abLocation];
  if(!lbook)
    DiePrintingMessage([NSString stringWithFormat:
				   @"Error: %@ isn't a valid "
				 @"AddressBookLocation\n", lbook], -1);

  srv = [[AddressBookServer alloc] initWithAddressBook: lbook
				   readOnlyPassword: roPassword
				   readWritePassword: rwPassword
				   socketServerAtPort: sock];


  receivePort = [NSSocketPort portWithNumber: rport
			      onHost: nil
			      forceAddress: nil
			      listener: YES];
  sendPort =  [NSSocketPort portWithNumber: sport
			    onHost: nil
			    forceAddress: nil
			    listener: NO];
  NSLog(@"Sendport at %d: %@\n", rport, receivePort);
  NSLog(@"Receiveport at %d: %@\n", sport, sendPort);
  conn = [[NSConnection alloc]
	   initWithReceivePort: receivePort sendPort: sendPort];
  
  [conn setRootObject: srv];
  [conn registerName: @"AddressServer"];

  fprintf(stderr, "Running.\n");
  
  [[NSRunLoop currentRunLoop] run];
		       
  [pool release];

  return 0;
}

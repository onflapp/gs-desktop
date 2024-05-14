// ADConverter.m (this is -*- ObjC -*-)
// 
// author: Björn Giesler <giesler@ira.uka.de>
// Riccardo Mottola

// Address Book Framework for GNUstep
// 


#import "ADConverter.h"
#import "ADPListConverter.h"
#import "ADVCFConverter.h"

ADConverterManager *_manager = nil;

@implementation ADConverterManager
+ (ADConverterManager*) sharedManager
{
  if(!_manager)
    _manager = [[self alloc] init];
  return _manager;
}

- init
{
  _icClasses = [[NSMutableDictionary alloc] initWithCapacity: 1];
  _ocClasses = [[NSMutableDictionary alloc] initWithCapacity: 1];

  // couple of standard converters
  
  [self registerInputConverterClass: [ADPListConverter class]
	forType: @"mfaddr"];
  
  [self registerInputConverterClass: [ADVCFConverter class]
	forType: @"vcf"];
  [self registerOutputConverterClass: [ADVCFConverter class]
	forType: @"vcf"];

  return [super init];
}

- (BOOL) registerInputConverterClass: (Class) c
			     forType: (NSString*) type
{
  type = [type lowercaseString];
  if([[_icClasses allKeys] containsObject: type])
    return NO;

  [_icClasses setObject: c forKey: type];
  return YES;
}

- (BOOL) registerOutputConverterClass: (Class) c
			      forType: (NSString*) type
{
  type = [type lowercaseString];
  if([[_ocClasses allKeys] containsObject: type])
    return NO;

  [_ocClasses setObject: c forKey: type];
  return YES;
}

- (id<ADInputConverting>) inputConverterForType: (NSString*) type
{
  Class c;

  c = [_icClasses objectForKey: type];
  if(!c) return nil;
  return [[[c alloc] initForInput] autorelease];
}

- (id<ADOutputConverting>) outputConverterForType: (NSString*) type
{
  Class c;

  c = [_ocClasses objectForKey: type];
  if(!c) return nil;
  return [[[c alloc] initForOutput] autorelease];
}

- (id<ADInputConverting>) inputConverterWithFile: (NSString*) filename
{
  id<ADInputConverting> obj;
  Class c;
  NSData *data;
  NSString *string;

  c = [_icClasses objectForKey: [[filename pathExtension]
				  lowercaseString]];
  if(!c) return nil;

  obj = [[[c alloc] initForInput] autorelease];
  data = [NSData dataWithContentsOfFile: filename];
  if (!data)
    {
      NSLog(@"Error while reading file %@", filename);
      return nil;
    }
  /*
  string = [[NSString alloc] initWithData:data encoding:NSUnicodeStringEncoding];
  if (string)
    {
      NSLog(@"File in NSUnicodeStringEncoding");
      goto encoding;
    }
  string = [[NSString alloc] initWithData:data encoding: NSUTF16BigEndianStringEncoding];
  if (string)
    {
      NSLog(@"File in NSUTF16BigEndianStringEncoding");
      goto encoding;
    }
  string = [[NSString alloc] initWithData:data encoding: NSUTF16LittleEndianStringEncoding];
  if (string)
    {
      NSLog(@"File in NSUTF16LittleEndianStringEncoding");
      goto encoding;
    }
  string = [[NSString alloc] initWithData:data encoding: NSUTF16LittleEndianStringEncoding];
  if (string)
    {
      NSLog(@"File in NSUTF16LittleEndianStringEncoding");
      goto encoding;
    }
  string = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
  if (string)
    {
      NSLog(@"File in NSUTF8StringEncoding");
      goto encoding;
    }
  string = [[NSString alloc] initWithData:data encoding: NSISOLatin1StringEncoding];
  if (string)
    {
      NSLog(@"File in NSISOLatin1StringEncoding");
      goto encoding;
    }
  string = [[NSString alloc] initWithData:data encoding: NSISOLatin2StringEncoding];
  if (string)
    {
      NSLog(@"File in NSISOLatin2StringEncoding");
      goto encoding;
    }
*/
  string = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
  if (string)
    {
      NSLog(@"File in NSUTF8StringEncoding");
      goto encoding;
    }
  string = [[NSString alloc] initWithData:data encoding: NSASCIIStringEncoding];
  if (!string)
    {
      NSLog(@"No encoding found for file %@, aborting.", filename);
      return nil;
    }
 encoding:
  if (![obj useString: AUTORELEASE(string)])
    return nil;
  return obj;
}

- (NSArray*) inputConvertableFileTypes
{
  return [_icClasses allKeys];
}
  
- (NSArray*) outputConvertableFileTypes
{
  return [_ocClasses allKeys];
}

@end

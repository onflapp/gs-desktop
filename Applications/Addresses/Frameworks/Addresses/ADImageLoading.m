// ADImageLoading.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#import "ADImageLoading.h"

@implementation ADPerson (ImageAdditions)
- (BOOL) setImageData: (NSData*) data
{
  if(!data) return [self removeValueForProperty: ADImageProperty];
  else return [self setValue: data forProperty: ADImageProperty];
}

- (NSData*) imageData
{
  return [self valueForProperty: ADImageProperty];
}

- (ADImageTag) beginLoadingImageDataForClient: (id<CImageClient>) client
{
  [NSException raise: ADUnimplementedError
	       format: @"Asynchronous loading not implemented on GNUstep"];
  return -1;
}

+ (void) cancelLoadingImageDataForTag: (ADImageTag) tag
{
  [NSException raise: ADUnimplementedError
	       format: @"Asynchronous loading not implemented on GNUstep"];
}
@end

#ifdef NSIMAGEREP_BROKEN
@implementation ADPerson (ImageAdditionsForBrokenNSImageRep)
- (BOOL) setImageDataWithFile: (NSString*) filename
{
  NSData *data;

  data = [NSData dataWithContentsOfFile: filename];
  if(!data) return NO;
  [self setImageData: data];
  
  if([self addressBook] &&
     [[self addressBook]
       respondsToSelector: @selector(setImageDataForPerson:withFile:)])
    return [[self addressBook] setImageDataForPerson: self withFile: filename];
  return YES;
}

- (NSString*) imageDataFile
{
  if(![self addressBook] ||
     ![[self addressBook]
	respondsToSelector: @selector(imageDataFileForPerson:)])
    return nil;
  else
    return [[self addressBook] imageDataFileForPerson: self];
}

- (BOOL) setImageDataType: (NSString*) type
{
  return [self setValue: type forProperty: ADImageTypeProperty];
}

@end
#endif


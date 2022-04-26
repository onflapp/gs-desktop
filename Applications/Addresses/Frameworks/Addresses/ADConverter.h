// ADConverter.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#ifndef _ADCONVERTER_H_
#define _ADCONVERTER_H_

#import <Foundation/Foundation.h>

#import <Addresses/ADRecord.h>

@protocol ADInputConverting
- initForInput;
- (BOOL) useString: (NSString*) string;
- (ADRecord*) nextRecord;
@end

@protocol ADOutputConverting
- initForOutput;
- (BOOL) canStoreMultipleRecords;
- (void) storeRecord: (ADRecord*) record;
- (NSString*) string;
@end

@interface ADConverterManager: NSObject
{
  NSMutableDictionary *_icClasses, *_ocClasses;
}

+ (ADConverterManager*) sharedManager;
- (BOOL) registerInputConverterClass: (Class) c
			     forType: (NSString*) type;
- (BOOL) registerOutputConverterClass: (Class) c
			      forType: (NSString*) type;
- (id<ADInputConverting>) inputConverterForType: (NSString*) type;
- (id<ADOutputConverting>) outputConverterForType: (NSString*) type;

/*!
  \brief Return a pre-initialized input converter for the given file

  Find a fitting converter and pre-initialize it with the date for the
  given file.
*/
- (id<ADInputConverting>) inputConverterWithFile: (NSString*) filename;

- (NSArray*) inputConvertableFileTypes;
- (NSArray*) outputConvertableFileTypes;
@end

#endif

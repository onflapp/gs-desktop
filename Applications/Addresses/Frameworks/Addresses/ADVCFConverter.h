// ADVCFConverter.h (this is -*- ObjC -*-)
// 
// Author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 

#ifndef _ADVCFCONVERTER_H_
#define _ADVCFCONVERTER_H_


#import <Addresses/ADConverter.h>


@interface ADVCFConverter: NSObject<ADInputConverting,ADOutputConverting>
{
  NSString *_str;
  NSMutableString *_out;
  BOOL _input;
  int _idx;
}

/* ADInputConverting */
- initForInput;
- (BOOL) useString: (NSString*) str;
- (ADRecord*) nextRecord;

/* ADOutputConverting */
- initForOutput;
- (BOOL) canStoreMultipleRecords;
- (void) storeRecord: (ADRecord*) record;
- (NSString*) string;
@end

#endif

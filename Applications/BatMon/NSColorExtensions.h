#import <AppKit/NSColor.h>

@class NSString;

@interface NSColor (GetColorsFromString)
+ (NSColor *)colorFromStringRepresentation:(NSString *)colorString;
- (NSString *)stringRepresentation;
@end

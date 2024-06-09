#import <Foundation/Foundation.h>

int main(int argc, char** argv, char** env)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  NSProcessInfo *pInfo;
  NSArray *arguments;

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env_c];
#endif

  pInfo = [NSProcessInfo processInfo];
  arguments = [pInfo arguments];

  NSString* BASE_DIR = @"/sys/class/backlight/intel_backlight";
  NSString* MAX_FILE = [BASE_DIR stringByAppendingPathComponent:@"max_brightness"];
  NSString* NOW_FILE = [BASE_DIR stringByAppendingPathComponent:@"actual_brightness"];
  NSString* SET_FILE = [BASE_DIR stringByAppendingPathComponent:@"brightness"];

  NSInteger MAX = [[NSString stringWithContentsOfFile:MAX_FILE] integerValue];
  if (MAX == 0) {
    [pool release];
    return 1;
  }

  NSInteger NOW = [[NSString stringWithContentsOfFile:NOW_FILE] integerValue];

  if ([arguments count] == 1 ) {
    NSLog(@"invalid argument");
    [pool release];
    return 3;
  }
  else if ([[arguments objectAtIndex:1] isEqualToString:@"set"] && [arguments count] >= 3 ) {
    float per = [[arguments objectAtIndex:2] floatValue];
    if (per == 0) NOW = 0;
    else if (per >= 100) NOW = MAX;
    else NOW = (MAX * (per / 100));
  }
  else if ([[arguments objectAtIndex:1] isEqualToString:@"inc"]) {
    NOW += 1000;
    if (NOW > MAX) NOW = MAX;
  }
  else if ([[arguments objectAtIndex:1] isEqualToString:@"dec"]) {
    NOW -= 1000;
    if (NOW < 0) NOW = 0;
  }
  else if ([[arguments objectAtIndex:1] isEqualToString:@"get"]) {
    float per = ((float)NOW / (float)MAX) * 100;

    fprintf(stdout, "%ld\n", (NSInteger)ceil(per));
    [pool release];
    return 0;
  }
  else {
    [pool release];
    return 2;
  }

  NSString* str = [NSString stringWithFormat:@"%ld\n", NOW];
  [str writeToFile:SET_FILE atomically:NO];

  [pool release];

  return 0;
}

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

  NSString* BASE_DIR = @"/sys/module/hid_apple/parameters";
  NSString* SWAP_FN = [BASE_DIR stringByAppendingPathComponent:@"swap_fn_leftctrl"];
  NSString* FN_MODE = [BASE_DIR stringByAppendingPathComponent:@"fnmode"];

  if ([arguments count] == 1 ) {
    NSInteger val = [[NSString stringWithContentsOfFile:FN_MODE] integerValue];
    printf("fnmode=%ld\n", val);

    val = [[NSString stringWithContentsOfFile:SWAP_FN] integerValue];
    printf("swapfn=%ld\n", val);
  }
  else if ([arguments count] >= 3 ) {
    NSInteger val = [[arguments objectAtIndex:1] integerValue];
    if (val == 0) {
      [@"1" writeToFile:FN_MODE atomically:NO];
    }
    else if (val == 1) {
      [@"2" writeToFile:FN_MODE atomically:NO];
    }

    val = [[arguments objectAtIndex:2] integerValue];
    if (val >= 0) {
      NSString* str = [NSString stringWithFormat:@"%ld\n", val];
      [str writeToFile:SWAP_FN atomically:NO];
    }
  }
  else {
    NSLog(@"invalid arguments");
  }

  [pool release];

  return 0;
}

#include <libinput.h>
#include "input.h"
#import <Foundation/Foundation.h>

int main(int argc, char* argv[]) {
    if (!initialize_context()) {
        NSLog(@"unable to initialize context");
        return 1;
    }

    setbuf(stdout, NULL);
    start_loop();

    return 0;
}

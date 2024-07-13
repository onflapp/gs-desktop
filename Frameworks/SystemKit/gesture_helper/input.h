#ifndef INPUT_HPP
#define INPUT_HPP

#include <libinput.h>
#include <fcntl.h>
#include <zconf.h>
#include <time.h>
#include <sys/time.h>
#import <Foundation/Foundation.h>

static struct libinput_interface libinput_interface;
static struct libinput* libinput;
static struct libinput_event* libinput_event;
static struct udev* udev;
static struct timeval last_time;
static double scroll_delta;
static int scroll_dir;
static int scroll_count;
static int hold_fingers;
static int swipe_fingers;
static int swipe_x;
static int swipe_y;

BOOL initialize_context();
void close_context();
void start_loop();
BOOL device_exists();
void handle_event();
void handle_hold(struct libinput_event_gesture* gev, int state);

#ifdef HAS_LIBINPUT19
void handle_scroll(struct libinput_event_pointer* ev);
#endif //HAS_LIBINPUT19

#endif //INPUT_HPP

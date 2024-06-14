#include <poll.h>
#include <unistd.h>
#include "input.h"

static int open_restricted(const char* path, int flags, void* user_data) {
    int fd = open(path, flags);
    return fd<0 ? -errno : fd;
}

static void close_restricted(int fd, void* user_data) {
    close(fd);
}


BOOL initialize_context() {
    last_time.tv_usec = 0;
    last_time.tv_sec = 0;
    scroll_delta = 0;
    scroll_count = 0;
    scroll_dir = 0;

    libinput_interface.open_restricted = open_restricted,
    libinput_interface.close_restricted = close_restricted,

    udev = udev_new();
    libinput = libinput_udev_create_context(&libinput_interface, NULL, udev);
    if (libinput_udev_assign_seat(libinput, "seat0") == 0) {
        return device_exists();
    }
    else {
        return NO;
    }
}

void start_loop() {
    struct pollfd fds;
    fds.fd = libinput_get_fd(libinput);
    fds.events = POLLIN;
    fds.revents = 0;

    while (poll(&fds, 1, -1)>-1) {
        handle_event();
    }
}

void close_context() {
    libinput_unref(libinput);
}

BOOL device_exists() {
    BOOL device_found = NO;
    while ((libinput_event = libinput_get_event(libinput)) != NULL) {
        void* device = libinput_event_get_device(libinput_event);
        if (libinput_device_has_capability(device, LIBINPUT_DEVICE_CAP_GESTURE)) {
            device_found = YES;
        }

        libinput_event_destroy(libinput_event);
        libinput_dispatch(libinput);
    }
    return device_found;
}


void handle_hold(struct libinput_event_gesture* gev, int state) {
    int count = libinput_event_gesture_get_finger_count(gev);
    if (state == 1) {
        hold_fingers = count;
    }
    else {
        if (hold_fingers > 2) {
            printf("HOLD%d\n", hold_fingers);
        }
        hold_fingers = 0;
    }
}

#ifdef HAS_LIBINPUT19
void handle_scroll(struct libinput_event_pointer* ev) {
    int has_vert = libinput_event_pointer_has_axis(ev, LIBINPUT_POINTER_AXIS_SCROLL_VERTICAL);
    if (!has_vert) return;

    hold_fingers = 0;

    //double x = libinput_event_pointer_get_scroll_value(ev, LIBINPUT_POINTER_AXIS_SCROLL_HORIZONTAL);
    double y = libinput_event_pointer_get_scroll_value(ev, LIBINPUT_POINTER_AXIS_SCROLL_VERTICAL);
    if (y > 0 && (scroll_dir == 0 || scroll_dir == 1)) {
        scroll_dir = 1;
        scroll_delta += y;
    }
    else if (y < 0 && (scroll_dir == 0 || scroll_dir == -1)) {
        scroll_dir = -1;
        scroll_delta -= y;
    }
    else {
        last_time.tv_sec = 0;
        scroll_delta = 0;
        scroll_dir = 0;
        scroll_count = 0;
    }

    if (scroll_dir != 0) {
        struct timeval t;
        struct timeval d;
        gettimeofday(&t, NULL);

        timersub(&t, &last_time, &d);
        int x = d.tv_usec / 10000;
        //NSLog(@">> %d.%d %d", d.tv_sec, x, scroll_count);

        if (scroll_delta > 10 && x > 10) {
            if (scroll_dir > 0) {
                printf("SCROLL_DOWN\n");
            }
            else if (scroll_dir < 0) {
                printf("SCROLL_UP\n");
            }

            last_time.tv_sec = t.tv_sec;
            last_time.tv_usec = t.tv_usec;
            scroll_delta = 0;
            scroll_count = 0;
            scroll_dir = 0;
        }
    }
}
#endif //HAS_LIBINPUT19

void handle_event() {
    libinput_dispatch(libinput);
    while ((libinput_event = libinput_get_event(libinput))) {
        int type = libinput_event_get_type(libinput_event);
        switch (type) {
        case LIBINPUT_EVENT_GESTURE_SWIPE_BEGIN:
            break;
        case LIBINPUT_EVENT_GESTURE_SWIPE_UPDATE:
            break;
        case LIBINPUT_EVENT_GESTURE_SWIPE_END:
            break;
        case LIBINPUT_EVENT_NONE:
            break;
        case LIBINPUT_EVENT_DEVICE_ADDED:
            break;
        case LIBINPUT_EVENT_DEVICE_REMOVED:
            break;
        case LIBINPUT_EVENT_KEYBOARD_KEY:
            break;
        case LIBINPUT_EVENT_POINTER_MOTION:
            break;
        case LIBINPUT_EVENT_POINTER_MOTION_ABSOLUTE:
            break;
        case LIBINPUT_EVENT_POINTER_BUTTON:
            break;
        case LIBINPUT_EVENT_POINTER_AXIS:
            break;
        case LIBINPUT_EVENT_TOUCH_DOWN:
            break;
        case LIBINPUT_EVENT_TOUCH_UP:
            break;
        case LIBINPUT_EVENT_TOUCH_MOTION:
            break;
        case LIBINPUT_EVENT_TOUCH_CANCEL:
            break;
        case LIBINPUT_EVENT_TOUCH_FRAME:
            break;
        case LIBINPUT_EVENT_TABLET_TOOL_AXIS:
            break;
        case LIBINPUT_EVENT_TABLET_TOOL_PROXIMITY:
            break;
        case LIBINPUT_EVENT_TABLET_TOOL_TIP:
            break;
        case LIBINPUT_EVENT_TABLET_TOOL_BUTTON:
            break;
        case LIBINPUT_EVENT_TABLET_PAD_BUTTON:
            break;
        case LIBINPUT_EVENT_TABLET_PAD_RING:
            break;
        case LIBINPUT_EVENT_TABLET_PAD_STRIP:
            break;
        case LIBINPUT_EVENT_GESTURE_PINCH_BEGIN:
            break;
        case LIBINPUT_EVENT_GESTURE_PINCH_UPDATE:
            break;
        case LIBINPUT_EVENT_GESTURE_PINCH_END:
            break;
        case LIBINPUT_EVENT_SWITCH_TOGGLE:
            break;
#ifdef HAS_LIBINPUT19
        case LIBINPUT_EVENT_GESTURE_HOLD_BEGIN:
            handle_hold(libinput_event_get_gesture_event(libinput_event), 1);
            break;
        case LIBINPUT_EVENT_GESTURE_HOLD_END:
            handle_hold(libinput_event_get_gesture_event(libinput_event), 0);
            break;
        case LIBINPUT_EVENT_POINTER_SCROLL_FINGER:
            handle_scroll(libinput_event_get_pointer_event(libinput_event));
            break;
#endif //HAS_LIBINPUT19
        }

        libinput_event_destroy(libinput_event);
        libinput_dispatch(libinput);
    }
}

// Minimal lights HAL for the iFLYTEK CB-C6 (Unisoc UD710 / sprd_backlight).
//
// The stock vendor module (lights.ud710.so) does not map the framework's
// 0..255 brightness onto the sysfs range in a monotonic way: after switching
// to an Android 13 GSI the same slider position produced wildly different
// backlight values, so the slider looked broken and flickered.
//
// This module implements the tiny "backlight only" subset of LIGHTS_HARDWARE_MODULE_ID
// and does a plain linear map: sysfs = brightness * max / 255, which is what the
// original Android 9 firmware effectively did.

#include <hardware/hardware.h>
#include <hardware/lights.h>

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BL_PATH "/sys/class/backlight/sprd_backlight/brightness"
#define BL_MAX_PATH "/sys/class/backlight/sprd_backlight/max_brightness"
#define BL_DEFAULT_MAX 1023

static int write_int(const char* path, int value) {
    char buf[16];
    int len = snprintf(buf, sizeof(buf), "%d", value);
    if (len <= 0) return -EINVAL;

    int fd = open(path, O_WRONLY | O_CLOEXEC);
    if (fd < 0) return -errno;

    ssize_t written = write(fd, buf, (size_t)len);
    int err = (written == (ssize_t)len) ? 0 : -EIO;
    close(fd);
    return err;
}

static int read_int(const char* path, int fallback) {
    char buf[16];
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return fallback;

    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    close(fd);
    if (n <= 0) return fallback;

    buf[n] = '\0';
    int value = atoi(buf);
    return value > 0 ? value : fallback;
}

static int set_light_backlight(struct light_device_t* dev,
                               const struct light_state_t* state) {
    (void)dev;

    // The framework passes the 0..255 slider value in the low byte of color
    // (possibly also replicated into the alpha channel).
    int brightness = (int)(state->color & 0xFF);
    if (brightness < 0) brightness = 0;
    if (brightness > 255) brightness = 255;

    static int cached_max = 0;
    if (cached_max <= 0) {
        cached_max = read_int(BL_MAX_PATH, BL_DEFAULT_MAX);
    }

    int value = (brightness * cached_max + 127) / 255;
    if (value > cached_max) value = cached_max;

    return write_int(BL_PATH, value);
}

static int set_light_others(struct light_device_t* dev,
                            const struct light_state_t* state) {
    (void)dev;
    (void)state;
    return 0;
}

static int close_light(struct hw_device_t* dev) {
    if (dev) free(dev);
    return 0;
}

static int open_lights(const struct hw_module_t* module, const char* name,
                       struct hw_device_t** device) {
    int (*set_light)(struct light_device_t*, const struct light_state_t*);

    if (name == NULL) return -EINVAL;

    if (strcmp(LIGHT_ID_BACKLIGHT, name) == 0) {
        set_light = set_light_backlight;
    } else if (strcmp(LIGHT_ID_BUTTONS, name) == 0 ||
               strcmp(LIGHT_ID_KEYBOARD, name) == 0 ||
               strcmp(LIGHT_ID_BATTERY, name) == 0 ||
               strcmp(LIGHT_ID_NOTIFICATIONS, name) == 0 ||
               strcmp(LIGHT_ID_ATTENTION, name) == 0 ||
               strcmp(LIGHT_ID_BLUETOOTH, name) == 0 ||
               strcmp(LIGHT_ID_WIFI, name) == 0) {
        set_light = set_light_others;
    } else {
        return -EINVAL;
    }

    struct light_device_t* dev = calloc(1, sizeof(struct light_device_t));
    if (dev == NULL) return -ENOMEM;

    dev->common.tag = HARDWARE_DEVICE_TAG;
    dev->common.version = LIGHTS_DEVICE_API_VERSION_2_0;
    dev->common.module = (struct hw_module_t*)module;
    dev->common.close = close_light;
    dev->set_light = set_light;

    *device = (struct hw_device_t*)dev;
    return 0;
}

static struct hw_module_methods_t light_module_methods = {
    .open = open_lights,
};

struct hw_module_t HAL_MODULE_INFO_SYM = {
    .tag = HARDWARE_MODULE_TAG,
    .module_api_version = HARDWARE_MODULE_API_VERSION(2, 0),
    .hal_api_version = HARDWARE_HAL_API_VERSION,
    .id = LIGHTS_HARDWARE_MODULE_ID,
    .name = "sprd_backlight linear lights HAL",
    .author = "WorkBuddy",
    .methods = &light_module_methods,
};

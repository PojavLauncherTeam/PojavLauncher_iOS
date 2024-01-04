#pragma once

#include <stdlib.h>
#include "gl_bridge.h"
#include "osm_bridge.h"

typedef union {
    gl_render_window_t gl;
    osm_render_window_t osm;
} basic_render_window_t;

typedef basic_render_window_t* (*br_init_context_t)(basic_render_window_t* share);
typedef void (*br_make_current_t)(basic_render_window_t* bundle);
typedef basic_render_window_t* (*br_get_current_t)();

bool (*br_init)();
br_init_context_t br_init_context;
br_make_current_t br_make_current;
//br_get_current_t br_get_current = NULL;
void (*br_swap_buffers)();
void (*br_setup_window)();
void (*br_swap_interval)(int swapInterval);
void (*br_terminate)();

static __thread basic_render_window_t* currentBundle;
static inline basic_render_window_t* br_get_current() {
    return currentBundle;
}

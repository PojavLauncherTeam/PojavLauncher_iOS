#pragma once

#import <QuartzCore/QuartzCore.h>
#include <EGL/egl.h>
#include <GL/osmesa.h>

typedef struct {
    GLboolean (*OSMesaMakeCurrent) (OSMesaContext ctx, void *buffer, GLenum type, GLsizei width, GLsizei height);
    OSMesaContext (*OSMesaGetCurrentContext) (void);
OSMesaContext  (*OSMesaCreateContext) (GLenum format, OSMesaContext sharelist);
    void (*OSMesaDestroyContext) (OSMesaContext ctx);
    void (*OSMesaPixelStore) ( GLint pname, GLint value );
    GLubyte* (*glGetString) (GLenum name);
    void (*glFinish) (void);
    void (*glClearColor) (GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
    void (*glClear) (GLbitfield mask);
} osmesa_library;

typedef struct {
    OSMesaContext context;
    uint32_t width, height;
    CGColorSpaceRef color_space;
    void* buffer;
} osm_render_window_t;

void osm_swap_buffers();
void set_osm_bridge_tbl();

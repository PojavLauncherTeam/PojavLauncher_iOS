#include <assert.h>
#include <dlfcn.h>
#include <stdio.h>
// #include "log.h"

#include "GL/gl.h"

void(*orig_glTexSubImage2D)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *data);

// Nothing here now
#if 0
#define LOOKUP_FUNC(func) \
    if (!orig_##func) { \
        orig_##func = dlsym(RTLD_NEXT, #func); \
    } if (!orig_##func) { \
        orig_##func = dlsym(RTLD_DEFAULT, #func); \
    }

void glTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *data) {
    LOOKUP_FUNC(glTexSubImage2D)
    printf("glTexSubImage2D(target=%d, level=%d xoffset=%d yoffset=%d width=%d height=%d format=%d type=%d data=%p)\n", target, level, xoffset, yoffset, width, height, format, type, data);
/*
    if (type == GL_UNSIGNED_INT_8_8_8_8_REV) {
        type = GL_UNSIGNED_BYTE;
    }
*/
    orig_glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type, data);
}
#endif

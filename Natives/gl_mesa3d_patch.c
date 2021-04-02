#include <assert.h>
#include <dlfcn.h>
// #include "log.h"

#include "GL/gl.h"

void (*glDrawArrays_real) (GLenum mode, GLint first, GLsizei count);

GLAPI void GLAPIENTRY glDrawArrays(GLenum mode, GLint first, GLsizei count) {
    if (!glDrawArrays_real) {
        glDrawArrays_real = dlsym(RTLD_NEXT, "glDrawArrays");
    } if (!glDrawArrays_real) {
        glDrawArrays_real = dlsym(RTLD_DEFAULT, "glDrawArrays");
    }

    // debug("func=%p, next=%p", glDrawArrays, glDrawArrays_real);

    assert(glDrawArrays != glDrawArrays_real);

    // debug("glDrawArrays mode=%p", mode);
    if (mode == GL_TRIANGLE_FAN) {
        // debug("ERROR: GL_TRIANGLE_FAN unsupported!");
        
        // this is wrong but idk how to deal with it yet...
        // minecraft stills works with this for unknown reason
        glDrawArrays_real(GL_TRIANGLE_STRIP, first, count);
        return;
    }

    glDrawArrays_real(mode, first, count);
}

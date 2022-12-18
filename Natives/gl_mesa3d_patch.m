#include <assert.h>
#include <dlfcn.h>
// #include "log.h"

#include "GL/gl.h"

void (*glDrawArrays_p) (GLenum mode, GLint first, GLsizei count);

GLAPI void GLAPIENTRY glDrawArrays(GLenum mode, GLint first, GLsizei count) {
    if (!glDrawArrays_p) {
        glDrawArrays_p = dlsym(RTLD_NEXT, "glDrawArrays");
    }

    // NSDebugLog(@"func=%p, next=%p", glDrawArrays, glDrawArrays_real);
    // NSDebugLog(@"glDrawArrays mode=%p", mode);
    if (mode == GL_TRIANGLE_FAN) {
        // NSDebugLog(@"ERROR: GL_TRIANGLE_FAN unsupported!");
        
        // this is wrong but idk how to deal with it yet...
        // minecraft stills works with this for unknown reason
        glDrawArrays_p(GL_TRIANGLE_STRIP, first, count);
    } else {
        glDrawArrays_p(mode, first, count);
    }
}

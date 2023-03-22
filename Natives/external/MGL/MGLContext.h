/*
  MGLContext.h
  mgl
  Created by Michael Larson on 12/17/21.
*/

#ifndef MGLContext_h
#define MGLContext_h

#ifndef __GLM_CONTEXT_
#define __GLM_CONTEXT_
typedef struct GLMContextRec_t *GLMContext;
#endif

GLMContext createGLMContext(GLenum format, GLenum type,
                            GLenum depth_format, GLenum depth_type,
                            GLenum stencil_format, GLenum stencil_type);

void MGLsetCurrentContext(GLMContext ctx);
void MGLswapBuffers(GLMContext ctx);

enum {
    MGL_PIXEL_FORMAT,
    MGL_PIXEL_TYPE,
    MGL_DEPTH_FORMAT,
    MGL_DEPTH_TYPE,
    MGL_STENCIL_FORMAT,
    MGL_STENCIL_TYPE,
    MGL_CONTEXT_FLAGS
};

#ifdef __cplusplus
extern "C" {
#endif

GLuint sizeForFormatType(GLenum format, GLenum type);
GLuint bicountForFormatType(GLenum format, GLenum type, GLenum component);

GLMContext MGLgetCurrentContext(void);
void MGLsetCurrentContext(GLMContext ctx);
void MGLswapBuffers(GLMContext ctx);
void MGLget(GLMContext ctx, GLenum param, GLuint *data);

#ifdef __cplusplus
};
#endif

#endif

#import <Foundation/Foundation.h>
#include <stdio.h>
#include <dlfcn.h>

#define GL_GLEXT_PROTOTYPES

#include "GL/gl.h"
#include "GL/glext.h"
//#include "GLES3/gl32.h"
#include "string_utils.h"

#define LOOKUP_FUNC(func) \
    if (!gles_##func) { \
        gles_##func = dlsym(RTLD_NEXT, #func); \
    } if (!gles_##func) { \
        gles_##func = dlsym(RTLD_DEFAULT, #func); \
    }

#define AliasDecl(NAME, EXT) \
    asm(".global _"# NAME "\n_" #NAME ": b _" #NAME #EXT);

// Core OpenGL 2.0
AliasDecl(glGetTexImage, ANGLE)
AliasDecl(glMapBuffer, OES)

// GL_KHR_debug
AliasDecl(glDebugMessageCallback, KHR)
AliasDecl(glDebugMessageControl, KHR)
AliasDecl(glDebugMessageInsert, KHR)
AliasDecl(glGetDebugMessageLog, KHR)
AliasDecl(glGetObjectLabel, KHR)
AliasDecl(glObjectLabel, KHR)
AliasDecl(glPopDebugGroup, KHR)
AliasDecl(glPushDebugGroup, KHR)

// GL_EXT_blend_func_extended
AliasDecl(glBindFragDataLocation, EXT)
AliasDecl(glBindFragDataLocationIndexed, EXT)

int proxy_width, proxy_height, proxy_intformat, maxTextureSize;

void(*gles_glCopyTexSubImage2D)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);
//void glGetBufferParameteriv(GLenum target, GLenum value, GLint * data);
void(*gles_glGetTexLevelParameteriv)(GLenum target, GLint level, GLenum pname, GLint *params);
void(*gles_glShaderSource)(GLuint shader, GLsizei count, const GLchar * const *string, const GLint *length);
void(*gles_glTexImage2D)(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *data);
void(*gles_glTexSubImage2D)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *data);
void(*gles_glTexParameterfv)(GLenum target, GLenum pname, const GLfloat *params);

void glClearDepth(GLdouble depth) {
    glClearDepthf(depth);
}

void glShaderSource(GLuint shader, GLsizei count, const GLchar * const *string, const GLint *length) {
    LOOKUP_FUNC(glShaderSource)

    // DBG(printf("glShaderSource(%d, %d, %p, %p)\n", shader, count, string, length);)
    char *source = NULL;
    char *converted;

    // get the size of the shader sources and than concatenate in a single string
    int l = 0;
    for (int i=0; i<count; i++) l+=(length && length[i] >= 0)?length[i]:strlen(string[i]);
    if (source) free(source);
    source = calloc(1, l+1);
    if(length) {
        for (int i=0; i<count; i++) {
            if(length[i] >= 0)
                strncat(source, string[i], length[i]);
            else
                strcat(source, string[i]);
        }
    } else {
        for (int i=0; i<count; i++)
            strcat(source, string[i]);
    }
    
    char *source2 = strchr(source, '#');
    if (!source2) {
        source2 = source;
    }
    // are there #version?
    if (!strncmp(source2, "#version ", 9)) {
        if (!strncmp(&source2[13], "es", 2)) {
            // This is for gl4es. TODO: maybe remove 'es' aswell?
            return;
        }
        converted = strdup(source2);
        if (converted[9] == '1') {
            if (converted[10] - '0' < 2) {
                // 100, 110 -> 120
                //converted[10] = '2';
            } else if (converted[10] - '0' < 6) {
                // 130, 140, 150 -> 330
                converted[9] = converted[10] = '3';
            }
        }
        // remove "core", is it safe?
        if (!strncmp(&converted[13], "core", 4)) {
            strncpy(&converted[13], "\n//c", 4);
        }
    } else {
        converted = calloc(1, strlen(source) + 13);
        strcpy(converted, "#version 120\n");
        strcpy(&converted[13], strdup(source));
    }

    int convertedLen = strlen(converted);

#ifdef __APPLE__
    // patch OptiFine 1.17.x
    if (FindString(converted, "\nuniform mat4 textureMatrix = mat4(1.0);")) {
        InplaceReplace(converted, &convertedLen, "\nuniform mat4 textureMatrix = mat4(1.0);", "\n#define textureMatrix mat4(1.0)");
    }
#endif

    // Workaround unassigned outputs: use gl_FragData[] instead of separate color outputs
    char tmpOutFindLine[20];
    char tmpOutReplaceLine[33];
    strncpy(tmpOutFindLine, "out vec4 outColor0;", 20);
    strncpy(tmpOutReplaceLine, "#define outColor0 gl_FragData[0]", 33);
    for (int i = 0; i < 8; i++) {
        tmpOutFindLine[17] = '0'+i;
        if (FindString(converted, tmpOutFindLine)) {
            tmpOutReplaceLine[16] = '0'+i;
            tmpOutReplaceLine[30] = '0'+i;
            converted = InplaceReplace(converted, &convertedLen, tmpOutFindLine, tmpOutReplaceLine);
        }
    }

    // some needed exts
    const char* extensions =
        "#extension GL_EXT_blend_func_extended : enable\n"
        "#extension GL_EXT_draw_buffers : enable\n"
        // For OptiFine (see patch above)
        "#extension GL_EXT_shader_non_constant_global_initializers : enable\n";
    converted = InplaceInsert(GetLine(converted, 1), extensions, converted, &convertedLen);

    //printf("[tinygl4angle] glShaderSource: %s\n", converted);

    gles_glShaderSource(shader, 1, (const GLchar * const*)((converted)?(&converted):(&source)), NULL);

    free(source);
    free(converted);
}

int isProxyTexture(GLenum target) {
    switch (target) {
        case GL_PROXY_TEXTURE_1D:
        case GL_PROXY_TEXTURE_2D:
        case GL_PROXY_TEXTURE_3D:
        case GL_PROXY_TEXTURE_RECTANGLE_ARB:
            return 1;
    }
    return 0;
}

static int inline nlevel(int size, int level) {
    if(size) {
        size>>=level;
        if(!size) size=1;
    }
    return size;
}

void glGetTexLevelParameteriv(GLenum target, GLint level, GLenum pname, GLint *params) {
    LOOKUP_FUNC(glGetTexLevelParameteriv)
    // NSLog("glGetTexLevelParameteriv(%x, %d, %x, %p)", target, level, pname, params);
    if (isProxyTexture(target)) {
        switch (pname) {
            case GL_TEXTURE_WIDTH:
                (*params) = nlevel(proxy_width,level);
                break;
            case GL_TEXTURE_HEIGHT: 
                (*params) = nlevel(proxy_height,level);
                break;
            case GL_TEXTURE_INTERNAL_FORMAT:
                (*params) = proxy_intformat;
                break;
        }
    } else {
        gles_glGetTexLevelParameteriv(target, level, pname, params);
    }
}

void glTexImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *data) {
    LOOKUP_FUNC(glTexImage2D)

    if (type == GL_UNSIGNED_INT_8_8_8_8_REV) {
        type = GL_UNSIGNED_BYTE;
    }

    if (isProxyTexture(target)) {
        if (!maxTextureSize) {
            glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
            // maxTextureSize = 16384;
            // NSLog(@"Maximum texture size: %d", maxTextureSize);
        }
        proxy_width = ((width<<level)>maxTextureSize)?0:width;
        proxy_height = ((height<<level)>maxTextureSize)?0:height;
        proxy_intformat = internalformat;
        // swizzle_internalformat((GLenum *) &internalformat, format, type);
    } else {
        gles_glTexImage2D(target, level, internalformat, width, height, border, format, type, data);
    }
}


void glTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *data) {
    LOOKUP_FUNC(glTexSubImage2D)
    if (type == GL_UNSIGNED_INT_8_8_8_8_REV) {
        type = GL_UNSIGNED_BYTE;
    }
    gles_glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type, data);
}


void glTexParameterfv(GLenum target, GLenum pname, const GLfloat *params) {
    LOOKUP_FUNC(glTexParameterfv)
    if (pname != GL_TEXTURE_LOD_BIAS) {
        gles_glTexParameterfv(target, pname, params);
    }
}
void glTexParameterf(GLenum target, GLenum pname, GLfloat param) {
    glTexParameterfv(target, pname, &param);
}

// Handle reading depth buffer
void glReadBuffer(GLenum mode) {
    // Override with stub
}

void glCopyTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height) {
    if (target != GL_TEXTURE_2D) {
        LOOKUP_FUNC(glCopyTexSubImage2D)
        gles_glCopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
    }

    // Override with stub
#if 0
    float *pixels = malloc(width*height*sizeof(float));
    for (int i = 0; i < width*height; i++) {
        pixels[i] = 0.5f;
    }
    glTexSubImage2D(target, level, xoffset, yoffset, width, height, GL_DEPTH_COMPONENT, GL_FLOAT, pixels);
    free(pixels);
#endif

#if 0
    static GLuint depthFB;
    if (!depthFB) {
        glGenFramebuffers(1, &depthFB);
    }
    int fbID, texID;
    glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &fbID);
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &texID);
    //glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, depthFB);
    glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, target, texID, level);
    assert(glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
    glBlitFramebuffer(xoffset, yoffset, width, height, x, y, width, height, GL_DEPTH_BUFFER_BIT, GL_NEAREST);
    glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, target, 0, level);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fbID);
#endif
}

// VertexArray stuff
#define THUNK(suffix, type, M2) \
void  glVertexAttrib1##suffix (GLuint index, type v0) { GLfloat f[4] = {0,0,0,1}; f[0] =v0; glVertexAttrib4fv(index, f); }; \
void  glVertexAttrib2##suffix (GLuint index, type v0, type v1) { GLfloat f[4] = {0,0,0,1}; f[0] =v0; f[1]=v1; glVertexAttrib4fv(index, f); }; \
void  glVertexAttrib3##suffix (GLuint index, type v0, type v1, type v2) { GLfloat f[4] = {0,0,0,1}; f[0] =v0; f[1]=v1; f[2]=v2; glVertexAttrib4fv(index, f); }; \
void  glVertexAttrib4##suffix (GLuint index, type v0, type v1, type v2, type v3) { GLfloat f[4] = {0,0,0,1}; f[0] =v0; f[1]=v1; f[2]=v2; f[3]=v3; glVertexAttrib4fv(index, f); }; \
void  glVertexAttrib1##suffix##v (GLuint index, const type *v) { GLfloat f[4] = {0,0,0,1}; f[0] =v[0]; glVertexAttrib4fv(index, f); }; \
void  glVertexAttrib2##suffix##v (GLuint index, const type *v) { GLfloat f[4] = {0,0,0,1}; f[0] =v[0]; f[1]=v[1]; glVertexAttrib4fv(index, f); }; \
void  glVertexAttrib3##suffix##v (GLuint index, const type *v) { GLfloat f[4] = {0,0,0,1}; f[0] =v[0]; f[1]=v[1]; f[2]=v[2]; glVertexAttrib4fv(index, f); };
THUNK(s, GLshort, );
THUNK(d, GLdouble, _D);
#undef THUNK
void  glVertexAttrib4dv (GLuint index, const GLdouble *v) { GLfloat f[4] = {0,0,0,1}; f[0] =v[0]; f[1]=v[1]; f[2]=v[2]; f[3]=v[3]; glVertexAttrib4fv(index, f); };

#define THUNK(suffix, type, norm) \
void  glVertexAttrib4##suffix##v (GLuint index, const type *v) { GLfloat f[4] = {0,0,0,1}; f[0] =v[0]; f[1]=v[1]; f[2]=v[2]; f[3]=v[3]; glVertexAttrib4fv(index, f); }; \
void  glVertexAttrib4N##suffix##v (GLuint index, const type *v) { GLfloat f[4] = {0,0,0,1}; f[0] =v[0]/norm; f[1]=v[1]/norm; f[2]=v[2]/norm; f[3]=v[3]/norm; glVertexAttrib4fv(index, f); };
THUNK(b, GLbyte, 127.0f);
THUNK(ub, GLubyte, 255.0f);
THUNK(s, GLshort, 32767.0f);
THUNK(us, GLushort, 65535.0f);
THUNK(i, GLint, 2147483647.0f);
THUNK(ui, GLuint, 4294967295.0f);
#undef THUNK
void glVertexAttrib4Nub(GLuint index, GLubyte v0, GLubyte v1, GLubyte v2, GLubyte v3) {GLfloat f[4] = {0,0,0,1}; f[0] =v0/255.f; f[1]=v1/255.f; f[2]=v2/255.f; f[3]=v3/255.f; glVertexAttrib4fv(index, f); };

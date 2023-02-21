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

int proxy_width, proxy_height, proxy_intformat, maxTextureSize;

//void glBindFragDataLocationEXT(GLuint program, GLuint colorNumber, const char * name);
//void glClearDepthf(GLclampf depth);
//void glGetBufferParameteriv(GLenum target, GLenum value, GLint * data);

void(*gles_glGetTexLevelParameteriv)(GLenum target, GLint level, GLenum pname, GLint *params);
void(*gles_glShaderSource)(GLuint shader, GLsizei count, const GLchar * const *string, const GLint *length);
void(*gles_glTexImage2D)(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *data);

void glBindFragDataLocation(GLuint program, GLuint colorNumber, const char * name) {
    glBindFragDataLocationEXT(program, colorNumber, name);
}

void glClearDepth(GLdouble depth) {
    glClearDepthf(depth);
}

void *glMapBuffer(GLenum target, GLenum access) {
    // Use: GL_EXT_map_buffer_range

    GLenum access_range;
    GLint length;

    switch (target) {
        // GL 4.2
        case GL_ATOMIC_COUNTER_BUFFER:

        // GL 4.3
        case GL_DISPATCH_INDIRECT_BUFFER:
        case GL_SHADER_STORAGE_BUFFER	:

        // GL 4.4
        case GL_QUERY_BUFFER:
            printf("ERROR: glMapBuffer unsupported target=0x%x", target);
            break; // not supported for now

	     case GL_DRAW_INDIRECT_BUFFER:
        case GL_TEXTURE_BUFFER:
            printf("ERROR: glMapBuffer unimplemented target=0x%x", target);
            break;
    }

    switch (access) {
        case GL_READ_ONLY:
            access_range = GL_MAP_READ_BIT;
            break;

        case GL_WRITE_ONLY:
            access_range = GL_MAP_WRITE_BIT;
            break;

        case GL_READ_WRITE:
            access_range = GL_MAP_READ_BIT | GL_MAP_WRITE_BIT;
            break;
    }

    glGetBufferParameteriv(target, GL_BUFFER_SIZE, &length);
    return glMapBufferRange(target, 0, length, access_range);
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

    // some needed exts
    const char* extensions =
        "#extension GL_EXT_blend_func_extended : enable\n"
        // For OptiFine (see patch above)
        "#extension GL_EXT_shader_non_constant_global_initializers : enable\n";
    converted = InplaceInsert(GetLine(converted, 1), extensions, converted, &convertedLen);

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

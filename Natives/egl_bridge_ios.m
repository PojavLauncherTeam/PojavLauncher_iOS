// Based on https://github.com/jschwartzenberg/openjfx8/blob/master/modules/graphics/src/main/native-prism-es2/ios/IOSWindowSystemInterface.m

/*
 * Copyright (c) 2012, 2014, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <dlfcn.h>

#import "egl_bridge_ios.h"

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#if defined (_LP64)
# define jlong_to_ptr(a) ((void*)(a))
# define ptr_to_jlong(a) ((jlong)(a))
#else
# define jlong_to_ptr(a) ((void*)(int)(a))
# define ptr_to_jlong(a) ((jlong)(int)(a))
#endif

void *createContext() {
    EAGLContext *ctx = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    return ptr_to_jlong(ctx);
}

void *getCurrentContext() {
    EAGLContext *ctx = [EAGLContext currentContext];
    return ptr_to_jlong(ctx);
}

typedef GLKView* Main_obtainGLKView();

GLuint RenderBuffer;
GLuint FrameBuffer;
GLuint DepthBuffer;
void *initCurrentContext() {
    Main_obtainGLKView *obtainGLKView = (Main_obtainGLKView *) dlsym(RTLD_DEFAULT, "obtainGLKView");
    if (!obtainGLKView) {
        NSLog(@"Unable to locate obtainGLKView");
    }
    GLKView* view = obtainGLKView();

    EAGLContext *ctx = [EAGLContext currentContext];
    
    glGenFramebuffersOES(1, &FrameBuffer);
    glGenRenderbuffersOES(1, &RenderBuffer);
    glGenRenderbuffersOES(1, &DepthBuffer);

    glBindFramebufferOES(GL_FRAMEBUFFER_OES, FrameBuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, RenderBuffer);

    if (![MainContext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)View.layer])
    {
        NSLog(@"error calling MainContext renderbufferStorage");
        return;
    }

    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, RenderBuffer);

    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &Width);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &Height);

    glBindRenderbufferOES(GL_RENDERBUFFER_OES, DepthBuffer);
    glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, Width, Height);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, DepthBuffer);

    glFlush();

    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
    }
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, FrameBuffer);
    
    return ptr_to_jlong(ctx);
}

jboolean makeCurrentContextShared(void *context) {
    EAGLSharegroup *group = ((__bridge EAGLContext *) context).sharegroup;
    EAGLContext sharedContext = nil;
    
    if (!group) {
        NSLog(@"Could not get sharegroup from the main context");
    }
    
    sharedContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3 sharegroup:group];
    if (!sharedContext) {
        sharedContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:group];
        if (!sharedContext) {
            NSLog(@"Could not create sharedContext");
            return JNI_FALSE;
        }
    }
    
    if (!makeCurrentContext((__bridge void *) sharedContext)){
        NSLog(@"Could not make current sharedContext");
        return JNI_FALSE;
    }
}

jboolean makeCurrentContext(void *context) {
    if ([EAGLContext setCurrentContext:(__bridge EAGLContext *)jlong_to_ptr(context)] == YES) {
        return JNI_TRUE;
    }

    return JNI_TRUE;
}

jboolean clearCurrentContext() {
    if ([EAGLContext setCurrentContext:nil] == YES) {
        return JNI_TRUE;
    }

    return JNI_FALSE;
}

void flushBuffer() {
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, RenderBuffer);

    [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
    
    // prepare new buffer
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, FrameBuffer);
}

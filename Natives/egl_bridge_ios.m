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

#import "AppDelegate.h"
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

GLuint RenderBuffer;
GLuint FrameBuffer;
GLuint DepthBuffer;
int Width, Height;
void *initCurrentContext() {
    NSLog(@"Obtaining GLKView");
    GLKView* glkView = obtainGLKView();

    EAGLContext *ctx = [EAGLContext currentContext];
    
    NSLog(@"Initializing framebuffer");
    glGenFramebuffers(1, &FrameBuffer);
    glGenRenderbuffers(1, &RenderBuffer);
    glGenRenderbuffers(1, &DepthBuffer);

    glBindFramebuffer(GL_FRAMEBUFFER, FrameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, RenderBuffer);

    NSLog(@"Initializing renderbuffer");
    if ([ctx renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)glkView.layer] == NO) {
        NSLog(@"error calling MainContext renderbufferStorage");
        return nil;
    }

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, RenderBuffer);

    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &Width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &Height);

    glBindRenderbuffer(GL_RENDERBUFFER, DepthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, Width, Height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, DepthBuffer);

    glFlush();

    NSLog(@"Checking framebuffer status");
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    NSLog(@"Binding framebuffer");
    glBindFramebuffer(GL_FRAMEBUFFER, FrameBuffer);
    
    return ptr_to_jlong(ctx);
}

jboolean makeCurrentContextShared(void *context) {
    EAGLSharegroup *group = ((__bridge EAGLContext *) context).sharegroup;
    if (group == nil) {
        NSLog(@"Could not get sharegroup from the main context");
        return JNI_FALSE;
    }
    
    EAGLContext *sharedContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3 sharegroup:group];
    if (sharedContext == nil) {
        sharedContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:group];
        if (sharedContext == nil) {
            NSLog(@"Could not create sharedContext");
            return JNI_FALSE;
        }
    }
    
    if (makeCurrentContext((__bridge void *) sharedContext) == JNI_FALSE){
        NSLog(@"Could not make current sharedContext");
        return JNI_FALSE;
    }
    
    return JNI_TRUE;
}

jboolean makeCurrentContext(void *context) {
    if ([EAGLContext setCurrentContext:(__bridge EAGLContext *)jlong_to_ptr(context)] == YES) {
        return JNI_TRUE;
    }

    return JNI_FALSE;
}

jboolean clearCurrentContext() {
    if ([EAGLContext setCurrentContext:nil] == YES) {
        return JNI_TRUE;
    }

    return JNI_FALSE;
}

void flushBuffer() {
    glBindRenderbuffer(GL_RENDERBUFFER, RenderBuffer);

    [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
    
    // prepare new buffer
    glBindFramebuffer(GL_FRAMEBUFFER, FrameBuffer);
}

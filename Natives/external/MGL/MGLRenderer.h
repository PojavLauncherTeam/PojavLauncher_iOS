/*
 * Copyright (C) Michael Larson on 1/6/2022
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * MGLRenderer.h
 * MGL
 *
 */

#ifndef MGLRenderer_h
#define MGLRenderer_h

#ifdef __OBJC__

#ifndef __GLM_CONTEXT_
#define __GLM_CONTEXT_
typedef struct GLMContextRec_t *GLMContext;
#endif

@interface MGLRenderer : NSObject

- (void) createMGLRendererAndBindToContext: (GLMContext) glm_ctx view: (UIView *) view;

@end
MTLPixelFormat mtlPixelFormatForGLFormatType(GLenum gl_format, GLenum gl_type);
#else

#ifdef __cplusplus
extern "C" {
#endif

GLenum mtlPixelFormatForGLFormatType(GLenum gl_format, GLenum gl_type);

#ifdef __cplusplus
}
#endif

#endif // #ifdef __OBJC__

#ifdef __cplusplus
extern "C" {
#endif
void* CppCreateMGLRendererAndBindToContext (void *window, void *glm_ctx);
#ifdef __cplusplus
}
#endif


#endif /* MGLRenderer_h */

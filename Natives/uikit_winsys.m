/**************************************************************************
 * 
 * Copyright 2010 VMware, Inc.
 * All Rights Reserved.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sub license, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL
 * THE COPYRIGHT HOLDERS, AUTHORS AND/OR ITS SUPPLIERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE 
 * USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * The above copyright notice and this permission notice (including the
 * next paragraph) shall be included in all copies or substantial portions
 * of the Software.
 * 
 **************************************************************************/

/**
 * @file
 * Null software rasterizer winsys.
 * 
 * There is no present support. Framebuffer data needs to be obtained via
 * transfers.
 *
 * @author Jose Fonseca
 */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdbool.h>

// #include "pipe/p_format.h"
// #include "util/u_memory.h"
// #include "frontend/sw_winsys.h"
#include "uikit_winsys.h"

enum pipe_format{};
struct pipe_resource;
struct sw_displaytarget;
struct winsys_handle;

struct uikit_displaytarget
{
	enum pipe_format format;

	unsigned width;
	unsigned height;
	unsigned stride;

	unsigned size;

	void* data;
};

static bool
uikit_sw_is_displaytarget_format_supported(struct sw_winsys *ws,
                                          unsigned tex_usage,
                                          enum pipe_format format )
{
   return true;
}


static void *
uikit_sw_displaytarget_map(struct sw_winsys *ws,
                          struct sw_displaytarget *dt,
                          unsigned flags )
{
   // assert(0);
   return NULL;
}


static void
uikit_sw_displaytarget_unmap(struct sw_winsys *ws,
                            struct sw_displaytarget *dt )
{
   // assert(0);
}


static void
uikit_sw_displaytarget_destroy(struct sw_winsys *winsys,
                              struct sw_displaytarget *dt)
{
	struct uikit_displaytarget* uikitDisplayTarget
		= uikit_sw_displaytarget(displayTarget);

	if (!uikitDisplayTarget)
		return;

	if (uikitDisplayTarget->data != NULL)
		free(uikitDisplayTarget->data);

	free(uikitDisplayTarget);
}


static struct sw_displaytarget *
uikit_sw_displaytarget_create(struct sw_winsys *winsys,
                             unsigned tex_usage,
                             enum pipe_format format,
                             unsigned width, unsigned height,
                             unsigned alignment,
                             const void *front_private,
                             unsigned *stride)
{
	struct uikit_displaytarget* uikitDisplayTarget
		= calloc(1, sizeof(struct uikit_displaytarget));
	assert(uikitDisplayTarget);

	printf("%s: %d x %d\n", __func__, width, height);

	uikitDisplayTarget->format = format;
	uikitDisplayTarget->width = width;
	uikitDisplayTarget->height = height;

	// size_t formatStride = util_format_get_stride(format, width);
	// unsigned blockSize = util_format_get_nblocksy(format, height);

   unsigned blockSize = 4;

	uikitDisplayTarget->stride = width; // align(formatStride, alignment);
	uikitDisplayTarget->size = uikitDisplayTarget->stride * blockSize;

	uikitDisplayTarget->data = calloc(4, width * height);

	*stride = uikitDisplayTarget->stride;

	// Cast to ghost sw_displaytarget type
	return (struct sw_displaytarget*)uikitDisplayTarget;
}


static struct sw_displaytarget *
uikit_sw_displaytarget_from_handle(struct sw_winsys *winsys,
                                  const struct pipe_resource *templat,
                                  struct winsys_handle *whandle,
                                  unsigned *stride)
{
   return NULL;
}


static bool
uikit_sw_displaytarget_get_handle(struct sw_winsys *winsys,
                                 struct sw_displaytarget *dt,
                                 struct winsys_handle *whandle)
{
   return false;
}


static void
uikit_sw_displaytarget_display(struct sw_winsys *winsys,
                              struct sw_displaytarget *dt,
                              void *context_private,
                              struct pipe_box *box)
{
   printf("displaytarget display\n");
}


static void
uikit_sw_destroy(struct sw_winsys *winsys)
{
   free(winsys);
}


struct sw_winsys *
uikit_sw_create(void)
{
   static struct sw_winsys *winsys;

   winsys = calloc(1, sizeof(struct sw_winsys));
   if (!winsys)
      return NULL;

   winsys->destroy = uikit_sw_destroy;
   winsys->is_displaytarget_format_supported = uikit_sw_is_displaytarget_format_supported;
   winsys->displaytarget_create = uikit_sw_displaytarget_create;
   winsys->displaytarget_from_handle = uikit_sw_displaytarget_from_handle;
   winsys->displaytarget_get_handle = uikit_sw_displaytarget_get_handle;
   winsys->displaytarget_map = uikit_sw_displaytarget_map;
   winsys->displaytarget_unmap = uikit_sw_displaytarget_unmap;
   winsys->displaytarget_display = uikit_sw_displaytarget_display;
   winsys->displaytarget_destroy = uikit_sw_displaytarget_destroy;

   return winsys;
}
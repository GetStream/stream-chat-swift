#ifndef CMARK_REGISTRY_H
#define CMARK_REGISTRY_H

#ifdef __cplusplus
extern "C" {
#endif

#include "cmark-gfm.h"
#include "plugin.h"

CMARK_GFM_EXPORT
void stream_cmark_register_plugin(cmark_plugin_init_func reg_fn);

CMARK_GFM_EXPORT
void stream_cmark_release_plugins(void);

CMARK_GFM_EXPORT
cmark_llist *stream_cmark_list_syntax_extensions(cmark_mem *mem);

#ifdef __cplusplus
}
#endif

#endif
